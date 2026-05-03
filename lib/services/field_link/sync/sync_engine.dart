import 'dart:async';
import 'dart:typed_data';

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/session_config.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/data/repositories/annotation_repository.dart';
import 'package:red_grid_link/data/repositories/marker_repository.dart';
import 'package:red_grid_link/core/logging/red_log.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/services/field_link/security/message_encryptor.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/delta_encoder.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// Single-byte magic prefix identifying an encrypted Field Link envelope.
///
/// SyncPayload plaintext is JSON UTF-8 and therefore always begins with
/// `{` (0x7B). Any byte other than 0x7B in position 0 is unambiguously
/// not a plaintext payload, so a magic byte makes encrypted-vs-plaintext
/// dispatch reliable without parsing.
///
/// Wire format (encrypted): `[0xE7][12-byte IV][ciphertext + 16-byte GCM tag]`
const int _kEncryptedEnvelopeMagic = 0xE7;

/// A control message received from a peer via the sync engine.
class ControlMessage {
  final String senderId;
  final Map<String, dynamic> data;
  const ControlMessage({required this.senderId, required this.data});
}

/// Main sync orchestrator for Field Link.
///
/// The sync engine sits between the transport layer (BLE / P2P) and the
/// UI layer, maintaining a CRDT-based replicated state and converting
/// between compact wire payloads and domain models.
///
/// **Incoming sync loop**:
/// 1. Receive raw bytes from [TransportService.incomingMessages].
/// 2. Decode via [DeltaEncoder].
/// 3. Merge into [CrdtState] (LWW registers + GCounter).
/// 4. Persist to SQLite via repositories.
/// 5. Emit the updated [CrdtState] on [stateStream] for the UI.
///
/// **Outgoing sync**:
/// 1. Local position change -> encode delta -> broadcast.
/// 2. Marker / annotation added -> encode delta -> broadcast.
/// 3. Heartbeat timer -> periodic position broadcast.
class SyncEngine {
  final TransportService _transport;
  final DeltaEncoder _encoder;
  final PeerRepository _peerRepository;
  final MarkerRepository _markerRepository;
  final AnnotationRepository? _annotationRepository;
  final String _localDeviceId;

  CrdtState _state;
  String? _sessionId;
  bool _isRunning = false;

  /// Optional encryptor — set by [start] when the session has a key
  /// (PIN or QR mode). When null, payloads are sent as plaintext.
  ///
  /// Audit 2026-05-03 P0: previously encryption was completely absent
  /// from the sync path despite being claimed in PRIVACY.md.
  MessageEncryptor? _encryptor;

  /// Symmetric key used by [_encryptor]. Derived from PIN+sessionId or
  /// scanned from a QR. Held only in-process; never persisted.
  String? _encryptionKey;

  Timer? _heartbeatTimer;
  StreamSubscription<TransportMessage>? _incomingSub;

  final StreamController<CrdtState> _stateController =
      StreamController<CrdtState>.broadcast();

  final StreamController<ControlMessage> _controlController =
      StreamController<ControlMessage>.broadcast();

  /// Stream of CRDT state updates for UI consumption.
  Stream<CrdtState> get stateStream => _stateController.stream;

  /// Stream of incoming control messages (senderId + data payload).
  ///
  /// Emitted for every control-type [SyncPayload] received from a peer.
  /// Subscribers (e.g., [FieldLinkService]) use this to handle events
  /// like key_exchange, role_assign, callsign_update, etc.
  Stream<ControlMessage> get controlStream => _controlController.stream;

  /// The current CRDT state snapshot.
  CrdtState get currentState => _state;

  /// Whether the sync engine is actively running.
  bool get isRunning => _isRunning;

  /// The local device identifier used as the CRDT node ID.
  String get localDeviceId => _localDeviceId;

  /// Local callsign to include in every position broadcast.
  /// Set by [FieldLinkService] when the user sets their display name.
  String localCallsign = '';

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  /// Total messages received by the sync engine.
  int _diagMessagesReceived = 0;
  int get diagMessagesReceived => _diagMessagesReceived;

  /// Messages successfully decoded and applied.
  int _diagMessagesApplied = 0;
  int get diagMessagesApplied => _diagMessagesApplied;

  /// Messages that failed to decode.
  int _diagMessagesFailed = 0;
  int get diagMessagesFailed => _diagMessagesFailed;

  /// Last decoding error message.
  String? _diagLastError;
  String? get diagLastError => _diagLastError;

  /// Number of positions in the CRDT state (excluding local).
  int get diagRemotePositionCount {
    int count = 0;
    for (final key in _state.positions.keys) {
      if (key != _localDeviceId) count++;
    }
    return count;
  }

  SyncEngine({
    required TransportService transport,
    required PeerRepository peerRepository,
    required MarkerRepository markerRepository,
    required String localDeviceId,
    AnnotationRepository? annotationRepository,
    DeltaEncoder encoder = const DeltaEncoder(),
  })  : _transport = transport,
        _peerRepository = peerRepository,
        _markerRepository = markerRepository,
        _annotationRepository = annotationRepository,
        _localDeviceId = localDeviceId,
        _encoder = encoder,
        _state = const CrdtState();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start the sync engine with the given [config].
  ///
  /// Subscribes to the transport's incoming message stream and starts
  /// the heartbeat timer.
  ///
  /// [encryptionKey], when supplied, switches the engine into encrypted
  /// envelope mode: outbound payloads are AES-256-GCM encrypted and
  /// prefixed with [_kEncryptedEnvelopeMagic]; inbound payloads with the
  /// magic prefix are decrypted and verified, while inbound payloads
  /// without the magic are dropped. Open-mode sessions pass null and
  /// continue to use plaintext.
  Future<void> start(
    SessionConfig config, {
    required String sessionId,
    String? encryptionKey,
  }) async {
    if (_isRunning) return;

    _sessionId = sessionId;
    _isRunning = true;
    _state = const CrdtState();
    _encryptionKey = encryptionKey;
    _encryptor = encryptionKey != null ? MessageEncryptor() : null;

    // Re-hydrate the CRDT state from any markers / annotations already
    // persisted for this session so a user who leaves and rejoins the
    // same session sees their previous waypoints, search areas, and
    // boundaries instead of an empty map. Without this, every join
    // wipes the in-memory state and the UI shows nothing until peers
    // re-broadcast — which never happens for solo session reuse.
    await _hydrateFromDb(sessionId);

    // Listen for incoming messages from transport.
    _incomingSub = _transport.incomingMessages.listen(
      _handleIncomingMessage,
      onError: (Object error) {
        // Log but don't crash the sync engine.
        // In production, surface via a status stream.
      },
    );

    // Start heartbeat for periodic position broadcasts.
    _startHeartbeat(config.updateIntervalMs);

    // Broadcast a join control message (best-effort; peers may not be
    // connected yet — join is implied by first heartbeat position).
    try {
      final joinPayload = _encoder.encodeControl(
        _localDeviceId,
        'join',
        {'sessionId': sessionId},
        _state.sequenceCounter.countFor(_localDeviceId),
      );
      await _transport.broadcast(_wireBytes(joinPayload.toBytes()));
    } catch (_) {
      // No peers connected yet; that's expected at session start.
    }

    _emitState();
  }

  /// Seed the CRDT state with markers + annotations already persisted
  /// for [sessionId] so a rejoiner sees their previous map content.
  ///
  /// Each entity is upserted using its `createdBy` device id as the CRDT
  /// node id so subsequent merges from the original creator (if they
  /// rejoin too) line up correctly with the sequence counter.
  Future<void> _hydrateFromDb(String sessionId) async {
    try {
      final markers = await _markerRepository.getMarkersBySession(sessionId);
      for (final marker in markers) {
        _state = _state.upsertMarker(marker.createdBy, marker);
      }
    } catch (_) {
      // Hydration failures are non-fatal — UI just shows fewer items.
    }
    final annoRepo = _annotationRepository;
    if (annoRepo != null) {
      try {
        final annotations = await annoRepo.getAnnotationsBySession(sessionId);
        for (final annotation in annotations) {
          _state = _state.upsertAnnotation(annotation.createdBy, annotation);
        }
      } catch (_) {
        // Same — failures are non-fatal.
      }
    }
  }

  /// Stop the sync engine and release resources.
  ///
  /// Broadcasts a leave control message before shutting down.
  Future<void> stop() async {
    if (!_isRunning) return;

    // Broadcast leave before shutting down.
    if (_sessionId != null) {
      try {
        final leavePayload = _encoder.encodeControl(
          _localDeviceId,
          'leave',
          {'sessionId': _sessionId!},
          _state.sequenceCounter.countFor(_localDeviceId),
        );
        await _transport.broadcast(_wireBytes(leavePayload.toBytes()));
      } catch (_) {
        // Best-effort; transport may already be closed.
      }
    }

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _incomingSub?.cancel();
    _incomingSub = null;
    _isRunning = false;
    _sessionId = null;
    _encryptor = null;
    _encryptionKey = null;
  }

  /// Wrap a plaintext sync payload in the on-the-wire envelope.
  ///
  /// In encrypted mode (PIN / QR sessions): returns
  /// `[0xE7][12-byte IV][AES-256-GCM ciphertext + 16-byte tag]`.
  /// In plaintext mode (Open sessions): returns the input unchanged.
  Uint8List _wireBytes(Uint8List plaintext) {
    final encryptor = _encryptor;
    final key = _encryptionKey;
    if (encryptor == null || key == null) return plaintext;
    final cipher = encryptor.encrypt(plaintext, key);
    final wrapped = Uint8List(cipher.length + 1);
    wrapped[0] = _kEncryptedEnvelopeMagic;
    wrapped.setRange(1, wrapped.length, cipher);
    return wrapped;
  }

  /// Recover the plaintext sync payload from on-the-wire bytes.
  ///
  /// Returns null when the bytes cannot be decrypted (wrong key,
  /// tampered ciphertext) or when the session is encrypted but the
  /// inbound bytes lack the magic envelope prefix (a peer running an
  /// older plaintext-only build, which we drop to fail closed).
  Uint8List? _unwrapBytes(Uint8List wire) {
    final encryptor = _encryptor;
    final key = _encryptionKey;
    if (encryptor == null || key == null) {
      // Open / non-encrypted session — accept everything as plaintext.
      // Reject anything sporting the encrypted envelope so a hostile
      // peer can't trick us into running ciphertext through the JSON
      // parser.
      if (wire.isNotEmpty && wire[0] == _kEncryptedEnvelopeMagic) {
        return null;
      }
      return wire;
    }
    // Encrypted session — require the envelope.
    if (wire.isEmpty || wire[0] != _kEncryptedEnvelopeMagic) {
      return null;
    }
    try {
      return encryptor.decrypt(wire.sublist(1), key);
    } catch (_) {
      // Decrypt failures are silently dropped; an attacker shouldn't be
      // able to learn anything from how we react.
      return null;
    }
  }

  /// Dispose all resources. The engine should not be used after this.
  void dispose() {
    _heartbeatTimer?.cancel();
    _incomingSub?.cancel();
    _stateController.close();
    _controlController.close();
    _isRunning = false;
  }

  // ---------------------------------------------------------------------------
  // Outgoing operations
  // ---------------------------------------------------------------------------

  /// Update the local device's position and broadcast the delta.
  Future<void> updateLocalPosition(Position position) async {
    if (!_isRunning) return;

    // Update CRDT state.
    _state = _state.updatePosition(_localDeviceId, position);

    // Encode and broadcast — include callsign so peers learn our name
    // from every heartbeat, not just a one-shot control message.
    final payload = _encoder.encodePosition(
      _localDeviceId,
      position,
      _state.sequenceCounter.countFor(_localDeviceId),
      callsign: localCallsign.isNotEmpty ? localCallsign : null,
    );
    await _transport.broadcast(_wireBytes(payload.toBytes()));

    _emitState();
  }

  /// Add or update a marker and broadcast the delta.
  /// Saves locally regardless of session state — broadcast is best-effort.
  Future<void> addMarker(Marker marker) async {
    _state = _state.upsertMarker(_localDeviceId, marker);

    if (!_isRunning) {
      _emitState();
      return;
    }

    final payload = _encoder.encodeMarker(
      _localDeviceId,
      marker,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(_wireBytes(payload.toBytes()));

    // Persist locally.
    if (_sessionId != null) {
      await _markerRepository.createMarker(marker, sessionId: _sessionId);
    }

    _emitState();
  }

  /// Add or update an annotation and broadcast the delta.
  /// Saves locally regardless of session state — broadcast is best-effort.
  Future<void> addAnnotation(Annotation annotation) async {
    _state = _state.upsertAnnotation(_localDeviceId, annotation);

    // Persist locally so the annotation survives restart and shows up in
    // After-Action Reports. Audit 2026-05-03 P0: annotations were
    // previously held only in CRDT memory and silently dropped on session
    // end. Persistence is best-effort — DB failure shouldn't kill the
    // sync path.
    final annoRepo = _annotationRepository;
    if (annoRepo != null && _sessionId != null) {
      try {
        final existing = await annoRepo.getAnnotationById(annotation.id);
        if (existing == null) {
          await annoRepo.createAnnotation(annotation, sessionId: _sessionId);
        } else {
          await annoRepo.updateAnnotation(annotation, sessionId: _sessionId);
        }
      } catch (_) {
        // Persist failure is non-fatal — CRDT state still holds the value.
      }
    }

    if (!_isRunning) {
      _emitState();
      return;
    }

    final payload = _encoder.encodeAnnotation(
      _localDeviceId,
      annotation,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(_wireBytes(payload.toBytes()));

    _emitState();
  }

  /// Remove a marker by ID and broadcast a tombstone.
  Future<void> removeMarker(String markerId) async {
    _state = _state.deleteMarker(_localDeviceId, markerId);

    if (!_isRunning) {
      _emitState();
      return;
    }

    final payload = _encoder.encodeMarkerDelete(
      _localDeviceId,
      markerId,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(_wireBytes(payload.toBytes()));

    // Remove from local DB.
    await _markerRepository.deleteMarker(markerId);

    _emitState();
  }

  /// Remove an annotation by ID and broadcast a tombstone.
  Future<void> removeAnnotation(String annotationId) async {
    _state = _state.deleteAnnotation(_localDeviceId, annotationId);

    // Mirror removeMarker: when the user deletes an annotation, also
    // remove it from the local DB so the deletion survives restart.
    final annoRepo = _annotationRepository;
    if (annoRepo != null) {
      try {
        await annoRepo.deleteAnnotation(annotationId);
      } catch (_) {
        // Non-fatal.
      }
    }

    if (!_isRunning) {
      _emitState();
      return;
    }

    final payload = _encoder.encodeAnnotationDelete(
      _localDeviceId,
      annotationId,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(_wireBytes(payload.toBytes()));

    _emitState();
  }

  /// Broadcast a control message payload to all connected peers.
  ///
  /// Used by [FieldLinkService] to send role assignments, callsign
  /// updates, and other control events.
  Future<void> broadcastControl(Map<String, dynamic> data) async {
    if (!_isRunning) return;

    final payload = _encoder.encodeControl(
      _localDeviceId,
      data['evt'] as String? ?? 'control',
      data,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    try {
      await _transport.broadcast(_wireBytes(payload.toBytes()));
    } catch (_) {
      // Best-effort broadcast.
    }
  }

  /// Update the heartbeat interval (e.g., when battery mode changes).
  void updateHeartbeatInterval(int intervalMs) {
    if (!_isRunning) return;
    _heartbeatTimer?.cancel();
    _startHeartbeat(intervalMs);
  }

  // ---------------------------------------------------------------------------
  // Incoming message handling
  // ---------------------------------------------------------------------------

  /// Handle a raw incoming message from the transport layer.
  Future<void> _handleIncomingMessage(TransportMessage message) async {
    _diagMessagesReceived++;
    try {
      // Decrypt-or-fail-closed before parsing. _unwrapBytes returns null
      // if the wire bytes don't match what the current session expects
      // (e.g. plaintext arriving on an encrypted session). Dropping is
      // the right call: a tampered or wrong-key message is exactly the
      // thing the audit's "fail closed in secure modes" requirement
      // asks us to refuse.
      final plaintext = _unwrapBytes(message.data);
      if (plaintext == null) {
        _diagMessagesFailed++;
        _diagLastError = 'unwrap rejected: wrong key or unencrypted on '
            'encrypted session';
        return;
      }
      final payload = SyncPayload.fromBytes(plaintext);

      // Ignore messages from ourselves.
      if (payload.senderId == _localDeviceId) return;

      // Extract callsign from position payloads and emit as a control
      // event so FieldLinkService can update the RoleManager. This ensures
      // peer names appear even if the one-shot callsign_update was missed.
      if (payload.type == SyncPayloadType.position) {
        final cs = payload.data['cs'] as String?;
        if (cs != null && cs.isNotEmpty && !_controlController.isClosed) {
          _controlController.add(ControlMessage(
            senderId: payload.senderId,
            data: {'evt': 'callsign_update', 'cs': cs},
          ));
        }
      }

      // Apply to CRDT state (merge handles conflict resolution).
      _state = _state.applyDelta(payload);

      // Persist side-effects to SQLite.
      await _persistDelta(payload);

      // Emit control messages on the dedicated control stream so that
      // FieldLinkService can handle key_exchange, role_assign, etc.
      if (payload.type == SyncPayloadType.control &&
          !_controlController.isClosed) {
        _controlController
            .add(ControlMessage(senderId: payload.senderId, data: payload.data));
      }

      _diagMessagesApplied++;
      _emitState();
    } catch (e) {
      _diagMessagesFailed++;
      _diagLastError = e.toString();
      // Bytes deliberately not echoed in production: with the encrypted
      // envelope wired the message body is ciphertext + tag, but even
      // plaintext payloads carry sender id and position. Diagnostics
      // capture (length only) is enough for troubleshooting; full body
      // dumps belong in the in-app diagnostics buffer (planned).
      RedLog.e(
        'SyncEngine',
        'DECODE FAILED (data: ${message.data.length} bytes)',
        e,
      );
    }
  }

  /// Persist the effects of a decoded delta to SQLite.
  Future<void> _persistDelta(SyncPayload payload) async {
    if (_sessionId == null) return;

    switch (payload.type) {
      case SyncPayloadType.position:
        final lat = payload.data['lat'];
        final lon = payload.data['lon'];
        if (lat is! num || lon is! num) break; // Malformed — skip persist
        await _peerRepository.updatePeerPosition(
          payload.senderId,
          lat: lat.toDouble(),
          lon: lon.toDouble(),
          mgrs: payload.data['mgrs'] as String?,
          lastSeen: payload.timestamp,
          altitude: (payload.data['alt'] as num?)?.toDouble(),
          speed: (payload.data['spd'] as num?)?.toDouble(),
          heading: (payload.data['hdg'] as num?)?.toDouble(),
          accuracy: (payload.data['acc'] as num?)?.toDouble(),
        );
        break;

      case SyncPayloadType.marker:
        if (payload.data['_deleted'] == true) {
          await _markerRepository.deleteMarker(payload.data['id'] as String);
        } else {
          final marker = Marker.fromJson(payload.data);
          final existing = await _markerRepository.getMarkerById(marker.id);
          if (existing != null) {
            await _markerRepository.updateMarker(
              marker.copyWith(isSynced: true),
              sessionId: _sessionId,
            );
          } else {
            await _markerRepository.createMarker(
              marker.copyWith(isSynced: true),
              sessionId: _sessionId,
            );
          }
        }
        break;

      case SyncPayloadType.annotation:
        // Mirror the marker handler: persist tombstones as deletes and
        // upsert the local row so remote annotations show up in AAR
        // exports and survive restart. Audit 2026-05-03 P0: this case
        // was previously a no-op, so received annotations were dropped
        // on the floor as soon as the CRDT state was discarded.
        final annoRepo = _annotationRepository;
        if (annoRepo == null) break;
        try {
          if (payload.data['_deleted'] == true) {
            await annoRepo.deleteAnnotation(payload.data['id'] as String);
            // Reflect tombstone in local CRDT state too.
            _state = _state.deleteAnnotation(
              payload.senderId,
              payload.data['id'] as String,
            );
          } else {
            final annotation = Annotation.fromJson(payload.data);
            final existing = await annoRepo.getAnnotationById(annotation.id);
            if (existing != null) {
              await annoRepo.updateAnnotation(
                annotation.copyWith(isSynced: true),
                sessionId: _sessionId,
              );
            } else {
              await annoRepo.createAnnotation(
                annotation.copyWith(isSynced: true),
                sessionId: _sessionId,
              );
            }
            // Keep CRDT state in sync with the persisted row.
            _state = _state.upsertAnnotation(payload.senderId, annotation);
          }
        } catch (_) {
          // Persist failure is non-fatal; the message is dropped but
          // sync_engine continues running.
        }
        break;

      case SyncPayloadType.control:
        // Control messages (join/leave/ping) are handled by the
        // FieldLinkService, which listens to stateStream.
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Heartbeat
  // ---------------------------------------------------------------------------

  /// Start a periodic heartbeat that broadcasts the local position.
  void _startHeartbeat(int intervalMs) {
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _onHeartbeat(),
    );
  }

  /// Heartbeat tick: re-broadcast the current local position.
  Future<void> _onHeartbeat() async {
    if (!_isRunning) return;

    final localPos = _state.positions[_localDeviceId]?.value;
    if (localPos == null) return;

    final payload = _encoder.encodePosition(
      _localDeviceId,
      localPos,
      _state.sequenceCounter.countFor(_localDeviceId),
      callsign: localCallsign.isNotEmpty ? localCallsign : null,
    );
    try {
      await _transport.broadcast(_wireBytes(payload.toBytes()));
    } catch (_) {
      // Best-effort broadcast; transport may be temporarily unavailable.
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Emit the current state to all stream listeners.
  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }
}

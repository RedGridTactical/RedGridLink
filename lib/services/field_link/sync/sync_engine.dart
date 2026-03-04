import 'dart:async';

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/session_config.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/data/repositories/marker_repository.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/delta_encoder.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

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
  final String _localDeviceId;

  CrdtState _state;
  String? _sessionId;
  bool _isRunning = false;

  Timer? _heartbeatTimer;
  StreamSubscription<TransportMessage>? _incomingSub;

  final StreamController<CrdtState> _stateController =
      StreamController<CrdtState>.broadcast();

  /// Stream of CRDT state updates for UI consumption.
  Stream<CrdtState> get stateStream => _stateController.stream;

  /// The current CRDT state snapshot.
  CrdtState get currentState => _state;

  /// Whether the sync engine is actively running.
  bool get isRunning => _isRunning;

  /// The local device identifier used as the CRDT node ID.
  String get localDeviceId => _localDeviceId;

  SyncEngine({
    required TransportService transport,
    required PeerRepository peerRepository,
    required MarkerRepository markerRepository,
    required String localDeviceId,
    DeltaEncoder encoder = const DeltaEncoder(),
  })  : _transport = transport,
        _peerRepository = peerRepository,
        _markerRepository = markerRepository,
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
  Future<void> start(SessionConfig config, {required String sessionId}) async {
    if (_isRunning) return;

    _sessionId = sessionId;
    _isRunning = true;
    _state = const CrdtState();

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

    // Broadcast a join control message.
    final joinPayload = _encoder.encodeControl(
      _localDeviceId,
      'join',
      {'sessionId': sessionId},
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(joinPayload.toBytes());

    _emitState();
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
        await _transport.broadcast(leavePayload.toBytes());
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
  }

  /// Dispose all resources. The engine should not be used after this.
  void dispose() {
    _heartbeatTimer?.cancel();
    _incomingSub?.cancel();
    _stateController.close();
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

    // Encode and broadcast.
    final payload = _encoder.encodePosition(
      _localDeviceId,
      position,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(payload.toBytes());

    _emitState();
  }

  /// Add or update a marker and broadcast the delta.
  Future<void> addMarker(Marker marker) async {
    if (!_isRunning) return;

    _state = _state.upsertMarker(_localDeviceId, marker);

    final payload = _encoder.encodeMarker(
      _localDeviceId,
      marker,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(payload.toBytes());

    // Persist locally.
    if (_sessionId != null) {
      await _markerRepository.createMarker(marker, sessionId: _sessionId);
    }

    _emitState();
  }

  /// Add or update an annotation and broadcast the delta.
  Future<void> addAnnotation(Annotation annotation) async {
    if (!_isRunning) return;

    _state = _state.upsertAnnotation(_localDeviceId, annotation);

    final payload = _encoder.encodeAnnotation(
      _localDeviceId,
      annotation,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(payload.toBytes());

    _emitState();
  }

  /// Remove a marker by ID and broadcast a tombstone.
  Future<void> removeMarker(String markerId) async {
    if (!_isRunning) return;

    _state = _state.deleteMarker(_localDeviceId, markerId);

    final payload = _encoder.encodeMarkerDelete(
      _localDeviceId,
      markerId,
      _state.sequenceCounter.countFor(_localDeviceId),
    );
    await _transport.broadcast(payload.toBytes());

    // Remove from local DB.
    await _markerRepository.deleteMarker(markerId);

    _emitState();
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
    try {
      final payload = SyncPayload.fromBytes(message.data);

      // Ignore messages from ourselves.
      if (payload.senderId == _localDeviceId) return;

      // Apply to CRDT state (merge handles conflict resolution).
      _state = _state.applyDelta(payload);

      // Persist side-effects to SQLite.
      await _persistDelta(payload);

      _emitState();
    } catch (e) {
      // Malformed payload — skip silently. In production, log the error.
    }
  }

  /// Persist the effects of a decoded delta to SQLite.
  Future<void> _persistDelta(SyncPayload payload) async {
    if (_sessionId == null) return;

    switch (payload.type) {
      case SyncPayloadType.position:
        await _peerRepository.updatePeerPosition(
          payload.senderId,
          lat: (payload.data['lat'] as num).toDouble(),
          lon: (payload.data['lon'] as num).toDouble(),
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
        // Annotations don't have a dedicated repository yet; the CRDT
        // state holds them in memory. Phase 4 will add persistence.
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
    );
    try {
      await _transport.broadcast(payload.toBytes());
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

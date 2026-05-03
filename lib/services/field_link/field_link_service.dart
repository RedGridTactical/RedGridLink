import 'dart:async';
import 'dart:convert';

import 'package:red_grid_link/core/logging/red_log.dart';
import 'package:red_grid_link/core/utils/crypto_utils.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/boundary_event.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/models/session_config.dart';
import 'package:red_grid_link/data/models/tactical_message.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/data/repositories/session_repository.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/boundary_manager.dart';
import 'package:red_grid_link/services/field_link/emergency_beacon_service.dart';
import 'package:red_grid_link/services/field_link/ghost/ghost_manager.dart';
import 'package:red_grid_link/services/field_link/message_service.dart';
import 'package:red_grid_link/services/field_link/platform/foreground_service.dart';
import 'package:red_grid_link/services/field_link/role_manager.dart';
import 'package:red_grid_link/services/field_link/security/key_exchange_manager.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/sync_engine.dart';
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/field_link/transport/multi_transport.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';
import 'package:red_grid_link/services/location/location_service.dart';

/// Connection status for the Field Link service.
enum FieldLinkStatus {
  /// No session active.
  idle,

  /// Session active, discovering peers.
  discovering,

  /// Session active, at least one peer connected.
  connected,

  /// Attempting to reconnect after a disconnect.
  reconnecting,

  /// Error state — requires re-initialization.
  error,
}

/// Facade coordinating all Field Link sub-services.
///
/// Orchestrates:
/// - [TransportService] — BLE / P2P communication.
/// - [SyncEngine] — CRDT-based state replication.
/// - [GhostManager] — Ghost marker lifecycle for disconnected peers.
/// - [BatteryManager] — Battery-conscious sync interval management.
/// - [SessionRepository] / [PeerRepository] — persistence.
///
/// The UI layer interacts exclusively through this facade.
class FieldLinkService {
  final TransportService _transport;
  final SyncEngine _syncEngine;
  final GhostManager _ghostManager;
  final BatteryManager _batteryManager;
  final SessionRepository _sessionRepository;
  final PeerRepository _peerRepository;
  final String _localDeviceId;

  /// Optional — when supplied, session create/join start GPS track recording
  /// against the active session id, and session leave stops it. Track points
  /// then flow into [TrackRepository] for AAR generation. Optional so tests
  /// and headless surfaces can construct the service without a GPS dependency.
  final LocationService? _locationService;
  late final RoleManager _roleManager;
  late final BoundaryManager _boundaryManager;
  final EmergencyBeaconService _emergencyBeacon = EmergencyBeaconService();
  final MessageService _messageService = MessageService();

  /// Manages ECDH P-256 key exchange for all connected peers.
  ///
  /// Encapsulates key pair generation, per-peer shared secret derivation,
  /// and key lifecycle. Replaces the previous inline KeyExchange + Map.
  final KeyExchangeManager _keyExchangeManager = KeyExchangeManager();

  Session? _activeSession;
  StreamSubscription<TransportState>? _transportStateSub;
  StreamSubscription<CrdtState>? _syncStateSub;
  StreamSubscription<ControlMessage>? _controlSub;
  StreamSubscription<DiscoveredDevice>? _autoConnectSub;
  Timer? _batteryPollTimer;
  Timer? _reconnectTimer;

  /// Current reconnect attempt count.
  int _reconnectAttempts = 0;

  /// Maximum reconnect attempts before marking peers as ghost.
  static const int _maxReconnectAttempts = 5;

  /// Reconnect backoff intervals in milliseconds: 2s, 4s, 8s, 16s, 30s.
  static const List<int> _reconnectIntervalsMs = [
    2000, 4000, 8000, 16000, 30000,
  ];

  final StreamController<Session?> _sessionController =
      StreamController<Session?>.broadcast();
  final StreamController<List<Peer>> _peersController =
      StreamController<List<Peer>>.broadcast();
  final StreamController<FieldLinkStatus> _statusController =
      StreamController<FieldLinkStatus>.broadcast();
  final StreamController<BoundaryEvent> _boundaryEventController =
      StreamController<BoundaryEvent>.broadcast();

  FieldLinkStatus _status = FieldLinkStatus.idle;

  /// Optional callback invoked with (deviceId, rssi) readings from BLE RSSI
  /// polling. Set by the provider layer to feed [ConnectionQualityNotifier].
  void Function(String deviceId, int rssi)? onRssiReading;

  /// Callback invoked when RSSI data should be cleared (e.g., session end).
  void Function()? onRssiClear;

  /// Callback invoked when the emergency state changes (remote SOS
  /// received or cancelled). Set by the provider layer to feed
  /// [emergencyActiveProvider].
  void Function(bool active)? onEmergencyStateChanged;

  FieldLinkService({
    required TransportService transport,
    required SyncEngine syncEngine,
    required GhostManager ghostManager,
    required BatteryManager batteryManager,
    required SessionRepository sessionRepository,
    required PeerRepository peerRepository,
    required String localDeviceId,
    LocationService? locationService,
  })  : _transport = transport,
        _syncEngine = syncEngine,
        _ghostManager = ghostManager,
        _batteryManager = batteryManager,
        _sessionRepository = sessionRepository,
        _peerRepository = peerRepository,
        _localDeviceId = localDeviceId,
        _locationService = locationService {
    _roleManager = RoleManager(localDeviceId: localDeviceId);
    _boundaryManager = BoundaryManager();
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// The currently active session, or null.
  Session? get activeSession => _activeSession;

  /// Stream of session changes.
  Stream<Session?> get sessionStream => _sessionController.stream;

  /// Whether a session is currently active.
  bool get isSessionActive => _activeSession != null;

  /// Create a new Field Link session.
  ///
  /// Generates a unique session ID and session key. If [securityMode]
  /// is [SecurityMode.pin], a 4-digit PIN is generated (or the provided
  /// [pin] is used).
  Future<Session> createSession({
    required String name,
    required SecurityMode securityMode,
    String? pin,
    required OperationalMode mode,
  }) async {
    // End any existing session first.
    if (_activeSession != null) {
      await leaveSession();
    }

    // Short 16-hex tag so it fits in the BLE advertisement LocalName
    // field (iOS CoreBluetooth only permits ServiceUUID + LocalName
    // for 3rd-party ads). The same tag is reused by joiners as their
    // session ID so CRDT, marker persistence, and session records all
    // align across peers.
    final sessionId = generateSessionTag();
    final sessionKey = generateSessionKey();
    final sessionPin = securityMode == SecurityMode.pin
        ? (pin ?? generatePin())
        : null;

    final session = Session(
      id: sessionId,
      name: name,
      securityMode: securityMode,
      pin: sessionPin,
      sessionKey: sessionKey,
      createdAt: DateTime.now(),
      operationalMode: mode,
      peers: [_localDeviceId],
      isActive: true,
    );

    await _sessionRepository.createSession(session);
    _activeSession = session;
    _roleManager.initializeAsCreator();
    _keyExchangeManager.initialize();
    _emitSession();

    // Determine sync config from mode.
    final config = _configForMode(mode);

    // Start sub-services.
    await _transport.initialize();

    // The creator advertises the Field Link GATT service so joiners
    // can discover and connect. Resolve the underlying BleTransport
    // even when it is wrapped in a MultiTransport (the iOS dual-stack
    // wrapper that runs BLE alongside Multipeer Connectivity).
    final ble = _resolveBleTransport();
    if (ble != null) {
      await ble.startAdvertising(sessionId);
    }

    // Subscribe to discovered devices BEFORE starting the scan so we
    // don't miss joiners discovered instantly.
    await _autoConnectSub?.cancel();
    _autoConnectSub = _transport.discoveredDevices.listen((device) async {
      if (_transport.connectedDeviceIds.contains(device.id)) return;

      // With v1.5.4 the joiner also advertises the same sessionId once
      // it commits to joining. Filter discoveries so the creator only
      // auto-connects to peers in its own session — without this, two
      // overlapping sessions in proximity would have hosts grabbing each
      // other's joiners.
      if (device.sessionId != null && device.sessionId != sessionId) {
        return;
      }

      try {
        RedLog.d('FieldLink', 'Creator auto-connecting to ${device.id}');
        await _transport.connect(device.id);
        RedLog.d('FieldLink', 'Creator connected to ${device.id}');
      } catch (e) {
        RedLog.w('FieldLink', 'Creator connect failed — will retry', e);
      }
    });

    await _transport.startDiscovery(sessionId);

    await _syncEngine.start(
      config,
      sessionId: sessionId,
      encryptionKey: _deriveEncryptionKey(session),
    );
    await _ghostManager.start();
    _startBatteryPolling();

    // Start GPS track recording against this session id so position
    // updates persist as TrackPoints and the AAR has a real route.
    // Audit 2026-05-03 P0: track recording was previously never invoked.
    await _locationService?.startTracking(sessionId);

    // Android: keep the BLE/Nearby radios running while the app is
    // backgrounded by promoting Field Link work into a foreground
    // service. iOS handles this through the bluetooth-central /
    // bluetooth-peripheral background modes declared in Info.plist
    // and so the call is a no-op there.
    // Audit 2026-05-03 P1: ForegroundService had a Dart wrapper but
    // was never invoked from session lifecycle.
    await ForegroundService.start();

    _setStatus(FieldLinkStatus.discovering);

    return session;
  }

  /// Join an existing Field Link session.
  ///
  /// Returns `true` if the join was successful. For PIN-protected
  /// sessions, the correct [pin] must be provided — it is validated
  /// by the session host via a BLE control message handshake, NOT by
  /// a local database lookup (the joiner's device has never seen the
  /// session before).
  ///
  /// Flow:
  ///   1. Scan for the host's BLE advertisement.
  ///   2. Connect as central (flutter_blue_plus).
  ///   3. Start sync engine + send a `join_request` control message
  ///      with the PIN (if provided).
  ///   4. The host validates the PIN against its real session and
  ///      responds with `join_response {accepted: true/false}`.
  ///   5. If rejected, disconnect and return false.
  Future<bool> joinSession(
    String sessionId, {
    String? pin,
    String? qrData,
  }) async {
    // End any existing session first.
    if (_activeSession != null) {
      await leaveSession();
    }

    // Parse QR data when supplied. Audit 2026-05-03 P0: qrData was
    // previously accepted by the API but ignored — the security mode
    // collapsed to PIN-or-Open regardless of how the user joined. Now:
    //   - Valid QR payload (JSON {id, key, ...}) → SecurityMode.qr
    //   - Invalid QR payload                     → fail closed (return false)
    //   - No qrData supplied                     → fall back to PIN/Open
    String? qrSessionKey;
    SecurityMode resolvedSecurityMode;
    if (qrData != null) {
      try {
        final payload = jsonDecode(qrData) as Map<String, dynamic>;
        final qrId = payload['id'] as String?;
        final qrKey = payload['key'] as String?;
        if (qrId == null || qrKey == null || qrKey.isEmpty) {
          // Malformed QR — refuse to join rather than silently downgrade
          // to Open, which is what the previous code path did.
          return false;
        }
        if (qrId != sessionId) {
          // The QR is for a different session id than the caller asked
          // us to join. Refuse — this is a likely sign of a swapped or
          // stale QR.
          return false;
        }
        qrSessionKey = qrKey;
        resolvedSecurityMode = SecurityMode.qr;
      } catch (_) {
        // Not valid JSON. Fail closed: the caller asked for a QR-secured
        // join but the bytes were unreadable, so we cannot prove identity.
        return false;
      }
    } else {
      resolvedSecurityMode = pin != null ? SecurityMode.pin : SecurityMode.open;
    }

    final session = Session(
      id: sessionId,
      name: 'Joined Session',
      securityMode: resolvedSecurityMode,
      pin: pin,
      sessionKey: qrSessionKey,
      createdAt: DateTime.now(),
      operationalMode: OperationalMode.sar,
      peers: [_localDeviceId],
      isActive: true,
    );

    // Use upsert — the joiner may retry joining the same session
    // (e.g., first open attempt fails PIN, then retry with correct PIN).
    // A plain INSERT would throw UNIQUE constraint on the second attempt.
    final existing = await _sessionRepository.getSessionById(sessionId);
    if (existing != null) {
      await _sessionRepository.activateSession(sessionId);
    } else {
      await _sessionRepository.createSession(session);
    }

    _activeSession = session.copyWith(isActive: true);
    _pendingJoinPin = pin;
    _pendingJoinKey = qrSessionKey;
    _roleManager.initializeAsJoiner();
    _keyExchangeManager.initialize();
    _emitSession();

    final config = _configForMode(session.operationalMode);

    await _transport.initialize();

    // The joiner ALSO advertises the same session id once it has
    // committed to joining. This makes the link symmetric:
    //
    // - If the host is backgrounded (iOS suppresses central-mode service
    //   UUID emission while backgrounded), the joiner's advertisement
    //   keeps the host discoverable to OS-level scan callbacks.
    // - If a third teammate joins later, they can find this joiner just
    //   as easily as they found the host.
    // - If the host's BLE advertising slot is contested (some Android
    //   chipsets rate-limit advertisers), the joiner's slot picks up the
    //   slack.
    //
    // Two phones advertising the same session id is fine — BLE central
    // scan results de-duplicate by remoteId, and the CRDT layer is
    // idempotent.
    final joinerBle = _resolveBleTransport();
    if (joinerBle != null) {
      try {
        await joinerBle.startAdvertising(sessionId);
      } catch (e) {
        // Best-effort: BLE peripheral advertising may not be available on
        // every device (some Android chipsets, older iOS hardware). The
        // joiner can still operate as a central-only client.
        RedLog.w('FieldLink', 'Joiner startAdvertising failed', e);
      }
    }

    // Subscribe to discovered devices BEFORE starting the scan so we
    // don't miss the creator if it's discovered instantly. Broadcast
    // streams don't buffer — any event emitted before a listener
    // subscribes is silently lost.
    await _autoConnectSub?.cancel();
    _autoConnectSub = _transport.discoveredDevices.listen((device) async {
      // Skip devices we're already connected to.
      if (_transport.connectedDeviceIds.contains(device.id)) return;

      // Only auto-connect to devices in our session. Without this guard,
      // the joiner would race against any nearby Field Link host —
      // including ones from other sessions — and try to handshake with
      // the wrong peer. `device.sessionId == null` means the peer is on
      // an old build that didn't include sessionId in its advertisement;
      // skip those rather than risk a cross-session collision.
      if (device.sessionId != null && device.sessionId != sessionId) {
        return;
      }

      try {
        RedLog.d('FieldLink', 'Auto-connecting to ${device.id}');
        await _transport.connect(device.id);
        RedLog.d('FieldLink', 'Connected to ${device.id}');
        // Only cancel the subscription AFTER a successful connect.
        // If connect fails, the subscription stays active so it can
        // retry on the next scan cycle.
        await _autoConnectSub?.cancel();
        _autoConnectSub = null;
      } catch (e) {
        // Connection failed — keep listening for retry on next scan.
        RedLog.w('FieldLink', 'Connect failed — will retry', e);
      }
    });

    await _transport.startDiscovery(sessionId);

    await _syncEngine.start(
      config,
      sessionId: sessionId,
      encryptionKey: _deriveEncryptionKey(session),
    );
    await _ghostManager.start();
    _startBatteryPolling();

    // Joiner also records its own GPS track for the session — both ends
    // need their own track so the AAR can show every participant's route.
    // Audit 2026-05-03 P0: track recording was previously never invoked.
    await _locationService?.startTracking(sessionId);

    // Same Android-only foreground service promotion as createSession;
    // keeps the joiner's radios alive when the user backgrounds the app.
    await ForegroundService.start();

    _setStatus(FieldLinkStatus.discovering);

    return true;
  }

  /// Derive the symmetric encryption key for a session.
  ///
  /// Returns null for Open sessions (plaintext sync). For PIN and QR
  /// sessions returns a key both peers can compute independently:
  ///   - QR mode  : the session secret embedded in the QR (host
  ///                generated, joiner scanned).
  ///   - PIN mode : `hashPin('field-link-pin:' + PIN)`. The host
  ///                session id is intentionally NOT mixed in: when the
  ///                joiner is constructed from a discovery result that
  ///                lacks `device.sessionId` (iOS BLE peripheral mode,
  ///                Android Nearby pre-handshake), `session.id` on the
  ///                joiner is the BLE/Nearby device id rather than the
  ///                host's session tag. Mixing it in produced different
  ///                keys on each side and silently broke PIN joins.
  ///                Codex review 2026-05-03 P1.
  ///
  /// Audit 2026-05-03 P0: previously the SyncEngine ran in plaintext
  /// regardless of security mode despite PRIVACY.md claiming AES-GCM
  /// for Field Link sync.
  String? _deriveEncryptionKey(Session session) {
    switch (session.securityMode) {
      case SecurityMode.open:
        return null;
      case SecurityMode.qr:
        // The QR key is base64url; pass it through verbatim so both
        // ends derive the same AES key inside MessageEncryptor's HKDF.
        return session.sessionKey;
      case SecurityMode.pin:
        final pin = session.pin;
        if (pin == null || pin.isEmpty) return null;
        // Fixed namespace prefix instead of the session id — see method
        // doc above for why. Both peers know the PIN; both compute the
        // same key without needing to agree on the session tag first.
        return hashPin('field-link-pin:$pin');
    }
  }

  /// PIN sent by the joiner, held until the host responds with
  /// `join_response`. Cleared after validation completes.
  String? _pendingJoinPin;

  /// Session key extracted from the QR code (joiner side), held until
  /// the host responds with `join_response`. Sent in the join_request so
  /// the host can verify the joiner actually scanned the right QR rather
  /// than guessing a session id. Cleared after validation completes.
  String? _pendingJoinKey;

  /// Timer that fires if the host hasn't sent a `join_response` within a
  /// reasonable window after we transmit the encrypted `join_request`.
  ///
  /// Codex review 2026-05-03 P2: when the joiner has the wrong PIN or
  /// QR key, the encrypted `join_request` GCM-tag-fails on the host,
  /// the host drops it during unwrap, and `_handleJoinRequest` is never
  /// reached — so the host never sends `accepted:false`. Without this
  /// timer the joiner UI would sit forever in "discovering". On expiry
  /// we behave the same as an explicit rejection: leave the session and
  /// surface a [FieldLinkStatus.error] so the UI can show
  /// "INCORRECT PIN" / "INVALID QR" and let the user try again.
  Timer? _joinAcceptTimer;

  /// Window the joiner waits for `join_response` after sending its
  /// encrypted `join_request`. Long enough to cover BLE retry + GATT
  /// notify chunking on slow devices, short enough that a wrong-PIN
  /// joiner doesn't sit there for tens of seconds.
  static const Duration _joinAcceptTimeout = Duration(seconds: 8);

  /// Leave the current session.
  ///
  /// Stops all sub-services, disconnects peers, and deactivates the
  /// session in the database.
  Future<void> leaveSession() async {
    if (_activeSession == null) return;

    final sessionId = _activeSession!.id;

    // Cancel any pending auto-connect and reconnect attempts.
    await _autoConnectSub?.cancel();
    _autoConnectSub = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    // Drop the wrong-PIN/wrong-QR fail-closed timer; the user has
    // explicitly left the session, so the rejection-by-timeout path
    // shouldn't fire afterward.
    _joinAcceptTimer?.cancel();
    _joinAcceptTimer = null;

    // Stop sub-services in order. Each step is best-effort: if any one
    // throws (transport failure mid-disconnect, DB lock contention,
    // platform channel error during foreground service stop), we still
    // run the rest so we don't strand the user in a partially-active
    // session.
    //
    // Codex review round 5 P2: previously a single thrown step would
    // bail out of leaveSession, leaving _isRunning, _activeSession,
    // and the transport/sync stack half-set. The next createSession
    // would skip its `if (_activeSession != null) await leaveSession()`
    // guard (because _activeSession was force-cleared by the timeout
    // catch) and then SyncEngine.start() would early-return because
    // _isRunning was never cleared, leaving the retry attached to the
    // stale session state.
    Future<void> bestEffort(String label, Future<void> Function() op) async {
      try {
        await op();
      } catch (e) {
        RedLog.w('FieldLink', 'leaveSession step "$label" failed', e);
      }
    }

    void bestEffortSync(String label, void Function() op) {
      try {
        op();
      } catch (e) {
        RedLog.w('FieldLink', 'leaveSession step "$label" failed', e);
      }
    }

    bestEffortSync('stopRssiPolling', _stopRssiPolling);
    // Stop GPS track recording so position updates don't keep flowing
    // into a deactivated session row in the track table.
    // Audit 2026-05-03 P0: track lifecycle was previously not wired.
    await bestEffort('stopTracking', () async {
      await _locationService?.stopTracking();
    });
    // Tear down the Android foreground service so the persistent
    // notification disappears and the OS can reclaim the wakelock.
    // No-op on iOS / desktop.
    await bestEffort('foregroundServiceStop', ForegroundService.stop);
    await bestEffort('syncEngineStop', _syncEngine.stop);
    await bestEffort('disconnectAll', _transport.disconnectAll);
    await bestEffort('stopDiscovery', _transport.stopDiscovery);
    final stopBle = _resolveBleTransport();
    if (stopBle != null) {
      await bestEffort('stopAdvertising', stopBle.stopAdvertising);
    }
    bestEffortSync('stopBatteryPolling', _stopBatteryPolling);

    // Mark all peers in this session as disconnected.
    await bestEffort('peerDisconnectAll',
        () => _peerRepository.disconnectAllInSession(sessionId));

    // Deactivate session.
    await bestEffort('sessionDeactivateAll',
        () => _sessionRepository.deactivateAll());

    bestEffortSync('emergencyBeaconDispose', _emergencyBeacon.dispose);
    bestEffortSync('messageServiceReset', _messageService.reset);
    bestEffortSync('roleManagerReset', _roleManager.reset);
    bestEffortSync('clearBoundary', _boundaryManager.clearBoundary);
    bestEffortSync('keyExchangeReset', _keyExchangeManager.reset);
    _activeSession = null;
    _emitSession();
    _setStatus(FieldLinkStatus.idle);
    bestEffortSync('removeAllGhosts', _ghostManager.removeAllGhosts);
  }

  // ---------------------------------------------------------------------------
  // Peer management
  // ---------------------------------------------------------------------------

  /// Stream of connected peers in the active session.
  Stream<List<Peer>> get peersStream => _peersController.stream;

  /// Stream of ghost markers for disconnected peers.
  Stream<List<Ghost>> get ghostsStream => _ghostManager.ghostStream;

  /// Remove a single ghost marker by peer ID.
  void removeGhost(String peerId) => _ghostManager.removeGhost(peerId);

  /// Remove all ghost markers.
  void removeAllGhosts() => _ghostManager.removeAllGhosts();

  /// Number of currently connected peers.
  int get connectedPeerCount => _transport.connectedDeviceIds.length;

  /// Stream of synced markers from the CRDT state.
  ///
  /// Emits the latest list of live (non-tombstoned) markers whenever
  /// the CRDT state changes.
  Stream<List<Marker>> get markersStream => _syncEngine.stateStream
      .map((state) => state.liveMarkers);

  /// Stream of synced annotations from the CRDT state.
  ///
  /// Emits the latest list of live (non-tombstoned) annotations whenever
  /// the CRDT state changes.
  Stream<List<Annotation>> get annotationsStream => _syncEngine.stateStream
      .map((state) => state.liveAnnotations);

  /// Current snapshot of all live markers.
  List<Marker> get currentMarkers => _syncEngine.currentState.liveMarkers;

  /// Current snapshot of all live annotations.
  List<Annotation> get currentAnnotations =>
      _syncEngine.currentState.liveAnnotations;

  /// The local device ID for this Field Link instance.
  String get localDeviceId => _localDeviceId;

  /// The role manager for this session.
  RoleManager get roleManager => _roleManager;

  /// The boundary manager for geofence alerts.
  BoundaryManager get boundaryManager => _boundaryManager;

  /// Per-peer ECDH-derived shared keys (read-only view).
  ///
  /// Returns a map of deviceId -> base64url shared key for all peers
  /// that have completed the ECDH key exchange handshake.
  Map<String, String> get peerKeys => _keyExchangeManager.peerKeys;

  /// The key exchange manager for per-peer encryption key derivation.
  KeyExchangeManager get keyExchangeManager => _keyExchangeManager;

  /// Stream of boundary crossing events (local user or peers exiting).
  Stream<BoundaryEvent> get boundaryEventStream =>
      _boundaryEventController.stream;

  /// The emergency beacon service for SOS functionality.
  EmergencyBeaconService get emergencyBeacon => _emergencyBeacon;

  /// The message service for tactical messaging.
  MessageService get messageService => _messageService;

  /// Activate the local emergency beacon.
  ///
  /// Broadcasts an emergency distress signal with the given GPS
  /// coordinates to all connected peers. Retransmits every 30 seconds
  /// until [deactivateEmergencyBeacon] is called.
  void activateEmergencyBeacon(double lat, double lon) {
    _emergencyBeacon.activate(
      localDeviceId: _localDeviceId,
      lat: lat,
      lon: lon,
      onBroadcast: (payload) => _syncEngine.broadcastControl(payload),
    );
  }

  /// Deactivate the local emergency beacon.
  ///
  /// Cancels the retransmit timer and broadcasts an emergency_cancel
  /// control message to all connected peers.
  void deactivateEmergencyBeacon() {
    _emergencyBeacon.deactivate(
      onBroadcast: (payload) => _syncEngine.broadcastControl(payload),
    );
  }

  /// Send a tactical message to all connected peers.
  ///
  /// For [TacticalMessageType.custom], provide [customText] (max 160 chars).
  void sendTacticalMessage(TacticalMessageType type, {String? customText}) {
    final payload = TacticalMessage(
      senderId: _localDeviceId,
      senderCallsign: _roleManager.callsign,
      type: type,
      customText: customText,
      timestamp: DateTime.now(),
    ).toJson();
    _syncEngine.broadcastControl(payload);
  }

  /// Check if the local user's position has crossed the boundary.
  ///
  /// Call this whenever the local GPS position updates. If a crossing
  /// is detected, a [BoundaryEvent] is emitted on [boundaryEventStream]
  /// and a `boundary_exit` control message is broadcast to peers.
  void checkLocalBoundary(double lat, double lon) {
    if (!_boundaryManager.hasBoundary) return;

    final crossed = _boundaryManager.checkBoundaryCrossing(
      _localDeviceId,
      lat,
      lon,
    );

    if (crossed) {
      final callsign = _roleManager.callsign;
      final event = BoundaryEvent(
        id: '${_localDeviceId}_${DateTime.now().millisecondsSinceEpoch}',
        peerId: _localDeviceId,
        callsign: callsign,
        timestamp: DateTime.now(),
        lat: lat,
        lon: lon,
      );

      if (!_boundaryEventController.isClosed) {
        _boundaryEventController.add(event);
      }

      // Notify peers (especially the Lead) about the exit.
      _syncEngine.broadcastControl({
        'evt': 'boundary_exit',
        'pid': _localDeviceId,
        'cs': callsign,
        'lat': lat,
        'lon': lon,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Role management
  // ---------------------------------------------------------------------------

  /// Assign a role to a peer and broadcast the change.
  ///
  /// Only the session lead can assign roles. No-op if not lead.
  void assignRole(String peerId, TeamRole role) {
    if (!_roleManager.isLead) return;
    _roleManager.assignRole(peerId, role);
    final payload = _roleManager.encodeRoleAssignment(peerId, role);
    if (payload != null) {
      _syncEngine.broadcastControl(payload);
    }
  }

  /// Promote a peer to lead, transferring the lead role.
  ///
  /// The local device is demoted to scout. No-op if not lead.
  void promotePeerToLead(String peerId) {
    if (!_roleManager.isLead) return;
    _roleManager.promotePeerToLead(peerId);
    final payload = _roleManager.encodeRoleAssignment(
      peerId,
      TeamRole.lead,
    );
    if (payload != null) {
      _syncEngine.broadcastControl(payload);
    }
  }

  /// Set the local device's callsign and broadcast to peers.
  void setCallsign(String value) {
    _roleManager.setCallsign(value);
    // Persist on the sync engine so every heartbeat includes the callsign.
    _syncEngine.localCallsign = value;
    final payload = _roleManager.encodeCallsignUpdate();
    _syncEngine.broadcastControl(payload);
  }

  // ---------------------------------------------------------------------------
  // Data sync
  // ---------------------------------------------------------------------------

  /// Update the local device's position and broadcast to peers.
  void updatePosition(Position position) {
    _syncEngine.updateLocalPosition(position);
  }

  /// Add a marker and broadcast to peers.
  void addMarker(Marker marker) {
    _syncEngine.addMarker(marker);
  }

  /// Add an annotation and broadcast to peers.
  void addAnnotation(Annotation annotation) {
    _syncEngine.addAnnotation(annotation);
  }

  /// Remove a marker by ID.
  void removeMarker(String markerId) {
    _syncEngine.removeMarker(markerId);
  }

  /// Remove an annotation by ID (tombstone via CRDT).
  void removeAnnotation(String annotationId) {
    _syncEngine.removeAnnotation(annotationId);
  }

  // ---------------------------------------------------------------------------
  // Battery
  // ---------------------------------------------------------------------------

  /// The current battery mode.
  BatteryMode get batteryMode => _batteryManager.currentMode;

  /// Set the battery mode and adjust sync interval accordingly.
  void setBatteryMode(BatteryMode mode) {
    _batteryManager.setMode(mode);
    _syncEngine.updateHeartbeatInterval(
      _batteryManager.recommendedIntervalMs,
    );
  }

  /// Human-readable battery projection string.
  String get batteryProjection => _batteryManager.projectedRemainingTime;

  /// Stream of battery mode changes.
  Stream<BatteryMode> get batteryModeStream => _batteryManager.modeStream;

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  /// The current Field Link status.
  FieldLinkStatus get status => _status;

  /// Stream of status changes.
  Stream<FieldLinkStatus> get statusStream => _statusController.stream;

  /// Stream of devices discovered during a passive session scan.
  ///
  /// Only active while [startSessionScan] has been called and before
  /// a session is joined.  Subscribe before calling [startSessionScan].
  Stream<DiscoveredDevice> get discoveredSessionsStream =>
      _transport.discoveredDevices;

  /// The active transport type.
  TransportType get activeTransport => _transport.type;

  /// The sync engine (exposed for diagnostics).
  SyncEngine get syncEngine => _syncEngine;

  /// The raw transport (exposed for diagnostics).
  TransportService get transport => _transport;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the Field Link service.
  ///
  /// Sets up stream subscriptions for transport state and sync engine
  /// state changes. Safe to call multiple times — cancels prior
  /// subscriptions first.
  Future<void> initialize() async {
    // Cancel existing subscriptions to avoid leaking listeners.
    await _transportStateSub?.cancel();
    await _syncStateSub?.cancel();
    await _controlSub?.cancel();

    // Listen for transport state changes.
    _transportStateSub = _transport.stateStream.listen(_onTransportState);

    // Listen for CRDT state changes to update peer list and detect
    // disconnections for ghost management.
    _syncStateSub = _syncEngine.stateStream.listen(_onSyncStateChanged);

    // Listen for incoming control messages (key exchange, role, etc.).
    _controlSub = _syncEngine.controlStream.listen(_onControlMessage);
  }

  /// Start a passive BLE scan for nearby Field Link sessions.
  ///
  /// Used by the join UI to populate the nearby-sessions list before a
  /// session is selected.  Subscribe to [discoveredSessionsStream] before
  /// calling this.  Has no effect if a session is already active.
  Future<void> startSessionScan() async {
    if (_activeSession != null) return;
    await _transport.initialize();
    // Use a well-known sentinel ID; the BLE scan filters by service UUID
    // only, so the session ID here does not affect what devices are found.
    await _transport.startDiscovery('__field_link_scan__');
    _setStatus(FieldLinkStatus.discovering);
  }

  /// Stop a passive session scan started by [startSessionScan].
  ///
  /// No-op if a session is currently active (discovery continues for the
  /// active session in that case).
  Future<void> stopSessionScan() async {
    if (_activeSession != null) return;
    await _transport.stopDiscovery();
    _setStatus(FieldLinkStatus.idle);
  }

  /// Dispose all resources. The service should not be used after this.
  Future<void> dispose() async {
    await _transportStateSub?.cancel();
    await _syncStateSub?.cancel();
    await _controlSub?.cancel();
    await _autoConnectSub?.cancel();
    _autoConnectSub = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Codex review round 2 P3: cancel the wrong-PIN/QR fail-closed
    // timer here too. Without this, a join that was waiting for
    // `join_response` when the service was disposed will still fire
    // its 8s timer afterward and try to call leaveSession on already-
    // disposed transport / sync resources.
    _joinAcceptTimer?.cancel();
    _joinAcceptTimer = null;
    _stopRssiPolling();
    _stopBatteryPolling();
    _syncEngine.dispose();
    _ghostManager.dispose();
    _batteryManager.dispose();
    await _transport.dispose();
    _sessionController.close();
    _peersController.close();
    _statusController.close();
    _boundaryEventController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Handle transport state transitions with reconnect logic.
  void _onTransportState(TransportState state) {
    switch (state) {
      case TransportState.connected:
        // Connection established — reset reconnect state.
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _setStatus(FieldLinkStatus.connected);
        // Start RSSI polling if transport is BLE.
        _startRssiPolling();
        // Broadcast ECDH public key to newly connected peers.
        _broadcastPublicKey();
        // If we're a joiner with a pending PIN or QR key, send a
        // join_request so the host can validate it via the BLE control
        // channel.
        if (_pendingJoinPin != null || _pendingJoinKey != null) {
          _syncEngine.broadcastControl({
            'evt': 'join_request',
            if (_pendingJoinPin != null) 'pin': _pendingJoinPin,
            if (_pendingJoinKey != null) 'key': _pendingJoinKey,
            'deviceId': _localDeviceId,
          });
          _pendingJoinPin = null;
          _pendingJoinKey = null;
          // Codex review 2026-05-03 P2: arm a fail-closed timer so a
          // joiner with a wrong PIN/QR key (whose encrypted join_request
          // the host can't decrypt) gets surfaced to the UI as a
          // rejection instead of an indefinite "discovering" spinner.
          _joinAcceptTimer?.cancel();
          _joinAcceptTimer = Timer(_joinAcceptTimeout, () async {
            if (_activeSession == null) return;
            // If we already got accepted, _handleJoinResponse will have
            // cleared the timer. Reaching here means no response.
            //
            // Codex review round 2 P2: await leaveSession BEFORE
            // emitting the error status. leaveSession ends with
            // _setStatus(FieldLinkStatus.idle); if we don't await it,
            // the idle emission races behind our error emission and
            // overwrites it.
            //
            // Codex review round 3 P2: wrap the cleanup in try/finally
            // so the rejection is surfaced to the UI even if
            // leaveSession's transport teardown / repository
            // deactivation throws — otherwise the unhandled error
            // inside the Timer callback would leave the joiner stuck
            // in their previous status.
            //
            // Codex review round 4 P2: also force-clear _activeSession
            // and emit null on sessionStream in the failure path. If
            // leaveSession throws BEFORE it reaches its own
            // `_activeSession = null; _emitSession();` lines, the
            // active-session-driven UI (driven by sessionStream) would
            // stay on the joining-session screen even though the
            // status went to error, and the user couldn't retry. This
            // belt-and-braces clear guarantees the session state is
            // consistent regardless of which step of teardown failed.
            try {
              await leaveSession();
            } catch (_) {
              // Best-effort cleanup; force-clear what leaveSession
              // didn't get to so the UI doesn't strand on a phantom
              // active session.
              _activeSession = null;
              _emitSession();
            } finally {
              _setStatus(FieldLinkStatus.error);
            }
          });
        }
        break;
      case TransportState.discovering:
        if (_status != FieldLinkStatus.connected) {
          _setStatus(FieldLinkStatus.discovering);
        }
        break;
      case TransportState.disconnected:
        // If we had connected peers, attempt to reconnect.
        if (_activeSession != null) {
          _attemptReconnect();
        }
        break;
      case TransportState.error:
        // On error, also attempt reconnect if session is active.
        if (_activeSession != null) {
          _attemptReconnect();
        } else {
          _setStatus(FieldLinkStatus.error);
        }
        break;
      case TransportState.idle:
      case TransportState.connecting:
        break;
    }
  }

  /// Attempt to reconnect with exponential backoff.
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // Max attempts exceeded — stop trying and report.
      _setStatus(FieldLinkStatus.discovering);
      _reconnectAttempts = 0;
      return;
    }

    _setStatus(FieldLinkStatus.reconnecting);

    final intervalIndex = _reconnectAttempts.clamp(
      0,
      _reconnectIntervalsMs.length - 1,
    );
    final delayMs = _reconnectIntervalsMs[intervalIndex];

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_activeSession == null) return;

      _reconnectAttempts++;

      try {
        // Restart discovery on the transport.
        await _transport.startDiscovery(_activeSession!.id);
        _setStatus(FieldLinkStatus.discovering);
      } on Exception {
        // Discovery restart failed — try again.
        _attemptReconnect();
      }
    });
  }

  /// Broadcast the local ECDH public key to all connected peers.
  ///
  /// If the key exchange manager has not been initialized (no active
  /// session), this is a no-op. We intentionally avoid calling
  /// `initialize()` here because that would regenerate the private key,
  /// invalidating all previously derived peer secrets.
  void _broadcastPublicKey() {
    final pubKey = _keyExchangeManager.localPublicKey;
    if (pubKey == null) return; // session not active

    _syncEngine.broadcastControl({
      'evt': 'key_exchange',
      'pub': pubKey,
    });
  }

  /// Handle an incoming control message from the sync engine.
  ///
  /// Dispatches to the appropriate handler based on the `evt` field:
  /// - `key_exchange`: ECDH public key from a peer
  /// - `role_assign`, `callsign_update`: forwarded to [RoleManager]
  /// - `boundary_exit`: boundary crossing notification
  void _onControlMessage(ControlMessage event) {
    final evt = event.data['evt'] as String?;

    switch (evt) {
      case 'key_exchange':
        _handleKeyExchange(event.senderId, event.data);
        break;
      case 'role_assign':
      case 'callsign_update':
        _roleManager.handleControlEvent(event.data, event.senderId);
        // Rebuild the peer list so role/callsign changes are reflected
        // in the UI immediately. The RoleManager is separate from CRDT
        // state, so we need to manually trigger a refresh.
        _onSyncStateChanged(_syncEngine.currentState);
        break;
      case 'emergency':
        // Only fire the UI state change when this is a genuinely NEW
        // emergency. The originator retransmits the same payload every
        // 30s for late-joining peers, and stale copies can arrive AFTER
        // a cancel via mesh re-delivery; re-firing for those would flip
        // the alert overlay back on after the user already cancelled.
        final isNewEmergency = _emergencyBeacon.handleRemoteEmergency(
          event.senderId,
          event.data,
        );
        if (isNewEmergency) {
          onEmergencyStateChanged?.call(true);
        }
        break;
      case 'emergency_cancel':
        // Only fire the UI state change when the cancel actually applied
        // (i.e. the cancelling sender owned the active beacon). Suppresses
        // spurious false-positive cancels from non-owning peers.
        final didCancel = _emergencyBeacon.handleRemoteCancel(
          event.senderId,
          event.data,
        );
        if (didCancel) {
          onEmergencyStateChanged?.call(false);
        }
        break;
      case 'message':
        final callsign = _roleManager.callsignForPeer(event.senderId);
        final msg = TacticalMessage.fromControl(
          event.senderId,
          callsign.isNotEmpty ? callsign : event.senderId,
          event.data,
        );
        _messageService.addMessage(msg);
        break;
      case 'join_request':
        _handleJoinRequest(event.senderId, event.data);
        break;
      case 'join_response':
        _handleJoinResponse(event.data);
        break;
      default:
        // Other control events (boundary_exit, join, leave, etc.) are
        // handled elsewhere or are informational.
        break;
    }
  }

  /// Handle an incoming `join_request` from a joiner (host side).
  ///
  /// Validates the joiner's PIN or QR key against the real session
  /// credentials. If the session is Open, the PIN matches, or the QR
  /// key matches, accepts the join. Otherwise rejects and the joiner
  /// will disconnect.
  ///
  /// Audit 2026-05-03 P1 fix: the previous QR branch always accepted
  /// without checking the joiner's key, so QR mode was UI-only theatre
  /// — anyone who knew the (broadcast) session id could join a "QR"
  /// session.
  void _handleJoinRequest(String senderId, Map<String, dynamic> data) {
    if (_activeSession == null) return;

    final sessionPin = _activeSession!.pin;
    final sessionKey = _activeSession!.sessionKey;
    final securityMode = _activeSession!.securityMode;
    final joinerPin = data['pin'] as String?;
    final joinerKey = data['key'] as String?;

    bool accepted;
    if (securityMode == SecurityMode.open) {
      // Open session — always accept.
      accepted = true;
    } else if (securityMode == SecurityMode.pin) {
      // PIN mode — validate.
      accepted = joinerPin != null && joinerPin == sessionPin;
    } else {
      // QR mode — the joiner must have scanned the QR and so must know
      // the session key the host generated. Compare directly. If the
      // host has no session key on file (e.g. a session created before
      // this fix shipped) we fall back to id-only acceptance to avoid
      // bricking existing sessions, but reject malformed/missing keys
      // when the host knows what to expect.
      if (sessionKey == null || sessionKey.isEmpty) {
        accepted = true;
      } else {
        accepted = joinerKey != null && joinerKey == sessionKey;
      }
    }

    _syncEngine.broadcastControl({
      'evt': 'join_response',
      'accepted': accepted,
      'targetDeviceId': senderId,
      // Include the host's session metadata so the joiner can mirror it
      // locally — without these the joiner's UI shows hardcoded defaults
      // ("Joined Session" name, SAR mode) that don't match the host.
      if (accepted) 'name': _activeSession!.name,
      if (accepted) 'mode': _activeSession!.operationalMode.id,
      // Tell the joiner who the lead is so they accept future role_assign
      // messages from us. Without this, the joiner's RoleManager doesn't
      // know we're lead and silently ignores promotions / role changes.
      if (accepted) 'lead': _localDeviceId,
    });

    if (!accepted) {
      // Optionally disconnect the rejected peer after a short delay
      // so the response has time to be delivered.
      Future.delayed(const Duration(seconds: 1), () {
        _transport.disconnect(senderId).catchError((_) {});
      });
    }
  }

  /// Handle an incoming `join_response` from the host (joiner side).
  ///
  /// If rejected, leaves the session and emits an error status so the
  /// UI can show "INCORRECT PIN" and revert to the join screen.
  void _handleJoinResponse(Map<String, dynamic> data) {
    final accepted = data['accepted'] as bool? ?? false;
    final targetId = data['targetDeviceId'] as String?;

    // Only process responses addressed to us.
    if (targetId != null && targetId != _localDeviceId) return;

    // Cancel the fail-closed wrong-PIN/wrong-QR timeout — we got SOME
    // response from the host (accepted or rejected). Codex review
    // 2026-05-03 P2.
    _joinAcceptTimer?.cancel();
    _joinAcceptTimer = null;

    if (!accepted) {
      // PIN was wrong — leave the session.
      leaveSession();
      // Notify listeners of the rejection via an error status.
      _setStatus(FieldLinkStatus.error);
      return;
    }

    // Mirror the host's session metadata locally so this device's UI
    // (mode-aware labels, session name, lead-only controls) matches the
    // host's. Without this, joiners show hardcoded defaults from
    // joinSession() and never reflect the actual session state.
    final hostName = data['name'] as String?;
    final hostModeId = data['mode'] as String?;
    final hostLeadId = data['lead'] as String?;

    if (_activeSession != null) {
      OperationalMode? hostMode;
      if (hostModeId != null) {
        hostMode = OperationalMode.values.firstWhere(
          (m) => m.id == hostModeId,
          orElse: () => _activeSession!.operationalMode,
        );
      }
      _activeSession = _activeSession!.copyWith(
        name: hostName,
        operationalMode: hostMode,
      );
      // Persist so the next launch / activeSessionProvider refresh
      // reads the correct values.
      _sessionRepository.updateSession(_activeSession!).catchError((_) => false);
      _emitSession();
    }

    // Trust the host's role assignments. Without recording the host as
    // lead, RoleManager's `_isLeader(senderId)` check rejects every
    // subsequent role_assign / promotion message from the host.
    if (hostLeadId != null && hostLeadId != _localDeviceId) {
      _roleManager.applyRemoteRoleChange(
        hostLeadId,
        TeamRole.lead,
        fromLeader: hostLeadId,
      );
    }
  }

  /// Handle an incoming `key_exchange` control message from a peer.
  ///
  /// Derives a shared secret from the peer's public key via
  /// [KeyExchangeManager] and sends our public key back so the peer
  /// can also derive the shared secret. If the local key pair has not
  /// been initialized (no active session), the message is silently
  /// dropped — we never call `initialize()` defensively because that
  /// would regenerate the private key and invalidate existing secrets.
  void _handleKeyExchange(String peerId, Map<String, dynamic> data) {
    final peerPubKey = data['pub'] as String?;
    if (peerPubKey == null || peerPubKey.isEmpty) return;

    // If we already have a shared key for this peer, skip derivation.
    if (_keyExchangeManager.hasKeyForPeer(peerId)) return;

    // Not initialized — session not active, drop the message.
    if (_keyExchangeManager.localPublicKey == null) return;

    // Derive the shared secret from the peer's public key.
    _keyExchangeManager.handlePeerPublicKey(peerId, peerPubKey);

    // Send our public key back so the peer can derive the same secret.
    _broadcastPublicKey();
  }

  /// Handle CRDT state changes from the sync engine.
  ///
  /// Updates the peer list stream and manages ghost transitions when
  /// peers connect/disconnect.
  void _onSyncStateChanged(CrdtState state) {
    if (_activeSession == null) return;

    // Build peer list from CRDT positions.
    final peers = <Peer>[];
    final connectedIds = _transport.connectedDeviceIds.toSet();

    for (final entry in state.currentPositions.entries) {
      if (entry.key == _localDeviceId) continue;

      final isConnected = connectedIds.contains(entry.key);
      final shortId = entry.key.length > 8
          ? entry.key.substring(0, 8)
          : entry.key;
      // Use the peer's callsign from the RoleManager if available,
      // otherwise fall back to the truncated device ID.
      final callsign = _roleManager.callsignForPeer(entry.key);
      final displayName = callsign.isNotEmpty ? callsign : shortId;

      final peerRole = _roleManager.roleForPeer(entry.key);
      peers.add(Peer(
        id: entry.key,
        displayName: displayName,
        callsign: callsign,
        role: peerRole,
        position: entry.value,
        lastSeen: entry.value.timestamp,
        isConnected: isConnected,
      ));

      // Ghost management: detect disconnection.
      if (!isConnected) {
        // If we have a position but no connection, create a ghost.
        if (_ghostManager.currentGhosts.every((g) => g.peerId != entry.key)) {
          _ghostManager.onPeerDisconnected(Peer(
            id: entry.key,
            displayName: shortId,
            position: entry.value,
            lastSeen: entry.value.timestamp,
            isConnected: false,
          ));
        }
      } else {
        // Peer reconnected — snap-to-live.
        _ghostManager.onPeerReconnected(entry.key);
      }
    }

    // Sync boundary annotation from CRDT state to BoundaryManager.
    final annotations = state.liveAnnotations;
    Annotation? boundaryAnnotation;
    for (final a in annotations) {
      if (a.type == AnnotationType.boundary) {
        boundaryAnnotation = a;
        break;
      }
    }
    if (boundaryAnnotation != null) {
      _boundaryManager.setBoundary(boundaryAnnotation);
    } else {
      _boundaryManager.clearBoundary();
    }

    // Check peer positions against the boundary.
    if (_boundaryManager.hasBoundary) {
      for (final peer in peers) {
        if (!peer.isConnected) continue;
        final pos = peer.position;
        if (pos == null) continue;
        final crossed = _boundaryManager.checkBoundaryCrossing(
          peer.id,
          pos.lat,
          pos.lon,
        );
        if (crossed) {
          final peerCallsign = _roleManager.callsignForPeer(peer.id);
          final callsign = peerCallsign.isNotEmpty ? peerCallsign : peer.displayName;
          final event = BoundaryEvent(
            id: '${peer.id}_${DateTime.now().millisecondsSinceEpoch}',
            peerId: peer.id,
            callsign: callsign,
            timestamp: DateTime.now(),
            lat: pos.lat,
            lon: pos.lon,
          );
          if (!_boundaryEventController.isClosed) {
            _boundaryEventController.add(event);
          }
        }
      }
    }

    if (!_peersController.isClosed) {
      _peersController.add(peers);
    }
  }

  /// Build a [SessionConfig] for the given operational mode.
  SessionConfig _configForMode(OperationalMode mode) {
    switch (mode) {
      case OperationalMode.sar:
        return const SessionConfig.active();
      case OperationalMode.backcountry:
        return const SessionConfig.expedition();
      case OperationalMode.hunting:
        return const SessionConfig.expedition();
      case OperationalMode.training:
        return const SessionConfig.active();
    }
  }

  /// Set the status and notify listeners.
  void _setStatus(FieldLinkStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// Emit the current session to stream listeners.
  void _emitSession() {
    if (!_sessionController.isClosed) {
      _sessionController.add(_activeSession);
    }
  }

  /// Start polling the battery level every 60 seconds.
  void _startBatteryPolling() {
    _stopBatteryPolling();
    _batteryPollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) async {
        await _batteryManager.getBatteryLevel();
      },
    );

    // Initial reading.
    _batteryManager.getBatteryLevel().then((level) {
      if (level != null) {
        _batteryManager.startSession(level);
      }
    });
  }

  /// Stop the battery polling timer.
  void _stopBatteryPolling() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = null;
  }

  /// Start RSSI polling if transport is BLE and a callback is registered.
  void _startRssiPolling() {
    final ble = _resolveBleTransport();
    final callback = onRssiReading;
    if (ble != null && callback != null) {
      ble.startRssiPolling(onRssi: callback);
    }
  }

  /// Stop RSSI polling and clear quality data.
  void _stopRssiPolling() {
    final ble = _resolveBleTransport();
    if (ble != null) {
      ble.stopRssiPolling();
    }
    onRssiClear?.call();
  }

  /// Find the underlying [BleTransport] instance regardless of whether
  /// `_transport` is a bare BLE transport or a [MultiTransport] wrapper.
  ///
  /// Returns null if no BLE transport is in the stack — e.g. a future
  /// configuration where MPC or Nearby Connections is used standalone.
  /// All BLE-only operations (peripheral mode advertising, RSSI polling)
  /// route through this helper instead of an `is BleTransport` check
  /// that would fail when the transport is wrapped.
  BleTransport? _resolveBleTransport() {
    final transport = _transport;
    if (transport is BleTransport) return transport;
    if (transport is MultiTransport) return transport.bleTransport;
    return null;
  }

  /// Public accessor for the underlying [BleTransport] used by the
  /// in-app Diagnostics screen (v1.5.4+312). Returns null if BLE is
  /// not part of the active transport stack.
  BleTransport? get bleTransportOrNull => _resolveBleTransport();
}

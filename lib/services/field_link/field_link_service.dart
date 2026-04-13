import 'dart:async';

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
import 'package:red_grid_link/services/field_link/role_manager.dart';
import 'package:red_grid_link/services/field_link/security/key_exchange_manager.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/sync_engine.dart';
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

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
  })  : _transport = transport,
        _syncEngine = syncEngine,
        _ghostManager = ghostManager,
        _batteryManager = batteryManager,
        _sessionRepository = sessionRepository,
        _peerRepository = peerRepository,
        _localDeviceId = localDeviceId {
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

    final sessionId = generateDeviceId(); // UUID v4
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
    // can discover and connect.
    final transport = _transport;
    if (transport is BleTransport) {
      await transport.startAdvertising(sessionId);
    }

    // Subscribe to discovered devices BEFORE starting the scan so we
    // don't miss joiners discovered instantly.
    await _autoConnectSub?.cancel();
    _autoConnectSub = _transport.discoveredDevices.listen((device) async {
      if (_transport.connectedDeviceIds.contains(device.id)) return;
      try {
        print('[FieldLink] Creator auto-connecting to ${device.id}...');
        await _transport.connect(device.id);
        print('[FieldLink] Creator connected to ${device.id}!');
      } catch (e) {
        print('[FieldLink] Creator connect failed: $e — will retry');
      }
    });

    await _transport.startDiscovery(sessionId);

    await _syncEngine.start(config, sessionId: sessionId);
    await _ghostManager.start();
    _startBatteryPolling();

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

    final session = Session(
      id: sessionId,
      name: 'Joined Session',
      securityMode: pin != null ? SecurityMode.pin : SecurityMode.open,
      pin: pin,
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
    _roleManager.initializeAsJoiner();
    _keyExchangeManager.initialize();
    _emitSession();

    final config = _configForMode(session.operationalMode);

    await _transport.initialize();

    // Subscribe to discovered devices BEFORE starting the scan so we
    // don't miss the creator if it's discovered instantly. Broadcast
    // streams don't buffer — any event emitted before a listener
    // subscribes is silently lost.
    await _autoConnectSub?.cancel();
    _autoConnectSub = _transport.discoveredDevices.listen((device) async {
      // Skip devices we're already connected to.
      if (_transport.connectedDeviceIds.contains(device.id)) return;

      try {
        print('[FieldLink] Auto-connecting to ${device.id}...');
        await _transport.connect(device.id);
        print('[FieldLink] Connected to ${device.id}!');
        // Only cancel the subscription AFTER a successful connect.
        // If connect fails, the subscription stays active so it can
        // retry on the next scan cycle.
        await _autoConnectSub?.cancel();
        _autoConnectSub = null;
      } catch (e) {
        // Connection failed — keep listening for retry on next scan.
        print('[FieldLink] Connect failed: $e — will retry');
      }
    });

    await _transport.startDiscovery(sessionId);

    await _syncEngine.start(config, sessionId: sessionId);
    await _ghostManager.start();
    _startBatteryPolling();

    _setStatus(FieldLinkStatus.discovering);

    return true;
  }

  /// PIN sent by the joiner, held until the host responds with
  /// `join_response`. Cleared after validation completes.
  String? _pendingJoinPin;

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

    // Stop sub-services in order.
    _stopRssiPolling();
    await _syncEngine.stop();
    await _transport.disconnectAll();
    await _transport.stopDiscovery();
    final stopTransport = _transport;
    if (stopTransport is BleTransport) {
      await stopTransport.stopAdvertising();
    }
    _stopBatteryPolling();

    // Mark all peers in this session as disconnected.
    await _peerRepository.disconnectAllInSession(sessionId);

    // Deactivate session.
    await _sessionRepository.deactivateAll();

    _emergencyBeacon.dispose();
    _messageService.reset();
    _roleManager.reset();
    _boundaryManager.clearBoundary();
    _keyExchangeManager.reset();
    _activeSession = null;
    _emitSession();
    _setStatus(FieldLinkStatus.idle);
    _ghostManager.removeAllGhosts();
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
        // If we're a joiner with a pending PIN, send a join_request
        // so the host can validate it via the BLE control channel.
        if (_pendingJoinPin != null) {
          _syncEngine.broadcastControl({
            'evt': 'join_request',
            'pin': _pendingJoinPin,
            'deviceId': _localDeviceId,
          });
          _pendingJoinPin = null;
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
        _emergencyBeacon.handleRemoteEmergency(event.senderId, event.data);
        onEmergencyStateChanged?.call(true);
        break;
      case 'emergency_cancel':
        _emergencyBeacon.handleRemoteCancel(event.senderId);
        onEmergencyStateChanged?.call(false);
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
  /// Validates the joiner's PIN against the real session PIN. If the
  /// session is Open or the PIN matches, accepts the join. Otherwise
  /// rejects and the joiner will disconnect.
  void _handleJoinRequest(String senderId, Map<String, dynamic> data) {
    if (_activeSession == null) return;

    final sessionPin = _activeSession!.pin;
    final securityMode = _activeSession!.securityMode;
    final joinerPin = data['pin'] as String?;

    bool accepted;
    if (securityMode == SecurityMode.open) {
      // Open session — always accept.
      accepted = true;
    } else if (securityMode == SecurityMode.pin) {
      // PIN mode — validate.
      accepted = joinerPin != null && joinerPin == sessionPin;
    } else {
      // QR mode — the QR payload contains the session ID which the
      // joiner already used to find us. Accept.
      accepted = true;
    }

    _syncEngine.broadcastControl({
      'evt': 'join_response',
      'accepted': accepted,
      'targetDeviceId': senderId,
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

    if (!accepted) {
      // PIN was wrong — leave the session.
      leaveSession();
      // Notify listeners of the rejection via an error status.
      _setStatus(FieldLinkStatus.error);
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
    final transport = _transport;
    final callback = onRssiReading;
    if (transport is BleTransport && callback != null) {
      transport.startRssiPolling(onRssi: callback);
    }
  }

  /// Stop RSSI polling and clear quality data.
  void _stopRssiPolling() {
    final transport = _transport;
    if (transport is BleTransport) {
      transport.stopRssiPolling();
    }
    onRssiClear?.call();
  }
}

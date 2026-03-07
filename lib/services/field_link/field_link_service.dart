import 'dart:async';

import 'package:red_grid_link/core/utils/crypto_utils.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/models/session_config.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/data/repositories/session_repository.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/ghost/ghost_manager.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/sync_engine.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// Connection status for the Field Link service.
enum FieldLinkStatus {
  /// No session active.
  idle,

  /// Session active, discovering peers.
  discovering,

  /// Session active, at least one peer connected.
  connected,

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

  Session? _activeSession;
  StreamSubscription<TransportState>? _transportStateSub;
  StreamSubscription<CrdtState>? _syncStateSub;
  Timer? _batteryPollTimer;

  final StreamController<Session?> _sessionController =
      StreamController<Session?>.broadcast();
  final StreamController<List<Peer>> _peersController =
      StreamController<List<Peer>>.broadcast();
  final StreamController<FieldLinkStatus> _statusController =
      StreamController<FieldLinkStatus>.broadcast();

  FieldLinkStatus _status = FieldLinkStatus.idle;

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
        _localDeviceId = localDeviceId;

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
    _emitSession();

    // Determine sync config from mode.
    final config = _configForMode(mode);

    // Start sub-services.
    await _transport.initialize();
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
  /// sessions, the correct [pin] must be provided.
  Future<bool> joinSession(
    String sessionId, {
    String? pin,
    String? qrData,
  }) async {
    // End any existing session first.
    if (_activeSession != null) {
      await leaveSession();
    }

    // For PIN mode, verify the PIN.
    final existingSession = await _sessionRepository.getSessionById(sessionId);
    if (existingSession != null &&
        existingSession.securityMode == SecurityMode.pin) {
      if (pin == null || existingSession.pin != pin) {
        return false;
      }
    }

    final session = existingSession ??
        Session(
          id: sessionId,
          name: 'Joined Session',
          securityMode: pin != null ? SecurityMode.pin : SecurityMode.open,
          pin: pin,
          createdAt: DateTime.now(),
          operationalMode: OperationalMode.sar,
          peers: [_localDeviceId],
          isActive: true,
        );

    if (existingSession == null) {
      await _sessionRepository.createSession(session);
    } else {
      await _sessionRepository.activateSession(sessionId);
    }

    _activeSession = session.copyWith(isActive: true);
    _emitSession();

    final config = _configForMode(session.operationalMode);

    await _transport.initialize();
    await _transport.startDiscovery(sessionId);
    await _syncEngine.start(config, sessionId: sessionId);
    await _ghostManager.start();
    _startBatteryPolling();

    _setStatus(FieldLinkStatus.discovering);

    return true;
  }

  /// Leave the current session.
  ///
  /// Stops all sub-services, disconnects peers, and deactivates the
  /// session in the database.
  Future<void> leaveSession() async {
    if (_activeSession == null) return;

    final sessionId = _activeSession!.id;

    // Stop sub-services in order.
    await _syncEngine.stop();
    await _transport.disconnectAll();
    await _transport.stopDiscovery();
    _stopBatteryPolling();

    // Mark all peers in this session as disconnected.
    await _peerRepository.disconnectAllInSession(sessionId);

    // Deactivate session.
    await _sessionRepository.deactivateAll();

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

  /// The active transport type.
  TransportType get activeTransport => _transport.type;

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

    // Listen for transport state changes.
    _transportStateSub = _transport.stateStream.listen(_onTransportState);

    // Listen for CRDT state changes to update peer list and detect
    // disconnections for ghost management.
    _syncStateSub = _syncEngine.stateStream.listen(_onSyncStateChanged);
  }

  /// Dispose all resources. The service should not be used after this.
  Future<void> dispose() async {
    await _transportStateSub?.cancel();
    await _syncStateSub?.cancel();
    _stopBatteryPolling();
    _syncEngine.dispose();
    _ghostManager.dispose();
    _batteryManager.dispose();
    await _transport.dispose();
    _sessionController.close();
    _peersController.close();
    _statusController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Handle transport state transitions.
  void _onTransportState(TransportState state) {
    switch (state) {
      case TransportState.connected:
        _setStatus(FieldLinkStatus.connected);
        break;
      case TransportState.discovering:
        if (_status != FieldLinkStatus.connected) {
          _setStatus(FieldLinkStatus.discovering);
        }
        break;
      case TransportState.disconnected:
        // If we had connected peers, they disconnected.
        if (_activeSession != null) {
          _setStatus(FieldLinkStatus.discovering);
        }
        break;
      case TransportState.error:
        _setStatus(FieldLinkStatus.error);
        break;
      case TransportState.idle:
      case TransportState.connecting:
        break;
    }
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

      peers.add(Peer(
        id: entry.key,
        displayName: shortId,
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
}

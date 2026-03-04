import 'dart:async';

import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/data/models/device_info.dart';
import 'package:red_grid_link/services/field_link/security/session_security.dart';
import 'package:red_grid_link/services/field_link/transport/transport_manager.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// Higher-level device discovery and session-join service.
///
/// Sits above [TransportManager] and adds:
/// - De-duplication and staleness tracking for discovered devices
/// - Session join / leave with optional authentication
/// - Auto-connect: when enabled, automatically connects to all discovered
///   devices that match the active session
///
/// The typical flow is:
///   1. [startAdvertising] — begin advertising the local device
///   2. [startScanning] — start looking for peers
///   3. Subscribe to [nearbyDevices] to populate the UI
///   4. [joinSession] — authenticate and connect to a specific device
///   5. [leaveSession] — disconnect and stop
class DiscoveryService {
  final TransportManager _transportManager;
  final SessionSecurity _sessionSecurity;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// The session ID we are currently advertising / scanning for.
  String? _activeSessionId;

  /// Information about the local device.
  DeviceInfo? _localDevice;

  /// Whether auto-connect is enabled.
  bool _autoConnect = false;

  /// Set of device IDs we have already auto-connected to (to avoid
  /// repeated attempts).
  final Set<String> _autoConnectedIds = {};

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Discovered devices (de-duplicated)
  // ---------------------------------------------------------------------------

  /// Discovered devices keyed by their ID, updated on each scan result.
  final Map<String, DiscoveredDevice> _discoveredMap = {};

  final StreamController<DiscoveredDevice> _nearbyController =
      StreamController<DiscoveredDevice>.broadcast();

  StreamSubscription<DiscoveredDevice>? _rawDiscoverySub;

  /// Timer for periodic staleness pruning.
  Timer? _pruneTimer;

  /// How long a discovered device stays in the list before it is considered
  /// stale and removed (milliseconds).
  static const int _staleThresholdMs = 30000; // 30 seconds

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  DiscoveryService({
    required TransportManager transportManager,
    required SessionSecurity sessionSecurity,
  })  : _transportManager = transportManager,
        _sessionSecurity = sessionSecurity;

  // ---------------------------------------------------------------------------
  // Public API — streams
  // ---------------------------------------------------------------------------

  /// Stream of de-duplicated nearby devices.
  ///
  /// Each emission is a single [DiscoveredDevice].  The map of all
  /// currently-known devices can be queried via [knownDevices].
  Stream<DiscoveredDevice> get nearbyDevices => _nearbyController.stream;

  /// Snapshot of all currently-known nearby devices.
  List<DiscoveredDevice> get knownDevices => _discoveredMap.values.toList();

  // ---------------------------------------------------------------------------
  // Advertising
  // ---------------------------------------------------------------------------

  /// Start advertising the local device for the given [sessionId].
  ///
  /// Advertising allows other devices to discover us.  The [localDevice]
  /// info is included in advertising metadata.
  Future<void> startAdvertising(
    String sessionId,
    DeviceInfo localDevice,
  ) async {
    _ensureNotDisposed();

    _activeSessionId = sessionId;
    _localDevice = localDevice;

    // The transport manager handles advertising internally when
    // starting a session.
    await _transportManager.startSession(sessionId, localDevice.displayName);
  }

  // ---------------------------------------------------------------------------
  // Scanning
  // ---------------------------------------------------------------------------

  /// Start scanning for nearby devices.
  ///
  /// [startAdvertising] should be called first so that peers can see us
  /// as well.  If not called, scanning still works but is one-directional.
  Future<void> startScanning() async {
    _ensureNotDisposed();

    // Subscribe to the transport manager's raw discovery stream.
    _rawDiscoverySub?.cancel();
    _rawDiscoverySub = _transportManager.discoveredDevices.listen(
      _onDeviceDiscovered,
    );

    // Start periodic staleness pruning.
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pruneStaleDevices(),
    );
  }

  /// Stop all discovery and advertising.
  Future<void> stopAll() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;

    await _rawDiscoverySub?.cancel();
    _rawDiscoverySub = null;

    await _transportManager.stopSession();

    _discoveredMap.clear();
    _autoConnectedIds.clear();
    _activeSessionId = null;
    _localDevice = null;
  }

  // ---------------------------------------------------------------------------
  // Session joining
  // ---------------------------------------------------------------------------

  /// Attempt to join a session by connecting to [deviceId].
  ///
  /// If the session has a PIN, pass it as [pin].  Returns true if
  /// authentication succeeds and the connection is established.
  Future<bool> joinSession(String deviceId, String? pin) async {
    _ensureNotDisposed();

    if (_activeSessionId == null) {
      throw const FieldLinkException(
        'No active session; call startAdvertising first',
      );
    }

    // Check session capacity.
    if (_transportManager.connectedDeviceIds.length >=
        SyncConstants.maxSessionDevices) {
      throw const FieldLinkException(
        'Session is full (max ${SyncConstants.maxSessionDevices} devices)',
      );
    }

    // Authenticate based on the security tier.
    final tier = _sessionSecurity.currentTier;
    bool authenticated;

    switch (tier) {
      case SecurityTier.open:
        authenticated = await _sessionSecurity.authenticateOpen();
      case SecurityTier.pin:
        if (pin == null) {
          throw const FieldLinkException('PIN required for this session');
        }
        authenticated = await _sessionSecurity.authenticatePin(
          pin,
          _sessionSecurity.sessionPin ?? '',
        );
      case SecurityTier.qr:
        // QR authentication is handled separately via
        // SessionSecurity.authenticateQr before calling joinSession.
        authenticated = true;
    }

    if (!authenticated) return false;

    // Connect via the transport manager (tries BLE first).
    try {
      await _transportManager.connectBle(deviceId);
      return true;
    } on TransportException {
      // If BLE fails, try P2P.
      try {
        await _transportManager.connectP2p(deviceId);
        return true;
      } on TransportException {
        return false;
      }
    }
  }

  /// Leave the current session, disconnecting from all peers.
  Future<void> leaveSession() async {
    await stopAll();
  }

  // ---------------------------------------------------------------------------
  // Auto-connect
  // ---------------------------------------------------------------------------

  /// Enable or disable automatic connection to discovered devices.
  ///
  /// When enabled, every newly discovered device that has not already been
  /// connected will be connected automatically via the transport manager.
  void enableAutoConnect(bool enabled) {
    _autoConnect = enabled;
    if (!enabled) {
      _autoConnectedIds.clear();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onDeviceDiscovered(DiscoveredDevice device) {
    // Ignore our own device.
    if (_localDevice != null && device.id == _localDevice!.id) return;

    // Update the de-duplicated map.
    _discoveredMap[device.id] = device;

    // Forward to consumers.
    if (!_nearbyController.isClosed) {
      _nearbyController.add(device);
    }

    // Auto-connect if enabled and we haven't already connected this device.
    if (_autoConnect &&
        !_autoConnectedIds.contains(device.id) &&
        !_transportManager.connectedDeviceIds.contains(device.id)) {
      _autoConnectedIds.add(device.id);

      // Fire-and-forget; failures are silently ignored for auto-connect.
      _transportManager.connectBle(device.id).catchError((_) {
        _autoConnectedIds.remove(device.id);
      });
    }
  }

  /// Remove devices from the discovered map that have not been seen
  /// within [_staleThresholdMs].
  void _pruneStaleDevices() {
    final now = DateTime.now();
    final staleIds = <String>[];

    for (final entry in _discoveredMap.entries) {
      final age = now.difference(entry.value.discoveredAt).inMilliseconds;
      if (age > _staleThresholdMs) {
        staleIds.add(entry.key);
      }
    }

    for (final id in staleIds) {
      _discoveredMap.remove(id);
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Release all resources.
  Future<void> dispose() async {
    _disposed = true;
    await stopAll();
    await _nearbyController.close();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const FieldLinkException('DiscoveryService has been disposed');
    }
  }
}

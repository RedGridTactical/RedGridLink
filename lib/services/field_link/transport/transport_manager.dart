import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/services/field_link/transport/android_p2p_transport.dart';
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/field_link/transport/ios_p2p_transport.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// Manages multiple transport services and auto-selects the best one.
///
/// Strategy:
///   1. Always start with BLE (lowest power, universally available).
///   2. Switch to P2P (Wi-Fi Direct / Multipeer) for bulk transfers
///      exceeding [SyncConstants.maxPayloadBytes].
///   3. Fall back to BLE if P2P fails or is unavailable.
///   4. Platform detection: use [AndroidP2pTransport] on Android,
///      [IosP2pTransport] on iOS.
///
/// The manager exposes a unified interface that delegates to whichever
/// transport is currently active.  Callers do not need to know which
/// transport is in use.
class TransportManager {
  // ---------------------------------------------------------------------------
  // Transports
  // ---------------------------------------------------------------------------

  late final BleTransport _bleTransport;
  TransportService? _p2pTransport;

  /// The transport currently selected for sending data.
  TransportService? _activeTransport;

  /// Whether auto-switching between BLE and P2P is enabled.
  bool _autoSwitch = true;

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  String? _sessionId;
  bool _sessionActive = false;

  // ---------------------------------------------------------------------------
  // Merged streams
  // ---------------------------------------------------------------------------

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  final StreamController<DiscoveredDevice> _discoveryController =
      StreamController<DiscoveredDevice>.broadcast();

  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();

  /// Subscriptions to individual transport streams.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  TransportManager();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The transport type currently selected for outgoing data.
  TransportType get activeTransport =>
      _activeTransport?.type ?? TransportType.ble;

  /// Merged stream of messages from all active transports.
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  /// Merged stream of discovered devices from all active transports.
  Stream<DiscoveredDevice> get discoveredDevices => _discoveryController.stream;

  /// Merged stream of state changes from all active transports.
  Stream<TransportState> get stateStream => _stateController.stream;

  /// The current state of the active transport.
  TransportState get currentState =>
      _activeTransport?.currentState ?? TransportState.idle;

  /// Device IDs connected across all transports (de-duplicated).
  List<String> get connectedDeviceIds {
    final ids = <String>{};
    ids.addAll(_bleTransport.connectedDeviceIds);
    final p2p = _p2pTransport;
    if (p2p != null) {
      ids.addAll(p2p.connectedDeviceIds);
    }
    return ids.toList();
  }

  /// Whether a session is currently active.
  bool get isSessionActive => _sessionActive;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize transports based on the current platform.
  ///
  /// BLE is always initialized.  The platform-specific P2P transport is
  /// created but initialization failures are non-fatal (BLE remains
  /// available as fallback).
  Future<void> initialize() async {
    _ensureNotDisposed();

    // Always create BLE transport.
    _bleTransport = BleTransport();
    await _bleTransport.initialize();

    // Create the appropriate P2P transport for the platform.
    TransportService? p2p;
    try {
      if (Platform.isAndroid) {
        p2p = AndroidP2pTransport();
        await p2p.initialize();
      } else if (Platform.isIOS) {
        p2p = IosP2pTransport();
        await p2p.initialize();
      }
    } on TransportException {
      // P2P initialization failed — continue with BLE only.
      p2p = null;
    }
    _p2pTransport = p2p;

    // Default active transport is BLE.
    _activeTransport = _bleTransport;

    // Wire up merged streams.
    _subscriptions.add(
      _bleTransport.incomingMessages.listen(_messageController.add),
    );
    _subscriptions.add(
      _bleTransport.discoveredDevices.listen(_discoveryController.add),
    );
    _subscriptions.add(
      _bleTransport.stateStream.listen(_stateController.add),
    );

    if (p2p != null) {
      _subscriptions.add(
        p2p.incomingMessages.listen(_messageController.add),
      );
      _subscriptions.add(
        p2p.discoveredDevices.listen(_discoveryController.add),
      );
      _subscriptions.add(
        p2p.stateStream.listen(_stateController.add),
      );
    }
  }

  /// Release all resources.  The instance should not be used after this.
  Future<void> dispose() async {
    _disposed = true;

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    await _bleTransport.dispose();
    await _p2pTransport?.dispose();

    await _messageController.close();
    await _discoveryController.close();
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Start a Field Link session.
  ///
  /// Begins discovery on BLE (and P2P if available and auto-switch is on).
  Future<void> startSession(String sessionId, String displayName) async {
    _ensureNotDisposed();

    _sessionId = sessionId;
    _sessionActive = true;

    // Always start BLE discovery.
    await _bleTransport.startDiscovery(sessionId);

    // Start P2P discovery in parallel if available and auto-switch is on.
    final p2p = _p2pTransport;
    if (_autoSwitch && p2p != null) {
      try {
        await p2p.startDiscovery(sessionId);
      } on TransportException {
        // P2P discovery failed — BLE continues.
      }
    }
  }

  /// Stop the current session and disconnect all peers.
  Future<void> stopSession() async {
    _sessionActive = false;
    _sessionId = null;

    await _bleTransport.stopDiscovery();
    await _bleTransport.disconnectAll();

    final p2p = _p2pTransport;
    if (p2p != null) {
      await p2p.stopDiscovery();
      await p2p.disconnectAll();
    }

    _activeTransport = _bleTransport;
  }

  // ---------------------------------------------------------------------------
  // Data transfer
  // ---------------------------------------------------------------------------

  /// Send [data] to a specific connected device.
  ///
  /// Automatically selects the best transport for the payload size:
  /// - Payloads <= [SyncConstants.maxPayloadBytes]: use BLE
  /// - Larger payloads: prefer P2P if the device is connected via P2P
  ///   and auto-switch is enabled; otherwise chunk over BLE
  Future<void> sendToDevice(String deviceId, Uint8List data) async {
    _ensureNotDisposed();

    final transport = _selectTransportForSend(deviceId, data.length);
    await transport.send(deviceId, data);
  }

  /// Broadcast [data] to all connected devices.
  ///
  /// Sends over each transport that has connected devices, selecting
  /// the appropriate transport per device.
  Future<void> broadcastToAll(Uint8List data) async {
    _ensureNotDisposed();

    final bleIds = Set<String>.from(_bleTransport.connectedDeviceIds);
    final p2p = _p2pTransport;
    final p2pIds = p2p != null
        ? Set<String>.from(p2p.connectedDeviceIds)
        : <String>{};

    final allIds = {...bleIds, ...p2pIds};
    final errors = <String>[];

    for (final deviceId in allIds) {
      try {
        final transport = _selectTransportForSend(deviceId, data.length);
        await transport.send(deviceId, data);
      } on Exception catch (e) {
        errors.add('$deviceId: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw TransportException(
        'Broadcast failed for some devices: ${errors.join('; ')}',
      );
    }
  }

  /// Select the best transport for sending [payloadSize] bytes to
  /// [deviceId].
  TransportService _selectTransportForSend(String deviceId, int payloadSize) {
    if (!_autoSwitch) {
      return _activeTransport ?? _bleTransport;
    }

    // For large payloads, prefer P2P if the device is connected there.
    final p2p = _p2pTransport;
    if (payloadSize > SyncConstants.maxPayloadBytes && p2p != null) {
      if (p2p.connectedDeviceIds.contains(deviceId)) {
        return p2p;
      }
    }

    // Fall back to BLE if the device is connected there.
    if (_bleTransport.connectedDeviceIds.contains(deviceId)) {
      return _bleTransport;
    }

    // If connected only via P2P, use that.
    if (p2p != null && p2p.connectedDeviceIds.contains(deviceId)) {
      return p2p;
    }

    // No transport has this device connected.
    throw TransportException(
      'Device $deviceId is not connected on any transport',
    );
  }

  // ---------------------------------------------------------------------------
  // Transport switching controls
  // ---------------------------------------------------------------------------

  /// Force BLE mode.  Disables auto-switching and stops P2P discovery.
  ///
  /// Use for expedition / battery-saving scenarios.
  void preferBle() {
    _autoSwitch = false;
    _activeTransport = _bleTransport;

    // Stop P2P discovery but keep BLE running.
    _p2pTransport?.stopDiscovery();
  }

  /// Prefer P2P when available.  Re-enables auto-switching and starts
  /// P2P discovery if a session is active.
  void preferP2p() {
    _autoSwitch = true;

    final p2p = _p2pTransport;
    if (p2p != null) {
      _activeTransport = p2p;

      // Start P2P discovery if we have an active session.
      final sid = _sessionId;
      if (_sessionActive && sid != null) {
        p2p.startDiscovery(sid).catchError((_) {
          // P2P discovery failure is non-fatal.
        });
      }
    }
  }

  /// Enable or disable automatic transport switching based on payload
  /// size.
  void setAutoSwitch(bool enabled) {
    _autoSwitch = enabled;

    if (!enabled) {
      // When disabling auto-switch, revert to BLE.
      _activeTransport = _bleTransport;
    }
  }

  // ---------------------------------------------------------------------------
  // Connection delegation
  // ---------------------------------------------------------------------------

  /// Connect to a discovered device via BLE.
  Future<void> connectBle(String deviceId) async {
    await _bleTransport.connect(deviceId);
  }

  /// Connect to a discovered device via the platform P2P transport.
  Future<void> connectP2p(String deviceId) async {
    final p2p = _p2pTransport;
    if (p2p == null) {
      throw const TransportException('P2P transport is not available');
    }
    await p2p.connect(deviceId);
  }

  /// Disconnect a device from all transports.
  Future<void> disconnectDevice(String deviceId) async {
    if (_bleTransport.connectedDeviceIds.contains(deviceId)) {
      await _bleTransport.disconnect(deviceId);
    }
    final p2p = _p2pTransport;
    if (p2p != null && p2p.connectedDeviceIds.contains(deviceId)) {
      await p2p.disconnect(deviceId);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const TransportException('TransportManager has been disposed');
    }
  }
}

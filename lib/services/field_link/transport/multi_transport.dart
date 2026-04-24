import 'dart:async';
import 'dart:typed_data';

import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// A [TransportService] that fans operations out to multiple underlying
/// transports.
///
/// On iOS, this wraps a [BleTransport] alongside an [IosP2pTransport]
/// (Multipeer Connectivity) so both run in parallel:
///
/// - Both advertise + scan with the same session id, doubling the chance
///   that two phones in proximity find each other when one transport
///   flakes (e.g. iOS suppresses BLE service-UUID emission while the app
///   is backgrounded; MPC keeps working in that state).
/// - Discovered devices from both transports are merged and surfaced via
///   [discoveredDevices], so the auto-connect logic in [FieldLinkService]
///   sees them through a single stream.
/// - `connect(deviceId)` tries the primary first, then falls back to any
///   secondary that knows about the device.
/// - `broadcast(data)` fans out to every transport with at least one
///   connected peer. The CRDT layer is idempotent, so duplicate delivery
///   when a peer happens to be on both transports is harmless.
/// - `send(deviceId, data)` routes to whichever transport currently has
///   that device connected.
///
/// On Android the secondary list is empty and behaviour matches a plain
/// [BleTransport] (Android Nearby Connections is a future addition; the
/// existing [AndroidP2pTransport] stub is not yet wired into production).
class MultiTransport implements TransportService {
  /// The primary transport. State, currentState, and type queries proxy
  /// here. Should be the BLE transport in the standard configuration.
  final TransportService _primary;

  /// Additional transports that run in parallel. Empty list disables
  /// fan-out and behaviour is identical to using [_primary] directly.
  final List<TransportService> _secondaries;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  final StreamController<DiscoveredDevice> _discoveryController =
      StreamController<DiscoveredDevice>.broadcast();

  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();

  bool _disposed = false;

  /// Wraps [primary] and zero or more [secondaries] under one TransportService.
  MultiTransport({
    required TransportService primary,
    List<TransportService> secondaries = const [],
  })  : _primary = primary,
        _secondaries = List.unmodifiable(secondaries);

  /// All wrapped transports — [_primary] first, then [_secondaries] in
  /// order. Iteration order is significant for `connect` fallback.
  Iterable<TransportService> get _all => [_primary, ..._secondaries];

  /// The wrapped [BleTransport] if one is present, else null. Used by
  /// [FieldLinkService] to invoke the BLE-only `startAdvertising`
  /// peripheral-mode method (which is not part of the [TransportService]
  /// interface).
  BleTransport? get bleTransport {
    for (final t in _all) {
      if (t is BleTransport) return t;
    }
    return null;
  }

  @override
  TransportType get type => _primary.type;

  @override
  TransportState get currentState => _primary.currentState;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  Stream<DiscoveredDevice> get discoveredDevices =>
      _discoveryController.stream;

  @override
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  @override
  List<String> get connectedDeviceIds {
    final ids = <String>{};
    for (final t in _all) {
      ids.addAll(t.connectedDeviceIds);
    }
    return ids.toList();
  }

  @override
  Future<void> initialize() async {
    _ensureNotDisposed();
    // Initialize transports independently. A failure on a secondary
    // (e.g. MPC permission denied) must not block the primary.
    await _primary.initialize();
    _wire(_primary);
    for (final t in _secondaries) {
      try {
        await t.initialize();
        _wire(t);
      } on Exception {
        // Secondary unavailable — primary continues.
      }
    }
  }

  void _wire(TransportService t) {
    _subscriptions.add(t.incomingMessages.listen(_messageController.add));
    _subscriptions.add(t.discoveredDevices.listen(_discoveryController.add));
    _subscriptions.add(t.stateStream.listen(_stateController.add));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    for (final t in _all) {
      try {
        await t.dispose();
      } on Exception {
        // Best-effort cleanup.
      }
    }
    await _messageController.close();
    await _discoveryController.close();
    await _stateController.close();
  }

  @override
  Future<void> startDiscovery(String sessionId) async {
    _ensureNotDisposed();
    // Start each transport's discovery independently. Failures on
    // secondaries are non-fatal so a single broken transport doesn't
    // prevent the rest from advertising/scanning.
    Object? firstError;
    for (final t in _all) {
      try {
        await t.startDiscovery(sessionId);
      } on Exception catch (e) {
        firstError ??= e;
      }
    }
    // If the primary failed, surface the error to the caller — the
    // session is unusable. Secondary failures are logged and swallowed
    // (see TODO: structured logging).
    if (firstError != null && _primary.currentState == TransportState.error) {
      throw TransportException(
        'Primary transport failed to start discovery',
        firstError is Exception ? firstError : null,
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    for (final t in _all) {
      try {
        await t.stopDiscovery();
      } on Exception {
        // Best-effort.
      }
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    _ensureNotDisposed();
    // Try each transport in turn. A device discovered via MPC won't be
    // reachable via BLE and vice versa, so the loop probes for a match
    // and stops on first success.
    Object? lastError;
    for (final t in _all) {
      try {
        await t.connect(deviceId);
        return;
      } on Exception catch (e) {
        lastError = e;
        continue;
      }
    }
    throw TransportException(
      'No transport could connect to $deviceId',
      lastError is Exception ? lastError : null,
    );
  }

  @override
  Future<void> disconnect(String deviceId) async {
    for (final t in _all) {
      if (t.connectedDeviceIds.contains(deviceId)) {
        try {
          await t.disconnect(deviceId);
        } on Exception {
          // Best-effort.
        }
      }
    }
  }

  @override
  Future<void> disconnectAll() async {
    for (final t in _all) {
      try {
        await t.disconnectAll();
      } on Exception {
        // Best-effort.
      }
    }
  }

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    _ensureNotDisposed();
    // Route to whichever transport actually has the peer connected.
    for (final t in _all) {
      if (t.connectedDeviceIds.contains(deviceId)) {
        await t.send(deviceId, data);
        return;
      }
    }
    throw TransportException(
      'Device $deviceId is not connected on any transport',
    );
  }

  @override
  Future<void> broadcast(Uint8List data) async {
    _ensureNotDisposed();
    // Fan out to every transport that has at least one connected peer.
    // CRDT operations are idempotent, so a peer connected via both
    // transports receiving the same delta twice is a no-op.
    for (final t in _all) {
      if (t.connectedDeviceIds.isEmpty) continue;
      try {
        await t.broadcast(data);
      } on Exception {
        // Per-transport broadcast failures are non-fatal — the next
        // heartbeat tick or delta will retry.
      }
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const TransportException('MultiTransport has been disposed');
    }
  }
}

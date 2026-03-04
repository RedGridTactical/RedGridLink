import 'dart:async';

import 'package:flutter/services.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// iOS Multipeer Connectivity transport via platform channel.
///
/// Uses Apple's MultipeerConnectivity framework for Wi-Fi / BLE hybrid
/// peer-to-peer communication on iOS devices.
///
/// This Dart side defines the full interface and forwards calls over a
/// [MethodChannel].  The native Swift implementation lives in
/// `ios/Runner/MultipeerPlugin.swift` and will be built in Phase 7.
///
/// All method-channel calls are guarded: if the native side is not yet
/// implemented, calls will throw a [MissingPluginException] which is
/// caught and wrapped in a [TransportException].
class IosP2pTransport implements TransportService {
  // ---------------------------------------------------------------------------
  // Platform channel
  // ---------------------------------------------------------------------------

  static const MethodChannel _channel =
      MethodChannel('com.redgrid.link/multipeer');

  static const EventChannel _eventChannel =
      EventChannel('com.redgrid.link/multipeer/events');

  /// Bonjour service type used for browsing / advertising.
  /// Must be 1-15 characters, lowercase ASCII letters, hyphens, and digits.
  static const String _serviceType = 'red-grid-link';

  // ---------------------------------------------------------------------------
  // Transport metadata
  // ---------------------------------------------------------------------------

  @override
  TransportType get type => TransportType.iosP2p;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  TransportState _state = TransportState.idle;

  @override
  TransportState get currentState => _state;

  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  final StreamController<DiscoveredDevice> _discoveryController =
      StreamController<DiscoveredDevice>.broadcast();

  @override
  Stream<DiscoveredDevice> get discoveredDevices => _discoveryController.stream;

  // ---------------------------------------------------------------------------
  // Connections
  // ---------------------------------------------------------------------------

  final Set<String> _connectedPeers = {};

  @override
  List<String> get connectedDeviceIds => _connectedPeers.toList();

  // ---------------------------------------------------------------------------
  // Incoming messages
  // ---------------------------------------------------------------------------

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  @override
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  // ---------------------------------------------------------------------------
  // Events from native side
  // ---------------------------------------------------------------------------

  StreamSubscription<dynamic>? _eventSubscription;

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    _ensureNotDisposed();

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object error) {
        _setState(TransportState.error);
      },
    );

    _setState(TransportState.idle);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stopDiscovery();
    await disconnectAll();
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _stateController.close();
    await _discoveryController.close();
    await _messageController.close();
  }

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  @override
  Future<void> startDiscovery(String sessionId) async {
    _ensureNotDisposed();
    _setState(TransportState.discovering);

    try {
      // Start advertising so other iOS devices can find us.
      await _channel.invokeMethod<void>('startAdvertising', {
        'serviceType': _serviceType,
        'displayName': 'RedGridLink', // Resolved at native layer
        'sessionId': sessionId,
      });

      // Browse for nearby peers advertising the same service type.
      await _channel.invokeMethod<void>('startBrowsing', {
        'serviceType': _serviceType,
      });
    } on MissingPluginException {
      throw const TransportException(
        'iOS Multipeer Connectivity native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      _setState(TransportState.error);
      throw TransportException(
        'Failed to start Multipeer Connectivity discovery',
        e,
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod<void>('stopBrowsing');
      await _channel.invokeMethod<void>('stopAdvertising');
    } on MissingPluginException {
      // Native side not implemented; ignore.
    } on PlatformException {
      // Best effort.
    }

    if (_state == TransportState.discovering) {
      _setState(
        _connectedPeers.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  @override
  Future<void> connect(String deviceId) async {
    _ensureNotDisposed();

    if (_connectedPeers.contains(deviceId)) return;

    _setState(TransportState.connecting);

    try {
      await _channel.invokeMethod<void>('invitePeer', {
        'peerId': deviceId,
      });
    } on MissingPluginException {
      throw const TransportException(
        'iOS Multipeer Connectivity native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      _setState(
        _connectedPeers.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
      throw TransportException(
        'Failed to connect to peer $deviceId',
        e,
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _connectedPeers.remove(deviceId);

    try {
      await _channel.invokeMethod<void>('disconnect', {
        'peerId': deviceId,
      });
    } on MissingPluginException {
      // Native side not implemented; ignore.
    } on PlatformException {
      // Best effort.
    }

    _setState(
      _connectedPeers.isEmpty
          ? TransportState.disconnected
          : TransportState.connected,
    );
  }

  @override
  Future<void> disconnectAll() async {
    _connectedPeers.clear();

    try {
      await _channel.invokeMethod<void>('disconnectAll');
    } on MissingPluginException {
      // Native side not implemented.
    } on PlatformException {
      // Best effort.
    }

    _setState(TransportState.disconnected);
  }

  // ---------------------------------------------------------------------------
  // Data transfer
  // ---------------------------------------------------------------------------

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    _ensureNotDisposed();

    if (!_connectedPeers.contains(deviceId)) {
      throw TransportException('Peer $deviceId is not connected');
    }

    try {
      await _channel.invokeMethod<void>('sendData', {
        'peerId': deviceId,
        'data': data,
      });
    } on MissingPluginException {
      throw const TransportException(
        'iOS Multipeer Connectivity native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      throw TransportException(
        'Failed to send data to peer $deviceId',
        e,
      );
    }
  }

  @override
  Future<void> broadcast(Uint8List data) async {
    final errors = <String>[];

    for (final peerId in _connectedPeers.toList()) {
      try {
        await send(peerId, data);
      } on Exception catch (e) {
        errors.add('$peerId: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw TransportException(
        'Broadcast failed for some peers: ${errors.join('; ')}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Native event handling
  // ---------------------------------------------------------------------------

  /// Dispatch events received from the native Swift side via the
  /// [EventChannel].
  ///
  /// Expected event format (Map):
  /// ```json
  /// {
  ///   "event": "onPeerFound" | "onPeerLost" | ...,
  ///   "data": { ... }
  /// }
  /// ```
  void _onNativeEvent(dynamic rawEvent) {
    if (rawEvent is! Map) return;

    final event = rawEvent['event'] as String?;
    final data = rawEvent['data'] as Map?;
    if (event == null || data == null) return;

    switch (event) {
      case 'onPeerFound':
        _handlePeerFound(data);
      case 'onPeerLost':
        _handlePeerLost(data);
      case 'onInviteReceived':
        _handleInviteReceived(data);
      case 'onSessionStateChanged':
        _handleSessionStateChanged(data);
      case 'onDataReceived':
        _handleDataReceived(data);
    }
  }

  void _handlePeerFound(Map<dynamic, dynamic> data) {
    final peerId = data['peerId'] as String?;
    final peerName = data['peerName'] as String? ?? 'Unknown';
    if (peerId == null) return;

    _discoveryController.add(DiscoveredDevice(
      id: peerId,
      name: peerName,
      deviceType: DeviceType.ios,
      discoveredAt: DateTime.now(),
    ));
  }

  void _handlePeerLost(Map<dynamic, dynamic> data) {
    // Peer lost events can be used by higher layers to remove stale
    // entries from the discovered-devices list.  The transport layer
    // does not maintain a persistent set of discovered peers — it
    // only emits events.
    //
    // TODO(Phase 7): Consider emitting a "lost" event type or a
    // separate stream.
  }

  void _handleInviteReceived(Map<dynamic, dynamic> data) {
    final peerId = data['peerId'] as String?;
    if (peerId == null) return;

    // Auto-accept incoming invitations.
    // TODO(Phase 7): Add authentication check before accepting.
    _channel.invokeMethod<void>('acceptInvite', {
      'peerId': peerId,
    }).catchError((_) {
      // Best effort.
    });
  }

  void _handleSessionStateChanged(Map<dynamic, dynamic> data) {
    final peerId = data['peerId'] as String?;
    final state = data['state'] as String?;
    if (peerId == null || state == null) return;

    switch (state) {
      case 'connected':
        _connectedPeers.add(peerId);
        _setState(TransportState.connected);
      case 'notConnected':
        _connectedPeers.remove(peerId);
        _setState(
          _connectedPeers.isEmpty
              ? TransportState.disconnected
              : TransportState.connected,
        );
      case 'connecting':
        _setState(TransportState.connecting);
    }
  }

  void _handleDataReceived(Map<dynamic, dynamic> data) {
    final peerId = data['peerId'] as String?;
    final bytes = data['data'];
    if (peerId == null || bytes == null) return;

    _messageController.add(TransportMessage(
      senderId: peerId,
      data: bytes is Uint8List
          ? bytes
          : Uint8List.fromList(List<int>.from(bytes as List)),
      receivedAt: DateTime.now(),
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setState(TransportState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const TransportException('IosP2pTransport has been disposed');
    }
  }
}

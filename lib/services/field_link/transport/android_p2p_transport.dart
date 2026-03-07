import 'dart:async';

import 'package:flutter/services.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// Android Nearby Connections transport via platform channel.
///
/// Uses Google Play Services Nearby Connections API (Strategy.P2P_CLUSTER)
/// for high-throughput, Wi-Fi-Direct-backed peer-to-peer communication.
///
/// This Dart side defines the full interface and forwards calls over a
/// [MethodChannel].  The native Kotlin implementation lives in
/// `android/app/src/main/kotlin/.../NearbyConnectionsPlugin.kt` and will
/// be built in Phase 7.
///
/// All method-channel calls are guarded: if the native side is not yet
/// implemented, calls will throw a [MissingPluginException] which is
/// caught and wrapped in a [TransportException].
class AndroidP2pTransport implements TransportService {
  // ---------------------------------------------------------------------------
  // Platform channel
  // ---------------------------------------------------------------------------

  static const MethodChannel _channel =
      MethodChannel('com.redgrid.link/nearby_connections');

  static const EventChannel _eventChannel =
      EventChannel('com.redgrid.link/nearby_connections/events');

  /// The session ID we are currently advertising for.
  String? _activeSessionId;

  // ---------------------------------------------------------------------------
  // Transport metadata
  // ---------------------------------------------------------------------------

  @override
  TransportType get type => TransportType.androidP2p;

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

  final Set<String> _connectedEndpoints = {};

  @override
  List<String> get connectedDeviceIds => _connectedEndpoints.toList();

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

    // Subscribe to the event channel coming from native code.
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
    _activeSessionId = sessionId;
    _setState(TransportState.discovering);

    try {
      // Start advertising so other devices can find us.
      await _channel.invokeMethod<void>('startAdvertising', {
        'sessionId': sessionId,
        'displayName': 'RedGridLink', // Resolved at native layer
      });

      // Simultaneously start discovering other advertisers.
      await _channel.invokeMethod<void>('startDiscovery', {
        'sessionId': sessionId,
      });
    } on MissingPluginException {
      throw const TransportException(
        'Android Nearby Connections native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      _setState(TransportState.error);
      throw TransportException(
        'Failed to start Nearby Connections discovery',
        e,
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod<void>('stopDiscovery');
      await _channel.invokeMethod<void>('stopAdvertising');
    } on MissingPluginException {
      // Native side not implemented; ignore.
    } on PlatformException {
      // Best effort.
    }

    if (_state == TransportState.discovering) {
      _setState(
        _connectedEndpoints.isEmpty
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

    if (_connectedEndpoints.contains(deviceId)) return;

    _setState(TransportState.connecting);

    try {
      await _channel.invokeMethod<void>('requestConnection', {
        'endpointId': deviceId,
      });
    } on MissingPluginException {
      throw const TransportException(
        'Android Nearby Connections native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      _setState(
        _connectedEndpoints.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
      throw TransportException(
        'Failed to connect to endpoint $deviceId',
        e,
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _connectedEndpoints.remove(deviceId);

    try {
      await _channel.invokeMethod<void>('disconnectFromEndpoint', {
        'endpointId': deviceId,
      });
    } on MissingPluginException {
      // Native side not implemented; ignore.
    } on PlatformException {
      // Best effort.
    }

    _setState(
      _connectedEndpoints.isEmpty
          ? TransportState.disconnected
          : TransportState.connected,
    );
  }

  @override
  Future<void> disconnectAll() async {
    _connectedEndpoints.clear();

    try {
      await _channel.invokeMethod<void>('stopAllEndpoints');
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

    if (!_connectedEndpoints.contains(deviceId)) {
      throw TransportException('Endpoint $deviceId is not connected');
    }

    try {
      await _channel.invokeMethod<void>('sendPayload', {
        'endpointId': deviceId,
        'bytes': data,
      });
    } on MissingPluginException {
      throw const TransportException(
        'Android Nearby Connections native plugin not implemented yet '
        '(Phase 7)',
      );
    } on PlatformException catch (e) {
      throw TransportException(
        'Failed to send payload to $deviceId',
        e,
      );
    }
  }

  @override
  Future<void> broadcast(Uint8List data) async {
    final errors = <String>[];

    for (final endpointId in _connectedEndpoints.toList()) {
      try {
        await send(endpointId, data);
      } on Exception catch (e) {
        errors.add('$endpointId: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw TransportException(
        'Broadcast failed for some endpoints: ${errors.join('; ')}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Native event handling
  // ---------------------------------------------------------------------------

  /// Dispatch events received from the native Kotlin side via the
  /// [EventChannel].
  ///
  /// Expected event format (Map):
  /// ```json
  /// {
  ///   "event": "onEndpointFound" | "onConnectionInitiated" | ... ,
  ///   "data": { ... }
  /// }
  /// ```
  void _onNativeEvent(dynamic rawEvent) {
    if (rawEvent is! Map) return;

    final event = rawEvent['event'] as String?;
    final data = rawEvent['data'] as Map?;
    if (event == null || data == null) return;

    switch (event) {
      case 'onEndpointFound':
        _handleEndpointFound(data);
      case 'onConnectionInitiated':
        _handleConnectionInitiated(data);
      case 'onConnectionResult':
        _handleConnectionResult(data);
      case 'onDisconnected':
        _handleDisconnected(data);
      case 'onPayloadReceived':
        _handlePayloadReceived(data);
    }
  }

  void _handleEndpointFound(Map<dynamic, dynamic> data) {
    final endpointId = data['endpointId'] as String?;
    final endpointName = data['endpointName'] as String? ?? 'Unknown';
    if (endpointId == null) return;

    _discoveryController.add(DiscoveredDevice(
      id: endpointId,
      name: endpointName,
      deviceType: DeviceType.android,
      discoveredAt: DateTime.now(),
    ));
  }

  void _handleConnectionInitiated(Map<dynamic, dynamic> data) {
    final endpointId = data['endpointId'] as String?;
    if (endpointId == null) return;

    // Verify the session ID matches before accepting.
    final peerSessionId = data['sessionId'] as String?;
    if (_activeSessionId != null &&
        peerSessionId != null &&
        peerSessionId != _activeSessionId) {
      // Reject connections from different sessions.
      _channel.invokeMethod<void>('rejectConnection', {
        'endpointId': endpointId,
      }).catchError((_) {});
      return;
    }

    // Accept connection for matching or unknown session.
    _channel.invokeMethod<void>('acceptConnection', {
      'endpointId': endpointId,
    }).catchError((_) {
      // Best effort.
    });
  }

  void _handleConnectionResult(Map<dynamic, dynamic> data) {
    final endpointId = data['endpointId'] as String?;
    final success = data['success'] as bool? ?? false;
    if (endpointId == null) return;

    if (success) {
      _connectedEndpoints.add(endpointId);
      _setState(TransportState.connected);
    } else {
      _setState(
        _connectedEndpoints.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
    }
  }

  void _handleDisconnected(Map<dynamic, dynamic> data) {
    final endpointId = data['endpointId'] as String?;
    if (endpointId == null) return;

    _connectedEndpoints.remove(endpointId);
    _setState(
      _connectedEndpoints.isEmpty
          ? TransportState.disconnected
          : TransportState.connected,
    );
  }

  void _handlePayloadReceived(Map<dynamic, dynamic> data) {
    final endpointId = data['endpointId'] as String?;
    final bytes = data['bytes'];
    if (endpointId == null || bytes == null) return;

    _messageController.add(TransportMessage(
      senderId: endpointId,
      data: bytes is Uint8List ? bytes : Uint8List.fromList(List<int>.from(bytes as List)),
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
      throw const TransportException('AndroidP2pTransport has been disposed');
    }
  }
}

import 'dart:typed_data';

import 'package:red_grid_link/data/models/peer.dart';

/// Transport mechanism type.
enum TransportType {
  /// Bluetooth Low Energy (universal, low power).
  ble,

  /// Android Nearby Connections (Wi-Fi Direct / BLE hybrid).
  androidP2p,

  /// iOS Multipeer Connectivity (Wi-Fi / BLE hybrid).
  iosP2p,
}

/// State of a transport service.
enum TransportState {
  /// Transport is initialized but not active.
  idle,

  /// Actively scanning / advertising for peers.
  discovering,

  /// Connection handshake in progress.
  connecting,

  /// At least one peer is connected and data can flow.
  connected,

  /// All peers disconnected (may auto-reconnect).
  disconnected,

  /// Unrecoverable error; requires re-initialization.
  error,
}

/// A device discovered during scanning / browsing.
class DiscoveredDevice {
  /// Platform-specific identifier (BLE address, endpoint ID, peer ID).
  ///
  /// Used by [TransportService.connect] to actually open a link to the
  /// peer. This is NOT the Field Link session UUID — see [sessionId].
  final String id;

  /// Human-readable name advertised by the peer.
  final String name;

  /// Field Link session UUID parsed from the peer's advertising payload
  /// (BLE service data on Android/iOS, MPC discoveryInfo on iOS).
  ///
  /// This is the UUID v4 the host generated in
  /// [FieldLinkService.createSession]. Joiners MUST pass this value to
  /// [FieldLinkService.joinSession] so both ends use the same CRDT
  /// session id. Falling back to [id] would create a sessionId mismatch
  /// (CoreBluetooth UUID vs. UUID v4) and silently drop all sync data.
  ///
  /// May be `null` if the peer is on an old build that did not include
  /// the session id in its advertisement, or if the scan callback fired
  /// before the service-data field was populated.
  final String? sessionId;

  /// Device platform inferred from advertising data.
  final DeviceType deviceType;

  /// Received signal strength indicator (BLE only).
  final int? rssi;

  /// When this device was first seen in the current scan window.
  final DateTime discoveredAt;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    this.sessionId,
    this.deviceType = DeviceType.unknown,
    this.rssi,
    required this.discoveredAt,
  });

  @override
  String toString() =>
      'DiscoveredDevice(id: $id, name: $name, sessionId: $sessionId, rssi: $rssi)';
}

/// An incoming data message from a connected peer.
class TransportMessage {
  /// Identifier of the sending device.
  final String senderId;

  /// Raw payload bytes.
  final Uint8List data;

  /// When the message was received locally.
  final DateTime receivedAt;

  const TransportMessage({
    required this.senderId,
    required this.data,
    required this.receivedAt,
  });

  @override
  String toString() =>
      'TransportMessage(from: $senderId, ${data.length} bytes)';
}

/// Abstract transport interface that all transport implementations must
/// fulfill.
///
/// The transport layer is responsible for:
/// - Discovering nearby devices running Red Grid Link
/// - Establishing peer-to-peer connections
/// - Sending and receiving raw byte payloads
///
/// Implementations exist for BLE (central mode via flutter_blue_plus),
/// Android Nearby Connections, and iOS Multipeer Connectivity.
abstract class TransportService {
  /// The transport mechanism this instance uses.
  TransportType get type;

  /// Stream of transport state transitions.
  Stream<TransportState> get stateStream;

  /// The current transport state (synchronous snapshot).
  TransportState get currentState;

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  /// Begin discovering nearby devices.
  ///
  /// [sessionId] is included in advertising / discovery metadata so that
  /// only devices in the same session are surfaced.
  Future<void> startDiscovery(String sessionId);

  /// Stop the current discovery scan / browse.
  Future<void> stopDiscovery();

  /// Stream of devices found during discovery.
  ///
  /// Devices may appear multiple times as their advertising data or RSSI
  /// changes. Consumers should de-duplicate by [DiscoveredDevice.id].
  Stream<DiscoveredDevice> get discoveredDevices;

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  /// Initiate a connection to the device identified by [deviceId].
  Future<void> connect(String deviceId);

  /// Disconnect from a single device.
  Future<void> disconnect(String deviceId);

  /// Disconnect from every connected device.
  Future<void> disconnectAll();

  /// List of device IDs that are currently connected.
  List<String> get connectedDeviceIds;

  // ---------------------------------------------------------------------------
  // Data transfer
  // ---------------------------------------------------------------------------

  /// Send [data] to a specific connected device.
  ///
  /// Throws [TransportException] if [deviceId] is not connected.
  Future<void> send(String deviceId, Uint8List data);

  /// Broadcast [data] to all currently connected devices.
  Future<void> broadcast(Uint8List data);

  /// Stream of messages received from connected peers.
  Stream<TransportMessage> get incomingMessages;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the transport (request permissions, set up adapters).
  Future<void> initialize();

  /// Release all resources. The instance should not be used after this.
  Future<void> dispose();
}

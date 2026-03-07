import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:red_grid_link/core/constants/ble_constants.dart';
import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

/// BLE transport implementation using flutter_blue_plus (central mode).
///
/// flutter_blue_plus supports the GATT central role well: scanning for
/// peripherals, connecting, reading/writing/subscribing to characteristics.
///
/// Peripheral (advertising / GATT server) support is limited on Flutter.
/// For MVP we rely on central-mode flows:
///   - Each device scans for peers advertising [BleConstants.fieldLinkServiceUuid].
///   - On connection, services are discovered and characteristics subscribed.
///   - Bidirectional communication uses writable characteristics with
///     notifications.
///
/// For full mesh advertising a native platform channel is needed (Phase 7).
class BleTransport implements TransportService {
  // ---------------------------------------------------------------------------
  // Transport metadata
  // ---------------------------------------------------------------------------

  @override
  TransportType get type => TransportType.ble;

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

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Subscription for the isScanning stream (auto-restart logic).
  StreamSubscription<bool>? _isScanningSubscription;

  /// Session ID embedded in manufacturer-specific advertising data so that
  /// only peers in the same session respond.
  ///
  /// Stored for scan restarts and peripheral advertising (Phase 7).
  String? _activeSessionId;

  /// The session ID currently being advertised / scanned, or null.
  String? get activeSessionId => _activeSessionId;

  // ---------------------------------------------------------------------------
  // Connections
  // ---------------------------------------------------------------------------

  /// Connected peripherals keyed by remote ID string.
  final Map<String, BluetoothDevice> _connectedDevices = {};

  /// Characteristic subscriptions per device.
  final Map<String, List<StreamSubscription<List<int>>>> _charSubscriptions =
      {};

  /// Connection state subscriptions per device (for reconnect handling).
  final Map<String, StreamSubscription<BluetoothConnectionState>>
      _connectionStateSubs = {};

  /// Cached writable characteristics per device (avoids re-discovering
  /// services on every send).
  final Map<String, BluetoothCharacteristic> _writableCharCache = {};

  /// Reconnection attempt counts (for exponential back-off).
  final Map<String, int> _reconnectAttempts = {};

  /// Maximum number of consecutive reconnection attempts before giving up.
  static const int _maxReconnectAttempts = 5;

  /// Base delay for exponential back-off (milliseconds).
  static const int _reconnectBaseDelayMs = 1000;

  @override
  List<String> get connectedDeviceIds => _connectedDevices.keys.toList();

  // ---------------------------------------------------------------------------
  // Incoming messages
  // ---------------------------------------------------------------------------

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  @override
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  // ---------------------------------------------------------------------------
  // MTU
  // ---------------------------------------------------------------------------

  /// Negotiated MTU per device.  Falls back to [BleConstants.minMtu].
  final Map<String, int> _negotiatedMtu = {};

  // ---------------------------------------------------------------------------
  // Chunking
  // ---------------------------------------------------------------------------

  /// Overhead bytes per ATT write (3 bytes ATT header).
  static const int _attOverhead = 3;

  /// Reassembly buffers for incoming chunked messages keyed by device ID.
  final Map<String, _ChunkBuffer> _chunkBuffers = {};

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  bool _disposed = false;

  @override
  Future<void> initialize() async {
    if (_disposed) {
      throw const TransportException('BleTransport has been disposed');
    }

    // Ensure Bluetooth is available and turned on.
    //
    // On iOS, CoreBluetooth initially reports the adapter state as `unknown`
    // while CBCentralManager initializes (~100-500ms). Using `.first` would
    // capture that initial `unknown` and incorrectly treat BT as unavailable.
    // We filter out `unknown` and wait for a definitive state (on/off/etc).
    debugPrint('[BleTransport] initialize: checking adapter state...');
    BluetoothAdapterState adapterState;
    try {
      adapterState = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      debugPrint('[BleTransport] adapter state check timed out after 5s');
      _setState(TransportState.error);
      throw const TransportException(
        'Bluetooth adapter state could not be determined. '
        'Please ensure Bluetooth is enabled and try again.',
      );
    }

    debugPrint('[BleTransport] adapter state: $adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      _setState(TransportState.error);
      throw const TransportException(
        'Bluetooth is not available or turned off',
      );
    }

    _setState(TransportState.idle);
    debugPrint('[BleTransport] initialized successfully');
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stopDiscovery();
    await disconnectAll();
    _writableCharCache.clear();
    await _stateController.close();
    await _discoveryController.close();
    await _messageController.close();
  }

  // ---------------------------------------------------------------------------
  // Discovery (central mode scanning)
  // ---------------------------------------------------------------------------

  @override
  Future<void> startDiscovery(String sessionId) async {
    _ensureNotDisposed();
    _activeSessionId = sessionId;

    // Stop any ongoing scan before starting a new one.
    await stopDiscovery();

    _setState(TransportState.discovering);
    debugPrint('[BleTransport] startDiscovery: session=$sessionId');

    // Start a continuous scan filtered to our service UUID.
    // flutter_blue_plus emits results via scanResults stream.
    await FlutterBluePlus.startScan(
      withServices: [Guid(BleConstants.fieldLinkServiceUuid)],
      timeout: const Duration(milliseconds: BleConstants.scanTimeoutMs),
      androidScanMode: AndroidScanMode.lowLatency,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object error) {
        _setState(TransportState.error);
      },
    );

    // When the scan completes (timeout), restart it automatically
    // to maintain continuous discovery.
    // Cancel any prior isScanning subscription to avoid leaking listeners.
    await _isScanningSubscription?.cancel();
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && _state == TransportState.discovering && !_disposed) {
        // Restart scan after a short pause to avoid hammering the adapter.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_state == TransportState.discovering && !_disposed) {
            FlutterBluePlus.startScan(
              withServices: [Guid(BleConstants.fieldLinkServiceUuid)],
              timeout: const Duration(milliseconds: BleConstants.scanTimeoutMs),
              androidScanMode: AndroidScanMode.lowLatency,
            );
          }
        });
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _isScanningSubscription?.cancel();
    _isScanningSubscription = null;

    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }

    if (_state == TransportState.discovering) {
      _setState(
        _connectedDevices.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
    }
  }

  /// Process a batch of scan results from flutter_blue_plus.
  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final device = result.device;
      final name = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown';

      // Infer device type from advertising data if possible.
      // For now, mark all as unknown; higher layers resolve via handshake.
      final discovered = DiscoveredDevice(
        id: device.remoteId.str,
        name: name,
        deviceType: DeviceType.unknown,
        rssi: result.rssi,
        discoveredAt: DateTime.now(),
      );

      _discoveryController.add(discovered);
    }
  }

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  @override
  Future<void> connect(String deviceId) async {
    _ensureNotDisposed();

    if (_connectedDevices.containsKey(deviceId)) return;

    _setState(TransportState.connecting);

    try {
      final device = BluetoothDevice.fromId(deviceId);

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );

      // Negotiate MTU (request preferred, accept whatever the peripheral
      // grants).
      int mtu = BleConstants.minMtu;
      try {
        mtu = await device.requestMtu(BleConstants.preferredMtu);
      } catch (_) {
        // MTU negotiation failure is non-fatal; use the default.
      }
      _negotiatedMtu[deviceId] = mtu;

      // Discover services, cache writable characteristic, and subscribe.
      final services = await device.discoverServices();
      await _subscribeToCharacteristics(deviceId, device, services);
      _cacheWritableCharacteristic(deviceId, services);

      _connectedDevices[deviceId] = device;
      _reconnectAttempts[deviceId] = 0;

      // Listen for disconnection events to trigger reconnection.
      // Cancel any prior subscription for this device first.
      await _connectionStateSubs[deviceId]?.cancel();
      _connectionStateSubs[deviceId] =
          device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDeviceDisconnected(deviceId);
        }
      });

      _setState(TransportState.connected);
    } on Exception catch (e) {
      _setState(
        _connectedDevices.isEmpty
            ? TransportState.idle
            : TransportState.connected,
      );
      throw TransportException(
        'Failed to connect to $deviceId',
        e,
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    final device = _connectedDevices.remove(deviceId);
    _negotiatedMtu.remove(deviceId);
    _reconnectAttempts.remove(deviceId);
    _chunkBuffers.remove(deviceId);
    _writableCharCache.remove(deviceId);

    // Cancel connection state subscription.
    await _connectionStateSubs.remove(deviceId)?.cancel();

    // Cancel characteristic subscriptions.
    final subs = _charSubscriptions.remove(deviceId);
    if (subs != null) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }

    try {
      await device?.disconnect();
    } catch (_) {
      // Best-effort disconnect.
    }

    _setState(
      _connectedDevices.isEmpty
          ? TransportState.disconnected
          : TransportState.connected,
    );
  }

  @override
  Future<void> disconnectAll() async {
    final ids = List<String>.from(_connectedDevices.keys);
    for (final id in ids) {
      await disconnect(id);
    }
  }

  /// Called when a remote device disconnects unexpectedly.
  ///
  /// Attempts reconnection with exponential back-off up to
  /// [_maxReconnectAttempts] times.
  void _onDeviceDisconnected(String deviceId) {
    _connectedDevices.remove(deviceId);
    _negotiatedMtu.remove(deviceId);
    _writableCharCache.remove(deviceId);

    // Cancel connection state subscription (avoid re-entrant calls).
    _connectionStateSubs.remove(deviceId)?.cancel();

    final subs = _charSubscriptions.remove(deviceId);
    if (subs != null) {
      for (final sub in subs) {
        sub.cancel();
      }
    }

    if (_disposed) return;

    _setState(
      _connectedDevices.isEmpty
          ? TransportState.disconnected
          : TransportState.connected,
    );

    // Attempt reconnection.
    final attempts = (_reconnectAttempts[deviceId] ?? 0) + 1;
    _reconnectAttempts[deviceId] = attempts;

    if (attempts > _maxReconnectAttempts) {
      _reconnectAttempts.remove(deviceId);
      return;
    }

    final delayMs =
        _reconnectBaseDelayMs * pow(2, attempts - 1).toInt();
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !_connectedDevices.containsKey(deviceId)) {
        connect(deviceId).catchError((_) {
          // Reconnection failed; the next scheduled attempt (if any)
          // will try again.
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Service / characteristic subscription
  // ---------------------------------------------------------------------------

  /// Subscribe to notifications on all Field Link characteristics within
  /// the discovered services.
  Future<void> _subscribeToCharacteristics(
    String deviceId,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    final targetCharUuids = {
      BleConstants.positionCharUuid,
      BleConstants.markerCharUuid,
      BleConstants.controlCharUuid,
      BleConstants.annotationCharUuid,
    };

    final subscriptions = <StreamSubscription<List<int>>>[];

    for (final service in services) {
      if (service.uuid.str.toLowerCase() !=
          BleConstants.fieldLinkServiceUuid.toLowerCase()) {
        continue;
      }

      for (final char in service.characteristics) {
        if (!targetCharUuids.contains(char.uuid.str.toLowerCase())) {
          continue;
        }

        // Enable notifications if the characteristic supports them.
        if (char.properties.notify || char.properties.indicate) {
          try {
            await char.setNotifyValue(true);

            final sub = char.onValueReceived.listen((value) {
              _onCharacteristicValueReceived(
                deviceId,
                Uint8List.fromList(value),
              );
            });

            subscriptions.add(sub);
          } catch (_) {
            // Characteristic subscription failure is non-fatal.
          }
        }
      }
    }

    _charSubscriptions[deviceId] = subscriptions;
  }

  /// Handle raw bytes received from a characteristic notification.
  ///
  /// If the payload is chunked (first byte is the chunk header), reassemble
  /// before emitting. Otherwise emit the complete message immediately.
  void _onCharacteristicValueReceived(String deviceId, Uint8List value) {
    if (value.isEmpty) return;

    // Chunking protocol:
    //   byte 0: flags  (0x00 = complete, 0x01 = first chunk, 0x02 = mid,
    //                    0x03 = last chunk)
    //   byte 1: sequence number (uint8, wraps)
    //   byte 2..: payload fragment
    final flag = value[0];

    if (flag == 0x00) {
      // Complete (non-chunked) message.
      _emitMessage(deviceId, Uint8List.sublistView(value, 1));
      return;
    }

    // Chunked message handling.
    final buffer = _chunkBuffers.putIfAbsent(deviceId, _ChunkBuffer.new);

    if (flag == 0x01) {
      // First chunk — reset buffer and mark as started.
      buffer.reset();
      buffer.hasFirstChunk = true;
    } else if (!buffer.hasFirstChunk) {
      // Mid/last chunk without a first chunk — discard to avoid corruption.
      buffer.reset();
      return;
    }

    if (value.length > 2) {
      buffer.append(Uint8List.sublistView(value, 2));
    }

    if (flag == 0x03) {
      // Last chunk — assemble and emit.
      final assembled = buffer.assemble();
      buffer.reset();
      _emitMessage(deviceId, assembled);
    }
  }

  void _emitMessage(String deviceId, Uint8List data) {
    _messageController.add(TransportMessage(
      senderId: deviceId,
      data: data,
      receivedAt: DateTime.now(),
    ));
  }

  // ---------------------------------------------------------------------------
  // Data transfer
  // ---------------------------------------------------------------------------

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    _ensureNotDisposed();

    final device = _connectedDevices[deviceId];
    if (device == null) {
      throw TransportException('Device $deviceId is not connected');
    }

    // Enforce max payload limit.
    if (data.length > SyncConstants.maxBulkPayloadBytes) {
      throw TransportException(
        'Payload size ${data.length} exceeds maximum '
        '${SyncConstants.maxBulkPayloadBytes} bytes',
      );
    }

    final characteristic = await _getWritableCharacteristic(device);
    if (characteristic == null) {
      throw TransportException(
        'No writable characteristic found on $deviceId',
      );
    }

    final mtu = _negotiatedMtu[deviceId] ?? BleConstants.minMtu;
    // Max payload per write = MTU - ATT overhead - chunk header (2 bytes).
    final maxChunkPayload = mtu - _attOverhead - 2;

    if (data.length <= maxChunkPayload) {
      // Fits in a single write — prepend the "complete" flag.
      final packet = Uint8List(1 + data.length);
      packet[0] = 0x00; // complete
      packet.setRange(1, packet.length, data);
      await characteristic.write(packet, withoutResponse: true);
    } else {
      // Chunk the payload.
      await _sendChunked(characteristic, data, maxChunkPayload);
    }
  }

  @override
  Future<void> broadcast(Uint8List data) async {
    final errors = <String>[];

    for (final deviceId in _connectedDevices.keys.toList()) {
      try {
        await send(deviceId, data);
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

  /// Send [data] to [characteristic] using the chunking protocol.
  Future<void> _sendChunked(
    BluetoothCharacteristic characteristic,
    Uint8List data,
    int maxChunkPayload,
  ) async {
    int offset = 0;
    int seq = 0;

    while (offset < data.length) {
      final remaining = data.length - offset;
      final chunkSize = remaining > maxChunkPayload
          ? maxChunkPayload
          : remaining;

      final isFirst = offset == 0;
      final isLast = offset + chunkSize >= data.length;

      int flag;
      if (isFirst && isLast) {
        flag = 0x00; // complete
      } else if (isFirst) {
        flag = 0x01; // first
      } else if (isLast) {
        flag = 0x03; // last
      } else {
        flag = 0x02; // middle
      }

      final packet = Uint8List(2 + chunkSize);
      packet[0] = flag;
      packet[1] = seq & 0xFF;
      packet.setRange(2, 2 + chunkSize, data, offset);

      await characteristic.write(packet, withoutResponse: true);

      offset += chunkSize;
      seq++;

      // Small delay between chunks to avoid overwhelming the BLE stack.
      if (!isLast) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }
  }

  /// Cache the writable characteristic for a device after initial
  /// service discovery (avoids re-discovering on every send).
  void _cacheWritableCharacteristic(
    String deviceId,
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (service.uuid.str.toLowerCase() !=
          BleConstants.fieldLinkServiceUuid.toLowerCase()) {
        continue;
      }

      BluetoothCharacteristic? fallback;
      for (final char in service.characteristics) {
        if (!char.properties.write && !char.properties.writeWithoutResponse) {
          continue;
        }
        if (char.uuid.str.toLowerCase() ==
            BleConstants.controlCharUuid.toLowerCase()) {
          _writableCharCache[deviceId] = char;
          return;
        }
        fallback ??= char;
      }
      if (fallback != null) {
        _writableCharCache[deviceId] = fallback;
      }
    }
  }

  /// Find a writable characteristic on the Field Link service.
  ///
  /// Returns the cached characteristic if available; otherwise falls back
  /// to a fresh service discovery (should only happen if cache was cleared).
  Future<BluetoothCharacteristic?> _getWritableCharacteristic(
    BluetoothDevice device,
  ) async {
    final cached = _writableCharCache[device.remoteId.str];
    if (cached != null) return cached;

    // Fallback: re-discover (e.g., after reconnection cleared cache).
    final services = await device.discoverServices();
    _cacheWritableCharacteristic(device.remoteId.str, services);
    return _writableCharCache[device.remoteId.str];
  }

  // ---------------------------------------------------------------------------
  // RSSI monitoring
  // ---------------------------------------------------------------------------

  /// Read the current RSSI for a connected device.
  ///
  /// Returns null if the device is not connected or RSSI cannot be read.
  Future<int?> readRssi(String deviceId) async {
    final device = _connectedDevices[deviceId];
    if (device == null) return null;

    try {
      return await device.readRssi();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Peripheral advertising stub
  // ---------------------------------------------------------------------------

  // NOTE: GATT server / peripheral advertising requires native platform
  // channels. flutter_blue_plus does not support the peripheral role.
  // For MVP, discovery works when at least one device acts as a scanner
  // and the other already has the service advertised at the OS level
  // (e.g., via a companion native module).

  /// Start advertising the Field Link service.
  ///
  /// This is a no-op stub. Native advertising requires platform channels
  /// on Android (BLE Advertiser API) and iOS (CBPeripheralManager).
  Future<void> startAdvertising(String sessionId) async {
    _activeSessionId = sessionId;
    // Native GATT server advertising — future enhancement
  }

  /// Stop advertising.
  Future<void> stopAdvertising() async {
    _activeSessionId = null;
    // Native GATT server advertising — future enhancement
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setState(TransportState newState) {
    if (_state == newState) return;
    debugPrint('[BleTransport] state: $_state → $newState');
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const TransportException('BleTransport has been disposed');
    }
  }
}

// ---------------------------------------------------------------------------
// Chunk reassembly buffer
// ---------------------------------------------------------------------------

/// Internal buffer for reassembling chunked BLE payloads.
class _ChunkBuffer {
  final List<Uint8List> _chunks = [];

  /// Whether a first-chunk (flag 0x01) has been received for the current
  /// message. Mid/last chunks are discarded if this is false.
  bool hasFirstChunk = false;

  void append(Uint8List chunk) => _chunks.add(chunk);

  void reset() {
    _chunks.clear();
    hasFirstChunk = false;
  }

  Uint8List assemble() {
    if (_chunks.isEmpty) return Uint8List(0);

    final totalLength = _chunks.fold<int>(0, (sum, c) => sum + c.length);
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in _chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }
}

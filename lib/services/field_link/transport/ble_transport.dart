import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:red_grid_link/core/constants/ble_constants.dart';
import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/core/logging/red_log.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/services/field_link/transport/ble_phy_service.dart';
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
  /// Creates a BLE transport.
  ///
  /// An optional [BlePhyService] can be provided for testing; defaults to a
  /// new instance that uses the real platform channel + flutter_blue_plus.
  BleTransport({BlePhyService? phyService})
      : _phyService = phyService ?? BlePhyService();

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

  /// Connected peripherals keyed by remote ID string (central-mode connections
  /// established via flutter_blue_plus when WE are the central).
  final Map<String, BluetoothDevice> _connectedDevices = {};

  /// Centrals that connected to us while we were advertising in peripheral
  /// mode (via CBPeripheralManager). Keyed by the central's CoreBluetooth UUID.
  /// These are NOT in [_connectedDevices] because they connected to our
  /// GATT server, not the other way around.
  final Set<String> _peripheralCentrals = {};

  /// Per-central `maximumUpdateValueLength` — the max bytes we can
  /// notify in one `pm.updateValue:forCharacteristic:onSubscribedCentrals:`
  /// call before iOS silently truncates. Surfaced from the native side via
  /// the `onCentralSubscribed` event. When broadcasting, we use the MIN of
  /// these so a single chunked stream is compatible with every subscriber.
  /// (v1.5.4+311 fix for the iPad-as-host → iPhone-as-joiner regression.)
  final Map<String, int> _peripheralCentralMaxUpdateLength = {};

  /// Maps CoreBluetooth central UUIDs (from peripheral mode) to the peer's
  /// logical device ID (from their first SyncPayload.senderId). CoreBluetooth
  /// identifies centrals by their system UUID which is different from the
  /// app-level _localDeviceId. Without this mapping, _onSyncStateChanged
  /// can't match CRDT position keys to connected device IDs.
  final Map<String, String> _centralIdToDeviceId = {};

  /// Characteristic subscriptions per device.
  final Map<String, List<StreamSubscription<List<int>>>> _charSubscriptions =
      {};

  /// Connection state subscriptions per device (for reconnect handling).
  final Map<String, StreamSubscription<BluetoothConnectionState>>
      _connectionStateSubs = {};

  /// Cached writable characteristics per device (avoids re-discovering
  /// services on every send).
  final Map<String, BluetoothCharacteristic> _writableCharCache = {};

  /// Periodic RSSI polling timer for connection quality monitoring.
  Timer? _rssiPollTimer;

  /// Reconnection attempt counts (for exponential back-off).
  final Map<String, int> _reconnectAttempts = {};

  /// BLE PHY service for Coded PHY (Long Range) negotiation.
  final BlePhyService _phyService;

  /// Whether Coded PHY was requested for a specific peer.
  bool isPeerCodedPhy(String deviceId) =>
      _phyService.isCodedPhyRequested(deviceId);

  /// All device IDs with Coded PHY requested.
  Set<String> get codedPhyPeers => _phyService.codedPhyPeers;

  /// Maximum number of consecutive reconnection attempts before giving up.
  static const int _maxReconnectAttempts = 5;

  /// Base delay for exponential back-off (milliseconds).
  static const int _reconnectBaseDelayMs = 1000;

  @override
  List<String> get connectedDeviceIds {
    // Union of central-mode connections (flutter_blue_plus) and
    // peripheral-mode connections (centrals that connected to our GATT server).
    // Use the mapped logical device ID (from the peer's first sync payload)
    // instead of the BLE remote ID / CB central UUID — the CRDT state keys
    // positions by _localDeviceId, not by BLE hardware ID.
    final ids = <String>{};
    for (final bleId in _connectedDevices.keys) {
      final deviceId = _centralIdToDeviceId[bleId];
      ids.add(deviceId ?? bleId);
    }
    for (final centralUuid in _peripheralCentrals) {
      final deviceId = _centralIdToDeviceId[centralUuid];
      if (deviceId != null) {
        ids.add(deviceId);
      } else {
        // Haven't received a sync payload from this central yet —
        // include the CB UUID as a placeholder so the set isn't empty.
        ids.add(centralUuid);
      }
    }
    return ids.toList();
  }

  // ---------------------------------------------------------------------------
  // Incoming messages
  // ---------------------------------------------------------------------------

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  @override
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  /// Total messages received by the transport (before sync engine).
  int _diagMessagesReceived = 0;
  int get diagMessagesReceived => _diagMessagesReceived;

  /// Total messages emitted to the sync engine.
  int _diagMessagesEmitted = 0;
  int get diagMessagesEmitted => _diagMessagesEmitted;

  /// Number of connected centrals in peripheral mode.
  int get diagPeripheralCentralCount => _peripheralCentrals.length;

  /// Number of central-mode connections (flutter_blue_plus).
  int get diagCentralConnectionCount => _connectedDevices.length;

  /// Last transport-layer error.
  String? _diagLastError;
  String? get diagLastError => _diagLastError;

  /// Per-central `maximumUpdateValueLength` map for the in-app
  /// Diagnostics screen (v1.5.4+312). Read-only snapshot of the
  /// internal state so the UI can show whether iOS reported the
  /// negotiated MTU per subscribed central.
  Map<String, int> get diagPeripheralCentralMaxUpdateLength =>
      Map.unmodifiable(_peripheralCentralMaxUpdateLength);

  /// Timestamp of the last successful `broadcast()` invocation (any
  /// path). Used by the Diagnostics screen to show whether the local
  /// heartbeat is firing.
  DateTime? _diagLastBroadcastAt;
  DateTime? get diagLastBroadcastAt => _diagLastBroadcastAt;

  /// Timestamp of the last incoming `_onCharacteristicValueReceived`
  /// (peripheral-mode central write OR central-mode notify). Used by
  /// the Diagnostics screen to show whether peers are actually reaching
  /// us at the BLE layer.
  DateTime? _diagLastReceivedAt;
  DateTime? get diagLastReceivedAt => _diagLastReceivedAt;

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
    if (kDebugMode) print('[BleTransport] initialize: checking adapter state...');
    BluetoothAdapterState adapterState;
    try {
      adapterState = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      if (kDebugMode) print('[BleTransport] adapter state check timed out after 5s');
      _setState(TransportState.error);
      throw const TransportException(
        'Bluetooth adapter state could not be determined. '
        'Please ensure Bluetooth is enabled and try again.',
      );
    }

    if (kDebugMode) print('[BleTransport] adapter state: $adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      _setState(TransportState.error);
      throw const TransportException(
        'Bluetooth is not available or turned off',
      );
    }

    _setState(TransportState.idle);
    if (kDebugMode) print('[BleTransport] initialized successfully');
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    stopRssiPolling();
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
    if (kDebugMode) print('[BleTransport] startDiscovery: session=$sessionId');

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

      // Parse the host's Field Link session UUID out of the advertisement
      // payload. The host (createSession side) writes the session id as
      // 16 raw bytes into CBAdvertisementDataServiceDataKey on iOS or
      // AdvertiseData.addServiceData(...) on Android, both keyed by
      // BleConstants.fieldLinkServiceUuid.
      //
      // Without this, the join button on the scan list would call
      // FieldLinkService.joinSession(device.id) — but device.id is the
      // BLE peripheral's CoreBluetooth UUID, NOT the host's UUID v4
      // sessionId, so the joiner ends up running CRDT under a different
      // sessionId than the host. The host then silently ignores all
      // sync messages and the two phones "can't find each other"
      // even though BLE is connected. This was the root cause of the
      // post-v1.5.2 reviewer reports.
      String? sessionId;
      try {
        final serviceData = result.advertisementData.serviceData;
        final guid = Guid(BleConstants.fieldLinkServiceUuid);
        // ScanResult.serviceData is keyed by Guid; some platforms strip
        // the dashes when normalising. Try both forms.
        final raw = serviceData[guid] ??
            serviceData[Guid(
                BleConstants.fieldLinkServiceUuid.replaceAll('-', ''))];
        if (raw != null && raw.isNotEmpty) {
          sessionId = BleConstants.decodeSessionIdFromBytes(raw);
        }
      } catch (_) {
        // Malformed service data — leave sessionId null. The user can
        // still manually paste the session id via the QR / Manual flow.
        sessionId = null;
      }

      // Infer device type from advertising data if possible.
      // For now, mark all as unknown; higher layers resolve via handshake.
      final discovered = DiscoveredDevice(
        id: device.remoteId.str,
        name: name,
        sessionId: sessionId,
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

      // Request Coded PHY for extended range (Android only, iOS auto-negotiates).
      // This is best-effort — connection works fine on standard LE 1M PHY.
      try {
        await _phyService.requestCodedPhyOnDevice(device);
      } catch (_) {
        // PHY request is non-fatal.
      }

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
    _phyService.clearDevice(deviceId);

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

    if (kDebugMode) print('[BleTransport] _subscribeToCharacteristics: '
        'device=$deviceId, services=${services.length}');

    for (final service in services) {
      if (kDebugMode) print('[BleTransport]   service: ${service.uuid.str}');
      if (service.uuid.str.toLowerCase() !=
          BleConstants.fieldLinkServiceUuid.toLowerCase()) {
        continue;
      }

      if (kDebugMode) print('[BleTransport]   MATCHED Field Link service!');

      for (final char in service.characteristics) {
        if (kDebugMode) print('[BleTransport]     char: ${char.uuid.str} '
            'notify=${char.properties.notify} '
            'indicate=${char.properties.indicate} '
            'write=${char.properties.write} '
            'writeNoResp=${char.properties.writeWithoutResponse}');

        if (!targetCharUuids.contains(char.uuid.str.toLowerCase())) {
          if (kDebugMode) print('[BleTransport]     SKIP (not a target char)');
          continue;
        }

        // Enable notifications if the characteristic supports them.
        if (char.properties.notify || char.properties.indicate) {
          try {
            await char.setNotifyValue(true);
            if (kDebugMode) print('[BleTransport]     SUBSCRIBED to ${char.uuid.str}');

            final sub = char.onValueReceived.listen((value) {
              if (kDebugMode) print('[BleTransport]     DATA received on ${char.uuid.str}: '
                  '${value.length} bytes');
              _onCharacteristicValueReceived(
                deviceId,
                Uint8List.fromList(value),
              );
            });

            subscriptions.add(sub);
          } catch (e) {
            if (kDebugMode) print('[BleTransport]     SUBSCRIBE FAILED: $e');
          }
        } else {
          if (kDebugMode) print('[BleTransport]     SKIP subscribe (no notify/indicate)');
        }
      }
    }

    if (kDebugMode) print('[BleTransport] subscribed to ${subscriptions.length} characteristics');
    _charSubscriptions[deviceId] = subscriptions;
  }

  /// Handle raw bytes received from a characteristic notification.
  ///
  /// If the payload is chunked (first byte is the chunk header), reassemble
  /// before emitting. Otherwise emit the complete message immediately.
  void _onCharacteristicValueReceived(String deviceId, Uint8List value) {
    if (value.isEmpty) return;
    _diagMessagesReceived++;
    _diagLastReceivedAt = DateTime.now();

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
    _diagMessagesEmitted++;
    if (kDebugMode) print('[BleTransport] INCOMING message from $deviceId: ${data.length} bytes');

    // Learn the peer's logical device ID from the payload so we can map
    // BLE remote IDs to _localDeviceIds. Without this mapping,
    // connectedDeviceIds returns BLE remote IDs but CRDT state positions
    // are keyed by _localDeviceId — they never match, and peers show
    // as disconnected with 0/8 connected.
    _learnDeviceIdFromPayload(deviceId, data);

    _messageController.add(TransportMessage(
      senderId: _centralIdToDeviceId[deviceId] ?? deviceId,
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
      await characteristic.write(packet, withoutResponse: false);
    } else {
      // Chunk the payload.
      await _sendChunked(characteristic, data, maxChunkPayload);
    }
  }

  @override
  Future<void> broadcast(Uint8List data) async {
    final errors = <String>[];
    _diagLastBroadcastAt = DateTime.now();

    // Send to central-mode connections (flutter_blue_plus — we connected to them).
    for (final deviceId in _connectedDevices.keys.toList()) {
      try {
        await send(deviceId, data);
      } on Exception catch (e) {
        errors.add('$deviceId: $e');
      }
    }

    // Send to peripheral-mode connections (centrals that connected to our
    // GATT server). Push data via ble_peripheral's updateCharacteristic which
    // triggers a characteristic notification on the central side.
    //
    // CRITICAL (v1.5.4+311): chunk the payload to fit each subscribed
    // central's `maximumUpdateValueLength`. Prior to this fix the entire
    // payload was shipped in one `pm.updateValue` call. iOS silently
    // truncates anything past the central's MTU - 3, and the iPhone
    // receive side (`_onCharacteristicValueReceived`) saw garbled bytes
    // that failed JSON parse and dropped silently. Symptom: iPhone
    // joiner showed 0/8 connected because the iPad host's heartbeat
    // never decoded successfully on the iPhone — even though the
    // notification was delivered.
    //
    // Default ATT MTU is 23 (20-byte payload). A position SyncPayload
    // is 150-250 bytes, so under default MTU the receiver got 19 of
    // those bytes — never a complete JSON object. Chunking with the
    // existing 0x01/0x02/0x03 protocol fixes this end-to-end.
    if (_peripheralCentrals.isNotEmpty) {
      try {
        // Use the smallest known per-central max-update-length so a
        // single chunked stream is compatible with every subscriber.
        // Default to BleConstants.minMtu - ATT_HEADER (20) when we
        // haven't received maxUpdateLength yet (e.g. on Android side
        // where we don't surface it). 20 - 2 (chunk header) = 18 bytes
        // payload per chunk in the worst case — slow but correct.
        final maxUpdateLen = _peripheralCentralMaxUpdateLength.values.isEmpty
            ? (BleConstants.minMtu - _attOverhead)
            : _peripheralCentralMaxUpdateLength.values
                .reduce((a, b) => a < b ? a : b);
        final maxChunkPayload = maxUpdateLen - 2; // 2 = chunk header bytes

        if (data.length <= maxChunkPayload) {
          // Fits in a single notification — emit with the "complete"
          // flag (0x00) so the receiver short-circuits the chunk
          // reassembly path.
          final packet = Uint8List(1 + data.length);
          packet[0] = 0x00; // complete (non-chunked)
          packet.setRange(1, packet.length, data);
          await _peripheralUpdateValue(
            BleConstants.positionCharUuid,
            packet,
          );
        } else {
          // Send the payload in chunks via the same protocol the
          // central-mode `_sendChunked` uses (flag bytes 0x01/0x02/0x03
          // + sequence number) so the receiver's reassembly logic
          // works without modification.
          await _sendChunkedViaPeripheral(
            BleConstants.positionCharUuid,
            data,
            maxChunkPayload,
          );
        }
      } catch (e) {
        RedLog.w('BleTransport', 'peripheral broadcast failed', e);
        errors.add('peripheral-broadcast: $e');
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

      await characteristic.write(packet, withoutResponse: false);

      offset += chunkSize;
      seq++;

      // Small delay between chunks to avoid overwhelming the BLE stack.
      if (!isLast) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }
  }

  /// Push one notification to subscribed centrals via the peripheral
  /// platform channel. Wraps the `updateValue` invocation with retry on
  /// transmit-queue-full (iOS returns false when the queue is full and
  /// expects the app to wait for `peripheralManagerIsReady` before
  /// retrying).
  Future<void> _peripheralUpdateValue(String charUuid, Uint8List packet) async {
    // Best-effort retry loop. On iOS `pm.updateValue` returns false when
    // the transmit queue is full; we block briefly and retry up to 3
    // times before giving up. The native side surfaces the boolean
    // result via the platform-channel return value. (v1.5.4+311 fix —
    // before this loop, a single congested notification was silently
    // lost.)
    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await _advertiserChannel.invokeMethod<bool>(
          'updateValue',
          {
            'characteristicUuid': charUuid,
            'data': packet,
          },
        );
        if (result == true || result == null) {
          return;
        }
      } on PlatformException catch (e) {
        RedLog.w(
          'BleTransport',
          '_peripheralUpdateValue platform error attempt=$attempt: '
              '${e.message}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    RedLog.w(
      'BleTransport',
      '_peripheralUpdateValue: dropped after $maxRetries retries '
          '(transmit queue stayed full)',
    );
  }

  /// Send [data] to all subscribed centrals using the chunking protocol
  /// (mirror of [_sendChunked] for the peripheral path). Uses
  /// [maxChunkPayload] derived from the SMALLEST subscribed central's
  /// `maximumUpdateValueLength` so a single notification stream is
  /// compatible with every subscriber.
  Future<void> _sendChunkedViaPeripheral(
    String charUuid,
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

      await _peripheralUpdateValue(charUuid, packet);

      offset += chunkSize;
      seq++;

      // Same inter-chunk pacing as central-mode `_sendChunked` to keep
      // the transmit queue from saturating.
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

  /// Try to extract the senderId from a raw SyncPayload so we can map
  /// the CoreBluetooth central UUID to the peer's logical device ID.
  void _learnDeviceIdFromPayload(String centralUuid, Uint8List rawData) {
    if (_centralIdToDeviceId.containsKey(centralUuid)) return;

    try {
      // The raw data from peripheral writes doesn't have the chunk header —
      // it's the raw JSON bytes of the SyncPayload.
      final jsonStr = String.fromCharCodes(rawData);
      if (!jsonStr.startsWith('{')) return;
      // SyncPayload uses 's' (compact) or 'senderId' (verbose) for the sender
      final sidMatch = RegExp(r'"(?:s|senderId)"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      if (sidMatch != null) {
        final deviceId = sidMatch.group(1)!;
        _centralIdToDeviceId[centralUuid] = deviceId;
        if (kDebugMode) print('[BleTransport] Learned device ID mapping: '
            '$centralUuid → $deviceId');
      }
    } catch (_) {
      // Best-effort — if we can't parse, the CB UUID is used as fallback.
    }
  }

  /// Start periodic RSSI polling for all connected devices.
  ///
  /// Calls [onRssi] with (deviceId, rssi) every [interval] for each
  /// connected device. Used to feed [ConnectionQualityNotifier].
  void startRssiPolling({
    required void Function(String deviceId, int rssi) onRssi,
    Duration interval = const Duration(seconds: 5),
  }) {
    stopRssiPolling();
    _rssiPollTimer = Timer.periodic(interval, (_) async {
      for (final deviceId in _connectedDevices.keys.toList()) {
        final rssi = await readRssi(deviceId);
        if (rssi != null) {
          onRssi(deviceId, rssi);
        }
      }
    });
  }

  /// Stop periodic RSSI polling.
  void stopRssiPolling() {
    _rssiPollTimer?.cancel();
    _rssiPollTimer = null;
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
  /// Start advertising the Field Link GATT service via the custom
  /// BleAdvertiserChannel (CBPeripheralManager on iOS).
  ///
  /// The GATT service UUID matches [BleConstants.fieldLinkServiceUuid],
  /// the same UUID that central-mode scanners filter on in [startDiscovery].
  /// Platform channel for BLE peripheral-mode advertising (GATT server).
  static const MethodChannel _advertiserChannel =
      MethodChannel('com.redgrid.link/ble_advertiser');

  /// Event channel for incoming writes from centrals when in peripheral mode.
  static const EventChannel _advertiserEventChannel =
      EventChannel('com.redgrid.link/ble_advertiser/events');

  /// Subscription for the advertiser event stream (peripheral mode).
  StreamSubscription<dynamic>? _advertiserEventSub;

  Future<void> startAdvertising(String sessionId) async {
    _activeSessionId = sessionId;

    try {
      await _advertiserChannel.invokeMethod<void>('startAdvertising', {
        'sessionId': sessionId,
      });
      if (kDebugMode) print('[BleTransport] startAdvertising: session=$sessionId');
    } on PlatformException catch (e) {
      if (kDebugMode) print('[BleTransport] startAdvertising failed: ${e.message}');
    }

    // Listen for incoming data from centrals that write to our GATT chars,
    // and track central connection/disconnection for peripheral mode.
    await _advertiserEventSub?.cancel();
    _advertiserEventSub = _advertiserEventChannel
        .receiveBroadcastStream()
        .listen((dynamic event) {
      if (event is! Map) return;
      final eventName = event['event'] as String?;
      final data = event['data'] as Map?;
      if (eventName == null || data == null) return;

      switch (eventName) {
        case 'onDataReceived':
          final centralId = data['centralId'] as String? ?? '';
          final rawData = data['data'];
          if (rawData is Uint8List && rawData.isNotEmpty) {
            // The joiner's send() prepends a chunk header (byte 0 = 0x00
            // for complete, or 0x01/0x02/0x03 for chunked). We need to
            // process it through _onCharacteristicValueReceived just like
            // central-mode data, NOT pass raw bytes directly — raw bytes
            // include the header which makes JSON parsing fail silently.
            _onCharacteristicValueReceived(centralId, rawData);
          }
          break;

        case 'onCentralSubscribed':
          final centralId = data['centralId'] as String? ?? '';
          // CBCentral.maximumUpdateValueLength surfaced from native.
          // Defaults to BleConstants.minMtu - 3 (= 20) when the platform
          // didn't include it in the event (older builds, or Android
          // where the API is different). We use this to chunk our
          // notify payloads so iOS doesn't silently truncate.
          final maxUpdateLen = (data['maxUpdateLength'] as num?)?.toInt() ??
              (BleConstants.minMtu - _attOverhead);
          RedLog.d(
            'BleTransport',
            'Central connected (peripheral): $centralId '
                'maxUpdateLen=$maxUpdateLen',
          );
          _peripheralCentrals.add(centralId);
          _peripheralCentralMaxUpdateLength[centralId] = maxUpdateLen;
          _setState(TransportState.connected);
          break;

        case 'onCentralUnsubscribed':
          final centralId = data['centralId'] as String? ?? '';
          if (kDebugMode) print('[BleTransport] Central disconnected (peripheral): $centralId');
          _peripheralCentrals.remove(centralId);
          _peripheralCentralMaxUpdateLength.remove(centralId);
          if (_connectedDevices.isEmpty && _peripheralCentrals.isEmpty) {
            _setState(TransportState.disconnected);
          }
          break;
      }
    });
  }

  /// Stop advertising and tear down the GATT server.
  Future<void> stopAdvertising() async {
    _activeSessionId = null;
    _peripheralCentrals.clear();
    _centralIdToDeviceId.clear();
    await _advertiserEventSub?.cancel();
    _advertiserEventSub = null;

    try {
      await _advertiserChannel.invokeMethod<void>('stopAdvertising');
      if (kDebugMode) print('[BleTransport] stopAdvertising');
    } catch (e) {
      if (kDebugMode) print('[BleTransport] stopAdvertising failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setState(TransportState newState) {
    if (_state == newState) return;
    if (kDebugMode) print('[BleTransport] state: $_state → $newState');
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

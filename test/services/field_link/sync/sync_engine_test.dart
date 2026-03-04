import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';
import 'package:red_grid_link/services/field_link/sync/delta_encoder.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';

// ---------------------------------------------------------------------------
// Mock transport for testing SyncEngine behavior
// ---------------------------------------------------------------------------

/// A minimal in-memory transport for testing the sync engine.
class MockTransport implements TransportService {
  @override
  TransportType get type => TransportType.ble;

  TransportState _state = TransportState.idle;

  @override
  TransportState get currentState => _state;

  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  final StreamController<DiscoveredDevice> _discoveryController =
      StreamController<DiscoveredDevice>.broadcast();

  @override
  Stream<DiscoveredDevice> get discoveredDevices => _discoveryController.stream;

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();

  @override
  Stream<TransportMessage> get incomingMessages => _messageController.stream;

  final List<Uint8List> sentBroadcasts = [];

  @override
  List<String> get connectedDeviceIds => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _discoveryController.close();
    await _messageController.close();
  }

  @override
  Future<void> startDiscovery(String sessionId) async {
    _state = TransportState.discovering;
  }

  @override
  Future<void> stopDiscovery() async {
    _state = TransportState.idle;
  }

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect(String deviceId) async {}

  @override
  Future<void> disconnectAll() async {}

  @override
  Future<void> send(String deviceId, Uint8List data) async {}

  @override
  Future<void> broadcast(Uint8List data) async {
    sentBroadcasts.add(data);
  }

  /// Inject an incoming message (simulating a remote peer).
  void injectMessage(TransportMessage message) {
    _messageController.add(message);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  Position makePosition({
    double lat = 35.0,
    double lon = -79.0,
    DateTime? timestamp,
  }) =>
      Position(
        lat: lat,
        lon: lon,
        mgrsRaw: '17SQV1234567890',
        mgrsFormatted: '',
        timestamp: timestamp ?? DateTime.now(),
      );

  // Since the SyncEngine takes concrete repository types (not interfaces)
  // bound to Drift, we test the engine's core building blocks independently:
  // CrdtState, DeltaEncoder, and the mock transport integration.

  group('CrdtState + DeltaEncoder integration', () {
    test('CrdtState applies position deltas correctly', () {
      const state = CrdtState();
      final pos = makePosition(lat: 35.5);
      final updated = state.updatePosition('local', pos);

      expect(updated.positions.containsKey('local'), isTrue);
      expect(updated.positions['local']!.value.lat, 35.5);
    });

    test('DeltaEncoder position roundtrip through bytes', () {
      const encoder = DeltaEncoder();
      final pos = makePosition(lat: 35.5, lon: -79.5);
      final payload = encoder.encodePosition('node-a', pos, 1);
      final bytes = payload.toBytes();
      final restored = SyncPayload.fromBytes(bytes);

      expect(restored.senderId, 'node-a');
      expect(restored.type, SyncPayloadType.position);
      expect((restored.data['lat'] as num).toDouble(), closeTo(35.5, 0.001));
    });

    test('CrdtState merge from two peers converges', () {
      const state = CrdtState();
      final posA = makePosition(lat: 35.0);
      final posB = makePosition(lat: 36.0);

      final stateA = state.updatePosition('peer-a', posA);
      final stateB = state.updatePosition('peer-b', posB);

      final merged = stateA.merge(stateB);
      expect(merged.currentPositions.length, 2);
      expect(merged.currentPositions['peer-a']!.lat, 35.0);
      expect(merged.currentPositions['peer-b']!.lat, 36.0);
    });

    test('CrdtState marker tombstone wins over add with older timestamp', () async {
      const state = CrdtState();
      final marker = Marker(
        id: 'mk-1',
        lat: 35.0,
        lon: -79.0,
        createdBy: 'a',
        createdAt: DateTime(2024, 1, 1),
      );

      final s1 = state.upsertMarker('a', marker);
      expect(s1.liveMarkers.length, 1);

      // Both upsertMarker and deleteMarker use DateTime.now() as the
      // LWW register timestamp. A small delay ensures the delete has a
      // strictly newer timestamp so it wins the LWW merge.
      await Future<void>.delayed(const Duration(milliseconds: 2));

      final s2 = s1.deleteMarker('a', 'mk-1');
      expect(s2.liveMarkers, isEmpty);
    });

    test('CrdtState applyDelta processes incoming position payload', () {
      const state = CrdtState();
      final payload = SyncPayload(
        type: SyncPayloadType.position,
        senderId: 'remote-peer',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: {
          'lat': 36.5,
          'lon': -80.0,
          'mgrs': '17SQV9999999999',
          'ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final updated = state.applyDelta(payload);
      expect(updated.positions.containsKey('remote-peer'), isTrue);
      expect(updated.positions['remote-peer']!.value.lat, 36.5);
      expect(updated.sequenceCounter.countFor('remote-peer'), 1);
    });
  });

  group('MockTransport broadcasts', () {
    late MockTransport transport;

    setUp(() {
      transport = MockTransport();
    });

    tearDown(() {
      transport.dispose();
    });

    test('broadcast records sent data', () async {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      await transport.broadcast(data);
      expect(transport.sentBroadcasts.length, 1);
      expect(transport.sentBroadcasts.first, data);
    });

    test('injected messages appear on incoming stream', () async {
      final message = TransportMessage(
        senderId: 'peer-x',
        data: Uint8List.fromList([10, 20, 30]),
        receivedAt: DateTime.now(),
      );

      expectLater(
        transport.incomingMessages,
        emits(isA<TransportMessage>()
            .having((m) => m.senderId, 'senderId', 'peer-x')),
      );

      transport.injectMessage(message);
    });
  });

  group('SyncPayload wire format', () {
    test('position payload toBytes/fromBytes roundtrip', () {
      final payload = SyncPayload(
        type: SyncPayloadType.position,
        senderId: 'abc',
        sequenceNum: 42,
        timestamp: DateTime(2024, 3, 2, 12, 0),
        data: {'lat': 35.139, 'lon': -79.001, 'spd': 1.2, 'hdg': 45.0},
      );

      final bytes = payload.toBytes();
      expect(bytes.length, lessThanOrEqualTo(200));

      final restored = SyncPayload.fromBytes(bytes);
      expect(restored.type, SyncPayloadType.position);
      expect(restored.senderId, 'abc');
      expect(restored.sequenceNum, 42);
      expect(restored.data['lat'], 35.139);
    });

    test('control payload roundtrip', () {
      final payload = SyncPayload(
        type: SyncPayloadType.control,
        senderId: 'xyz',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: {'action': 'join', 'sessionId': 'sess-1'},
      );

      final bytes = payload.toBytes();
      final restored = SyncPayload.fromBytes(bytes);
      expect(restored.type, SyncPayloadType.control);
      expect(restored.data['action'], 'join');
    });
  });
}

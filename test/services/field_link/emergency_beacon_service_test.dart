import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/emergency_beacon_service.dart';

void main() {
  late EmergencyBeaconService beacon;

  setUp(() {
    beacon = EmergencyBeaconService();
  });

  tearDown(() {
    beacon.dispose();
  });

  group('activate', () {
    test('sets isActive and stores coordinates', () {
      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: (_) {},
      );

      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'device-1');
      expect(beacon.activeLat, 38.8895);
      expect(beacon.activeLon, -77.0353);
      expect(beacon.activeTimestamp, isNotNull);
    });

    test('calls onBroadcast immediately', () {
      final broadcasts = <Map<String, dynamic>>[];

      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: broadcasts.add,
      );

      expect(broadcasts, hasLength(1));
      expect(broadcasts.first['evt'], 'emergency');
      expect(broadcasts.first['lat'], 38.8895);
      expect(broadcasts.first['lon'], -77.0353);
      expect(broadcasts.first['ts'], isA<int>());
    });
  });

  group('deactivate', () {
    test('cancels timer and clears state', () {
      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: (_) {},
      );

      expect(beacon.isActive, isTrue);

      beacon.deactivate(onBroadcast: (_) {});

      expect(beacon.isActive, isFalse);
      expect(beacon.activeSenderId, isNull);
      expect(beacon.activeLat, isNull);
      expect(beacon.activeLon, isNull);
      expect(beacon.activeTimestamp, isNull);
    });

    test('broadcasts emergency_cancel', () {
      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: (_) {},
      );

      final cancelBroadcasts = <Map<String, dynamic>>[];
      beacon.deactivate(onBroadcast: cancelBroadcasts.add);

      expect(cancelBroadcasts, hasLength(1));
      expect(cancelBroadcasts.first['evt'], 'emergency_cancel');
    });
  });

  group('handleRemoteEmergency', () {
    test('sets state from payload', () {
      final ts = DateTime.now().millisecondsSinceEpoch;

      beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': ts,
      });

      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'peer-42');
      expect(beacon.activeLat, 34.0522);
      expect(beacon.activeLon, -118.2437);
      expect(
        beacon.activeTimestamp,
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
    });
  });

  group('handleRemoteCancel', () {
    test('clears state for matching sender', () {
      beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      expect(beacon.isActive, isTrue);

      beacon.handleRemoteCancel('peer-42');

      expect(beacon.isActive, isFalse);
      expect(beacon.activeSenderId, isNull);
      expect(beacon.activeLat, isNull);
      expect(beacon.activeLon, isNull);
      expect(beacon.activeTimestamp, isNull);
    });

    test('ignores non-matching sender', () {
      beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      beacon.handleRemoteCancel('peer-99');

      // State should remain active — different sender.
      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'peer-42');
    });
  });

  group('dispose', () {
    test('clears all state', () {
      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: (_) {},
      );

      expect(beacon.isActive, isTrue);

      beacon.dispose();

      expect(beacon.isActive, isFalse);
      expect(beacon.activeSenderId, isNull);
      expect(beacon.activeLat, isNull);
      expect(beacon.activeLon, isNull);
      expect(beacon.activeTimestamp, isNull);
    });
  });
}

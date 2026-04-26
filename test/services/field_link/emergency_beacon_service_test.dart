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

    test('broadcasts emergency_cancel with sender + ts', () {
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
      expect(cancelBroadcasts.first['sender'], 'device-1');
      expect(cancelBroadcasts.first['ts'], isA<int>());
    });

    test('returns true when active, false when not', () {
      // Inactive — nothing to cancel.
      expect(beacon.deactivate(onBroadcast: (_) {}), isFalse);

      beacon.activate(
        localDeviceId: 'device-1',
        lat: 38.8895,
        lon: -77.0353,
        onBroadcast: (_) {},
      );

      expect(beacon.deactivate(onBroadcast: (_) {}), isTrue);
    });
  });

  group('handleRemoteEmergency', () {
    test('sets state from payload and returns true for new emergency', () {
      final ts = DateTime.now().millisecondsSinceEpoch;

      final isNew = beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': ts,
      });

      expect(isNew, isTrue);
      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'peer-42');
      expect(beacon.activeLat, 34.0522);
      expect(beacon.activeLon, -118.2437);
      expect(
        beacon.activeTimestamp,
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
    });

    test('returns false for retransmit with same ts (dedup)', () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final payload = {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': ts,
      };

      // First delivery — new.
      expect(beacon.handleRemoteEmergency('peer-42', payload), isTrue);

      // Same payload, again (the originator's 30s retransmit) — dedup.
      expect(beacon.handleRemoteEmergency('peer-42', payload), isFalse);
      expect(beacon.handleRemoteEmergency('peer-42', payload), isFalse);

      // State stays consistent.
      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'peer-42');
    });

    test('returns false for stale retransmit arriving after cancel', () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final payload = {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': ts,
      };

      // Initial emergency.
      expect(beacon.handleRemoteEmergency('peer-42', payload), isTrue);

      // Sender cancels.
      expect(beacon.handleRemoteCancel('peer-42'), isTrue);
      expect(beacon.isActive, isFalse);

      // Stale in-flight retransmit arrives AFTER the cancel.
      // This is the smoking-gun bug — without dedup, this would flip the
      // alert overlay back on. Must be ignored.
      expect(beacon.handleRemoteEmergency('peer-42', payload), isFalse);
      expect(beacon.isActive, isFalse);
      expect(beacon.activeSenderId, isNull);
    });

    test('returns true for genuinely new emergency after a cancel', () {
      final ts1 = DateTime.now().millisecondsSinceEpoch;

      expect(
        beacon.handleRemoteEmergency('peer-42', {
          'lat': 34.0522,
          'lon': -118.2437,
          'ts': ts1,
        }),
        isTrue,
      );

      beacon.handleRemoteCancel('peer-42');
      expect(beacon.isActive, isFalse);

      // New emergency from same peer with newer ts (waited >1ms).
      final ts2 = ts1 + 60000; // 60 s later
      expect(
        beacon.handleRemoteEmergency('peer-42', {
          'lat': 34.0530,
          'lon': -118.2440,
          'ts': ts2,
        }),
        isTrue,
      );
      expect(beacon.isActive, isTrue);
      expect(beacon.activeLat, 34.0530);
    });
  });

  group('handleRemoteCancel', () {
    test('clears state and returns true for matching sender', () {
      beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      expect(beacon.isActive, isTrue);

      expect(beacon.handleRemoteCancel('peer-42'), isTrue);

      expect(beacon.isActive, isFalse);
      expect(beacon.activeSenderId, isNull);
      expect(beacon.activeLat, isNull);
      expect(beacon.activeLon, isNull);
      expect(beacon.activeTimestamp, isNull);
    });

    test('returns false for non-matching sender (state unchanged)', () {
      beacon.handleRemoteEmergency('peer-42', {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      expect(beacon.handleRemoteCancel('peer-99'), isFalse);

      // State should remain active — different sender.
      expect(beacon.isActive, isTrue);
      expect(beacon.activeSenderId, 'peer-42');
    });

    test('cancel suppresses subsequent stale retransmits from same sender',
        () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final payload = {
        'lat': 34.0522,
        'lon': -118.2437,
        'ts': ts,
      };

      beacon.handleRemoteEmergency('peer-42', payload);

      // Cancel uses cancel ts (or local now) as the high-water-mark.
      beacon.handleRemoteCancel('peer-42', {
        'sender': 'peer-42',
        'ts': ts + 5000,
      });

      // Multiple stale retransmits arrive after the cancel — all ignored.
      expect(beacon.handleRemoteEmergency('peer-42', payload), isFalse);
      expect(beacon.handleRemoteEmergency('peer-42', payload), isFalse);
      expect(beacon.isActive, isFalse);
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

    test('clears dedup state so post-dispose emergencies are treated as new',
        () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      beacon.handleRemoteEmergency('peer-42', {
        'lat': 1.0,
        'lon': 1.0,
        'ts': ts,
      });

      beacon.dispose();

      // Same ts after dispose should still be treated as new (dedup map
      // was cleared).
      expect(
        beacon.handleRemoteEmergency('peer-42', {
          'lat': 1.0,
          'lon': 1.0,
          'ts': ts,
        }),
        isTrue,
      );
    });
  });
}

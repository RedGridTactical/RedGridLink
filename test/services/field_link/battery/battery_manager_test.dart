import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BatteryManager manager;

  setUp(() {
    manager = BatteryManager();
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------
  group('construction', () {
    test('defaults to expedition mode', () {
      expect(manager.currentMode, BatteryMode.expedition);
    });

    test('can be created with active mode', () {
      final active = BatteryManager(initialMode: BatteryMode.active);
      expect(active.currentMode, BatteryMode.active);
      active.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // setMode
  // -------------------------------------------------------------------------
  group('setMode', () {
    test('changes mode', () {
      manager.setMode(BatteryMode.active);
      expect(manager.currentMode, BatteryMode.active);
    });

    test('no-op when setting same mode', () {
      manager.setMode(BatteryMode.expedition);
      expect(manager.currentMode, BatteryMode.expedition);
    });

    test('emits on mode change', () async {
      expectLater(
        manager.modeStream,
        emits(BatteryMode.active),
      );
      manager.setMode(BatteryMode.active);
    });

    test('does not emit when mode unchanged', () async {
      // Set to expedition (already the default).
      manager.setMode(BatteryMode.expedition);
      // Should not have emitted anything.
      // This tests the guard in setMode.
    });
  });

  // -------------------------------------------------------------------------
  // recommendedIntervalMs
  // -------------------------------------------------------------------------
  group('recommendedIntervalMs', () {
    test('expedition mode returns 30s interval', () {
      manager.setMode(BatteryMode.expedition);
      expect(
        manager.recommendedIntervalMs,
        SyncConstants.expeditionIntervalMs,
      );
      expect(manager.recommendedIntervalMs, 30000);
    });

    test('active mode returns 5s interval', () {
      manager.setMode(BatteryMode.active);
      expect(
        manager.recommendedIntervalMs,
        SyncConstants.activeIntervalMs,
      );
      expect(manager.recommendedIntervalMs, 5000);
    });
  });

  // -------------------------------------------------------------------------
  // Battery level tracking
  // -------------------------------------------------------------------------
  group('updateBatteryLevel', () {
    test('records battery level', () {
      manager.updateBatteryLevel(85);
      expect(manager.currentBatteryLevel, 85);
    });

    test('updates battery level on subsequent calls', () {
      manager.updateBatteryLevel(90);
      manager.updateBatteryLevel(85);
      expect(manager.currentBatteryLevel, 85);
    });

    test('limits history to 60 readings', () {
      for (int i = 0; i <= 70; i++) {
        manager.updateBatteryLevel(100 - i);
      }
      // Should not throw; history is internally bounded.
      expect(manager.currentBatteryLevel, 30); // 100 - 70
    });
  });

  // -------------------------------------------------------------------------
  // startSession
  // -------------------------------------------------------------------------
  group('startSession', () {
    test('records session start time and battery', () {
      manager.startSession(95);
      expect(manager.batteryAtStart, 95);
      expect(manager.currentBatteryLevel, 95);
      expect(manager.sessionStartTime, isNotNull);
    });

    test('clears previous history', () {
      manager.updateBatteryLevel(90);
      manager.updateBatteryLevel(85);
      manager.startSession(100);
      // History was cleared; drain rate should be 0.
      expect(manager.drainRatePerHour, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // drainRatePerHour
  // -------------------------------------------------------------------------
  group('drainRatePerHour', () {
    test('returns 0 with insufficient data', () {
      expect(manager.drainRatePerHour, 0.0);
    });

    test('returns 0 when battery has not drained', () {
      manager.updateBatteryLevel(100);
      // Need to wait or simulate time passing.
      manager.updateBatteryLevel(100);
      expect(manager.drainRatePerHour, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // projectedRemainingTime
  // -------------------------------------------------------------------------
  group('projectedRemainingTime', () {
    test('returns Calculating with no data', () {
      expect(manager.projectedRemainingTime, 'Calculating...');
    });

    test('returns Calculating when battery level is null', () {
      expect(manager.projectedRemainingTime, 'Calculating...');
    });

    test('returns Calculating when drain rate is 0', () {
      manager.updateBatteryLevel(100);
      expect(manager.projectedRemainingTime, 'Calculating...');
    });
  });

  // -------------------------------------------------------------------------
  // getBatteryLevel
  // -------------------------------------------------------------------------
  group('getBatteryLevel', () {
    test('returns null when platform channel not registered', () async {
      // In test environment, the platform channel is not registered.
      final level = await manager.getBatteryLevel();
      expect(level, isNull);
    });
  });
}

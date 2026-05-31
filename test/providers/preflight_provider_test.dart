import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/providers/preflight_provider.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';

void main() {
  PreflightReport report({String? deviceId, String? callsign}) =>
      PreflightReport(
        deviceId: deviceId,
        callsign: callsign,
        checks: const [
          PreflightCheck(
            id: PreflightCheckId.gpsFix,
            label: 'GPS fix',
            status: PreflightStatus.ready,
            detail: '',
          ),
        ],
      );

  group('teamPreflightReportsProvider / TeamPreflightNotifier', () {
    test('ignores reports with a null or empty deviceId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(teamPreflightReportsProvider.notifier);

      notifier.upsert(report(deviceId: null));
      notifier.upsert(report(deviceId: ''));

      expect(container.read(teamPreflightReportsProvider), isEmpty);
    });

    test('stores by deviceId and replaces on repeat', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(teamPreflightReportsProvider.notifier);

      notifier.upsert(report(deviceId: 'p1', callsign: 'ALPHA'));
      expect(container.read(teamPreflightReportsProvider).keys, ['p1']);

      final updated = report(deviceId: 'p1', callsign: 'BRAVO');
      notifier.upsert(updated);
      final state = container.read(teamPreflightReportsProvider);
      expect(state.length, 1);
      expect(state['p1'], same(updated));
    });

    test('clear empties the board', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(teamPreflightReportsProvider.notifier);

      notifier.upsert(report(deviceId: 'p1'));
      notifier.clear();

      expect(container.read(teamPreflightReportsProvider), isEmpty);
    });
  });

  group('PreflightSnapshotStore', () {
    test('first capture per session wins (step-off, not overwritten)', () {
      final store = PreflightSnapshotStore();
      final first = report(deviceId: 'a');
      final second = report(deviceId: 'b');
      store.capture('s1', first);
      store.capture('s1', second);
      expect(store.forSession('s1'), same(first));
    });

    test('forSession returns null for an unknown session', () {
      expect(PreflightSnapshotStore().forSession('nope'), isNull);
    });

    test('clear removes a session snapshot', () {
      final store = PreflightSnapshotStore();
      store.capture('s1', report(deviceId: 'x'));
      store.clear('s1');
      expect(store.forSession('s1'), isNull);
    });
  });
}

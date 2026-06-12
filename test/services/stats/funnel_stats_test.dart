import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/stats/funnel_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FunnelStats', () {
    test('snapshot is empty before any increments', () async {
      expect(await FunnelStats.instance.snapshot(), isEmpty);
    });

    test('increment creates and bumps counters', () async {
      await FunnelStats.instance.increment('paywall_views');
      await FunnelStats.instance.increment('paywall_views');
      await FunnelStats.instance.increment('gate.all_themes');

      final snap = await FunnelStats.instance.snapshot();
      expect(snap['paywall_views'], 2);
      expect(snap['gate.all_themes'], 1);
    });

    test('snapshot only includes funnel-prefixed keys', () async {
      SharedPreferences.setMockInitialValues({'unrelated_key': 42});
      await FunnelStats.instance.increment('purchase_success.pro_annual');

      final snap = await FunnelStats.instance.snapshot();
      expect(snap.keys, ['purchase_success.pro_annual']);
    });

    test('keyFor normalizes feature names', () {
      expect(FunnelStats.keyFor('After-Action Reports'),
          'after_action_reports');
      expect(FunnelStats.keyFor('All Themes'), 'all_themes');
      expect(FunnelStats.keyFor('8-Device Field Link'),
          '8_device_field_link');
      expect(FunnelStats.keyFor('Unlimited Offline Maps'),
          'unlimited_offline_maps');
    });
  });
}

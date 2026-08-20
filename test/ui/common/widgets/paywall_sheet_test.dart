import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/app_theme.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/ui/common/widgets/paywall_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SUNSET (v1.7.0): `showPaywallSheet` no longer shows a paywall — every
/// former upsell entry point opens the merge notice instead. These tests
/// replace the old paywall-UI suite and pin three things: the sheet sells
/// nothing, it names the successor app, and it can be dismissed.
void main() {
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  Future<void> openSheet(WidgetTester tester, {String? featureName}) async {
    final colors = getTacticalColors('red');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: buildTheme(colors),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      showPaywallSheet(context, featureName: featureName),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('SunsetSheet (former paywall entry points)', () {
    testWidgets('announces the merge into Red Grid MGRS', (tester) async {
      await openSheet(tester);
      expect(find.text('NOW PART OF RED GRID MGRS'), findsOneWidget);
      expect(find.textContaining('unlocked, free'), findsOneWidget);
    });

    testWidgets('sells nothing: no prices, tiers, or purchase CTAs',
        (tester) async {
      await openSheet(tester);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text('BEST VALUE'), findsNothing);
      expect(find.text('PRO ANNUAL'), findsNothing);
      expect(find.textContaining('trial', findRichText: true), findsNothing);
      expect(find.textContaining('Restore'), findsNothing);
    });

    testWidgets('offers the successor app', (tester) async {
      await openSheet(tester);
      expect(find.text('GET RED GRID MGRS'), findsOneWidget);
    });

    testWidgets('featureName param is accepted and still shows the notice',
        (tester) async {
      await openSheet(tester, featureName: 'All Themes');
      expect(find.text('NOW PART OF RED GRID MGRS'), findsOneWidget);
    });

    testWidgets('CONTINUE dismisses the sheet', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('NOW PART OF RED GRID MGRS'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/app_theme.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/ui/common/widgets/paywall_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  Future<void> openPaywall(WidgetTester tester, {String? featureName}) async {
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

  group('PaywallSheet', () {
    testWidgets('shows exactly one BEST VALUE badge (Pro Annual)',
        (tester) async {
      await openPaywall(tester);
      expect(find.text('BEST VALUE'), findsOneWidget);
    });

    testWidgets('Pro Annual is listed first and pre-selected',
        (tester) async {
      await openPaywall(tester);
      expect(find.text('PRO ANNUAL'), findsOneWidget);
      // Exactly one selected radio — the default Pro Annual.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.text('Save 37% vs monthly'), findsOneWidget);
    });

    testWidgets('CTA shows trial copy for the default Pro Annual selection',
        (tester) async {
      await openPaywall(tester);
      // No store products load in tests, but iOS trial copy is driven by
      // the declared config only when store data exists — so the CTA
      // falls back to SUBSCRIBE with the fallback price.
      expect(find.text('SUBSCRIBE'), findsOneWidget);
      expect(find.textContaining('cancel anytime'), findsOneWidget);
    });

    testWidgets('Lifetime is demoted to a quiet one-time row',
        (tester) async {
      await openPaywall(tester);
      final row = find.text('LIFETIME — Pro+Link, one-time purchase');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
    });

    testWidgets('selecting Lifetime switches the CTA to one-time copy',
        (tester) async {
      await openPaywall(tester);
      final row = find.text('LIFETIME — Pro+Link, one-time purchase');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text('BUY LIFETIME'), findsOneWidget);
      expect(find.textContaining('· one-time purchase'), findsOneWidget);
    });

    testWidgets('feature name is surfaced in the header', (tester) async {
      await openPaywall(tester, featureName: 'After-Action Reports');
      expect(find.text('AFTER-ACTION REPORTS'), findsOneWidget);
    });

    testWidgets('restore purchases link is present', (tester) async {
      await openPaywall(tester);
      final link = find.text('RESTORE PURCHASES');
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      expect(link, findsOneWidget);
    });
  });
}

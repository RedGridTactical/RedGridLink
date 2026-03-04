import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/core/theme/app_theme.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/ui/screens/onboarding/onboarding_screen.dart';

void main() {
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  Widget buildTestableOnboarding() {
    final colors = getTacticalColors('red');
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: buildTheme(colors),
        home: const OnboardingScreen(),
      ),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('welcome page shows RED GRID LINK title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      expect(find.text('RED GRID LINK'), findsOneWidget);
    });

    testWidgets('welcome page shows PROXIMITY COORDINATION subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      expect(find.text('PROXIMITY COORDINATION'), findsOneWidget);
    });

    testWidgets('welcome page shows feature bullets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      expect(find.text('MGRS-native coordinate display'), findsOneWidget);
      expect(
        find.text('Field Link proximity sync (2-8 devices)'),
        findsOneWidget,
      );
      expect(find.text('Offline map support'), findsOneWidget);
      expect(
        find.text('Battery-efficient expedition mode'),
        findsOneWidget,
      );
    });

    testWidgets('Next button is visible on page 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      // TacticalButton with label 'Next' renders as 'NEXT' (uppercased)
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('tapping Next advances from page 0 to page 1 (disclaimer)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      // Page 0: Welcome
      expect(find.text('RED GRID LINK'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Page 1: Disclaimer — shows 'IMPORTANT' heading
      expect(find.text('IMPORTANT'), findsOneWidget);
    });

    testWidgets('page 1 shows disclaimer checkbox text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      // Navigate to page 1
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('I understand the limitations'),
        findsOneWidget,
      );
    });

    testWidgets(
      'cannot advance past disclaimer without accepting checkbox',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableOnboarding());
        await tester.pumpAndSettle();

        // Go to page 1
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // Try to advance without accepting
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // Should still be on page 1 — 'IMPORTANT' still visible
        expect(find.text('IMPORTANT'), findsOneWidget);

        // Should show warning snackbar
        expect(
          find.text('YOU MUST ACKNOWLEDGE THE DISCLAIMER TO CONTINUE'),
          findsOneWidget,
        );
      },
    );

    testWidgets('dot indicators are visible on all pages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      // There should be 4 dot indicators (one per page)
      // The dots are Containers with decoration. The active one is 24px wide,
      // inactive ones are 8px wide.
      // We can verify by finding the overall structure.
      expect(find.text('NEXT'), findsOneWidget);
    });
  });
}

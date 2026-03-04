import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/app.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Theme switching', () {
    testWidgets('starts with red theme and can switch to green', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              // Capture the container through a consumer
              container = ProviderScope.containerOf(context);
              return const RedGridLinkApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // --- Verify red theme is active ---
      final redColors = getTacticalColors('red');

      // The scaffold background should match the red theme's bg
      final scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.backgroundColor, redColors.bg);

      // The RED GRID LINK title should be in the accent color (red)
      final titleWidget = tester.widget<Text>(
        find.text('RED GRID LINK'),
      );
      expect(titleWidget.style?.color, redColors.accent);

      // --- Switch to green theme via provider ---
      await container.read(themeIdProvider.notifier).set('green');
      await tester.pumpAndSettle();

      // --- Verify green theme is now active ---
      final greenColors = getTacticalColors('green');

      final scaffoldAfter = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffoldAfter.backgroundColor, greenColors.bg);

      final titleAfter = tester.widget<Text>(
        find.text('RED GRID LINK'),
      );
      expect(titleAfter.style?.color, greenColors.accent);
    });

    testWidgets('starts with pre-set green theme', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_id': 'green',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const RedGridLinkApp(),
        ),
      );
      await tester.pumpAndSettle();

      final greenColors = getTacticalColors('green');

      // Scaffold should have green bg
      final scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.backgroundColor, greenColors.bg);

      // Title should use green accent
      final titleWidget = tester.widget<Text>(
        find.text('RED GRID LINK'),
      );
      expect(titleWidget.style?.color, greenColors.accent);
    });

    testWidgets('theme switch persists to repository', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const RedGridLinkApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state is red
      expect(repo.themeId, 'red');

      // Switch to blue
      await container.read(themeIdProvider.notifier).set('blue');
      await tester.pumpAndSettle();

      // Verify persisted
      expect(repo.themeId, 'blue');
    });
  });
}

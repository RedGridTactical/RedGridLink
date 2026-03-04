import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/app.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  group('App launch and onboarding flow', () {
    testWidgets(
      'shows onboarding on first launch, navigate pages, then HomeScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
            ],
            child: const RedGridLinkApp(),
          ),
        );
        await tester.pumpAndSettle();

        // --- Verify onboarding screen appears (page 0: welcome) ---
        expect(find.text('RED GRID LINK'), findsOneWidget);
        expect(find.text('PROXIMITY COORDINATION'), findsOneWidget);

        // --- Page 0 -> Page 1: Tap Next ---
        expect(find.text('NEXT'), findsOneWidget);
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // Page 1: Disclaimer
        expect(find.text('IMPORTANT'), findsOneWidget);

        // Must accept disclaimer before advancing. Tap the checkbox text area.
        await tester.tap(find.textContaining('I understand the limitations'));
        await tester.pumpAndSettle();

        // --- Page 1 -> Page 2: Tap Next ---
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // Page 2: Permissions
        expect(find.text('PERMISSIONS'), findsOneWidget);

        // --- Page 2 -> Page 3: Tap Next ---
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // Page 3: Quick Setup
        expect(find.text('QUICK SETUP'), findsOneWidget);

        // --- Finish onboarding: Tap "Start Using Red Grid Link" ---
        // TacticalButton renders label uppercased
        await tester.tap(find.text('START USING RED GRID LINK'));
        await tester.pumpAndSettle();

        // --- Verify HomeScreen appears with bottom navigation ---
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('MAP'), findsOneWidget);
        expect(find.text('GRID'), findsOneWidget);
        expect(find.text('LINK'), findsOneWidget);
        expect(find.text('TOOLS'), findsOneWidget);
        expect(find.text('SETTINGS'), findsOneWidget);
      },
    );

    testWidgets(
      'skips onboarding when already completed',
      (WidgetTester tester) async {
        // Pre-set onboarding as completed
        SharedPreferences.setMockInitialValues({
          'settings_has_completed_onboarding': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final completedRepo = SettingsRepository(prefs);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(completedRepo),
            ],
            child: const RedGridLinkApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Should go straight to HomeScreen with bottom nav
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        // Should not show the onboarding welcome text
        expect(find.text('PROXIMITY COORDINATION'), findsNothing);
      },
    );

    testWidgets(
      'tab switching works on HomeScreen',
      (WidgetTester tester) async {
        // Skip onboarding for this test
        SharedPreferences.setMockInitialValues({
          'settings_has_completed_onboarding': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final completedRepo = SettingsRepository(prefs);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(completedRepo),
            ],
            child: const RedGridLinkApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify bottom nav is present
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Tap through tabs and verify they can be selected
        // GRID tab
        await tester.tap(find.text('GRID'));
        await tester.pumpAndSettle();

        // LINK tab
        await tester.tap(find.text('LINK'));
        await tester.pumpAndSettle();

        // TOOLS tab
        await tester.tap(find.text('TOOLS'));
        await tester.pumpAndSettle();

        // SETTINGS tab
        await tester.tap(find.text('SETTINGS'));
        await tester.pumpAndSettle();

        // Back to MAP tab
        await tester.tap(find.text('MAP'));
        await tester.pumpAndSettle();

        // All tabs should still be visible
        expect(find.text('MAP'), findsOneWidget);
        expect(find.text('GRID'), findsOneWidget);
        expect(find.text('LINK'), findsOneWidget);
        expect(find.text('TOOLS'), findsOneWidget);
        expect(find.text('SETTINGS'), findsOneWidget);
      },
    );
  });
}

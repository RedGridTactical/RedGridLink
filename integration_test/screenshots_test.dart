// Screenshot capture test for App Store marketing.
//
// Boots the Red Grid Link app in demo mode (fake team session, peers,
// markers, ghosts, and boundary all injected via demoDataProvider) and
// captures one PNG per marketing screen. Paired with a driver script
// (integration_test/test_driver/screenshot_driver.dart) that writes the
// captured bytes to ./screenshots/ on the host filesystem.
//
// To run:
//   flutter drive \
//     --driver=integration_test/test_driver/screenshot_driver.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d "<simulator name>"
//
// Screens captured (named):
//   01_map_team         Main map with 3 peers, 5 markers, 1 ghost, boundary
//   02_grid_mgrs        Grid screen with live 10-digit MGRS
//   03_field_link       Field Link session info with roster
//   04_tools            11 tactical tools grid
//   05_emergency        Emergency overlay with SOS active (scripted)
//   06_messaging        Tactical message bar with pre-canned list
//   07_ghost_markers    Map zoomed to show ghost markers + decay
//   08_themes           Settings screen with theme selector

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/app.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the app in demo mode with onboarding completed so we land on
  /// HomeScreen immediately. Returns once the first frame has settled.
  Future<void> bootDemoApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_has_completed_onboarding': true,
      'settings_demo_mode': true,
      'settings_theme_id': 'red',
      'settings_operational_mode': 'sar',
      'settings_display_name': 'OVERWATCH',
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
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Taps a bottom nav tab by text and settles.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Captures a screenshot via the integration_test binding. The driver
  /// script on the host side will persist the bytes to ./screenshots/.
  Future<void> capture(String name) async {
    // The iOS renderer requires the surface be converted before a
    // screenshot can be taken. No-op on other platforms.
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  group('App Store screenshots', () {
    testWidgets('01_map_team — main map with team, markers, ghost, boundary',
        (tester) async {
      await bootDemoApp(tester);
      // HomeScreen opens on MAP tab by default
      await capture('01_map_team');
    });

    testWidgets('02_grid_mgrs — grid screen with live 10-digit MGRS',
        (tester) async {
      await bootDemoApp(tester);
      await tapTab(tester, 'GRID');
      await capture('02_grid_mgrs');
    });

    testWidgets('03_field_link — active session with team roster',
        (tester) async {
      await bootDemoApp(tester);
      await tapTab(tester, 'LINK');
      await capture('03_field_link');
    });

    testWidgets('04_tools — 11 tactical tools grid', (tester) async {
      await bootDemoApp(tester);
      await tapTab(tester, 'TOOLS');
      await capture('04_tools');
    });

    testWidgets('05_themes — settings screen showing theme options',
        (tester) async {
      await bootDemoApp(tester);
      await tapTab(tester, 'SETTINGS');
      // Scroll down to theme selector if needed
      await tester.pumpAndSettle();
      await capture('05_themes');
    });

    testWidgets('06_nvg_green_theme — map rendered in NVG Green',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings_has_completed_onboarding': true,
        'settings_demo_mode': true,
        'settings_theme_id': 'green',
        'settings_operational_mode': 'sar',
        'settings_display_name': 'OVERWATCH',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
          child: const RedGridLinkApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await capture('06_nvg_green_theme');
    });

    testWidgets('07_blue_force_theme — map rendered in Blue Force',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings_has_completed_onboarding': true,
        'settings_demo_mode': true,
        'settings_theme_id': 'blue',
        'settings_operational_mode': 'sar',
        'settings_display_name': 'OVERWATCH',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
          child: const RedGridLinkApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await capture('07_blue_force_theme');
    });

    testWidgets('08_day_white_theme — map rendered in Day White',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings_has_completed_onboarding': true,
        'settings_demo_mode': true,
        'settings_theme_id': 'white',
        'settings_operational_mode': 'sar',
        'settings_display_name': 'OVERWATCH',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
          child: const RedGridLinkApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await capture('08_day_white_theme');
    });
  });
}

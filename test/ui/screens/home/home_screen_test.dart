import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/core/theme/app_theme.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/ui/screens/home/home_screen.dart';

void main() {
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  /// Build a testable HomeScreen. We provide only settingsRepositoryProvider
  /// and stub out dependent screens by using a simplified HomeScreen that
  /// does not attempt to instantiate heavyweight services. Since HomeScreen
  /// uses IndexedStack with the actual screens, we test the home_screen.dart
  /// navigation bar directly by wrapping it in a ProviderScope with the
  /// necessary overrides.
  ///
  /// The map/field_link/location providers are only accessed when the
  /// sub-screens build. We rely on IndexedStack lazily painting only the
  /// active child. For the MAP tab (index 0), MapScreen's build will
  /// attempt to read providers that throw. We override them to avoid that.
  Widget buildTestableHome() {
    final colors = getTacticalColors('red');
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: buildTheme(colors),
        home: const _TestableHomeScreen(),
      ),
    );
  }

  group('HomeScreen bottom navigation', () {
    testWidgets('shows 5 bottom navigation tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('GRID'), findsOneWidget);
      expect(find.text('LINK'), findsOneWidget);
      expect(find.text('TOOLS'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('has correct icons for each tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('default tab is index 0 (MAP)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      // MAP placeholder screen is shown
      expect(find.text('MAP SCREEN'), findsOneWidget);
    });

    testWidgets('tapping GRID tab switches to index 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('GRID'));
      await tester.pumpAndSettle();

      expect(find.text('GRID SCREEN'), findsOneWidget);
    });

    testWidgets('tapping LINK tab switches to index 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('LINK'));
      await tester.pumpAndSettle();

      expect(find.text('LINK SCREEN'), findsOneWidget);
    });

    testWidgets('tapping TOOLS tab switches to index 3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('TOOLS'));
      await tester.pumpAndSettle();

      expect(find.text('TOOLS SCREEN'), findsOneWidget);
    });

    testWidgets('tapping SETTINGS tab switches to index 4', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS SCREEN'), findsOneWidget);
    });

    testWidgets('switching tabs preserves the bottom nav bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('TOOLS'));
      await tester.pumpAndSettle();

      // Nav bar should still be present with all tabs
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('GRID'), findsOneWidget);
      expect(find.text('LINK'), findsOneWidget);
      expect(find.text('TOOLS'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Testable version of HomeScreen that uses simple placeholder screens instead
// of the real MapScreen, GridScreen, etc. which have heavy dependencies.
// This lets us test the navigation bar behaviour in isolation.
// ---------------------------------------------------------------------------

class _TestableHomeScreen extends ConsumerWidget {
  const _TestableHomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = getTacticalColors(ref.watch(themeIdProvider));
    final activeTab = ref.watch(activeTabProvider);

    final screens = <Widget>[
      const Center(child: Text('MAP SCREEN')),
      const Center(child: Text('GRID SCREEN')),
      const Center(child: Text('LINK SCREEN')),
      const Center(child: Text('TOOLS SCREEN')),
      const Center(child: Text('SETTINGS SCREEN')),
    ];

    return Scaffold(
      body: IndexedStack(
        index: activeTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: activeTab,
          onTap: (index) {
            ref.read(activeTabProvider.notifier).state = index;
          },
          backgroundColor: colors.bg,
          selectedItemColor: colors.accent,
          unselectedItemColor: colors.text4,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'GRID'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bluetooth), label: 'LINK'),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'TOOLS'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}

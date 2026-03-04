import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/haptics.dart';
import '../../../providers/theme_provider.dart';
import '../field_link/field_link_screen.dart';
import '../grid/grid_screen.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';
import '../tools/tools_screen.dart';

/// Provider that remembers the last active tab index.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Main navigation scaffold with 5 bottom tabs.
///
/// Tabs: MAP | GRID | LINK | TOOLS | SETTINGS
///
/// Uses an [IndexedStack] so each tab's state is preserved when
/// switching between them. The active tab is remembered via
/// [activeTabProvider].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final activeTab = ref.watch(activeTabProvider);

    // Build tab screens. MapScreen takes colors directly; the others
    // watch currentThemeProvider internally.
    final screens = <Widget>[
      MapScreen(colors: colors),
      const GridScreen(),
      const FieldLinkScreen(),
      const ToolsScreen(),
      const SettingsScreen(),
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
            tapLight();
            ref.read(activeTabProvider.notifier).state = index;
          },
          backgroundColor: colors.bg,
          selectedItemColor: colors.accent,
          unselectedItemColor: colors.text4,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 24,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'MAP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on),
              label: 'GRID',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth),
              label: 'LINK',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'TOOLS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}

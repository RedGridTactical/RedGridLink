import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/mode_provider.dart';
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
///
/// A thin mode indicator bar sits above the bottom navigation,
/// showing the current operational mode (SAR, Backcountry, Hunting,
/// or Training) so the user always knows which context is active.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final activeTab = ref.watch(activeTabProvider);
    final mode = ref.watch(currentModeProvider);

    // Trigger GPS initialization when HomeScreen loads (after onboarding).
    // This starts the location stream so Grid/Map tabs receive position data.
    ref.watch(locationInitProvider);

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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mode indicator bar ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(
                top: BorderSide(color: colors.border, width: 0.5),
                bottom: BorderSide(color: colors.border, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mode.icon, size: 12, color: colors.accent),
                const SizedBox(width: 6),
                Text(
                  '${mode.label} MODE',
                  style: TacticalTextStyles.label(colors).copyWith(
                    fontSize: 10,
                    color: colors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '\u2022 ${mode.description}',
                  style: TacticalTextStyles.dim(colors).copyWith(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom navigation bar ──────────────────────────────────
          Container(
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
        ],
      ),
    );
  }
}

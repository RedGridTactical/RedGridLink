import 'package:flutter/material.dart';
import 'package:red_grid_link/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/widgets/paywall_sheet.dart';
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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  /// SUNSET: merge notice above the tab stack. Dismissible for the
  /// session only, on purpose — the app is retired and every launch
  /// should restate where the product went.
  bool _sunsetBannerVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On app resume, force a re-check of location permission and
    // restart the GPS stream if it stalled. Three scenarios this
    // catches:
    //   1. User granted location in iOS Settings while the app was
    //      backgrounded — invalidate makes the next watch re-run
    //      LocationService.initialize().
    //   2. Stream stalled (iOS sometimes tears down location after
    //      long backgrounding) — re-running initialize() restarts it.
    //   3. Fresh-install upgrade where prior version had different
    //      permission state — covers any state mismatch on first run.
    // This is a no-op when the stream is already running and emitting.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationInitProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          if (_sunsetBannerVisible)
            Material(
              color: colors.card,
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () {
                    tapLight();
                    showPaywallSheet(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.accent, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.merge_type, size: 16, color: colors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'RED GRID LINK IS NOW PART OF RED GRID MGRS. '
                            'TAP FOR DETAILS',
                            style: TacticalTextStyles.caption(colors),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: colors.text3),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          onPressed: () =>
                              setState(() => _sunsetBannerVisible = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: activeTab,
              children: screens,
            ),
          ),
        ],
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
              // Audit 2026-05-03 P1 fix: bottom-nav labels were
              // hardcoded English even though every locale ARB ships
              // tabMap/tabGrid/tabLink/tabTools/tabSettings keys.
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map),
                  label: AppLocalizations.of(context)?.tabMap ?? 'MAP',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.grid_on),
                  label: AppLocalizations.of(context)?.tabGrid ?? 'GRID',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bluetooth),
                  label: AppLocalizations.of(context)?.tabLink ?? 'LINK',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.build),
                  label: AppLocalizations.of(context)?.tabTools ?? 'TOOLS',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings),
                  label:
                      AppLocalizations.of(context)?.tabSettings ?? 'SETTINGS',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

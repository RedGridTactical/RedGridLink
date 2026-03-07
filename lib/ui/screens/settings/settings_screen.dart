import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/map/tile_manager.dart';
import '../../common/widgets/mode_selector.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/tactical_card.dart';
import 'widgets/about_screen.dart';
import 'widgets/calibration_section.dart';
import 'widgets/field_link_settings.dart';
import 'widgets/subscription_section.dart';
import 'widgets/theme_selector.dart';
import '../help/help_screen.dart';

/// Full settings screen.
///
/// Organised into collapsible sections: Display, Navigation, Field Link,
/// Operational Mode, Maps, About, and Subscription.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final mode = ref.watch(currentModeProvider);
    final mapSource = ref.watch(mapSourceProvider);
    final showGrid = ref.watch(showMgrsGridProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'SETTINGS',
                style: TacticalTextStyles.heading(colors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Configuration and preferences',
                style: TacticalTextStyles.caption(colors),
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── DISPLAY ────────────────────────────────────────
                    const ThemeSelector(),

                    const SizedBox(height: 20),

                    // ── NAVIGATION ─────────────────────────────────────
                    const CalibrationSection(),

                    const SizedBox(height: 20),

                    // ── FIELD LINK ─────────────────────────────────────
                    const FieldLinkSettings(),

                    const SizedBox(height: 20),

                    // ── OPERATIONAL MODE ───────────────────────────────
                    SectionHeader(title: 'Operational Mode', colors: colors),
                    const SizedBox(height: 12),
                    TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(mode.icon, size: 18, color: colors.accent),
                              const SizedBox(width: 8),
                              Text(
                                'MODE',
                                style: TacticalTextStyles.label(colors),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const ModeSelector(),
                          const SizedBox(height: 8),
                          Text(
                            '${mode.description}. '
                            '${mode.markerLabel}s / ${mode.baseLabel} / '
                            '${mode.rallyPointLabel}.',
                            style: TacticalTextStyles.dim(colors),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── MAPS ───────────────────────────────────────────
                    SectionHeader(title: 'Maps', colors: colors),
                    const SizedBox(height: 12),
                    TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MAP SOURCE',
                            style: TacticalTextStyles.label(colors),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MapSourceChip(
                                label: 'OSM',
                                value: TileSources.osm,
                                current: mapSource,
                                colors: colors,
                                onTap: () => ref
                                    .read(mapSourceProvider.notifier)
                                    .state = TileSources.osm,
                              ),
                              const SizedBox(width: 8),
                              _MapSourceChip(
                                label: 'TOPO',
                                value: TileSources.topo,
                                current: mapSource,
                                colors: colors,
                                onTap: () => ref
                                    .read(mapSourceProvider.notifier)
                                    .state = TileSources.topo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SHOW MGRS GRID',
                                style: TacticalTextStyles.label(colors),
                              ),
                              SizedBox(
                                height: AppConstants.minTouchTarget,
                                child: Switch(
                                  value: showGrid,
                                  activeTrackColor: colors.accent,
                                  onChanged: (v) => ref
                                      .read(showMgrsGridProvider.notifier)
                                      .state = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the download button on the map to save '
                            'tiles for offline use.',
                            style: TacticalTextStyles.dim(colors),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── DEVELOPER ──────────────────────────────────
                    SectionHeader(title: 'Developer', colors: colors),
                    const SizedBox(height: 12),
                    TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEMO MODE',
                                  style: TacticalTextStyles.label(colors),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Uses Washington DC coordinates '
                                  'instead of live GPS',
                                  style: TacticalTextStyles.dim(colors),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: AppConstants.minTouchTarget,
                            child: Switch(
                              value: ref.watch(demoModeProvider),
                              activeTrackColor: colors.accent,
                              onChanged: (v) => ref
                                  .read(demoModeProvider.notifier)
                                  .set(v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── HELP & ABOUT ─────────────────────────────────
                    SectionHeader(title: 'Help & About', colors: colors),
                    const SizedBox(height: 12),
                    TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          _NavRow(
                            icon: Icons.help_outline,
                            label: 'HELP & GETTING STARTED',
                            subtitle: 'Guides, FAQ, and quick start',
                            colors: colors,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HelpScreen(),
                              ),
                            ),
                          ),
                          Divider(
                            color: colors.border2,
                            height: 1,
                            indent: 12,
                            endIndent: 12,
                          ),
                          _NavRow(
                            icon: Icons.info_outline,
                            label: 'ABOUT RED GRID LINK',
                            subtitle:
                                'v${AppConstants.appVersion} · Terms · Privacy',
                            colors: colors,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AboutScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── SUBSCRIPTION ───────────────────────────────────
                    const SubscriptionSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppConstants.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TacticalTextStyles.label(colors),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TacticalTextStyles.dim(colors),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.text3),
          ],
        ),
      ),
    );
  }
}

class _MapSourceChip extends StatelessWidget {
  const _MapSourceChip({
    required this.label,
    required this.value,
    required this.current,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String value;
  final String current;
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppConstants.minTouchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : colors.card2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accent : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TacticalTextStyles.caption(colors).copyWith(
              color: isSelected ? Colors.white : colors.text2,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../data/models/operational_mode.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/map/tile_manager.dart';
import '../../common/widgets/mode_selector.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/tactical_card.dart';
import 'widgets/calibration_section.dart';
import 'widgets/field_link_settings.dart';
import 'widgets/subscription_section.dart';
import 'widgets/theme_selector.dart';

/// Full settings screen.
///
/// Organised into collapsible sections: Display, Navigation, Field Link,
/// Operational Mode, Maps, About, and Subscription.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final operationalMode = ref.watch(operationalModeProvider);
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
                          Text(
                            'MODE',
                            style: TacticalTextStyles.label(colors),
                          ),
                          const SizedBox(height: 8),
                          const ModeSelector(),
                          const SizedBox(height: 8),
                          Text(
                            _modeDescription(operationalMode),
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
                            'Offline map downloads coming soon.',
                            style: TacticalTextStyles.dim(colors),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── ABOUT ──────────────────────────────────────────
                    SectionHeader(title: 'About', colors: colors),
                    const SizedBox(height: 12),
                    TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'VERSION',
                            value: AppConstants.appVersion,
                            colors: colors,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'BUILD',
                            value: 'Phase 5 - Flutter',
                            colors: colors,
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showLicenses(context),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: AppConstants.minTouchTarget,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'VIEW LICENSES',
                                style: TacticalTextStyles.body(colors).copyWith(
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Divider(color: colors.border2),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.rangeDisclaimer,
                            style: TacticalTextStyles.dim(colors),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This app is a coordination tool, not a safety '
                            'device. Always carry proper navigation equipment.',
                            style: TacticalTextStyles.dim(colors),
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

  String _modeDescription(String modeId) {
    final mode = OperationalMode.values.firstWhere(
      (m) => m.id == modeId,
      orElse: () => OperationalMode.sar,
    );
    return '${mode.description}. '
        'Markers: ${mode.markerLabel}, '
        'Base: ${mode.baseLabel}, '
        'Rally: ${mode.rallyPointLabel}.';
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        Text(value, style: TacticalTextStyles.body(colors)),
      ],
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

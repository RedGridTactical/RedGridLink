import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/widgets/tactical_card.dart';
import 'widgets/back_azimuth_tool.dart';
import 'widgets/coordinate_converter_tool.dart';
import 'widgets/dead_reckoning_tool.dart';
import 'widgets/declination_tool.dart';
import 'widgets/pace_count_tool.dart';
import 'widgets/precision_reference_tool.dart';
import 'widgets/range_estimation_tool.dart';
import 'widgets/resection_tool.dart';
import 'widgets/slope_calculator_tool.dart';
import 'widgets/solar_bearing_tool.dart';
import 'widgets/tds_tool.dart';

/// Tool definition for the tools grid.
class _ToolDef {
  final String label;
  final IconData icon;
  final String description;
  final Widget Function(TacticalColorScheme colors) builder;

  const _ToolDef({
    required this.label,
    required this.icon,
    required this.description,
    required this.builder,
  });
}

/// Grid of 11 tactical navigation tools.
///
/// Each card opens the corresponding tool as a full-screen page.
/// All cards meet the 44px minimum touch target.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  static final List<_ToolDef> _tools = [
    _ToolDef(
      label: 'DEAD\nRECKON',
      icon: Icons.explore,
      description: 'Plot position from heading + distance',
      builder: (_) => const DeadReckoningTool(),
    ),
    _ToolDef(
      label: 'RESECT',
      icon: Icons.architecture,
      description: 'Locate position from 2 known points',
      builder: (_) => const ResectionTool(),
    ),
    _ToolDef(
      label: 'PACE\nCOUNT',
      icon: Icons.directions_walk,
      description: 'Count paces to measure distance',
      builder: (_) => const PaceCountTool(),
    ),
    _ToolDef(
      label: 'DECLI-\nNATION',
      icon: Icons.compass_calibration,
      description: 'Magnetic to true bearing conversion',
      builder: (_) => const DeclinationTool(),
    ),
    _ToolDef(
      label: 'CELESTIAL\nNAV',
      icon: Icons.wb_sunny,
      description: 'Sun and moon bearing reference',
      builder: (_) => const SolarBearingTool(),
    ),
    _ToolDef(
      label: 'TIME\nDIST SPD',
      icon: Icons.timer,
      description: 'Time-distance-speed calculator',
      builder: (colors) => TdsTool(colors: colors),
    ),
    _ToolDef(
      label: 'BACK\nAZIMUTH',
      icon: Icons.swap_horiz,
      description: 'Compute reciprocal bearing',
      builder: (colors) => BackAzimuthTool(colors: colors),
    ),
    _ToolDef(
      label: 'COORD\nCONVERT',
      icon: Icons.sync_alt,
      description: 'MGRS / Lat-Lon / DMS / UTM',
      builder: (colors) => CoordinateConverterTool(colors: colors),
    ),
    _ToolDef(
      label: 'RANGE\nESTIMATE',
      icon: Icons.straighten,
      description: 'Mil-relation range estimation',
      builder: (colors) => RangeEstimationTool(colors: colors),
    ),
    _ToolDef(
      label: 'SLOPE\nCALC',
      icon: Icons.trending_up,
      description: 'Slope percentage and angle',
      builder: (colors) => SlopeCalculatorTool(colors: colors),
    ),
    _ToolDef(
      label: 'PRECISION\nREF',
      icon: Icons.grid_on,
      description: 'MGRS precision level reference',
      builder: (colors) => PrecisionReferenceTool(colors: colors),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final mode = ref.watch(currentModeProvider);

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
                'TACTICAL TOOLS',
                style: TacticalTextStyles.heading(colors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                mode.toolsSubtitle,
                style: TacticalTextStyles.caption(colors),
              ),
            ),
            const SizedBox(height: 16),

            // 2x4 grid of tool cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _tools.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final tool = _tools[index];
                    return _ToolCard(
                      tool: tool,
                      colors: colors,
                      onTap: () {
                        tapMedium();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => tool.builder(colors),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual tool card in the grid.
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.colors,
    required this.onTap,
  });

  final _ToolDef tool;
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tool.icon,
            color: colors.accent,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            tool.label,
            style: TacticalTextStyles.buttonText(colors).copyWith(
              fontSize: 12,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              tool.description,
              style: TacticalTextStyles.dim(colors).copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

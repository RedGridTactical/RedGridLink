import 'package:flutter/material.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../core/utils/tactical.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// MGRS precision reference card.
///
/// Shows all 5 precision levels with descriptions, visual scale,
/// and example coordinates at each precision.
class PrecisionReferenceTool extends StatelessWidget {
  const PrecisionReferenceTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // Example position for demonstration (US Capitol Building)
    const double exLat = 38.8899;
    const double exLon = -77.0091;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('PRECISION REF',
            style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'MGRS Precision Levels', colors: colors),
            const SizedBox(height: 12),

            // Precision level cards
            for (int level = 1; level <= 5; level++) ...[
              _PrecisionLevelCard(
                level: level,
                label: precisionLabels[level] ?? '',
                exampleMgrs: formatMGRS(toMGRS(exLat, exLon, level)),
                colors: colors,
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),
            SectionHeader(title: 'Usage Guide', colors: colors),
            const SizedBox(height: 12),

            TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuideRow(
                    level: '1',
                    gridSize: '10km',
                    use: 'Regional planning, area reference',
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _GuideRow(
                    level: '2',
                    gridSize: '1km',
                    use: 'General area, rally points',
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _GuideRow(
                    level: '3',
                    gridSize: '100m',
                    use: 'SAR grid squares, patrol areas',
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _GuideRow(
                    level: '4',
                    gridSize: '10m',
                    use: 'Point targets, casualty location',
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  _GuideRow(
                    level: '5',
                    gridSize: '1m',
                    use: 'Precision survey, evidence markers',
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(12),
              child: Text(
                'The MGRS coordinate format is:\n'
                'ZONE BAND  GRID-SQ  EASTING  NORTHING\n\n'
                'Example at full precision (1m):\n'
                '18S UJ 23456 67890\n\n'
                'Higher precision = more digits = smaller grid square.\n'
                'Most tactical operations use precision 4 (10m) or 5 (1m).',
                style: TacticalTextStyles.caption(colors),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Precision level card
// ---------------------------------------------------------------------------

class _PrecisionLevelCard extends StatelessWidget {
  const _PrecisionLevelCard({
    required this.level,
    required this.label,
    required this.exampleMgrs,
    required this.colors,
  });

  final int level;
  final String label;
  final String exampleMgrs;
  final TacticalColorScheme colors;

  // Visual scale width based on precision
  double get _barFraction {
    switch (level) {
      case 1:
        return 1.0; // 10km
      case 2:
        return 0.6; // 1km
      case 3:
        return 0.35; // 100m
      case 4:
        return 0.15; // 10m
      case 5:
        return 0.05; // 1m
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TacticalTextStyles.subheading(colors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Scale bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 6,
                    width: constraints.maxWidth * _barFraction,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exampleMgrs,
                    style: TacticalTextStyles.mgrsSmall(colors),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guide row
// ---------------------------------------------------------------------------

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.level,
    required this.gridSize,
    required this.use,
    required this.colors,
  });

  final String level;
  final String gridSize;
  final String use;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            level,
            style: TacticalTextStyles.value(colors).copyWith(fontSize: 14),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            gridSize,
            style: TacticalTextStyles.body(colors),
          ),
        ),
        Expanded(
          child: Text(
            use,
            style: TacticalTextStyles.caption(colors),
          ),
        ),
      ],
    );
  }
}

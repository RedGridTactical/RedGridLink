import 'package:flutter/material.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';
import 'package:red_grid_link/ui/common/widgets/tactical_card.dart';

/// Card showing AAR session summary statistics in a tactical grid layout.
///
/// Displays: duration, participant count, marker count, track points,
/// distance traveled, area covered, and annotations.
class AarSummaryCard extends StatelessWidget {
  const AarSummaryCard({
    super.key,
    required this.aar,
    required this.colors,
  });

  final AarData aar;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final totalDistance = AarService.calculateTotalDistance(aar.trackPoints);
    final areaCovered = AarService.calculateAreaCovered(aar.trackPoints);

    return TacticalCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.assessment, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'SESSION SUMMARY',
                style: TacticalTextStyles.subheading(colors),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            aar.sessionName.toUpperCase(),
            style: TacticalTextStyles.caption(colors),
          ),
          const SizedBox(height: 4),
          Text(
            '${aar.operationalMode.description} // '
            '${AarService.formatTacticalTimestamp(aar.startTime)}',
            style: TacticalTextStyles.dim(colors),
          ),
          const SizedBox(height: 12),

          // Stats grid
          _StatsGrid(
            colors: colors,
            items: [
              _StatItem('DURATION', AarService.formatDuration(aar.duration)),
              _StatItem('PARTICIPANTS', aar.totalPeers.toString()),
              _StatItem('MARKERS', aar.totalMarkers.toString()),
              _StatItem('TRACK PTS', aar.totalTrackPoints.toString()),
              _StatItem('DISTANCE', AarService.formatDistance(totalDistance)),
              _StatItem('AREA', '${areaCovered.toStringAsFixed(2)} km\u00B2'),
              _StatItem('ANNOTATIONS', aar.annotations.length.toString()),
              _StatItem('MODE', aar.operationalMode.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.colors,
    required this.items,
  });

  final TacticalColorScheme colors;
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _StatTile(item: item, colors: colors)).toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
    required this.colors,
  });

  final _StatItem item;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 2, // 2 columns
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TacticalTextStyles.value(colors),
          ),
        ],
      ),
    );
  }
}

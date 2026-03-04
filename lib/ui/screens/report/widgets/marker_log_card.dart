import 'package:flutter/material.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';
import 'package:red_grid_link/ui/common/widgets/tactical_card.dart';

/// Card showing a log of all markers placed during the session.
///
/// Each marker row shows the icon type, label, MGRS coordinates,
/// timestamp, and who placed it.
class MarkerLogCard extends StatelessWidget {
  const MarkerLogCard({
    super.key,
    required this.aar,
    required this.colors,
  });

  final AarData aar;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.place, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                '${aar.operationalMode.markerLabel.toUpperCase()} LOG',
                style: TacticalTextStyles.subheading(colors),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border2),
                ),
                child: Text(
                  '${aar.totalMarkers}',
                  style: TacticalTextStyles.caption(colors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (aar.markers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'NO MARKERS PLACED',
                  style: TacticalTextStyles.dim(colors),
                ),
              ),
            )
          else
            ...aar.markers.asMap().entries.map((entry) {
              final isLast = entry.key == aar.markers.length - 1;
              return _MarkerRow(
                index: entry.key + 1,
                marker: entry.value,
                colors: colors,
                showDivider: !isLast,
              );
            }),
        ],
      ),
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.index,
    required this.marker,
    required this.colors,
    this.showDivider = true,
  });

  final int index;
  final Marker marker;
  final TacticalColorScheme colors;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index badge
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border2),
                ),
                child: Text(
                  '$index',
                  style: TacticalTextStyles.caption(colors).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Icon
              Icon(
                _iconForMarker(marker.icon),
                size: 18,
                color: Color(marker.color),
              ),
              const SizedBox(width: 8),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label and type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            marker.label.isEmpty
                                ? marker.icon.name.toUpperCase()
                                : marker.label.toUpperCase(),
                            style: TacticalTextStyles.body(colors),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          marker.icon.name.toUpperCase(),
                          style: TacticalTextStyles.dim(colors),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // MGRS coordinates
                    Text(
                      marker.mgrs.isEmpty
                          ? '${marker.lat.toStringAsFixed(5)}, ${marker.lon.toStringAsFixed(5)}'
                          : marker.mgrs,
                      style: TacticalTextStyles.mgrsSmall(colors).copyWith(
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Timestamp and creator
                    Text(
                      '${AarService.formatTacticalTimestamp(marker.createdAt)} // '
                      '${marker.createdBy.toUpperCase()}',
                      style: TacticalTextStyles.dim(colors),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: colors.border2, height: 1),
      ],
    );
  }

  IconData _iconForMarker(MarkerIcon icon) {
    switch (icon) {
      case MarkerIcon.waypoint:
        return Icons.location_on;
      case MarkerIcon.danger:
        return Icons.warning;
      case MarkerIcon.camp:
        return Icons.cabin;
      case MarkerIcon.rally:
        return Icons.flag;
      case MarkerIcon.find:
        return Icons.search;
      case MarkerIcon.checkpoint:
        return Icons.check_circle;
      case MarkerIcon.stand:
        return Icons.nature;
      case MarkerIcon.custom:
        return Icons.star;
    }
  }
}

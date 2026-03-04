// Reusable popup card for map markers (synced markers, waypoints, etc.).
//
// Displays:
//   - Marker label and icon
//   - MGRS coordinate
//   - Distance and bearing from current position
//   - Creator name and timestamp
//   - Action buttons: copy MGRS, delete (if creator)
//
// Used by SyncedMarkersLayer and other marker-displaying layers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/marker.dart' as model;

class MarkerPopup extends StatelessWidget {
  final model.Marker marker;
  final TacticalColorScheme colors;
  final double? distanceMeters;
  final double? bearingDegrees;
  final bool isCreator;
  final VoidCallback? onDelete;
  final VoidCallback onClose;

  const MarkerPopup({
    super.key,
    required this.marker,
    required this.colors,
    this.distanceMeters,
    this.bearingDegrees,
    this.isCreator = false,
    this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mgrsStr = marker.mgrs.isNotEmpty
        ? mgrs_util.formatMGRS(marker.mgrs)
        : mgrs_util.formatMGRS(
            mgrs_util.toMGRS(marker.lat, marker.lon),
          );

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + label + close
          Row(
            children: [
              Icon(
                _iconForMarkerType(marker.icon),
                size: 18,
                color: Color(marker.color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  marker.label.isNotEmpty ? marker.label : marker.icon.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 16, color: colors.text3),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // MGRS
          _InfoRow(
            label: 'MGRS',
            value: mgrsStr,
            colors: colors,
            isAccent: true,
          ),

          // Distance and bearing
          if (distanceMeters != null)
            _InfoRow(
              label: 'DIST',
              value: mgrs_util.formatDistance(distanceMeters!),
              colors: colors,
            ),
          if (bearingDegrees != null)
            _InfoRow(
              label: 'BRG',
              value: '${bearingDegrees!.round()}\u00B0',
              colors: colors,
            ),

          // Creator
          _InfoRow(
            label: 'BY',
            value: marker.createdBy.length > 12
                ? '${marker.createdBy.substring(0, 12)}...'
                : marker.createdBy,
            colors: colors,
          ),

          // Time
          _InfoRow(
            label: 'TIME',
            value: _formatTime(marker.createdAt),
            colors: colors,
          ),

          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.copy,
                label: 'MGRS',
                colors: colors,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: mgrsStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'MGRS COPIED',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: colors.text,
                          letterSpacing: 1,
                        ),
                      ),
                      backgroundColor: colors.card,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (isCreator && onDelete != null) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'DEL',
                  colors: colors,
                  isDestructive: true,
                  onTap: onDelete!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForMarkerType(model.MarkerIcon icon) {
    return switch (icon) {
      model.MarkerIcon.waypoint => Icons.place,
      model.MarkerIcon.danger => Icons.warning,
      model.MarkerIcon.camp => Icons.cabin,
      model.MarkerIcon.rally => Icons.flag,
      model.MarkerIcon.find => Icons.search,
      model.MarkerIcon.checkpoint => Icons.check_circle_outline,
      model.MarkerIcon.stand => Icons.person_pin_circle,
      model.MarkerIcon.custom => Icons.star,
    };
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Single info row: label + value.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TacticalColorScheme colors;
  final bool isAccent;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: colors.text4,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isAccent ? colors.accent : colors.text2,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small action button.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final TacticalColorScheme colors;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFCC4444) : colors.text2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

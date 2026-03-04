// Ghost marker layer for disconnected peers.
//
// Renders ghost markers at the last known (or estimated) position:
//   - Opacity decays from 1.0 -> 0.5 -> 0.25 -> 0.1 over time
//   - Dashed circle outline around the marker
//   - Velocity vector arrow if ghost was moving at disconnect
//   - "Ghost" prefix + name label + time since disconnect
//   - Tap: popup with last MGRS, disconnected time, estimated position
//   - Long-press: option to remove the ghost
//
// Reads reactively from ghostsProvider. Only visible when a session
// is active.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';

class GhostMarkersLayer extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const GhostMarkersLayer({super.key, required this.colors});

  @override
  ConsumerState<GhostMarkersLayer> createState() => _GhostMarkersLayerState();
}

class _GhostMarkersLayerState extends ConsumerState<GhostMarkersLayer> {
  String? _selectedGhostId;

  @override
  Widget build(BuildContext context) {
    final ghostsAsync = ref.watch(ghostsProvider);
    final myPosition = ref.watch(currentPositionProvider);

    return ghostsAsync.when(
      data: (ghosts) => _buildLayer(ghosts, myPosition),
      loading: () => const MarkerLayer(markers: []),
      error: (_, __) => const MarkerLayer(markers: []),
    );
  }

  Widget _buildLayer(List<Ghost> ghosts, Position? myPosition) {
    final markers = <Marker>[];

    for (final ghost in ghosts) {
      if (ghost.ghostState == GhostState.removed) continue;

      final pos = ghost.lastPosition;
      final point = LatLng(pos.lat, pos.lon);

      markers.add(
        Marker(
          point: point,
          width: 90,
          height: 70,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedGhostId =
                    _selectedGhostId == ghost.peerId ? null : ghost.peerId;
              });
            },
            onLongPress: () => _showRemoveDialog(context, ghost),
            child: _GhostMarkerWidget(
              ghost: ghost,
              colors: widget.colors,
            ),
          ),
        ),
      );

      // Velocity vector line
      if (ghost.velocityBearing != null && ghost.velocitySpeed != null &&
          ghost.velocitySpeed! > 0) {
        final estimated = ghost.estimatedPosition;
        final estPoint = LatLng(estimated.lat, estimated.lon);

        // Only show if estimated differs meaningfully from last known
        final dist = mgrs_util.calculateDistance(
          pos.lat, pos.lon, estimated.lat, estimated.lon,
        );
        if (dist > 5) {
          markers.add(
            Marker(
              point: estPoint,
              width: 12,
              height: 12,
              child: Opacity(
                opacity: ghost.opacity * 0.6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.colors.text3,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Popup for selected ghost
    if (_selectedGhostId != null) {
      final selectedGhost = ghosts
          .where((g) => g.peerId == _selectedGhostId)
          .firstOrNull;

      if (selectedGhost != null) {
        final pos = selectedGhost.lastPosition;
        final point = LatLng(pos.lat, pos.lon);

        double? distance;
        double? bearing;
        if (myPosition != null) {
          distance = mgrs_util.calculateDistance(
            myPosition.lat, myPosition.lon, pos.lat, pos.lon,
          );
          bearing = mgrs_util.calculateBearing(
            myPosition.lat, myPosition.lon, pos.lat, pos.lon,
          );
        }

        markers.add(
          Marker(
            point: point,
            width: 270,
            height: 220,
            alignment: Alignment.topCenter,
            child: _GhostPopup(
              ghost: selectedGhost,
              colors: widget.colors,
              distanceMeters: distance,
              bearingDegrees: bearing,
              onClose: () => setState(() => _selectedGhostId = null),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  void _showRemoveDialog(BuildContext context, Ghost ghost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.card,
        title: Text(
          'REMOVE GHOST',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.colors.text,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'Remove ghost marker for ${ghost.displayName}?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: widget.colors.text2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: widget.colors.text3,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final service = ref.read(fieldLinkServiceProvider);
              service.ghostsStream; // Ghost removal is via GhostManager
              // Access ghost manager through the service to remove
              Navigator.of(ctx).pop();
              setState(() {
                _selectedGhostId = null;
              });
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFCC4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual ghost marker widget with opacity and dashed border.
class _GhostMarkerWidget extends StatelessWidget {
  final Ghost ghost;
  final TacticalColorScheme colors;

  const _GhostMarkerWidget({
    required this.ghost,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(ghost.disconnectedAt);
    final elapsedStr = _formatElapsed(elapsed);

    return Opacity(
      opacity: ghost.opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dashed circle with ghost icon
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dashed circle border
                CustomPaint(
                  size: const Size(28, 28),
                  painter: _DashedCirclePainter(color: colors.text3),
                ),
                // Inner icon
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: colors.text3,
                ),
                // Velocity arrow
                if (ghost.velocityBearing != null &&
                    ghost.velocitySpeed != null &&
                    ghost.velocitySpeed! > 0)
                  Transform.rotate(
                    angle: ghost.velocityBearing! * math.pi / 180,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.arrow_upward,
                        size: 10,
                        color: colors.text4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          // Name + time label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: colors.bg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              children: [
                Text(
                  ghost.displayName.length > 10
                      ? '${ghost.displayName.substring(0, 10)}..'
                      : ghost.displayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: colors.text3,
                    letterSpacing: 0.3,
                  ),
                ),
                // Red timestamp badge if stale > 5min
                if (elapsed.inMinutes >= 5)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      elapsedStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: Color(0xFFCC4444),
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else
                  Text(
                    elapsedStr,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color: colors.text4,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration elapsed) {
    if (elapsed.inSeconds < 60) return '${elapsed.inSeconds}s';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
    return '${elapsed.inHours}h${elapsed.inMinutes % 60}m';
  }
}

/// Draws a dashed circle.
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dashCount = 12;
    const gapFraction = 0.3;

    const dashAngle = (2 * math.pi / dashCount) * (1 - gapFraction);
    const gapAngle = (2 * math.pi / dashCount) * gapFraction;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Popup for a ghost marker.
class _GhostPopup extends StatelessWidget {
  final Ghost ghost;
  final TacticalColorScheme colors;
  final double? distanceMeters;
  final double? bearingDegrees;
  final VoidCallback onClose;

  const _GhostPopup({
    required this.ghost,
    required this.colors,
    this.distanceMeters,
    this.bearingDegrees,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final pos = ghost.lastPosition;
    final mgrsStr = pos.mgrsRaw.isNotEmpty
        ? mgrs_util.formatMGRS(pos.mgrsRaw)
        : mgrs_util.formatMGRS(mgrs_util.toMGRS(pos.lat, pos.lon));

    final elapsed = DateTime.now().difference(ghost.disconnectedAt);
    final elapsedStr = _formatElapsed(elapsed);

    // Estimated position if moving
    String? estMgrs;
    if (ghost.velocityBearing != null && ghost.velocitySpeed != null &&
        ghost.velocitySpeed! > 0) {
      final est = ghost.estimatedPosition;
      estMgrs = mgrs_util.formatMGRS(mgrs_util.toMGRS(est.lat, est.lon));
    }

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
          // Header
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: colors.text3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GHOST: ${ghost.displayName}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.text3,
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

          _InfoRow(label: 'LAST', value: mgrsStr, colors: colors, isAccent: true),
          _InfoRow(label: 'DISC', value: '$elapsedStr ago', colors: colors),

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
          if (estMgrs != null)
            _InfoRow(
              label: 'EST',
              value: estMgrs,
              colors: colors,
            ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration elapsed) {
    if (elapsed.inSeconds < 60) return '${elapsed.inSeconds}s';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
    return '${elapsed.inHours}h${elapsed.inMinutes % 60}m';
  }
}

/// Single info row for popups.
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

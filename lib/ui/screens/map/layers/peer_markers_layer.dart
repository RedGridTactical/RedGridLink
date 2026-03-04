// Live peer position markers on the map.
//
// Renders each connected peer as a colored circle with:
//   - Name label below
//   - Heading arrow showing movement direction
//   - Auto-assigned color from a tactical palette
//   - Tap interaction: shows PeerPopup with details
//
// Reads reactively from connectedPeersProvider. Only re-renders
// when the peer list actually changes.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';

import '../widgets/peer_popup.dart';

/// Auto-assigned peer colors (8 max peers).
const List<Color> peerColors = [
  Color(0xFF4FC3F7), // Light blue
  Color(0xFFFFB74D), // Orange
  Color(0xFF81C784), // Green
  Color(0xFFE57373), // Red
  Color(0xFFBA68C8), // Purple
  Color(0xFF4DD0E1), // Cyan
  Color(0xFFFFD54F), // Yellow
  Color(0xFFA1887F), // Brown
];

/// Get a stable color for a peer based on their ID.
Color colorForPeer(String peerId) {
  final hash = peerId.hashCode.abs();
  return peerColors[hash % peerColors.length];
}

class PeerMarkersLayer extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const PeerMarkersLayer({super.key, required this.colors});

  @override
  ConsumerState<PeerMarkersLayer> createState() => _PeerMarkersLayerState();
}

class _PeerMarkersLayerState extends ConsumerState<PeerMarkersLayer> {
  String? _selectedPeerId;

  @override
  Widget build(BuildContext context) {
    final peersAsync = ref.watch(connectedPeersProvider);
    final myPosition = ref.watch(currentPositionProvider);

    return peersAsync.when(
      data: (peers) => _buildLayer(peers, myPosition),
      loading: () => const MarkerLayer(markers: []),
      error: (_, __) => const MarkerLayer(markers: []),
    );
  }

  Widget _buildLayer(List<Peer> peers, Position? myPosition) {
    final markers = <Marker>[];

    for (final peer in peers) {
      if (peer.position == null || !peer.isConnected) continue;

      final pos = peer.position!;
      final point = LatLng(pos.lat, pos.lon);
      final color = colorForPeer(peer.id);

      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 60,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeerId =
                    _selectedPeerId == peer.id ? null : peer.id;
              });
            },
            child: _PeerMarkerWidget(
              peer: peer,
              color: color,
              colors: widget.colors,
            ),
          ),
        ),
      );
    }

    // Add popup marker for selected peer
    if (_selectedPeerId != null) {
      final selectedPeer = peers
          .where((p) => p.id == _selectedPeerId && p.position != null)
          .firstOrNull;

      if (selectedPeer != null) {
        final pos = selectedPeer.position!;
        final point = LatLng(pos.lat, pos.lon);

        double? distance;
        double? bearing;
        if (myPosition != null) {
          distance = mgrs_util.calculateDistance(
            myPosition.lat,
            myPosition.lon,
            pos.lat,
            pos.lon,
          );
          bearing = mgrs_util.calculateBearing(
            myPosition.lat,
            myPosition.lon,
            pos.lat,
            pos.lon,
          );
        }

        markers.add(
          Marker(
            point: point,
            width: 280,
            height: 260,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PeerPopup(
                  peer: selectedPeer,
                  colors: widget.colors,
                  distanceMeters: distance,
                  bearingDegrees: bearing,
                  onClose: () {
                    setState(() => _selectedPeerId = null);
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }
}

/// Individual peer marker widget: colored circle + heading arrow + name.
class _PeerMarkerWidget extends StatelessWidget {
  final Peer peer;
  final Color color;
  final TacticalColorScheme colors;

  const _PeerMarkerWidget({
    required this.peer,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final heading = peer.position?.heading;
    final hasHeading = heading != null && heading > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle + heading arrow
        SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main circle
              Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.85),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Heading arrow
              if (hasHeading)
                Center(
                  child: Transform.rotate(
                    angle: (heading * math.pi / 180),
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: _HeadingArrowPainter(color: color),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Name label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: colors.bg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            peer.displayName.length > 10
                ? '${peer.displayName.substring(0, 10)}..'
                : peer.displayName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the heading direction arrow.
class _HeadingArrowPainter extends CustomPainter {
  final Color color;

  _HeadingArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final tipY = center.dy - size.height / 2 + 1;

    // Arrow pointing up (will be rotated by Transform.rotate)
    final path = ui.Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 4, tipY + 8)
      ..lineTo(center.dx + 4, tipY + 8)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeadingArrowPainter oldDelegate) =>
      color != oldDelegate.color;
}

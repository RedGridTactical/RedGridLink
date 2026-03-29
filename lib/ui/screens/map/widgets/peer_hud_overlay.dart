// Floating HUD overlay showing distance and bearing to connected peers.
//
// Displays a compact horizontal strip at the top of the map view.
// Each peer shows: callsign, distance (m/km), bearing (degrees),
// and age of last update. Auto-hides when no peers are connected.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/core/utils/geo_utils.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/providers/ble_phy_provider.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';
import 'package:red_grid_link/providers/theme_provider.dart';
import 'package:red_grid_link/ui/common/widgets/signal_bars.dart';

/// Floating HUD overlay displaying peer distance and bearing info.
///
/// Place this in a [Stack] on top of the map. It auto-hides when
/// there are no connected peers.
class PeerHudOverlay extends ConsumerWidget {
  const PeerHudOverlay({
    super.key,
    required this.peers,
    required this.myLat,
    required this.myLon,
  });

  /// Currently connected peers.
  final List<Peer> peers;

  /// Local device latitude.
  final double myLat;

  /// Local device longitude.
  final double myLon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peers.isEmpty) return const SizedBox.shrink();

    final colors = ref.watch(currentThemeProvider);
    final isLrSupported = ref.watch(isCodedPhySupportedProvider).valueOrNull ?? false;

    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, size: 14, color: colors.accent),
                const SizedBox(width: 6),
                ...peers.map((peer) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _PeerChip(
                      peer: peer,
                      myLat: myLat,
                      myLon: myLon,
                      colors: colors,
                      isLrSupported: isLrSupported,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact chip showing peer callsign, distance, bearing, and signal quality.
class _PeerChip extends ConsumerWidget {
  const _PeerChip({
    required this.peer,
    required this.myLat,
    required this.myLon,
    required this.colors,
    required this.isLrSupported,
  });

  final Peer peer;
  final double myLat;
  final double myLon;
  final TacticalColorScheme colors;
  final bool isLrSupported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qualityMap = ref.watch(connectionQualityProvider);
    final quality = qualityMap[peer.id];

    final pos = peer.position;
    if (pos == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quality != null) ...[
            SignalBars(bars: quality.bars, tier: quality.tier, size: 12),
          ],
          // Long Range badge when Coded PHY is supported
          if (isLrSupported)
            const Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'LR',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            peer.displayName.toUpperCase(),
            style: TacticalTextStyles.dim(colors),
          ),
        ],
      );
    }

    final distance = _haversineDistance(myLat, myLon, pos.lat, pos.lon);
    final bearing = _calculateBearing(myLat, myLon, pos.lat, pos.lon);
    final age = DateTime.now().difference(pos.timestamp);
    final ageStr = _formatAge(age);
    final distStr = _formatDistance(distance);
    final compass = compassDirection(bearing);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Signal bars indicator (replaces simple dot when quality data exists)
        if (quality != null) ...[
          SignalBars(bars: quality.bars, tier: quality.tier, size: 12),
        ] else ...[
          // Fallback connection indicator dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: peer.isConnected
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
        // Long Range badge when Coded PHY is supported
        if (isLrSupported)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'LR',
              style: TextStyle(
                fontSize: 9,
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          peer.displayName.toUpperCase(),
          style: TacticalTextStyles.caption(colors).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$distStr  ${bearing.toStringAsFixed(0)}° $compass',
          style: TacticalTextStyles.dim(colors),
        ),
        if (age.inSeconds > 30) ...[
          const SizedBox(width: 4),
          Text(
            ageStr,
            style: TacticalTextStyles.dim(colors).copyWith(
              color: age.inMinutes > 5
                  ? Colors.red.withValues(alpha: 0.8)
                  : colors.text4,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  /// Format distance for display.
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  /// Format age duration for display.
  String _formatAge(Duration age) {
    if (age.inSeconds < 60) return '${age.inSeconds}s';
    if (age.inMinutes < 60) return '${age.inMinutes}m';
    return '${age.inHours}h';
  }

  /// Haversine distance between two points in meters.
  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const double R = 6371000; // Earth radius in meters
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Calculate bearing from point 1 to point 2 in degrees (0-360).
  static double _calculateBearing(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    final double dLon = (lon2 - lon1) * pi / 180;
    final double phi1 = lat1 * pi / 180;
    final double phi2 = lat2 * pi / 180;
    final double y = sin(dLon) * cos(phi2);
    final double x =
        cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLon);
    final double theta = atan2(y, x);
    return (theta * 180 / pi + 360) % 360;
  }
}

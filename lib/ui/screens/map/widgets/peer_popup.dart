// Popup card for peer markers on the map.
//
// Displays:
//   - Peer name and device type icon
//   - Current MGRS coordinate
//   - Distance from you and bearing to peer
//   - Last update time
//   - Battery level indicator
//   - Signal quality (based on last-seen recency)
//
// Shown when tapping a peer marker in the PeerMarkersLayer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/peer.dart';

class PeerPopup extends StatelessWidget {
  final Peer peer;
  final TacticalColorScheme colors;
  final double? distanceMeters;
  final double? bearingDegrees;
  final VoidCallback onClose;

  const PeerPopup({
    super.key,
    required this.peer,
    required this.colors,
    this.distanceMeters,
    this.bearingDegrees,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mgrsStr = peer.position != null
        ? mgrs_util.formatMGRS(peer.position!.mgrsRaw.isNotEmpty
            ? peer.position!.mgrsRaw
            : mgrs_util.toMGRS(peer.position!.lat, peer.position!.lon))
        : 'NO FIX';

    final signalQuality = _getSignalQuality();

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
          // Header: device icon + name + signal + close
          Row(
            children: [
              Icon(
                _deviceIcon(peer.deviceType),
                size: 16,
                color: colors.text2,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  peer.displayName,
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
              // Signal bars
              _SignalBars(quality: signalQuality, colors: colors),
              const SizedBox(width: 8),
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

          // Distance
          if (distanceMeters != null)
            _InfoRow(
              label: 'DIST',
              value: mgrs_util.formatDistance(distanceMeters!),
              colors: colors,
            ),

          // Bearing
          if (bearingDegrees != null)
            _InfoRow(
              label: 'BRG',
              value: '${bearingDegrees!.round()}\u00B0',
              colors: colors,
            ),

          // Battery
          if (peer.batteryLevel != null)
            _InfoRow(
              label: 'BATT',
              value: '${peer.batteryLevel}%',
              colors: colors,
              valueColor: _batteryColor(peer.batteryLevel!),
            ),

          // Last seen
          _InfoRow(
            label: 'SEEN',
            value: _formatLastSeen(peer.lastSeen),
            colors: colors,
          ),

          // Speed / heading
          if (peer.position?.speed != null && peer.position!.speed! > 0.1)
            _InfoRow(
              label: 'SPD',
              value: '${peer.position!.speed!.toStringAsFixed(1)} m/s',
              colors: colors,
            ),

          const SizedBox(height: 8),

          // Copy MGRS action
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colors.text2.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 12, color: colors.text2),
                    const SizedBox(width: 4),
                    Text(
                      'MGRS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: colors.text2,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.android => Icons.phone_android,
      DeviceType.ios => Icons.phone_iphone,
      DeviceType.unknown => Icons.devices,
    };
  }

  /// Signal quality: 3 = fresh (<10s), 2 = recent (<30s), 1 = stale (<60s), 0 = old.
  int _getSignalQuality() {
    final elapsed = DateTime.now().difference(peer.lastSeen).inSeconds;
    if (elapsed < 10) return 3;
    if (elapsed < 30) return 2;
    if (elapsed < 60) return 1;
    return 0;
  }

  Color _batteryColor(int level) {
    if (level > 50) return const Color(0xFF44CC44);
    if (level > 20) return const Color(0xFFCCCC44);
    return const Color(0xFFCC4444);
  }

  String _formatLastSeen(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inSeconds < 5) return 'NOW';
    if (elapsed.inSeconds < 60) return '${elapsed.inSeconds}s ago';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    return '${elapsed.inHours}h ago';
  }
}

/// Single info row: label + value.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TacticalColorScheme colors;
  final bool isAccent;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isAccent = false,
    this.valueColor,
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
                color: valueColor ?? (isAccent ? colors.accent : colors.text2),
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

/// Signal quality indicator (3 vertical bars).
class _SignalBars extends StatelessWidget {
  final int quality; // 0-3
  final TacticalColorScheme colors;

  const _SignalBars({required this.quality, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final isActive = i < quality;
        return Container(
          width: 3,
          height: 6.0 + (i * 3),
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: isActive ? colors.accent : colors.text5,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/utils/geo_utils.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';
import 'package:red_grid_link/providers/emergency_beacon_provider.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';

/// Full-screen alert overlay displayed when a remote emergency beacon
/// is received.
///
/// Shows the sender's callsign, MGRS coordinates, distance/bearing from
/// the local device, and time since activation. Triggers haptic feedback
/// on appearance. The "ACKNOWLEDGE" button dismisses the overlay but
/// the beacon remains active until the sender cancels.
class EmergencyAlertOverlay extends ConsumerStatefulWidget {
  const EmergencyAlertOverlay({super.key});

  @override
  ConsumerState<EmergencyAlertOverlay> createState() =>
      _EmergencyAlertOverlayState();
}

class _EmergencyAlertOverlayState extends ConsumerState<EmergencyAlertOverlay> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    // Re-arm overlay when a new emergency arrives after acknowledgement.
    ref.listen<bool>(emergencyActiveProvider, (previous, next) {
      if (previous == false && next == true) {
        setState(() => _acknowledged = false);
      }
    });

    final isActive = ref.watch(emergencyActiveProvider);

    if (!isActive || _acknowledged) {
      return const SizedBox.shrink();
    }

    final service = ref.watch(fieldLinkServiceProvider);
    final beacon = service.emergencyBeacon;
    final localDeviceId = service.localDeviceId;

    // Only show overlay for REMOTE emergencies (not our own).
    if (beacon.activeSenderId == null ||
        beacon.activeSenderId == localDeviceId) {
      return const SizedBox.shrink();
    }

    // Trigger haptic feedback on appearance.
    HapticFeedback.heavyImpact();

    final senderCallsign = _resolveCallsign(
      service,
      beacon.activeSenderId!,
    );
    final emergencyLat = beacon.activeLat;
    final emergencyLon = beacon.activeLon;
    final emergencyTimestamp = beacon.activeTimestamp;

    final myPosition = ref.watch(currentPositionProvider);

    String mgrsStr = '--';
    String distStr = '--';
    String bearingStr = '--';

    if (emergencyLat != null && emergencyLon != null) {
      try {
        final mgrsRaw = toMGRS(emergencyLat, emergencyLon);
        mgrsStr = formatMGRS(mgrsRaw);
      } catch (_) {
        mgrsStr = '${emergencyLat.toStringAsFixed(5)}, '
            '${emergencyLon.toStringAsFixed(5)}';
      }

      if (myPosition != null) {
        final dist = _haversineDistance(
          myPosition.lat,
          myPosition.lon,
          emergencyLat,
          emergencyLon,
        );
        final bearing = _calculateBearing(
          myPosition.lat,
          myPosition.lon,
          emergencyLat,
          emergencyLon,
        );
        distStr = _formatDistance(dist);
        bearingStr = '${bearing.toStringAsFixed(0)}\u00B0 '
            '${compassDirection(bearing)}';
      }
    }

    String ageStr = '--';
    if (emergencyTimestamp != null) {
      final age = DateTime.now().difference(emergencyTimestamp);
      ageStr = _formatAge(age);
    }

    return Positioned.fill(
      child: Material(
        color: Colors.red.withValues(alpha: 0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 72,
                ),
                const SizedBox(height: 16),
                const Text(
                  'EMERGENCY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  senderCallsign.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                _InfoRow(label: 'POSITION', value: mgrsStr),
                const SizedBox(height: 12),
                _InfoRow(label: 'DISTANCE', value: distStr),
                const SizedBox(height: 12),
                _InfoRow(label: 'BEARING', value: bearingStr),
                const SizedBox(height: 12),
                _InfoRow(label: 'TIME', value: '$ageStr ago'),
                const SizedBox(height: 48),
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _acknowledged = true);
                    },
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Resolve a peer's callsign from the role manager.
  String _resolveCallsign(dynamic service, String peerId) {
    try {
      final callsign = service.roleManager.callsignForPeer(peerId);
      if (callsign.isNotEmpty) return callsign;
    } catch (_) {
      // Fall through to default.
    }
    return peerId.length > 8 ? peerId.substring(0, 8) : peerId;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatAge(Duration age) {
    if (age.inSeconds < 60) return '${age.inSeconds}s';
    if (age.inMinutes < 60) return '${age.inMinutes}m';
    return '${age.inHours}h';
  }

  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const double r = 6371000;
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

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

/// Simple label-value row for the emergency alert overlay.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

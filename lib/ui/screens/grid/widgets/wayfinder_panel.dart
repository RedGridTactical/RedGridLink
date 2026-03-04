import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../common/widgets/bearing_arrow.dart';
import '../../../common/widgets/mgrs_display.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../../providers/location_provider.dart';

/// Holds the waypoint state — set via the provider below.
class WaypointState {
  final double? lat;
  final double? lon;
  final String? mgrs;
  final String? mgrsFormatted;

  const WaypointState({this.lat, this.lon, this.mgrs, this.mgrsFormatted});

  bool get hasWaypoint => lat != null && lon != null;
}

/// Notifier that stores a single saved waypoint.
class WaypointNotifier extends StateNotifier<WaypointState> {
  WaypointNotifier() : super(const WaypointState());

  void setWaypoint(double lat, double lon, String mgrs, String mgrsFormatted) {
    state = WaypointState(
      lat: lat,
      lon: lon,
      mgrs: mgrs,
      mgrsFormatted: mgrsFormatted,
    );
  }

  void clear() {
    state = const WaypointState();
  }
}

final waypointProvider =
    StateNotifierProvider<WaypointNotifier, WaypointState>((ref) {
  return WaypointNotifier();
});

/// Navigation guidance panel showing bearing and distance to a saved waypoint.
class WayfinderPanel extends ConsumerWidget {
  const WayfinderPanel({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoint = ref.watch(waypointProvider);
    final position = ref.watch(currentPositionProvider);

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WAYFINDER',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 8),
          if (!waypoint.hasWaypoint) ...[
            Text(
              'No waypoint set',
              style: TacticalTextStyles.body(colors),
            ),
            const SizedBox(height: 12),
            TacticalButton(
              label: 'Set Waypoint',
              icon: Icons.add_location_alt,
              colors: colors,
              onPressed: position != null
                  ? () {
                      tapMedium();
                      ref.read(waypointProvider.notifier).setWaypoint(
                            position.lat,
                            position.lon,
                            position.mgrsRaw,
                            position.mgrsFormatted,
                          );
                      notifySuccess();
                    }
                  : null,
            ),
          ] else ...[
            _WaypointInfo(
              waypoint: waypoint,
              position: position,
              colors: colors,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TacticalButton(
                    label: 'Update',
                    icon: Icons.my_location,
                    colors: colors,
                    isCompact: true,
                    onPressed: position != null
                        ? () {
                            tapMedium();
                            ref.read(waypointProvider.notifier).setWaypoint(
                                  position.lat,
                                  position.lon,
                                  position.mgrsRaw,
                                  position.mgrsFormatted,
                                );
                            notifySuccess();
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TacticalButton(
                    label: 'Clear',
                    icon: Icons.close,
                    colors: colors,
                    isCompact: true,
                    isDestructive: true,
                    onPressed: () {
                      tapMedium();
                      ref.read(waypointProvider.notifier).clear();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WaypointInfo extends StatelessWidget {
  const _WaypointInfo({
    required this.waypoint,
    required this.position,
    required this.colors,
  });

  final WaypointState waypoint;
  final dynamic position; // Position?
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    double? bearing;
    double? distance;

    if (position != null && waypoint.hasWaypoint) {
      bearing = calculateBearing(
        position.lat,
        position.lon,
        waypoint.lat!,
        waypoint.lon!,
      );
      distance = calculateDistance(
        position.lat,
        position.lon,
        waypoint.lat!,
        waypoint.lon!,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Waypoint MGRS
        MgrsDisplay(
          mgrs: waypoint.mgrsFormatted ?? waypoint.mgrs ?? '',
          isLarge: false,
          colors: colors,
        ),
        const SizedBox(height: 12),
        if (bearing != null && distance != null) ...[
          Row(
            children: [
              BearingArrow(
                bearingDegrees: bearing,
                size: 36,
                colors: colors,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bearing.toStringAsFixed(0)}\u00B0',
                    style: TacticalTextStyles.value(colors),
                  ),
                  Text(
                    formatDistance(distance),
                    style: TacticalTextStyles.value(colors).copyWith(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Text(
            'Waiting for GPS...',
            style: TacticalTextStyles.caption(colors),
          ),
        ],
      ],
    );
  }
}

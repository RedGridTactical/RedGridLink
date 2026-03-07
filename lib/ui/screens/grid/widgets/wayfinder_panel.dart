import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../data/models/operational_mode.dart';
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
///
/// Supports two methods of setting a waypoint:
///   1. Use current GPS position ("Use GPS" button)
///   2. Manual MGRS grid entry (text field that parses MGRS → lat/lon)
class WayfinderPanel extends ConsumerStatefulWidget {
  const WayfinderPanel({
    super.key,
    required this.colors,
    required this.mode,
  });

  final TacticalColorScheme colors;
  final OperationalMode mode;

  @override
  ConsumerState<WayfinderPanel> createState() => _WayfinderPanelState();
}

class _WayfinderPanelState extends ConsumerState<WayfinderPanel> {
  final TextEditingController _mgrsController = TextEditingController();
  String? _mgrsError;
  bool _showMgrsInput = false;

  TacticalColorScheme get colors => widget.colors;
  OperationalMode get mode => widget.mode;

  @override
  void dispose() {
    _mgrsController.dispose();
    super.dispose();
  }

  /// Parse user-entered MGRS and set as waypoint.
  void _setWaypointFromMgrs() {
    final input = _mgrsController.text.trim();
    if (input.isEmpty) {
      setState(() => _mgrsError = 'Enter an MGRS grid coordinate');
      return;
    }

    final result = parseMGRSToLatLon(input);
    if (result == null) {
      setState(() => _mgrsError = 'Invalid MGRS format');
      return;
    }

    final mgrsRaw = toMGRS(result.lat, result.lon);
    final mgrsFormatted = formatMGRS(mgrsRaw);

    tapMedium();
    ref.read(waypointProvider.notifier).setWaypoint(
          result.lat,
          result.lon,
          mgrsRaw,
          mgrsFormatted,
        );
    notifySuccess();

    _mgrsController.clear();
    setState(() {
      _mgrsError = null;
      _showMgrsInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waypoint = ref.watch(waypointProvider);
    final position = ref.watch(currentPositionProvider);

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WAYFINDER',
                style: TacticalTextStyles.label(colors),
              ),
              const SizedBox(width: 6),
              Text(
                '\u2022 ${mode.markerLabel.toUpperCase()}',
                style: TacticalTextStyles.dim(colors).copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!waypoint.hasWaypoint) ...[
            Text(
              'No ${mode.markerLabel.toLowerCase()} set',
              style: TacticalTextStyles.body(colors),
            ),
            const SizedBox(height: 12),

            // Two-button row: Use GPS + Enter Grid
            Row(
              children: [
                Expanded(
                  child: TacticalButton(
                    label: 'Use GPS',
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
                    label: 'Enter Grid',
                    icon: Icons.edit_location_alt,
                    colors: colors,
                    isCompact: true,
                    onPressed: () {
                      tapLight();
                      setState(() {
                        _showMgrsInput = !_showMgrsInput;
                        _mgrsError = null;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Manual MGRS input field
            if (_showMgrsInput) ...[
              const SizedBox(height: 12),
              _MgrsInputField(
                controller: _mgrsController,
                colors: colors,
                error: _mgrsError,
                onSubmit: _setWaypointFromMgrs,
              ),
            ],
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
                    label: 'GPS',
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
                    label: 'Grid',
                    icon: Icons.edit_location_alt,
                    colors: colors,
                    isCompact: true,
                    onPressed: () {
                      tapLight();
                      setState(() {
                        _showMgrsInput = !_showMgrsInput;
                        _mgrsError = null;
                      });
                    },
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
            // Manual MGRS input field (when editing existing waypoint)
            if (_showMgrsInput) ...[
              const SizedBox(height: 12),
              _MgrsInputField(
                controller: _mgrsController,
                colors: colors,
                error: _mgrsError,
                onSubmit: _setWaypointFromMgrs,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Text input field for manual MGRS grid coordinate entry.
class _MgrsInputField extends StatelessWidget {
  const _MgrsInputField({
    required this.controller,
    required this.colors,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final TacticalColorScheme colors;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENTER MGRS GRID',
          style: TacticalTextStyles.label(colors),
        ),
        const SizedBox(height: 4),
        Text(
          'e.g. 18S UJ 23456 12345',
          style: TacticalTextStyles.caption(colors),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: colors.text,
                  letterSpacing: 1.0,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: '18S UJ 23456 12345',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: colors.text4,
                  ),
                  filled: true,
                  fillColor: colors.bg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.accent, width: 1.5),
                  ),
                  errorText: error,
                  errorStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: const Color(0xFFCC0000),
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: colors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onSubmit,
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: colors.accent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

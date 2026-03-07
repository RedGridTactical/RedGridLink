import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../data/models/operational_mode.dart';
import '../../../../data/models/waypoint.dart';
import '../../../common/dialogs/text_input_dialog.dart';
import '../../../common/widgets/bearing_arrow.dart';
import '../../../common/widgets/mgrs_display.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/theme_provider.dart';

/// Navigation guidance panel showing bearing and distance to a saved waypoint.
///
/// Supports three methods of setting a waypoint:
///   1. Use current GPS position ("Use GPS" button)
///   2. Manual MGRS grid entry (text field that parses MGRS -> lat/lon)
///   3. Select from saved waypoints list ("Saved" button)
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

  /// Set the active waypoint from a Waypoint model.
  void _activateWaypoint(Waypoint waypoint) {
    tapMedium();
    ref.read(activeWaypointProvider.notifier).state = waypoint;
    notifySuccess();
  }

  /// Set the active waypoint from the current GPS position.
  void _setFromGps() {
    final position = ref.read(currentPositionProvider);
    if (position == null) return;

    tapMedium();
    ref.read(activeWaypointProvider.notifier).state = Waypoint(
      id: generateDeviceId(),
      name: 'GPS Mark',
      lat: position.lat,
      lon: position.lon,
      mgrs: position.mgrsRaw,
      mgrsFormatted: position.mgrsFormatted,
      createdAt: DateTime.now(),
    );
    notifySuccess();
  }

  /// Parse user-entered MGRS and set as active waypoint.
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
    ref.read(activeWaypointProvider.notifier).state = Waypoint(
      id: generateDeviceId(),
      name: 'Grid Entry',
      lat: result.lat,
      lon: result.lon,
      mgrs: mgrsRaw,
      mgrsFormatted: mgrsFormatted,
      createdAt: DateTime.now(),
    );
    notifySuccess();

    _mgrsController.clear();
    setState(() {
      _mgrsError = null;
      _showMgrsInput = false;
    });
  }

  /// Save the active waypoint to the persistent list.
  Future<void> _saveActiveWaypoint() async {
    final active = ref.read(activeWaypointProvider);
    if (active == null) return;

    final name = await showTextInputDialog(
      context,
      title: 'Save Waypoint',
      initialValue: active.name,
      hintText: 'Waypoint name',
      maxLength: 32,
      colors: colors,
    );

    if (name != null && name.isNotEmpty) {
      tapMedium();
      final waypoint = Waypoint(
        id: active.id,
        name: name,
        lat: active.lat,
        lon: active.lon,
        mgrs: active.mgrs,
        mgrsFormatted: active.mgrsFormatted,
        createdAt: active.createdAt,
      );
      await ref.read(waypointListProvider.notifier).add(waypoint);
      // Update active with new name
      ref.read(activeWaypointProvider.notifier).state = waypoint;
      notifySuccess();
    }
  }

  /// Clear the active waypoint.
  void _clearActive() {
    tapMedium();
    ref.read(activeWaypointProvider.notifier).state = null;
  }

  /// Show the saved waypoints bottom sheet.
  void _showSavedWaypoints() {
    tapLight();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SavedWaypointsSheet(
        colors: colors,
        ref: ref,
        onSelect: (waypoint) {
          Navigator.of(context).pop();
          _activateWaypoint(waypoint);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWaypointProvider);
    final position = ref.watch(currentPositionProvider);
    final savedCount = ref.watch(waypointListProvider).length;
    final hasActive = active != null;

    // Compute device heading for relative bearing arrow.
    // Use GPS heading when moving (speed > 0.5 m/s), compass otherwise.
    final compassHeading = ref.watch(compassHeadingProvider);
    final speed = position?.speed ?? 0;
    final double? _effectiveHeading;
    if (speed > 0.5 && position?.heading != null && position!.heading! > 0) {
      _effectiveHeading = position.heading;
    } else {
      _effectiveHeading = compassHeading ?? position?.heading;
    }

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
          if (!hasActive) ...[
            Text(
              'No ${mode.markerLabel.toLowerCase()} set',
              style: TacticalTextStyles.body(colors),
            ),
            const SizedBox(height: 12),

            // Three-button row: Use GPS + Enter Grid + Saved
            Row(
              children: [
                Expanded(
                  child: TacticalButton(
                    label: 'Use GPS',
                    icon: Icons.my_location,
                    colors: colors,
                    isCompact: true,
                    onPressed: position != null ? _setFromGps : null,
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
                if (savedCount > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TacticalButton(
                      label: 'Saved',
                      icon: Icons.bookmark,
                      colors: colors,
                      isCompact: true,
                      onPressed: _showSavedWaypoints,
                    ),
                  ),
                ],
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
            // Active waypoint name
            Text(
              active.name.toUpperCase(),
              style: TacticalTextStyles.dim(colors).copyWith(
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            _WaypointInfo(
              waypoint: active,
              position: position,
              heading: _effectiveHeading,
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
                    onPressed: position != null ? _setFromGps : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TacticalButton(
                    label: 'Save',
                    icon: Icons.bookmark_add,
                    colors: colors,
                    isCompact: true,
                    onPressed: _saveActiveWaypoint,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TacticalButton(
                    label: savedCount > 0 ? 'List' : 'Grid',
                    icon: savedCount > 0
                        ? Icons.bookmark
                        : Icons.edit_location_alt,
                    colors: colors,
                    isCompact: true,
                    onPressed: savedCount > 0
                        ? _showSavedWaypoints
                        : () {
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
                    onPressed: _clearActive,
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
    required this.heading,
    required this.colors,
  });

  final Waypoint waypoint;
  final dynamic position; // Position?
  final double? heading; // Device heading for relative arrow
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    double? bearing;
    double? distance;

    if (position != null) {
      bearing = calculateBearing(
        position.lat,
        position.lon,
        waypoint.lat,
        waypoint.lon,
      );
      distance = calculateDistance(
        position.lat,
        position.lon,
        waypoint.lat,
        waypoint.lon,
      );
    }

    // Relative bearing: the arrow shows which way to turn from current heading.
    // If heading is unavailable, fall back to absolute bearing.
    final double? arrowDegrees;
    if (bearing != null && heading != null) {
      arrowDegrees = (bearing - heading! + 360) % 360;
    } else {
      arrowDegrees = bearing;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Waypoint MGRS
        MgrsDisplay(
          mgrs: waypoint.mgrsFormatted.isNotEmpty
              ? waypoint.mgrsFormatted
              : waypoint.mgrs,
          isLarge: false,
          colors: colors,
        ),
        const SizedBox(height: 12),
        if (bearing != null && distance != null) ...[
          Row(
            children: [
              BearingArrow(
                bearingDegrees: arrowDegrees!,
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

/// Bottom sheet displaying saved waypoints with management actions.
class _SavedWaypointsSheet extends StatelessWidget {
  const _SavedWaypointsSheet({
    required this.colors,
    required this.ref,
    required this.onSelect,
  });

  final TacticalColorScheme colors;
  final WidgetRef ref;
  final ValueChanged<Waypoint> onSelect;

  @override
  Widget build(BuildContext context) {
    final waypoints = ref.watch(waypointListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Text(
                  'SAVED WAYPOINTS',
                  style: TacticalTextStyles.subheading(colors),
                ),
                const Spacer(),
                Text(
                  '${waypoints.length}',
                  style: TacticalTextStyles.dim(colors),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),

          // List
          if (waypoints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No saved waypoints',
                style: TacticalTextStyles.caption(colors),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: waypoints.length,
                separatorBuilder: (_, __) =>
                    Divider(color: colors.border2, height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final wp = waypoints[index];
                  return Dismissible(
                    key: ValueKey(wp.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: const Color(0xFFCC0000),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) {
                      ref.read(waypointListProvider.notifier).remove(wp.id);
                      // If the deleted waypoint was active, clear it
                      final active = ref.read(activeWaypointProvider);
                      if (active?.id == wp.id) {
                        ref.read(activeWaypointProvider.notifier).state = null;
                      }
                    },
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        wp.name,
                        style: TacticalTextStyles.body(colors),
                      ),
                      subtitle: Text(
                        wp.mgrsFormatted.isNotEmpty
                            ? wp.mgrsFormatted
                            : wp.mgrs,
                        style: TacticalTextStyles.caption(colors).copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colors.text3,
                      ),
                      onTap: () => onSelect(wp),
                      onLongPress: () async {
                        final newName = await showTextInputDialog(
                          context,
                          title: 'Rename Waypoint',
                          initialValue: wp.name,
                          hintText: 'Waypoint name',
                          maxLength: 32,
                          colors: colors,
                        );
                        if (newName != null && newName.isNotEmpty) {
                          ref
                              .read(waypointListProvider.notifier)
                              .rename(wp.id, newName);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

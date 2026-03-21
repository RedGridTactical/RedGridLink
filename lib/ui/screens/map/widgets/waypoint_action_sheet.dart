import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/constants/app_constants.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/core/utils/crypto_utils.dart';
import 'package:red_grid_link/core/utils/haptics.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/models/waypoint.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/providers/theme_provider.dart';

/// Bottom sheet for creating a waypoint at a tapped map location.
///
/// Displays the MGRS coordinate and lat/lon, a name text field,
/// and action buttons for saving locally and/or sharing with the team.
class WaypointActionSheet extends ConsumerStatefulWidget {
  final double lat;
  final double lon;
  final String mgrs;

  const WaypointActionSheet({
    super.key,
    required this.lat,
    required this.lon,
    required this.mgrs,
  });

  @override
  ConsumerState<WaypointActionSheet> createState() =>
      _WaypointActionSheetState();
}

class _WaypointActionSheetState extends ConsumerState<WaypointActionSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveLocally() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    tapMedium();

    final mgrsFormatted = formatMGRS(widget.mgrs);
    final waypoint = Waypoint(
      id: generateDeviceId(),
      name: name,
      lat: widget.lat,
      lon: widget.lon,
      mgrs: widget.mgrs,
      mgrsFormatted: mgrsFormatted,
      createdAt: DateTime.now(),
    );

    ref.read(waypointListProvider.notifier).add(waypoint);
    ref.read(activeWaypointProvider.notifier).state = waypoint;
    notifySuccess();

    if (mounted) Navigator.of(context).pop();
  }

  void _shareWithTeam() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    tapMedium();

    final localDeviceId = ref.read(localDeviceIdProvider);
    final marker = model.Marker(
      id: generateDeviceId(),
      lat: widget.lat,
      lon: widget.lon,
      mgrs: widget.mgrs,
      label: name,
      icon: model.MarkerIcon.waypoint,
      createdBy: localDeviceId,
      createdAt: DateTime.now(),
      origin: model.MarkerOrigin.sharedWaypoint,
    );

    ref.read(fieldLinkServiceProvider).addMarker(marker);
    notifySuccess();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final isSessionActive = ref.watch(isSessionActiveProvider);
    final mgrsFormatted = formatMGRS(widget.mgrs);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: colors.accent.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            'NEW WAYPOINT',
            style: TacticalTextStyles.heading(colors),
          ),
          const SizedBox(height: 12),

          // MGRS coordinate
          Text(
            mgrsFormatted,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),

          // Lat/Lon
          Text(
            '${widget.lat.toStringAsFixed(6)}, ${widget.lon.toStringAsFixed(6)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.text3,
            ),
          ),
          const SizedBox(height: 16),

          // Name input
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 64,
            style: TacticalTextStyles.body(colors),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              labelText: 'WAYPOINT NAME',
              labelStyle: TacticalTextStyles.dim(colors),
              hintText: 'e.g. Rally Point',
              hintStyle: TacticalTextStyles.dim(colors),
              filled: true,
              fillColor: colors.card2,
              counterStyle: TacticalTextStyles.dim(colors),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Save locally
              Expanded(
                child: SizedBox(
                  height: AppConstants.minTouchTarget,
                  child: OutlinedButton.icon(
                    onPressed: _saveLocally,
                    icon: Icon(Icons.bookmark, size: 16, color: colors.accent),
                    label: Text(
                      'SAVE TO MY WAYPOINTS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

              // Share with team (only when session is active)
              if (isSessionActive) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: AppConstants.minTouchTarget,
                    child: ElevatedButton.icon(
                      onPressed: _shareWithTeam,
                      icon:
                          const Icon(Icons.wifi, size: 16, color: Colors.white),
                      label: const Text(
                        'SHARE WITH TEAM',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Show the waypoint action sheet as a modal bottom sheet.
void showWaypointActionSheet(
  BuildContext context, {
  required double lat,
  required double lon,
  required String mgrs,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WaypointActionSheet(lat: lat, lon: lon, mgrs: mgrs),
  );
}

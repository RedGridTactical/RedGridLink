// Synced team markers layer for the map.
//
// Renders markers shared by all peers in the Field Link session:
//   - Different icons per marker type (waypoint, danger, camp, etc.)
//   - Color-coded by creator (same palette as peer markers)
//   - Tap marker: popup with label, MGRS, creator name, time
//   - Long-press: edit label or delete (only if you are the creator)
//
// Reads reactively from syncedMarkersProvider. Only visible when
// a session is active.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';

import '../widgets/marker_popup.dart';
import 'peer_markers_layer.dart'; // For colorForPeer

class SyncedMarkersLayer extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const SyncedMarkersLayer({super.key, required this.colors});

  @override
  ConsumerState<SyncedMarkersLayer> createState() => _SyncedMarkersLayerState();
}

class _SyncedMarkersLayerState extends ConsumerState<SyncedMarkersLayer> {
  String? _selectedMarkerId;

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(syncedMarkersProvider);
    final myPosition = ref.watch(currentPositionProvider);
    final localDeviceId = ref.watch(localDeviceIdProvider);

    return markersAsync.when(
      data: (markers) => _buildLayer(markers, myPosition, localDeviceId),
      loading: () => const fm.MarkerLayer(markers: []),
      error: (_, __) => const fm.MarkerLayer(markers: []),
    );
  }

  Widget _buildLayer(
    List<model.Marker> syncedMarkers,
    Position? myPosition,
    String localDeviceId,
  ) {
    final markers = <fm.Marker>[];

    for (final marker in syncedMarkers) {
      final point = LatLng(marker.lat, marker.lon);
      final creatorColor = colorForPeer(marker.createdBy);

      markers.add(
        fm.Marker(
          point: point,
          width: 70,
          height: 56,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMarkerId =
                    _selectedMarkerId == marker.id ? null : marker.id;
              });
            },
            onLongPress: () {
              if (marker.createdBy == localDeviceId) {
                _showEditDeleteDialog(context, marker);
              }
            },
            child: _SyncedMarkerWidget(
              marker: marker,
              creatorColor: creatorColor,
              colors: widget.colors,
            ),
          ),
        ),
      );
    }

    // Popup for selected marker
    if (_selectedMarkerId != null) {
      final selectedMarker = syncedMarkers
          .where((m) => m.id == _selectedMarkerId)
          .firstOrNull;

      if (selectedMarker != null) {
        final point = LatLng(selectedMarker.lat, selectedMarker.lon);

        double? distance;
        double? bearing;
        if (myPosition != null) {
          distance = mgrs_util.calculateDistance(
            myPosition.lat,
            myPosition.lon,
            selectedMarker.lat,
            selectedMarker.lon,
          );
          bearing = mgrs_util.calculateBearing(
            myPosition.lat,
            myPosition.lon,
            selectedMarker.lat,
            selectedMarker.lon,
          );
        }

        markers.add(
          fm.Marker(
            point: point,
            width: 280,
            height: 260,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarkerPopup(
                  marker: selectedMarker,
                  colors: widget.colors,
                  distanceMeters: distance,
                  bearingDegrees: bearing,
                  isCreator: selectedMarker.createdBy == localDeviceId,
                  onDelete: () {
                    ref.read(fieldLinkServiceProvider).removeMarker(
                          selectedMarker.id,
                        );
                    setState(() => _selectedMarkerId = null);
                  },
                  onClose: () =>
                      setState(() => _selectedMarkerId = null),
                ),
              ],
            ),
          ),
        );
      }
    }

    return fm.MarkerLayer(markers: markers);
  }

  void _showEditDeleteDialog(BuildContext context, model.Marker marker) {
    final labelController = TextEditingController(text: marker.label);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.card,
        title: Text(
          'EDIT MARKER',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.colors.text,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: widget.colors.text,
              ),
              decoration: InputDecoration(
                labelText: 'LABEL',
                labelStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: widget.colors.text3,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.colors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.colors.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(fieldLinkServiceProvider).removeMarker(marker.id);
              Navigator.of(ctx).pop();
              setState(() => _selectedMarkerId = null);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFCC4444),
              ),
            ),
          ),
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
              final updated = marker.copyWith(label: labelController.text);
              ref.read(fieldLinkServiceProvider).addMarker(updated);
              Navigator.of(ctx).pop();
            },
            child: Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: widget.colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual synced marker widget with icon and label.
class _SyncedMarkerWidget extends StatelessWidget {
  final model.Marker marker;
  final Color creatorColor;
  final TacticalColorScheme colors;

  const _SyncedMarkerWidget({
    required this.marker,
    required this.creatorColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: creatorColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: creatorColor, width: 1.5),
          ),
          child: Center(
            child: Icon(
              _iconForType(marker.icon),
              size: 14,
              color: creatorColor,
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Label
        if (marker.label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: colors.bg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              marker.label.length > 10
                  ? '${marker.label.substring(0, 10)}..'
                  : marker.label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: creatorColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForType(model.MarkerIcon icon) {
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
}

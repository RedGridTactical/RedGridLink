// Main map screen for Red Grid Link.
//
// Displays a flutter_map with:
//   - Online tile layer (OSM or OpenTopo, togglable)
//   - MGRS grid overlay (togglable)
//   - Current position marker (blue dot)
//   - Peer markers (live connected peers from Field Link)
//   - Ghost markers (disconnected peers with opacity decay)
//   - Synced team markers (waypoints, danger, camp, etc.)
//   - Annotations (polylines and polygons)
//   - Drawing preview layer (in-progress annotation)
//   - Floating zoom and control buttons
//   - Annotation drawing toolbar (togglable)
//   - Bottom coordinate bar showing MGRS, zoom, bearing
//
// Uses Riverpod for reactive state management. All Field Link
// layers are only visible when a session is active.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/constants/map_constants.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/mode_provider.dart';
import 'package:red_grid_link/services/map/mgrs_grid_overlay.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

import 'layers/annotation_layer.dart';
import 'layers/ghost_markers_layer.dart';
import 'layers/peer_markers_layer.dart';
import 'layers/synced_markers_layer.dart';
import 'widgets/annotation_toolbar.dart';
import 'widgets/coordinate_bar.dart';
import 'widgets/map_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const MapScreen({super.key, required this.colors});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  TacticalColorScheme get colors => widget.colors;

  @override
  Widget build(BuildContext context) {
    final mapSource = ref.watch(mapSourceProvider);
    final showGrid = ref.watch(showMgrsGridProvider);
    final controllerService = ref.read(mapControllerServiceProvider);
    final tileManager = ref.read(tileManagerProvider);
    final isSessionActive = ref.watch(isSessionActiveProvider);
    final gpsPosition = ref.watch(currentPositionProvider);
    final opMode = ref.watch(currentModeProvider);

    // Feed GPS position to the map controller for auto-follow and recenter.
    // This bridges LocationService → MapControllerService reactively.
    if (gpsPosition != null) {
      final latLng = LatLng(gpsPosition.lat, gpsPosition.lon);
      controllerService.followPosition(latLng);
    }
    final showToolbar = ref.watch(showAnnotationToolbarProvider);
    final isDrawing = ref.watch(isDrawingActiveProvider);
    final drawingMode = ref.watch(drawingModeProvider);
    final drawingPoints = ref.watch(drawingPointsProvider);
    final drawingColorIndex = ref.watch(drawingColorIndexProvider);
    final offlineRegionId = ref.watch(activeOfflineRegionIdProvider);

    // When offline source selected, auto-select first downloaded region
    if (mapSource == TileSources.offline && offlineRegionId == null) {
      final downloaded = ref.read(downloadedRegionsProvider).maybeWhen(
            data: (regions) => regions,
            orElse: () => <MapRegion>[],
          );
      if (downloaded.isNotEmpty) {
        // Schedule the state update after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(activeOfflineRegionIdProvider.notifier).state =
                downloaded.first.id;
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // ── FlutterMap ─────────────────────────────────────────────────
          FlutterMap(
            mapController: controllerService.mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                MapConstants.defaultLat,
                MapConstants.defaultLon,
              ),
              initialZoom: MapConstants.defaultZoom,
              minZoom: MapConstants.minZoom,
              maxZoom: MapConstants.maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              backgroundColor: colors.bg,
              onPositionChanged: _onPositionChanged,
              onTap: isDrawing
                  ? (tapPos, latLng) =>
                      _onMapTapWhileDrawing(latLng, drawingMode)
                  : null,
            ),
            children: [
              // Tile layer (online or offline)
              _buildTileLayer(mapSource, tileManager, offlineRegionId),

              // MGRS grid overlay
              if (showGrid) MgrsGridOverlay(colors: colors),

              // ── Field Link layers (session-gated) ──────────────────────
              if (isSessionActive) ...[
                // Annotations (polylines/polygons) — rendered first (below markers)
                AnnotationLayer(colors: colors),

                // Synced team markers
                SyncedMarkersLayer(colors: colors),

                // Ghost markers
                GhostMarkersLayer(colors: colors),

                // Live peer markers
                PeerMarkersLayer(colors: colors),
              ],

              // ── Drawing preview layer ──────────────────────────────────
              if (isDrawing && drawingPoints.isNotEmpty)
                _buildDrawingPreview(
                  drawingPoints,
                  drawingMode,
                  drawingColorIndex,
                ),

              // Current position marker (always on top)
              _buildPositionMarker(
                gpsPosition != null
                    ? LatLng(gpsPosition.lat, gpsPosition.lon)
                    : null,
              ),
            ],
          ),

          // ── Floating controls ──────────────────────────────────────────
          MapControls(colors: colors),

          // ── Annotation toolbar toggle button ───────────────────────────
          if (isSessionActive && !showToolbar)
            Positioned(
              right: 12,
              bottom: 60,
              child: _AnnotationToggleButton(
                colors: colors,
                onTap: () {
                  ref.read(showAnnotationToolbarProvider.notifier).state = true;
                },
              ),
            ),

          // ── Drawing mode indicator ─────────────────────────────────────
          if (isDrawing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 12,
              child: _DrawingHint(
                colors: colors,
                mode: drawingMode,
                markerLabel: opMode.markerLabel,
              ),
            ),

          // ── Attribution bar ────────────────────────────────────────────
          Positioned(
            left: 8,
            bottom: showToolbar ? 120 : 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.bg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mapSource == TileSources.topo
                    ? MapConstants.openTopoAttribution
                    : MapConstants.osmAttribution,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: colors.text4,
                ),
              ),
            ),
          ),

          // ── Annotation toolbar (above coordinate bar) ──────────────────
          if (showToolbar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 44, // Above coordinate bar
              child: AnnotationToolbar(colors: colors),
            ),

          // ── Coordinate bar (bottom) ────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CoordinateBar(colors: colors),
          ),
        ],
      ),
    );
  }

  /// Build the appropriate tile layer based on the current source.
  ///
  /// Returns an online [TileLayer] for OSM/TOPO sources, or an offline
  /// MBTiles-backed tile layer when the offline source is selected and
  /// a downloaded region is available.
  Widget _buildTileLayer(
    String mapSource,
    TileManager tileManager,
    String? offlineRegionId,
  ) {
    if (mapSource == TileSources.offline && offlineRegionId != null) {
      // Look up the region to get its file path
      final regions = ref.read(downloadedRegionsProvider).maybeWhen(
            data: (r) => r,
            orElse: () => <MapRegion>[],
          );

      final region = regions.cast<MapRegion?>().firstWhere(
            (r) => r!.id == offlineRegionId,
            orElse: () => null,
          );

      if (region != null && region.filePath != null) {
        return FutureBuilder<TileProvider?>(
          future: tileManager.loadMBTilesProvider(region.filePath!),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return TileLayer(
                tileProvider: snapshot.data!,
                maxZoom: region.maxZoom.toDouble(),
                minZoom: region.minZoom.toDouble(),
              );
            }
            // Fallback to online while loading
            return tileManager.getOnlineTileLayer(TileSources.osm);
          },
        );
      }
    }

    // Online tile layer (OSM or TOPO)
    return tileManager.getOnlineTileLayer(mapSource);
  }

  /// Handle map camera position changes.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    // Update providers with current camera state
    ref.read(mapCenterProvider.notifier).state = camera.center;
    ref.read(mapZoomProvider.notifier).state = camera.zoom;

    // If user pans manually, disable auto-follow
    if (hasGesture && ref.read(isFollowingProvider)) {
      ref.read(isFollowingProvider.notifier).state = false;
      ref.read(mapControllerServiceProvider).stopFollowing();
    }
  }

  /// Handle map tap while in drawing mode.
  void _onMapTapWhileDrawing(LatLng point, DrawingMode mode) {
    final current = ref.read(drawingPointsProvider);

    if (mode == DrawingMode.marker) {
      // For markers, only allow one point then trigger finish
      ref.read(drawingPointsProvider.notifier).state = [point];
      // Auto-finish after placing marker point
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFinishMarker(point);
      });
    } else {
      // For polylines/polygons, accumulate points
      ref.read(drawingPointsProvider.notifier).state = [...current, point];
    }
  }

  /// Auto-finish when a marker point is placed.
  void _autoFinishMarker(LatLng point) {
    // The toolbar handles the label dialog and save
    // Just ensure the point is recorded; the user uses the
    // toolbar's Done button or it auto-shows the dialog.
  }

  /// Build the drawing preview layer showing in-progress annotation.
  Widget _buildDrawingPreview(
    List<LatLng> points,
    DrawingMode mode,
    int colorIndex,
  ) {
    final color = annotationColors[colorIndex];

    if (mode == DrawingMode.marker && points.isNotEmpty) {
      // Show single marker preview
      return MarkerLayer(
        markers: [
          Marker(
            point: points.first,
            width: 24,
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.6),
                border: Border.all(color: color, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.place, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    if (points.length < 2) {
      // Show single point indicator
      if (points.isNotEmpty) {
        return MarkerLayer(
          markers: [
            Marker(
              point: points.first,
              width: 12,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    if (mode == DrawingMode.polygon) {
      return PolygonLayer(
        polygons: [
          Polygon(
            points: points,
            color: color.withValues(alpha: 0.15),
            borderColor: color.withValues(alpha: 0.7),
            borderStrokeWidth: 2,
          ),
        ],
      );
    }

    // Polyline preview
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: color.withValues(alpha: 0.7),
          strokeWidth: 2,
        ),
      ],
    );
  }

  /// Build the current position marker (blue dot).
  Widget _buildPositionMarker(LatLng? position) {
    if (position == null) {
      return const MarkerLayer(markers: []);
    }

    return MarkerLayer(
      markers: [
        Marker(
          point: position,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2196F3).withValues(alpha: 0.8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Toggle button to show the annotation toolbar.
class _AnnotationToggleButton extends StatelessWidget {
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  const _AnnotationToggleButton({
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Draw annotation',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border, width: 1),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: colors.card.withValues(alpha: 0.88),
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(Icons.draw, size: 20, color: colors.text2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawing mode hint banner at the top of the map.
class _DrawingHint extends StatelessWidget {
  final TacticalColorScheme colors;
  final DrawingMode mode;
  final String markerLabel;

  const _DrawingHint({
    required this.colors,
    required this.mode,
    this.markerLabel = 'MARKER',
  });

  @override
  Widget build(BuildContext context) {
    final hint = switch (mode) {
      DrawingMode.polyline => 'TAP MAP TO ADD POINTS. USE TOOLBAR TO FINISH.',
      DrawingMode.polygon => 'TAP MAP TO ADD VERTICES. USE TOOLBAR TO FINISH.',
      DrawingMode.marker => 'TAP MAP TO PLACE ${markerLabel.toUpperCase()}.',
      DrawingMode.none => '',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: colors.text2,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

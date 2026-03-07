// Riverpod providers for map state management.
//
// Provides reactive state for:
//   - MapControllerService (navigation, zoom, following)
//   - TileManager (online/offline tile sources)
//   - Map source selection (OSM vs Topo)
//   - MGRS grid toggle
//   - Position following toggle
//   - Available offline regions

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/services/map/map_controller_service.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

// -----------------------------------------------------------------------------
// Services
// -----------------------------------------------------------------------------

/// Provides the tile manager singleton.
final tileManagerProvider = Provider<TileManager>((ref) {
  return TileManager();
});

/// Provides the map controller service singleton.
///
/// The underlying [MapController] is created here and should be passed
/// to the [FlutterMap] widget via `mapController:`.
final mapControllerServiceProvider = Provider<MapControllerService>((ref) {
  return MapControllerService();
});

// -----------------------------------------------------------------------------
// UI state
// -----------------------------------------------------------------------------

/// Active tile source: 'osm' or 'topo'.
final mapSourceProvider = StateProvider<String>((ref) {
  return TileSources.osm;
});

/// Whether the MGRS grid overlay is visible.
final showMgrsGridProvider = StateProvider<bool>((ref) {
  return true;
});

/// Whether the map is auto-following GPS position.
final isFollowingProvider = StateProvider<bool>((ref) {
  return true;
});

/// Current map center position (updated on camera move).
final mapCenterProvider = StateProvider<LatLng>((ref) {
  return const LatLng(39.8283, -98.5795); // CONUS center default
});

/// Current zoom level (updated on camera move).
final mapZoomProvider = StateProvider<double>((ref) {
  return 4.0;
});

/// MGRS string for the current map center.
final mapCenterMgrsProvider = Provider<String>((ref) {
  final center = ref.watch(mapCenterProvider);
  if (center.latitude < -80 || center.latitude > 84) return 'OUT OF RANGE';
  return ref.watch(mapControllerServiceProvider).getMGRSAtCenter();
});

// -----------------------------------------------------------------------------
// Annotation drawing state
// -----------------------------------------------------------------------------

/// Current drawing tool mode.
enum DrawingMode {
  /// Not drawing.
  none,

  /// Drawing a polyline.
  polyline,

  /// Drawing a polygon.
  polygon,

  /// Placing a single marker.
  marker,
}

/// Whether the annotation toolbar is visible.
final showAnnotationToolbarProvider = StateProvider<bool>((ref) {
  return false;
});

/// Current drawing mode.
final drawingModeProvider = StateProvider<DrawingMode>((ref) {
  return DrawingMode.none;
});

/// Points accumulated while drawing an annotation.
final drawingPointsProvider = StateProvider<List<LatLng>>((ref) {
  return [];
});

/// Selected color for annotation drawing (index into preset palette).
final drawingColorIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Whether map interaction should route taps to the drawing engine
/// instead of normal map gestures.
final isDrawingActiveProvider = Provider<bool>((ref) {
  return ref.watch(drawingModeProvider) != DrawingMode.none;
});

// -----------------------------------------------------------------------------
// Offline regions
// -----------------------------------------------------------------------------

/// Available offline map regions from the database.
final mapRegionsProvider = FutureProvider<List<MapRegion>>((ref) async {
  final tileManager = ref.watch(tileManagerProvider);
  return tileManager.getAvailableRegions();
});

/// Downloaded (locally available) offline regions.
final downloadedRegionsProvider = FutureProvider<List<MapRegion>>((ref) async {
  final tileManager = ref.watch(tileManagerProvider);
  return tileManager.getDownloadedRegions();
});

// Wraps flutter_map's MapController with tactical navigation helpers.
//
// Provides MGRS-aware navigation, position following, zoom control,
// and grid density information.

import 'package:flutter/widgets.dart' show EdgeInsets;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/constants/map_constants.dart';
import 'package:red_grid_link/core/extensions/latlng_ext.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;

/// Grid density levels corresponding to MGRS zoom thresholds.
enum MgrsGridLevel {
  /// Grid Zone Designators only (6 lon x 8 lat).
  gzd,

  /// 100km grid squares within each GZD.
  gridSquare100km,

  /// 1km grid lines.
  km1,

  /// 100m grid lines.
  m100,
}

/// Tactical map controller wrapping [MapController].
class MapControllerService {
  final MapController mapController;

  /// Whether the map should auto-center on GPS position updates.
  bool _isFollowing = true;

  /// Last known GPS position for re-center functionality.
  LatLng? _lastGpsPosition;

  MapControllerService({MapController? controller})
      : mapController = controller ?? MapController();

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Center the map on a lat/lon position, optionally changing zoom.
  void centerOn(LatLng position, {double? zoom}) {
    mapController.move(position, zoom ?? currentZoom);
  }

  /// Center the map on an MGRS coordinate string.
  ///
  /// Does nothing if the MGRS string cannot be parsed.
  void centerOnMGRS(String mgrs) {
    final result = mgrs_util.parseMGRSToLatLon(mgrs);
    if (result != null) {
      centerOn(LatLng(result.lat, result.lon));
    }
  }

  /// Fit the map to show the given bounds with optional padding.
  void fitBounds(LatLngBounds bounds, {double padding = 48.0}) {
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(padding),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zoom
  // ---------------------------------------------------------------------------

  /// Zoom in by one level.
  void zoomIn() {
    final newZoom = (currentZoom + 1).clamp(
      MapConstants.minZoom,
      MapConstants.maxZoom,
    );
    mapController.move(mapController.camera.center, newZoom);
  }

  /// Zoom out by one level.
  void zoomOut() {
    final newZoom = (currentZoom - 1).clamp(
      MapConstants.minZoom,
      MapConstants.maxZoom,
    );
    mapController.move(mapController.camera.center, newZoom);
  }

  /// Set exact zoom level.
  void setZoom(double zoom) {
    final clamped = zoom.clamp(MapConstants.minZoom, MapConstants.maxZoom);
    mapController.move(mapController.camera.center, clamped);
  }

  /// Current zoom level.
  double get currentZoom => mapController.camera.zoom;

  /// Current map center.
  LatLng get center => mapController.camera.center;

  // ---------------------------------------------------------------------------
  // Position following
  // ---------------------------------------------------------------------------

  /// Update the tracked GPS position. If following is enabled, re-centers.
  void followPosition(LatLng position) {
    _lastGpsPosition = position;
    if (_isFollowing) {
      centerOn(position);
    }
  }

  /// Stop auto-centering on GPS updates.
  void stopFollowing() {
    _isFollowing = false;
  }

  /// Resume auto-centering on GPS updates.
  void startFollowing() {
    _isFollowing = true;
    if (_lastGpsPosition != null) {
      centerOn(_lastGpsPosition!);
    }
  }

  /// Whether the map is currently auto-following GPS position.
  bool get isFollowing => _isFollowing;

  /// Last known GPS position, if any.
  LatLng? get lastGpsPosition => _lastGpsPosition;

  /// Re-center on the last known GPS position.
  /// Does nothing if no GPS position is known.
  void recenter() {
    if (_lastGpsPosition != null) {
      _isFollowing = true;
      centerOn(_lastGpsPosition!);
    } else {
      // If no GPS, center on default
      centerOn(
        const LatLng(MapConstants.defaultLat, MapConstants.defaultLon),
        zoom: MapConstants.defaultZoom,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Grid info
  // ---------------------------------------------------------------------------

  /// Get the MGRS coordinate of the current map center.
  String getMGRSAtCenter() {
    final c = mapController.camera.center;
    return c.toFormattedMGRS();
  }

  /// Get the current MGRS grid density level based on zoom.
  MgrsGridLevel getCurrentGridLevel() {
    final zoom = currentZoom;
    if (zoom >= MapConstants.kmGridZoomThreshold) return MgrsGridLevel.m100;
    if (zoom >= MapConstants.gridSquareZoomThreshold) return MgrsGridLevel.km1;
    if (zoom >= MapConstants.gzdZoomThreshold) {
      return MgrsGridLevel.gridSquare100km;
    }
    return MgrsGridLevel.gzd;
  }

  /// Get a human-readable label for the current grid density.
  String getCurrentGridDensityLabel() {
    switch (getCurrentGridLevel()) {
      case MgrsGridLevel.gzd:
        return 'GZD';
      case MgrsGridLevel.gridSquare100km:
        return '100km';
      case MgrsGridLevel.km1:
        return '1km';
      case MgrsGridLevel.m100:
        return '100m';
    }
  }

  /// Returns the grid spacing in meters for the current zoom level.
  int getCurrentGridDensity() {
    switch (getCurrentGridLevel()) {
      case MgrsGridLevel.gzd:
        return 0; // Not a metric grid
      case MgrsGridLevel.gridSquare100km:
        return 100000;
      case MgrsGridLevel.km1:
        return 1000;
      case MgrsGridLevel.m100:
        return 100;
    }
  }
}

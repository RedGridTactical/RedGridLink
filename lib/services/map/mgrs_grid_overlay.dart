// MGRS grid line overlay layer for flutter_map.
//
// Draws Military Grid Reference System grid lines at varying density
// based on current zoom level:
//   - zoom < 8:  GZD boundaries only (6 lon x 8 lat bands)
//   - zoom 8-12: 100km grid square boundaries
//   - zoom 12-15: 1km grid lines
//   - zoom 15+:  100m grid lines
//
// Grid lines are rendered using flutter_map's PolylineLayer and labels
// use MarkerLayer so everything stays in map-coordinate space.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/constants/map_constants.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;

/// Returns the MGRS grid overlay layers (polylines + labels) for the
/// current map camera state.
///
/// Usage inside FlutterMap's children list:
/// ```dart
/// ...MgrsGridOverlay.buildLayers(camera, colors)
/// ```
class MgrsGridOverlay extends StatelessWidget {
  final TacticalColorScheme colors;

  const MgrsGridOverlay({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = camera.zoom;
    final bounds = camera.visibleBounds;

    final polylines = <Polyline>[];
    final markers = <Marker>[];

    if (zoom < MapConstants.gzdZoomThreshold) {
      _buildGzdGrid(bounds, polylines, markers, zoom);
    } else if (zoom < MapConstants.gridSquareZoomThreshold) {
      _buildGzdGrid(bounds, polylines, markers, zoom);
      _build100kmGrid(bounds, polylines, markers, zoom);
    } else if (zoom < MapConstants.kmGridZoomThreshold) {
      _build100kmGrid(bounds, polylines, markers, zoom);
      _buildMetricGrid(bounds, polylines, markers, zoom, 1000);
    } else {
      _buildMetricGrid(bounds, polylines, markers, zoom, 100);
    }

    return Stack(
      children: [
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GZD-level grid (latitude bands 8 + longitude zones 6)
  // ---------------------------------------------------------------------------

  void _buildGzdGrid(
    LatLngBounds bounds,
    List<Polyline> polylines,
    List<Marker> markers,
    double zoom,
  ) {
    final gridColor = colors.accent.withValues(alpha:0.35);
    const strokeWidth = 1.0;

    final west = bounds.west.floorToDouble();
    final east = bounds.east.ceilToDouble();
    final south = max(bounds.south, -80.0);
    final north = min(bounds.north, 84.0);

    // Latitude band boundaries: -80 to 84 in 8-degree steps
    // (last band X is 12 degrees: 72-84)
    final latBands = <double>[];
    for (double lat = -80; lat <= 84; lat += 8) {
      latBands.add(lat);
    }

    for (final lat in latBands) {
      if (lat < south - 8 || lat > north + 8) continue;
      polylines.add(Polyline(
        points: [LatLng(lat, west), LatLng(lat, east)],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Longitude zone boundaries: every 6 degrees
    for (double lon = -180; lon <= 180; lon += 6) {
      if (lon < west - 6 || lon > east + 6) continue;
      final clampedSouth = max(south, -80.0);
      final clampedNorth = min(north, 84.0);
      polylines.add(Polyline(
        points: [LatLng(clampedSouth, lon), LatLng(clampedNorth, lon)],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Labels at zone intersections
    if (zoom >= 3) {
      _addGzdLabels(bounds, markers, zoom);
    }
  }

  void _addGzdLabels(
    LatLngBounds bounds,
    List<Marker> markers,
    double zoom,
  ) {
    final west = bounds.west;
    final east = bounds.east;
    final south = max(bounds.south, -80.0);
    final north = min(bounds.north, 84.0);

    const bandLetters = 'CDEFGHJKLMNPQRSTUVWX';
    final fontSize = (zoom < 5) ? 10.0 : 12.0;

    for (double lat = -80; lat < 84; lat += 8) {
      if (lat + 8 < south || lat > north) continue;
      final bandIdx = ((lat + 80) / 8).floor();
      if (bandIdx < 0 || bandIdx >= bandLetters.length) continue;
      final bandLetter = bandLetters[bandIdx];

      for (double lon = -180; lon < 180; lon += 6) {
        if (lon + 6 < west || lon > east) continue;
        final zoneNum = ((lon + 180) / 6).floor() + 1;
        final label = '$zoneNum$bandLetter';
        final center = LatLng(lat + 4, lon + 3);

        markers.add(Marker(
          point: center,
          width: 40,
          height: 20,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colors.accent.withValues(alpha:0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 100km grid square boundaries
  // ---------------------------------------------------------------------------

  void _build100kmGrid(
    LatLngBounds bounds,
    List<Polyline> polylines,
    List<Marker> markers,
    double zoom,
  ) {
    final gridColor = colors.accent.withValues(alpha:0.25);
    const strokeWidth = 0.8;

    // Work in UTM grid: iterate by approximate 100km steps in lat/lon
    // At mid-latitudes, 100km ~ 0.9 degrees latitude, varies by longitude
    final latStep = _metersToLatDeg(100000);
    final midLat = (bounds.south + bounds.north) / 2;
    final lonStep = _metersToLonDeg(100000, midLat);

    final south = bounds.south - latStep;
    final north = bounds.north + latStep;
    final west = bounds.west - lonStep;
    final east = bounds.east + lonStep;

    // Snap to 100km grid origin
    final startLat = (south / latStep).floor() * latStep;
    final startLon = (west / lonStep).floor() * lonStep;

    // Horizontal lines (constant latitude)
    for (double lat = startLat; lat <= north; lat += latStep) {
      if (lat < -80 || lat > 84) continue;
      polylines.add(Polyline(
        points: [
          LatLng(lat, max(west, -180)),
          LatLng(lat, min(east, 180)),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Vertical lines (constant longitude)
    for (double lon = startLon; lon <= east; lon += lonStep) {
      final clampedS = max(south, -80.0);
      final clampedN = min(north, 84.0);
      polylines.add(Polyline(
        points: [
          LatLng(clampedS, lon),
          LatLng(clampedN, lon),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Labels: show grid square ID at center of each cell
    if (zoom >= 9) {
      for (double lat = startLat; lat <= north - latStep; lat += latStep) {
        for (double lon = startLon; lon <= east - lonStep; lon += lonStep) {
          final centerLat = lat + latStep / 2;
          final centerLon = lon + lonStep / 2;
          if (centerLat < -80 || centerLat > 84) continue;
          if (!bounds.contains(LatLng(centerLat, centerLon))) continue;

          final mgrs = mgrs_util.toMGRS(centerLat, centerLon, 1);
          if (mgrs == 'ERROR' || mgrs == 'OUT OF RANGE' || mgrs.length < 5) {
            continue;
          }
          // Extract grid square letters (chars 3-4 for 2-digit zone)
          final match =
              RegExp(r'^(\d{1,2})([A-Z])([A-Z]{2})').firstMatch(mgrs);
          if (match == null) continue;
          final squareId = match.group(3)!;

          markers.add(Marker(
            point: LatLng(centerLat, centerLon),
            width: 30,
            height: 18,
            child: Text(
              squareId,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.accent.withValues(alpha:0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ));
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Metric grid (1km or 100m)
  // ---------------------------------------------------------------------------

  void _buildMetricGrid(
    LatLngBounds bounds,
    List<Polyline> polylines,
    List<Marker> markers,
    double zoom,
    int metersPerCell,
  ) {
    final gridColor = colors.accent.withValues(alpha:
      metersPerCell == 1000 ? 0.20 : 0.15,
    );
    final strokeWidth = metersPerCell == 1000 ? 0.6 : 0.4;

    final midLat = (bounds.south + bounds.north) / 2;
    final latStep = _metersToLatDeg(metersPerCell.toDouble());
    final lonStep = _metersToLonDeg(metersPerCell.toDouble(), midLat);

    // Limit the number of grid lines for performance
    final maxLines = metersPerCell == 1000 ? 60 : 80;

    final south = bounds.south - latStep;
    final north = bounds.north + latStep;
    final west = bounds.west - lonStep;
    final east = bounds.east + lonStep;

    final startLat = (south / latStep).floor() * latStep;
    final startLon = (west / lonStep).floor() * lonStep;

    // Count lines to avoid excessive rendering
    final latLineCount = ((north - startLat) / latStep).ceil();
    final lonLineCount = ((east - startLon) / lonStep).ceil();

    if (latLineCount > maxLines || lonLineCount > maxLines) {
      // Too many lines -- fall back to coarser grid
      if (metersPerCell == 100) {
        _buildMetricGrid(bounds, polylines, markers, zoom, 1000);
        return;
      }
      return;
    }

    // Horizontal lines
    for (double lat = startLat; lat <= north; lat += latStep) {
      if (lat < -80 || lat > 84) continue;
      polylines.add(Polyline(
        points: [
          LatLng(lat, max(west, -180)),
          LatLng(lat, min(east, 180)),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Vertical lines
    for (double lon = startLon; lon <= east; lon += lonStep) {
      final clampedS = max(south, -80.0);
      final clampedN = min(north, 84.0);
      polylines.add(Polyline(
        points: [
          LatLng(clampedS, lon),
          LatLng(clampedN, lon),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ));
    }

    // Labels: show easting/northing at intersections (sparse — every 5th line)
    if (zoom >= 14 && metersPerCell == 1000) {
      _addMetricLabels(
        bounds, markers, startLat, startLon, latStep, lonStep, north, east, 5,
      );
    } else if (zoom >= 16 && metersPerCell == 100) {
      _addMetricLabels(
        bounds, markers, startLat, startLon, latStep, lonStep, north, east, 10,
      );
    }
  }

  void _addMetricLabels(
    LatLngBounds bounds,
    List<Marker> markers,
    double startLat,
    double startLon,
    double latStep,
    double lonStep,
    double north,
    double east,
    int skip,
  ) {
    int latIdx = 0;
    for (double lat = startLat; lat <= north; lat += latStep) {
      latIdx++;
      if (latIdx % skip != 0) continue;
      int lonIdx = 0;
      for (double lon = startLon; lon <= east; lon += lonStep) {
        lonIdx++;
        if (lonIdx % skip != 0) continue;
        if (!bounds.contains(LatLng(lat, lon))) continue;
        if (lat < -80 || lat > 84) continue;

        final mgrs = mgrs_util.toMGRS(lat, lon, 4);
        if (mgrs == 'ERROR' || mgrs == 'OUT OF RANGE') continue;

        // Extract last 8 digits (4-digit easting + 4-digit northing)
        final match =
            RegExp(r'^(\d{1,2})([A-Z])([A-Z]{2})(\d+)$').firstMatch(mgrs);
        if (match == null) continue;
        final nums = match.group(4)!;
        if (nums.length < 8) continue;
        final eStr = nums.substring(0, 4);
        final nStr = nums.substring(4);
        final label = '$eStr\n$nStr';

        markers.add(Marker(
          point: LatLng(lat, lon),
          width: 40,
          height: 28,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: colors.accent.withValues(alpha:0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Approximate degrees latitude per [meters].
  static double _metersToLatDeg(double meters) {
    // 1 degree latitude ~ 111,320 m
    return meters / 111320.0;
  }

  /// Approximate degrees longitude per [meters] at the given [latitude].
  static double _metersToLonDeg(double meters, double latitude) {
    final cosLat = cos(latitude * pi / 180);
    if (cosLat.abs() < 1e-10) return 360; // near poles
    return meters / (111320.0 * cosLat);
  }
}

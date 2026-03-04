/// LatLng extensions for MGRS conversion and geospatial calculations.
///
/// Wraps the pure-Dart mgrs.dart utilities for ergonomic use on LatLng objects.

import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;

extension LatLngExtensions on LatLng {
  /// Convert this position to an MGRS coordinate string.
  ///
  /// [precision] Grid precision (1-5, default 5 = 1m accuracy).
  /// Returns raw MGRS string, e.g. "18SUJ2345678901".
  String toMGRS([int precision = 5]) {
    return mgrs_util.toMGRS(latitude, longitude, precision);
  }

  /// Convert this position to a formatted MGRS string with spaces.
  ///
  /// Returns formatted string, e.g. "18S UJ 23456 78901".
  String toFormattedMGRS() {
    final raw = mgrs_util.toMGRS(latitude, longitude, 5);
    return mgrs_util.formatMGRS(raw);
  }

  /// Calculate distance in meters to another LatLng point (Haversine).
  ///
  /// Returns distance in meters.
  double distanceTo(LatLng other) {
    return mgrs_util.calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  /// Calculate bearing in degrees (0-360, 0=North) to another LatLng point.
  ///
  /// Returns bearing in degrees.
  double bearingTo(LatLng other) {
    return mgrs_util.calculateBearing(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }
}

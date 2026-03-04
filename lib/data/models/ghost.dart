import 'dart:math';
import 'package:red_grid_link/data/models/position.dart';

/// Ghost decay state for disconnected peers
enum GhostState {
  /// Just disconnected — full opacity marker
  full,

  /// Fading — half opacity
  faded,

  /// Dim — quarter opacity
  dim,

  /// Outline only — barely visible
  outline,

  /// Removed from map
  removed;

  static GhostState fromString(String value) =>
      GhostState.values.firstWhere(
        (e) => e.name == value,
        orElse: () => GhostState.full,
      );
}

/// Ghost marker for a disconnected peer
class Ghost {
  final String peerId;
  final String displayName;
  final Position lastPosition;
  final DateTime disconnectedAt;
  final GhostState ghostState;
  final double? velocityBearing;
  final double? velocitySpeed;

  const Ghost({
    required this.peerId,
    required this.displayName,
    required this.lastPosition,
    required this.disconnectedAt,
    this.ghostState = GhostState.full,
    this.velocityBearing,
    this.velocitySpeed,
  });

  /// Opacity based on ghost state
  double get opacity => switch (ghostState) {
    GhostState.full => 1.0,
    GhostState.faded => 0.5,
    GhostState.dim => 0.25,
    GhostState.outline => 0.1,
    GhostState.removed => 0.0,
  };

  /// Estimated current position using velocity vector and elapsed time.
  /// Projects the last known position along the bearing at the recorded speed.
  /// Returns lastPosition if no velocity data is available.
  Position get estimatedPosition {
    if (velocityBearing == null || velocitySpeed == null || velocitySpeed == 0) {
      return lastPosition;
    }

    final elapsed = DateTime.now().difference(disconnectedAt);
    final distanceMeters = velocitySpeed! * elapsed.inSeconds;

    // Convert bearing to radians
    final bearingRad = velocityBearing! * pi / 180.0;

    // Earth radius in meters
    const earthRadius = 6371000.0;

    final latRad = lastPosition.lat * pi / 180.0;
    final lonRad = lastPosition.lon * pi / 180.0;
    final angularDist = distanceMeters / earthRadius;

    final newLatRad = asin(
      sin(latRad) * cos(angularDist) +
          cos(latRad) * sin(angularDist) * cos(bearingRad),
    );
    final newLonRad = lonRad +
        atan2(
          sin(bearingRad) * sin(angularDist) * cos(latRad),
          cos(angularDist) - sin(latRad) * sin(newLatRad),
        );

    final newLat = newLatRad * 180.0 / pi;
    final newLon = newLonRad * 180.0 / pi;

    return Position(
      lat: newLat,
      lon: newLon,
      altitude: lastPosition.altitude,
      speed: velocitySpeed,
      heading: velocityBearing,
      accuracy: lastPosition.accuracy,
      mgrsRaw: '', // Must be recomputed
      mgrsFormatted: '',
      timestamp: DateTime.now(),
    );
  }

  Ghost copyWith({
    GhostState? ghostState,
    double? velocityBearing,
    double? velocitySpeed,
  }) =>
      Ghost(
        peerId: peerId,
        displayName: displayName,
        lastPosition: lastPosition,
        disconnectedAt: disconnectedAt,
        ghostState: ghostState ?? this.ghostState,
        velocityBearing: velocityBearing ?? this.velocityBearing,
        velocitySpeed: velocitySpeed ?? this.velocitySpeed,
      );
}

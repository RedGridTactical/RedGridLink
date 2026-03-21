import 'package:red_grid_link/data/models/annotation.dart';

/// Manages geofence boundary state and crossing detection.
///
/// Uses ray casting point-in-polygon to determine whether a peer's
/// position is inside or outside the active boundary annotation.
/// Tracks per-peer inside/outside state to detect exit transitions.
class BoundaryManager {
  Annotation? _boundary;
  final Map<String, bool> _wasInside = {};

  /// The currently active boundary annotation, or null.
  Annotation? get boundary => _boundary;

  /// Whether a boundary is currently set.
  bool get hasBoundary => _boundary != null;

  /// Set the active boundary annotation and clear previous state.
  void setBoundary(Annotation boundary) {
    _boundary = boundary;
    _wasInside.clear();
  }

  /// Clear the active boundary and reset all tracking state.
  void clearBoundary() {
    _boundary = null;
    _wasInside.clear();
  }

  /// Returns true if the given point is inside the boundary.
  ///
  /// If no boundary is set, returns true (no restriction).
  bool isInsideBoundary(double lat, double lon) {
    if (_boundary == null) return true;
    return _pointInPolygon(lat, lon, _boundary!.points);
  }

  /// Returns true if peer just crossed OUT of the boundary
  /// (inside -> outside transition).
  ///
  /// On first check for a peer, assumes they were inside. If they
  /// are already outside on first check, that counts as a crossing.
  bool checkBoundaryCrossing(String peerId, double lat, double lon) {
    if (_boundary == null) return false;
    final isInside = _pointInPolygon(lat, lon, _boundary!.points);
    final wasInside = _wasInside[peerId] ?? true; // assume inside on first check
    _wasInside[peerId] = isInside;
    return wasInside && !isInside;
  }

  /// Ray casting point-in-polygon algorithm.
  ///
  /// Counts the number of times a ray from the point crosses polygon
  /// edges. An odd count means the point is inside.
  bool _pointInPolygon(
    double lat,
    double lon,
    List<AnnotationPoint> polygon,
  ) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final yi = polygon[i].lat;
      final xi = polygon[i].lon;
      final yj = polygon[j].lat;
      final xj = polygon[j].lon;
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

import 'dart:math';

import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/data/repositories/annotation_repository.dart';
import 'package:red_grid_link/data/repositories/marker_repository.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/data/repositories/session_repository.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';

/// AAR (After-Action Report) compilation service.
///
/// Gathers all session data from repositories and compiles it into
/// an [AarData] model suitable for PDF export.
class AarService {
  final SessionRepository _sessionRepo;
  final PeerRepository _peerRepo;
  final MarkerRepository _markerRepo;
  final TrackRepository _trackRepo;
  final AnnotationRepository _annotationRepo;

  AarService({
    required SessionRepository sessionRepository,
    required PeerRepository peerRepository,
    required MarkerRepository markerRepository,
    required TrackRepository trackRepository,
    required AnnotationRepository annotationRepository,
  })  : _sessionRepo = sessionRepository,
        _peerRepo = peerRepository,
        _markerRepo = markerRepository,
        _trackRepo = trackRepository,
        _annotationRepo = annotationRepository;

  /// Compile a complete AAR for the given session ID.
  ///
  /// Gathers session config, participants, markers, annotations, and
  /// track points into a single [AarData] snapshot.
  ///
  /// Throws [ArgumentError] if the session is not found.
  Future<AarData> compileAar(String sessionId) async {
    final session = await _sessionRepo.getSessionById(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final peers = await _peerRepo.getPeersBySession(sessionId);
    final markers = await _markerRepo.getMarkersBySession(sessionId);
    final trackPoints = await _trackRepo.getTracksBySession(sessionId);
    final annotations = await _annotationRepo.getAnnotationsBySession(sessionId);

    // Use the session creation time as start, and the latest data point
    // or current time as the end.
    final endTime = _computeEndTime(trackPoints, session.createdAt);

    return AarData(
      sessionId: session.id,
      sessionName: session.name,
      operationalMode: session.operationalMode,
      startTime: session.createdAt,
      endTime: endTime,
      peers: peers,
      markers: markers,
      trackPoints: trackPoints,
      annotations: annotations,
    );
  }

  /// Determine session end time from the latest track point timestamp,
  /// latest marker timestamp, or fall back to now.
  DateTime _computeEndTime(
    List<TrackPoint> trackPoints,
    DateTime sessionStart,
  ) {
    DateTime latest = sessionStart;

    for (final tp in trackPoints) {
      if (tp.timestamp.isAfter(latest)) {
        latest = tp.timestamp;
      }
    }

    // If no track points recorded, use current time
    if (latest == sessionStart) {
      latest = DateTime.now();
    }

    return latest;
  }

  // ---------------------------------------------------------------------------
  // Statistics helpers
  // ---------------------------------------------------------------------------

  /// Calculate total distance traveled (in meters) for a specific peer's
  /// track points, using the Haversine formula.
  static double calculateDistanceForPeer(
    List<TrackPoint> trackPoints,
    String peerId,
    List<Peer> peers,
  ) {
    // Track points don't carry a peer ID in the current model, so we
    // compute total distance across all track points for the session.
    // In practice, each device records its own track locally.
    return calculateTotalDistance(trackPoints);
  }

  /// Calculate total distance (in meters) across sequential track points.
  static double calculateTotalDistance(List<TrackPoint> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += _haversineDistance(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
    }
    return total;
  }

  /// Calculate the approximate bounding-box area covered (in square km).
  static double calculateAreaCovered(List<TrackPoint> points) {
    if (points.length < 2) return 0.0;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }

    // Approximate width and height in meters
    final widthM = _haversineDistance(minLat, minLon, minLat, maxLon);
    final heightM = _haversineDistance(minLat, minLon, maxLat, minLon);

    // Convert to square kilometers
    return (widthM * heightM) / 1e6;
  }

  /// Format a [Duration] to a human-readable string: "2h 34m".
  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format a [DateTime] to tactical DTG format: "02MAR26 1430Z".
  static String formatTacticalTimestamp(DateTime dt) {
    final utc = dt.toUtc();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];

    final day = utc.day.toString().padLeft(2, '0');
    final month = months[utc.month - 1];
    final year = (utc.year % 100).toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');

    return '$day$month$year $hour${minute}Z';
  }

  /// Format distance in meters to a display string.
  /// Under 1000m shows meters, over shows km.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // ---------------------------------------------------------------------------
  // Haversine
  // ---------------------------------------------------------------------------

  /// Haversine distance between two lat/lon points in meters.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * (pi / 180);
}

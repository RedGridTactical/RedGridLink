import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/tracks_dao.dart';
import 'package:red_grid_link/data/models/track_point.dart' as model;

/// Repository for recording and retrieving GPS track points.
///
/// Wraps [TracksDao] and converts between Drift data classes
/// and the application's [model.TrackPoint] model objects.
class TrackRepository {
  final AppDatabase _db;

  TrackRepository(this._db);

  TracksDao get _dao => _db.tracksDao;

  /// Record a single track point.
  Future<void> recordTrackPoint(
    model.TrackPoint point, {
    String? sessionId,
  }) =>
      _dao.insertTrack(_toCompanion(point, sessionId: sessionId));

  /// Record multiple track points in a batch.
  Future<void> recordTrackPoints(
    List<model.TrackPoint> points, {
    String? sessionId,
  }) =>
      _dao.insertTracks(
        points.map((p) => _toCompanion(p, sessionId: sessionId)).toList(),
      );

  /// Get all track points for a session, ordered by timestamp.
  Future<List<model.TrackPoint>> getTracksBySession(String sessionId) async {
    final rows = await _dao.getTracksBySession(sessionId);
    return rows.map(_toModel).toList();
  }

  /// Watch track points for a session.
  Stream<List<model.TrackPoint>> watchTracksBySession(String sessionId) =>
      _dao.watchTracksBySession(sessionId).map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get track points between two timestamps (for AAR export).
  Future<List<model.TrackPoint>> getTracksBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _dao.getTracksBetween(start, end);
    return rows.map(_toModel).toList();
  }

  /// Delete track points older than the given cutoff.
  Future<int> deleteOlderThan(DateTime cutoff) =>
      _dao.deleteOlderThan(cutoff);

  /// Delete all tracks for a session.
  Future<int> deleteTracksBySession(String sessionId) =>
      _dao.deleteTracksBySession(sessionId);

  // --- Conversion helpers ---

  model.TrackPoint _toModel(Track row) => model.TrackPoint(
        lat: row.lat,
        lon: row.lon,
        altitude: row.altitude,
        speed: row.speed,
        heading: row.heading,
        accuracy: row.accuracy,
        timestamp: row.timestamp,
      );

  TracksCompanion _toCompanion(
    model.TrackPoint tp, {
    String? sessionId,
  }) =>
      TracksCompanion(
        sessionId: Value(sessionId),
        lat: Value(tp.lat),
        lon: Value(tp.lon),
        altitude: Value(tp.altitude),
        speed: Value(tp.speed),
        heading: Value(tp.heading),
        accuracy: Value(tp.accuracy),
        timestamp: Value(tp.timestamp),
      );
}

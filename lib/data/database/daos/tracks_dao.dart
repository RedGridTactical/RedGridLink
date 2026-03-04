import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/tracks_table.dart';

part 'tracks_dao.g.dart';

/// Data access object for [Tracks] table operations.
@DriftAccessor(tables: [Tracks])
class TracksDao extends DatabaseAccessor<AppDatabase> with _$TracksDaoMixin {
  TracksDao(super.db);

  /// Insert a new track point.
  Future<int> insertTrack(TracksCompanion track) =>
      into(tracks).insert(track);

  /// Insert multiple track points in a batch.
  Future<void> insertTracks(List<TracksCompanion> trackList) async {
    await batch((b) => b.insertAll(tracks, trackList));
  }

  /// Get all track points for a given session, ordered by timestamp.
  Future<List<Track>> getTracksBySession(String sessionId) =>
      (select(tracks)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  /// Watch track points for a given session.
  Stream<List<Track>> watchTracksBySession(String sessionId) =>
      (select(tracks)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .watch();

  /// Get track points between two timestamps.
  Future<List<Track>> getTracksBetween(DateTime start, DateTime end) =>
      (select(tracks)
            ..where((t) =>
                t.timestamp.isBiggerOrEqualValue(start) &
                t.timestamp.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  /// Delete track points older than the given date.
  Future<int> deleteOlderThan(DateTime cutoff) =>
      (delete(tracks)..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
          .go();

  /// Delete all tracks for a session.
  Future<int> deleteTracksBySession(String sessionId) =>
      (delete(tracks)..where((t) => t.sessionId.equals(sessionId))).go();
}

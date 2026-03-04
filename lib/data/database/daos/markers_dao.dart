import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/markers_table.dart';

part 'markers_dao.g.dart';

/// Data access object for [Markers] table operations.
@DriftAccessor(tables: [Markers])
class MarkersDao extends DatabaseAccessor<AppDatabase>
    with _$MarkersDaoMixin {
  MarkersDao(super.db);

  /// Get all markers for a given session.
  Future<List<Marker>> getMarkersBySession(String sessionId) =>
      (select(markers)..where((t) => t.sessionId.equals(sessionId))).get();

  /// Watch all markers for a given session.
  Stream<List<Marker>> watchMarkersBySession(String sessionId) =>
      (select(markers)..where((t) => t.sessionId.equals(sessionId))).watch();

  /// Get all unsynced markers.
  Future<List<Marker>> getUnsyncedMarkers() =>
      (select(markers)..where((t) => t.isSynced.equals(false))).get();

  /// Get a marker by its ID.
  Future<Marker?> getMarkerById(String id) =>
      (select(markers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert a new marker.
  Future<int> insertMarker(MarkersCompanion marker) =>
      into(markers).insert(marker);

  /// Update an existing marker.
  Future<bool> updateMarker(MarkersCompanion marker) =>
      (update(markers)..where((t) => t.id.equals(marker.id.value)))
          .write(marker)
          .then((rows) => rows > 0);

  /// Mark a marker as synced.
  Future<bool> markAsSynced(String id) =>
      (update(markers)..where((t) => t.id.equals(id)))
          .write(const MarkersCompanion(isSynced: Value(true)))
          .then((rows) => rows > 0);

  /// Delete a marker by ID.
  Future<int> deleteMarker(String id) =>
      (delete(markers)..where((t) => t.id.equals(id))).go();

  /// Delete all markers for a session.
  Future<int> deleteMarkersBySession(String sessionId) =>
      (delete(markers)..where((t) => t.sessionId.equals(sessionId))).go();
}

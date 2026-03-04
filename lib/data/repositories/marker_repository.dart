import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/markers_dao.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;

/// Repository for managing map markers.
///
/// Wraps [MarkersDao] and converts between Drift data classes
/// and the application's [model.Marker] model objects.
class MarkerRepository {
  final AppDatabase _db;

  MarkerRepository(this._db);

  MarkersDao get _dao => _db.markersDao;

  /// Get all markers for a session.
  Future<List<model.Marker>> getMarkersBySession(String sessionId) async {
    final rows = await _dao.getMarkersBySession(sessionId);
    return rows.map(_toModel).toList();
  }

  /// Watch all markers for a session.
  Stream<List<model.Marker>> watchMarkersBySession(String sessionId) =>
      _dao.watchMarkersBySession(sessionId).map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get all markers that have not been synced.
  Future<List<model.Marker>> getUnsyncedMarkers() async {
    final rows = await _dao.getUnsyncedMarkers();
    return rows.map(_toModel).toList();
  }

  /// Get a marker by ID.
  Future<model.Marker?> getMarkerById(String id) async {
    final row = await _dao.getMarkerById(id);
    return row != null ? _toModel(row) : null;
  }

  /// Create a new marker.
  Future<void> createMarker(model.Marker marker, {String? sessionId}) =>
      _dao.insertMarker(_toCompanion(marker, sessionId: sessionId));

  /// Update an existing marker.
  Future<bool> updateMarker(model.Marker marker, {String? sessionId}) =>
      _dao.updateMarker(_toCompanion(marker, sessionId: sessionId));

  /// Mark a marker as synced.
  Future<bool> markAsSynced(String id) => _dao.markAsSynced(id);

  /// Delete a marker by ID.
  Future<int> deleteMarker(String id) => _dao.deleteMarker(id);

  /// Delete all markers for a session.
  Future<int> deleteMarkersBySession(String sessionId) =>
      _dao.deleteMarkersBySession(sessionId);

  // --- Conversion helpers ---

  model.Marker _toModel(Marker row) => model.Marker(
        id: row.id,
        lat: row.lat,
        lon: row.lon,
        mgrs: row.mgrs,
        label: row.label,
        icon: model.MarkerIcon.fromString(row.icon),
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        color: row.color,
        isSynced: row.isSynced,
      );

  MarkersCompanion _toCompanion(
    model.Marker m, {
    String? sessionId,
  }) =>
      MarkersCompanion(
        id: Value(m.id),
        sessionId: Value(sessionId),
        lat: Value(m.lat),
        lon: Value(m.lon),
        mgrs: Value(m.mgrs),
        label: Value(m.label),
        icon: Value(m.icon.name),
        createdBy: Value(m.createdBy),
        createdAt: Value(m.createdAt),
        color: Value(m.color),
        isSynced: Value(m.isSynced),
      );
}

import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/map_regions_dao.dart';
import 'package:red_grid_link/data/models/map_region.dart' as model;

/// Repository for managing offline map region downloads.
///
/// Wraps [MapRegionsDao] and converts between Drift data classes
/// and the application's [model.MapRegion] model objects.
class MapRepository {
  final AppDatabase _db;

  MapRepository(this._db);

  MapRegionsDao get _dao => _db.mapRegionsDao;

  /// Get all map regions.
  Future<List<model.MapRegion>> getAllRegions() async {
    final rows = await _dao.getAllRegions();
    return rows.map(_toModel).toList();
  }

  /// Watch all map regions.
  Stream<List<model.MapRegion>> watchAllRegions() =>
      _dao.watchAllRegions().map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get only downloaded regions.
  Future<List<model.MapRegion>> getDownloadedRegions() async {
    final rows = await _dao.getDownloadedRegions();
    return rows.map(_toModel).toList();
  }

  /// Watch downloaded regions.
  Stream<List<model.MapRegion>> watchDownloadedRegions() =>
      _dao.watchDownloadedRegions().map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get a region by ID.
  Future<model.MapRegion?> getRegionById(String id) async {
    final row = await _dao.getRegionById(id);
    return row != null ? _toModel(row) : null;
  }

  /// Create a new map region entry.
  Future<void> createRegion(model.MapRegion region) =>
      _dao.insertRegion(_toCompanion(region));

  /// Update an existing region.
  Future<bool> updateRegion(model.MapRegion region) =>
      _dao.updateRegion(_toCompanion(region));

  /// Mark a region as downloaded with its file path and size.
  Future<bool> markAsDownloaded(
    String id, {
    required String filePath,
    required int sizeBytes,
  }) =>
      _dao.markAsDownloaded(id, filePath: filePath, sizeBytes: sizeBytes);

  /// Delete a region by ID.
  Future<int> deleteRegion(String id) => _dao.deleteRegion(id);

  // --- Conversion helpers ---

  model.MapRegion _toModel(MapRegion row) => model.MapRegion(
        id: row.id,
        name: row.name,
        bounds: model.MapBounds(
          north: row.boundsNorth,
          south: row.boundsSouth,
          east: row.boundsEast,
          west: row.boundsWest,
        ),
        minZoom: row.minZoom,
        maxZoom: row.maxZoom,
        sizeBytes: row.sizeBytes,
        downloadedAt: row.downloadedAt,
        filePath: row.filePath,
      );

  MapRegionsCompanion _toCompanion(model.MapRegion r) => MapRegionsCompanion(
        id: Value(r.id),
        name: Value(r.name),
        boundsNorth: Value(r.bounds.north),
        boundsSouth: Value(r.bounds.south),
        boundsEast: Value(r.bounds.east),
        boundsWest: Value(r.bounds.west),
        minZoom: Value(r.minZoom),
        maxZoom: Value(r.maxZoom),
        sizeBytes: Value(r.sizeBytes),
        downloadedAt: Value(r.downloadedAt),
        filePath: Value(r.filePath),
      );
}

import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/map_regions_table.dart';

part 'map_regions_dao.g.dart';

/// Data access object for [MapRegions] table operations.
@DriftAccessor(tables: [MapRegions])
class MapRegionsDao extends DatabaseAccessor<AppDatabase>
    with _$MapRegionsDaoMixin {
  MapRegionsDao(super.db);

  /// Get all map regions.
  Future<List<MapRegion>> getAllRegions() => select(mapRegions).get();

  /// Watch all map regions.
  Stream<List<MapRegion>> watchAllRegions() => select(mapRegions).watch();

  /// Get only downloaded regions (where downloadedAt is not null).
  Future<List<MapRegion>> getDownloadedRegions() =>
      (select(mapRegions)
            ..where((t) => t.downloadedAt.isNotNull()))
          .get();

  /// Watch downloaded regions.
  Stream<List<MapRegion>> watchDownloadedRegions() =>
      (select(mapRegions)
            ..where((t) => t.downloadedAt.isNotNull()))
          .watch();

  /// Get a region by its ID.
  Future<MapRegion?> getRegionById(String id) =>
      (select(mapRegions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Insert a new map region.
  Future<int> insertRegion(MapRegionsCompanion region) =>
      into(mapRegions).insert(region);

  /// Update an existing region.
  Future<bool> updateRegion(MapRegionsCompanion region) =>
      (update(mapRegions)..where((t) => t.id.equals(region.id.value)))
          .write(region)
          .then((rows) => rows > 0);

  /// Mark a region as downloaded with its file path and size.
  Future<bool> markAsDownloaded(
    String id, {
    required String filePath,
    required int sizeBytes,
  }) =>
      (update(mapRegions)..where((t) => t.id.equals(id)))
          .write(MapRegionsCompanion(
            filePath: Value(filePath),
            sizeBytes: Value(sizeBytes),
            downloadedAt: Value(DateTime.now()),
          ))
          .then((rows) => rows > 0);

  /// Delete a region by ID.
  Future<int> deleteRegion(String id) =>
      (delete(mapRegions)..where((t) => t.id.equals(id))).go();
}

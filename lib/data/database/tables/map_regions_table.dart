import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for downloaded offline map regions.
class MapRegions extends Table {
  /// Unique region ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Human-readable region name.
  TextColumn get name => text()();

  /// Northern boundary latitude.
  RealColumn get boundsNorth => real()();

  /// Southern boundary latitude.
  RealColumn get boundsSouth => real()();

  /// Eastern boundary longitude.
  RealColumn get boundsEast => real()();

  /// Western boundary longitude.
  RealColumn get boundsWest => real()();

  /// Minimum zoom level.
  IntColumn get minZoom => integer()();

  /// Maximum zoom level.
  IntColumn get maxZoom => integer()();

  /// File size in bytes (null until downloaded).
  IntColumn get sizeBytes => integer().nullable()();

  /// When the region was downloaded (null if not yet downloaded).
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  /// File system path to the downloaded tile data.
  TextColumn get filePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

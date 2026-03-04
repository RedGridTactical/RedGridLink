import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for map annotations (polylines and polygons).
class Annotations extends Table {
  /// Unique annotation ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Foreign key to sessions table (nullable for standalone annotations).
  TextColumn get sessionId => text().nullable()();

  /// Geometry type: polyline or polygon.
  TextColumn get type => text()();

  /// JSON-encoded array of {lat, lon} points.
  TextColumn get pointsJson => text()();

  /// Color as an ARGB integer.
  IntColumn get color => integer().withDefault(const Constant(0xFFFF0000))();

  /// Line stroke width.
  RealColumn get strokeWidth => real().withDefault(const Constant(2.0))();

  /// Optional label.
  TextColumn get label => text().nullable()();

  /// ID of the peer that created this annotation.
  TextColumn get createdBy => text()();

  /// When the annotation was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Whether this annotation has been synced to peers.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

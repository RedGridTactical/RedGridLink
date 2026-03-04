import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for synced map markers.
class Markers extends Table {
  /// Unique marker ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Foreign key to sessions table (nullable for standalone markers).
  TextColumn get sessionId => text().nullable()();

  /// GPS latitude.
  RealColumn get lat => real()();

  /// GPS longitude.
  RealColumn get lon => real()();

  /// MGRS coordinate string.
  TextColumn get mgrs => text()();

  /// User-assigned label.
  TextColumn get label => text()();

  /// Icon type: waypoint, danger, camp, rally, find, checkpoint, stand, custom.
  TextColumn get icon => text().withDefault(const Constant('waypoint'))();

  /// ID of the peer that created this marker.
  TextColumn get createdBy => text()();

  /// When the marker was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Color as an ARGB integer.
  IntColumn get color => integer().withDefault(const Constant(0xFFFF0000))();

  /// Whether this marker has been synced to peers.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

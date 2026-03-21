import 'package:drift/drift.dart';

/// Drift table for geofence boundary crossing events.
class BoundaryEvents extends Table {
  /// Unique event ID (UUID v4).
  TextColumn get id => text()();

  /// Foreign key to sessions table.
  TextColumn get sessionId => text()();

  /// ID of the peer that triggered the event.
  TextColumn get peerId => text()();

  /// Callsign of the peer at the time of the event.
  TextColumn get callsign => text()();

  /// When the boundary event occurred.
  DateTimeColumn get timestamp => dateTime()();

  /// GPS latitude of the crossing point.
  RealColumn get lat => real()();

  /// GPS longitude of the crossing point.
  RealColumn get lon => real()();

  @override
  Set<Column> get primaryKey => {id};
}

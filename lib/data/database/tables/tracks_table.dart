import 'package:drift/drift.dart';

/// Drift table for GPS track points.
class Tracks extends Table {
  /// Auto-incrementing integer primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to sessions table (nullable for standalone tracks).
  TextColumn get sessionId => text().nullable()();

  /// GPS latitude.
  RealColumn get lat => real()();

  /// GPS longitude.
  RealColumn get lon => real()();

  /// GPS altitude in meters.
  RealColumn get altitude => real().nullable()();

  /// Speed in m/s.
  RealColumn get speed => real().nullable()();

  /// Compass heading in degrees.
  RealColumn get heading => real().nullable()();

  /// GPS accuracy in meters.
  RealColumn get accuracy => real().nullable()();

  /// When this track point was recorded.
  DateTimeColumn get timestamp => dateTime()();
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for connected peers in a Field Link session.
class Peers extends Table {
  /// Unique peer ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Foreign key to sessions table.
  TextColumn get sessionId => text()();

  /// User-configured display name.
  TextColumn get displayName => text()();

  /// Device platform: android, ios, or unknown.
  TextColumn get deviceType => text().withDefault(const Constant('unknown'))();

  /// GPS latitude.
  RealColumn get lat => real().nullable()();

  /// GPS longitude.
  RealColumn get lon => real().nullable()();

  /// GPS altitude in meters.
  RealColumn get altitude => real().nullable()();

  /// Speed in m/s.
  RealColumn get speed => real().nullable()();

  /// Compass heading in degrees.
  RealColumn get heading => real().nullable()();

  /// GPS accuracy in meters.
  RealColumn get accuracy => real().nullable()();

  /// Raw MGRS coordinate string.
  TextColumn get mgrsRaw => text().nullable()();

  /// Last time a position update was received.
  DateTimeColumn get lastSeen => dateTime()();

  /// Whether the peer is currently connected.
  BoolColumn get isConnected => boolean().withDefault(const Constant(true))();

  /// Battery level 0-100.
  IntColumn get batteryLevel => integer().nullable()();

  /// Sync mode: expedition or active.
  TextColumn get syncMode =>
      text().withDefault(const Constant('expedition'))();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for Field Link sessions.
class Sessions extends Table {
  /// Unique session ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Human-readable session name.
  TextColumn get name => text()();

  /// Security mode: open, pin, or qr.
  TextColumn get securityMode => text().withDefault(const Constant('open'))();

  /// Optional 4-digit PIN (for pin security mode).
  TextColumn get pin => text().nullable()();

  /// Optional session encryption key (for qr security mode).
  TextColumn get sessionKey => text().nullable()();

  /// When the session was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Operational mode: sar, backcountry, hunting, or training.
  TextColumn get operationalMode => text().withDefault(const Constant('sar'))();

  /// Whether this session is currently active.
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift table for completed session history records.
///
/// Stores a summary of each completed Field Link session for
/// review, AAR generation, and "Resume" functionality.
class SessionHistoryEntries extends Table {
  /// Unique session history entry ID (UUID v4).
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Human-readable session name.
  TextColumn get name => text()();

  /// Operational mode used during the session (sar, backcountry, etc.).
  TextColumn get mode => text().withDefault(const Constant('sar'))();

  /// When the session started (epoch ms).
  IntColumn get startTime => integer()();

  /// When the session ended (epoch ms). Null if still in progress.
  IntColumn get endTime => integer().nullable()();

  /// Number of peers that participated in the session.
  IntColumn get peerCount => integer().withDefault(const Constant(0))();

  /// Number of markers placed during the session.
  IntColumn get markerCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

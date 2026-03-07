import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/session_history_table.dart';

part 'session_history_dao.g.dart';

/// Data access object for [SessionHistoryEntries] table operations.
@DriftAccessor(tables: [SessionHistoryEntries])
class SessionHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SessionHistoryDaoMixin {
  SessionHistoryDao(super.db);

  /// Watch all session history entries ordered by start time (newest first).
  Stream<List<SessionHistoryEntry>> watchAll() =>
      (select(sessionHistoryEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .watch();

  /// Get all session history entries ordered by start time (newest first).
  Future<List<SessionHistoryEntry>> getAll() =>
      (select(sessionHistoryEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .get();

  /// Get a single entry by its ID.
  Future<SessionHistoryEntry?> getById(String id) =>
      (select(sessionHistoryEntries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Get the most recent N session history entries.
  Future<List<SessionHistoryEntry>> getRecent(int limit) =>
      (select(sessionHistoryEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(limit))
          .get();

  /// Insert a new session history entry.
  Future<int> insertEntry(SessionHistoryEntriesCompanion entry) =>
      into(sessionHistoryEntries).insert(entry);

  /// Update an existing session history entry (e.g., to set endTime).
  Future<bool> updateEntry(SessionHistoryEntriesCompanion entry) =>
      (update(sessionHistoryEntries)
            ..where((t) => t.id.equals(entry.id.value)))
          .write(entry)
          .then((rows) => rows > 0);

  /// Delete a session history entry by its ID.
  Future<int> deleteEntry(String id) =>
      (delete(sessionHistoryEntries)..where((t) => t.id.equals(id))).go();

  /// Delete all session history entries.
  Future<int> deleteAll() => delete(sessionHistoryEntries).go();
}

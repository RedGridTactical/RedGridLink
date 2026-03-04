import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/sessions_table.dart';

part 'sessions_dao.g.dart';

/// Data access object for [Sessions] table operations.
@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  /// Watch all sessions ordered by creation date (newest first).
  Stream<List<Session>> watchAllSessions() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Get all sessions.
  Future<List<Session>> getAllSessions() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get a single session by its ID.
  Future<Session?> getSessionById(String id) =>
      (select(sessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Watch a single session by its ID.
  Stream<Session?> watchSessionById(String id) =>
      (select(sessions)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  /// Get the currently active session, if any.
  Future<Session?> getActiveSession() =>
      (select(sessions)..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();

  /// Watch the currently active session.
  Stream<Session?> watchActiveSession() =>
      (select(sessions)..where((t) => t.isActive.equals(true)))
          .watchSingleOrNull();

  /// Insert a new session.
  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  /// Update an existing session.
  Future<bool> updateSession(SessionsCompanion session) =>
      (update(sessions)..where((t) => t.id.equals(session.id.value)))
          .write(session)
          .then((rows) => rows > 0);

  /// Deactivate all sessions (set isActive = false).
  Future<int> deactivateAll() =>
      (update(sessions)).write(const SessionsCompanion(
        isActive: Value(false),
      ));

  /// Delete a session by its ID.
  Future<int> deleteSession(String id) =>
      (delete(sessions)..where((t) => t.id.equals(id))).go();
}

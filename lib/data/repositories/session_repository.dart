import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/sessions_dao.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/session.dart' as model;

/// Repository for managing Field Link sessions.
///
/// Wraps [SessionsDao] and converts between Drift data classes
/// and the application's [model.Session] model objects.
class SessionRepository {
  final AppDatabase _db;

  SessionRepository(this._db);

  SessionsDao get _dao => _db.sessionsDao;

  /// Get all sessions, newest first.
  Future<List<model.Session>> getAllSessions() async {
    final rows = await _dao.getAllSessions();
    return rows.map(_toModel).toList();
  }

  /// Watch all sessions, newest first.
  Stream<List<model.Session>> watchAllSessions() =>
      _dao.watchAllSessions().map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get a single session by ID.
  Future<model.Session?> getSessionById(String id) async {
    final row = await _dao.getSessionById(id);
    return row != null ? _toModel(row) : null;
  }

  /// Watch a single session by ID.
  Stream<model.Session?> watchSessionById(String id) =>
      _dao.watchSessionById(id).map(
        (row) => row != null ? _toModel(row) : null,
      );

  /// Get the currently active session.
  Future<model.Session?> getActiveSession() async {
    final row = await _dao.getActiveSession();
    return row != null ? _toModel(row) : null;
  }

  /// Watch the currently active session.
  Stream<model.Session?> watchActiveSession() =>
      _dao.watchActiveSession().map(
        (row) => row != null ? _toModel(row) : null,
      );

  /// Create a new session, deactivating all others first.
  Future<model.Session> createSession(model.Session session) async {
    await _dao.deactivateAll();
    await _dao.insertSession(_toCompanion(session));
    return session;
  }

  /// Update an existing session.
  Future<bool> updateSession(model.Session session) =>
      _dao.updateSession(_toCompanion(session));

  /// Activate a session by ID, deactivating all others.
  Future<void> activateSession(String id) async {
    await _dao.deactivateAll();
    await _dao.updateSession(SessionsCompanion(
      id: Value(id),
      isActive: const Value(true),
    ));
  }

  /// Deactivate all sessions.
  Future<void> deactivateAll() => _dao.deactivateAll();

  /// Delete a session by ID.
  Future<int> deleteSession(String id) => _dao.deleteSession(id);

  // --- Conversion helpers ---

  model.Session _toModel(Session row) => model.Session(
        id: row.id,
        name: row.name,
        securityMode: model.SecurityMode.fromString(row.securityMode),
        pin: row.pin,
        sessionKey: row.sessionKey,
        createdAt: row.createdAt,
        operationalMode: OperationalMode.values.firstWhere(
          (m) => m.id == row.operationalMode,
          orElse: () => OperationalMode.sar,
        ),
        isActive: row.isActive,
      );

  SessionsCompanion _toCompanion(model.Session s) => SessionsCompanion(
        id: Value(s.id),
        name: Value(s.name),
        securityMode: Value(s.securityMode.name),
        pin: Value(s.pin),
        sessionKey: Value(s.sessionKey),
        createdAt: Value(s.createdAt),
        operationalMode: Value(s.operationalMode.id),
        isActive: Value(s.isActive),
      );
}

import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/boundary_events_table.dart';

part 'boundary_event_dao.g.dart';

/// Data access object for [BoundaryEvents] table operations.
@DriftAccessor(tables: [BoundaryEvents])
class BoundaryEventDao extends DatabaseAccessor<AppDatabase>
    with _$BoundaryEventDaoMixin {
  BoundaryEventDao(super.db);

  /// Insert a new boundary crossing event.
  Future<int> insertEvent(BoundaryEventsCompanion event) =>
      into(boundaryEvents).insert(event);

  /// Get all boundary events for a given session.
  Future<List<BoundaryEvent>> getEventsForSession(String sessionId) =>
      (select(boundaryEvents)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();

  /// Watch all boundary events for a given session.
  Stream<List<BoundaryEvent>> watchEventsForSession(String sessionId) =>
      (select(boundaryEvents)
            ..where((t) => t.sessionId.equals(sessionId)))
          .watch();
}

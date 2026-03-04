import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/annotations_table.dart';

part 'annotations_dao.g.dart';

/// Data access object for [Annotations] table operations.
@DriftAccessor(tables: [Annotations])
class AnnotationsDao extends DatabaseAccessor<AppDatabase>
    with _$AnnotationsDaoMixin {
  AnnotationsDao(super.db);

  /// Get all annotations for a given session.
  Future<List<Annotation>> getAnnotationsBySession(String sessionId) =>
      (select(annotations)..where((t) => t.sessionId.equals(sessionId)))
          .get();

  /// Watch all annotations for a given session.
  Stream<List<Annotation>> watchAnnotationsBySession(String sessionId) =>
      (select(annotations)..where((t) => t.sessionId.equals(sessionId)))
          .watch();

  /// Get all unsynced annotations.
  Future<List<Annotation>> getUnsyncedAnnotations() =>
      (select(annotations)..where((t) => t.isSynced.equals(false))).get();

  /// Get an annotation by its ID.
  Future<Annotation?> getAnnotationById(String id) =>
      (select(annotations)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Insert a new annotation.
  Future<int> insertAnnotation(AnnotationsCompanion annotation) =>
      into(annotations).insert(annotation);

  /// Update an existing annotation.
  Future<bool> updateAnnotation(AnnotationsCompanion annotation) =>
      (update(annotations)
            ..where((t) => t.id.equals(annotation.id.value)))
          .write(annotation)
          .then((rows) => rows > 0);

  /// Mark an annotation as synced.
  Future<bool> markAsSynced(String id) =>
      (update(annotations)..where((t) => t.id.equals(id)))
          .write(const AnnotationsCompanion(isSynced: Value(true)))
          .then((rows) => rows > 0);

  /// Delete an annotation by ID.
  Future<int> deleteAnnotation(String id) =>
      (delete(annotations)..where((t) => t.id.equals(id))).go();

  /// Delete all annotations for a session.
  Future<int> deleteAnnotationsBySession(String sessionId) =>
      (delete(annotations)..where((t) => t.sessionId.equals(sessionId)))
          .go();
}

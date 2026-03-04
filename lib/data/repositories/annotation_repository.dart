import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/annotations_dao.dart';
import 'package:red_grid_link/data/models/annotation.dart' as model;

/// Repository for managing map annotations (polylines and polygons).
///
/// Wraps [AnnotationsDao] and converts between Drift data classes
/// and the application's [model.Annotation] model objects.
///
/// Annotation points are stored as a JSON-encoded text column
/// containing an array of `{lat, lon}` objects.
class AnnotationRepository {
  final AppDatabase _db;

  AnnotationRepository(this._db);

  AnnotationsDao get _dao => _db.annotationsDao;

  /// Get all annotations for a session.
  Future<List<model.Annotation>> getAnnotationsBySession(
    String sessionId,
  ) async {
    final rows = await _dao.getAnnotationsBySession(sessionId);
    return rows.map(_toModel).toList();
  }

  /// Watch all annotations for a session.
  Stream<List<model.Annotation>> watchAnnotationsBySession(
    String sessionId,
  ) =>
      _dao.watchAnnotationsBySession(sessionId).map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get all annotations that have not been synced.
  Future<List<model.Annotation>> getUnsyncedAnnotations() async {
    final rows = await _dao.getUnsyncedAnnotations();
    return rows.map(_toModel).toList();
  }

  /// Get an annotation by ID.
  Future<model.Annotation?> getAnnotationById(String id) async {
    final row = await _dao.getAnnotationById(id);
    return row != null ? _toModel(row) : null;
  }

  /// Create a new annotation.
  Future<void> createAnnotation(
    model.Annotation annotation, {
    String? sessionId,
  }) =>
      _dao.insertAnnotation(
        _toCompanion(annotation, sessionId: sessionId),
      );

  /// Update an existing annotation.
  Future<bool> updateAnnotation(
    model.Annotation annotation, {
    String? sessionId,
  }) =>
      _dao.updateAnnotation(
        _toCompanion(annotation, sessionId: sessionId),
      );

  /// Mark an annotation as synced.
  Future<bool> markAsSynced(String id) => _dao.markAsSynced(id);

  /// Delete an annotation by ID.
  Future<int> deleteAnnotation(String id) => _dao.deleteAnnotation(id);

  /// Delete all annotations for a session.
  Future<int> deleteAnnotationsBySession(String sessionId) =>
      _dao.deleteAnnotationsBySession(sessionId);

  // --- Conversion helpers ---

  model.Annotation _toModel(Annotation row) {
    final pointsList = (jsonDecode(row.pointsJson) as List<dynamic>)
        .map((p) =>
            model.AnnotationPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    return model.Annotation(
      id: row.id,
      type: model.AnnotationType.fromString(row.type),
      points: pointsList,
      color: row.color,
      strokeWidth: row.strokeWidth,
      label: row.label,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      isSynced: row.isSynced,
    );
  }

  AnnotationsCompanion _toCompanion(
    model.Annotation a, {
    String? sessionId,
  }) =>
      AnnotationsCompanion(
        id: Value(a.id),
        sessionId: Value(sessionId),
        type: Value(a.type.name),
        pointsJson: Value(
          jsonEncode(a.points.map((p) => p.toJson()).toList()),
        ),
        color: Value(a.color),
        strokeWidth: Value(a.strokeWidth),
        label: Value(a.label),
        createdBy: Value(a.createdBy),
        createdAt: Value(a.createdAt),
        isSynced: Value(a.isSynced),
      );
}

/// Integration coverage for the audit's annotation persistence and
/// track lifecycle fixes. Uses an in-memory Drift database so the
/// repository wiring runs end-to-end without touching a real device.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/database/app_database.dart';
// Drift's generated `Annotation` data class collides with the model
// `Annotation`; namespace the model so the rest of the file stays
// readable.
import 'package:red_grid_link/data/models/annotation.dart' as model;
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/data/repositories/annotation_repository.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('audit 2026-05-03 — AnnotationRepository round-trip', () {
    late AppDatabase db;
    late AnnotationRepository repo;

    setUp(() {
      db = _inMemoryDb();
      repo = AnnotationRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    model.Annotation makeAnnotation(String id, {bool isSynced = false}) =>
        model.Annotation(
          id: id,
          type: model.AnnotationType.polyline,
          points: const [
            model.AnnotationPoint(lat: 35.0, lon: -79.0),
            model.AnnotationPoint(lat: 35.1, lon: -79.1),
          ],
          createdBy: 'peer-a',
          createdAt: DateTime.utc(2026, 5, 1, 12, 0),
          isSynced: isSynced,
        );

    test('createAnnotation persists and getAnnotationById returns it',
        () async {
      const sessionId = 'sess-1';
      await repo.createAnnotation(makeAnnotation('ann-1'),
          sessionId: sessionId);

      final got = await repo.getAnnotationById('ann-1');
      expect(got, isNotNull);
      expect(got!.id, 'ann-1');
      expect(got.points.length, 2);
      expect(got.createdBy, 'peer-a');
    });

    test('updateAnnotation marks isSynced flag (mirrors inbound CRDT path)',
        () async {
      const sessionId = 'sess-1';
      await repo.createAnnotation(makeAnnotation('ann-2'),
          sessionId: sessionId);
      await repo.updateAnnotation(
        makeAnnotation('ann-2', isSynced: true),
        sessionId: sessionId,
      );

      final got = await repo.getAnnotationById('ann-2');
      expect(got, isNotNull);
      expect(got!.isSynced, isTrue);
    });

    test('deleteAnnotation removes the row (mirrors tombstone application)',
        () async {
      const sessionId = 'sess-1';
      await repo.createAnnotation(makeAnnotation('ann-3'),
          sessionId: sessionId);

      final before = await repo.getAnnotationById('ann-3');
      expect(before, isNotNull);

      await repo.deleteAnnotation('ann-3');

      final after = await repo.getAnnotationById('ann-3');
      expect(after, isNull);
    });

    test('getAnnotationsBySession lists every annotation for that session',
        () async {
      const sessionId = 'sess-1';
      await repo.createAnnotation(makeAnnotation('ann-1'),
          sessionId: sessionId);
      await repo.createAnnotation(makeAnnotation('ann-2'),
          sessionId: sessionId);
      await repo.createAnnotation(makeAnnotation('ann-3'),
          sessionId: 'sess-2'); // different session

      final got = await repo.getAnnotationsBySession(sessionId);
      expect(got.length, 2);
      expect(got.map((a) => a.id), containsAll(['ann-1', 'ann-2']));
    });
  });

  group('audit 2026-05-03 — TrackRepository session-scoped recording', () {
    late AppDatabase db;
    late TrackRepository repo;

    setUp(() {
      db = _inMemoryDb();
      repo = TrackRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    TrackPoint point(double lat, double lon) => TrackPoint(
          lat: lat,
          lon: lon,
          accuracy: 5.0,
          timestamp: DateTime.utc(2026, 5, 1, 12, 0),
        );

    test('recordTrackPoint persists with sessionId set by FieldLink lifecycle',
        () async {
      const sessionId = 'sess-1';
      await repo.recordTrackPoint(point(35.0, -79.0), sessionId: sessionId);
      await repo.recordTrackPoint(point(35.1, -79.1), sessionId: sessionId);

      final got = await repo.getTracksBySession(sessionId);
      expect(got.length, 2);
      expect(got.first.lat, closeTo(35.0, 1e-9));
      expect(got.last.lat, closeTo(35.1, 1e-9));
    });

    test('points without a sessionId do NOT appear in session queries',
        () async {
      await repo.recordTrackPoint(point(36.0, -80.0)); // no sessionId
      final got = await repo.getTracksBySession('sess-1');
      expect(got, isEmpty);
    });

    test('two sessions keep their tracks isolated', () async {
      await repo.recordTrackPoint(point(35.0, -79.0), sessionId: 'sess-A');
      await repo.recordTrackPoint(point(35.5, -79.5), sessionId: 'sess-A');
      await repo.recordTrackPoint(point(40.0, -80.0), sessionId: 'sess-B');

      final a = await repo.getTracksBySession('sess-A');
      final b = await repo.getTracksBySession('sess-B');
      expect(a.length, 2);
      expect(b.length, 1);
    });
  });
}

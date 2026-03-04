import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/services/field_link/sync/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();

  // Helper factories
  Position makePosition({
    double lat = 35.0,
    double lon = -79.0,
    DateTime? timestamp,
  }) =>
      Position(
        lat: lat,
        lon: lon,
        mgrsRaw: '',
        mgrsFormatted: '',
        timestamp: timestamp ?? DateTime(2024, 3, 1),
      );

  Marker makeMarker({
    String id = 'm1',
    String createdBy = 'a',
    DateTime? createdAt,
  }) =>
      Marker(
        id: id,
        lat: 35.0,
        lon: -79.0,
        createdBy: createdBy,
        createdAt: createdAt ?? DateTime(2024, 3, 1),
      );

  Annotation makeAnnotation({
    String id = 'ann1',
    String createdBy = 'a',
    DateTime? createdAt,
  }) =>
      Annotation(
        id: id,
        type: AnnotationType.polyline,
        points: const [AnnotationPoint(lat: 35.0, lon: -79.0)],
        createdBy: createdBy,
        createdAt: createdAt ?? DateTime(2024, 3, 1),
      );

  // -------------------------------------------------------------------------
  // isRemoteNewer
  // -------------------------------------------------------------------------
  group('isRemoteNewer', () {
    test('remote newer timestamp returns true', () {
      expect(
        resolver.isRemoteNewer(
          DateTime(2024, 1, 1),
          'a',
          DateTime(2024, 1, 2),
          'b',
        ),
        isTrue,
      );
    });

    test('remote older timestamp returns false', () {
      expect(
        resolver.isRemoteNewer(
          DateTime(2024, 1, 2),
          'a',
          DateTime(2024, 1, 1),
          'b',
        ),
        isFalse,
      );
    });

    test('equal timestamps — higher remoteId returns true', () {
      final ts = DateTime(2024, 1, 1);
      expect(resolver.isRemoteNewer(ts, 'a', ts, 'b'), isTrue);
    });

    test('equal timestamps — lower remoteId returns false', () {
      final ts = DateTime(2024, 1, 1);
      expect(resolver.isRemoteNewer(ts, 'b', ts, 'a'), isFalse);
    });

    test('equal timestamps and IDs returns false', () {
      final ts = DateTime(2024, 1, 1);
      expect(resolver.isRemoteNewer(ts, 'a', ts, 'a'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // resolvePosition
  // -------------------------------------------------------------------------
  group('resolvePosition', () {
    test('keeps local when local is newer', () {
      final local = makePosition(
        lat: 35.0,
        timestamp: DateTime(2024, 1, 2),
      );
      final remote = makePosition(
        lat: 36.0,
        timestamp: DateTime(2024, 1, 1),
      );

      final result = resolver.resolvePosition(local, remote, 'a', 'b');
      expect(result.lat, 35.0);
    });

    test('takes remote when remote is newer', () {
      final local = makePosition(
        lat: 35.0,
        timestamp: DateTime(2024, 1, 1),
      );
      final remote = makePosition(
        lat: 36.0,
        timestamp: DateTime(2024, 1, 2),
      );

      final result = resolver.resolvePosition(local, remote, 'a', 'b');
      expect(result.lat, 36.0);
    });

    test('tiebreaker: higher device ID wins', () {
      final ts = DateTime(2024, 1, 1);
      final local = makePosition(lat: 35.0, timestamp: ts);
      final remote = makePosition(lat: 36.0, timestamp: ts);

      // 'b' > 'a', so remote wins.
      final result = resolver.resolvePosition(local, remote, 'a', 'b');
      expect(result.lat, 36.0);
    });
  });

  // -------------------------------------------------------------------------
  // resolveMarker
  // -------------------------------------------------------------------------
  group('resolveMarker', () {
    test('keeps local when local is newer', () {
      final local = makeMarker(
        id: 'm1',
        createdBy: 'a',
        createdAt: DateTime(2024, 1, 2),
      );
      final remote = makeMarker(
        id: 'm1',
        createdBy: 'b',
        createdAt: DateTime(2024, 1, 1),
      );

      final result = resolver.resolveMarker(local, remote);
      expect(result.createdBy, 'a');
    });

    test('takes remote when remote is newer', () {
      final local = makeMarker(
        id: 'm1',
        createdBy: 'a',
        createdAt: DateTime(2024, 1, 1),
      );
      final remote = makeMarker(
        id: 'm1',
        createdBy: 'b',
        createdAt: DateTime(2024, 1, 2),
      );

      final result = resolver.resolveMarker(local, remote);
      expect(result.createdBy, 'b');
    });

    test('tiebreaker: higher createdBy wins', () {
      final ts = DateTime(2024, 1, 1);
      final local = makeMarker(id: 'm1', createdBy: 'a', createdAt: ts);
      final remote = makeMarker(id: 'm1', createdBy: 'b', createdAt: ts);

      final result = resolver.resolveMarker(local, remote);
      expect(result.createdBy, 'b');
    });
  });

  // -------------------------------------------------------------------------
  // resolveAnnotation
  // -------------------------------------------------------------------------
  group('resolveAnnotation', () {
    test('keeps local when local is newer', () {
      final local = makeAnnotation(
        id: 'a1',
        createdBy: 'a',
        createdAt: DateTime(2024, 1, 2),
      );
      final remote = makeAnnotation(
        id: 'a1',
        createdBy: 'b',
        createdAt: DateTime(2024, 1, 1),
      );

      final result = resolver.resolveAnnotation(local, remote);
      expect(result.createdBy, 'a');
    });

    test('takes remote when remote is newer', () {
      final local = makeAnnotation(
        id: 'a1',
        createdBy: 'a',
        createdAt: DateTime(2024, 1, 1),
      );
      final remote = makeAnnotation(
        id: 'a1',
        createdBy: 'b',
        createdAt: DateTime(2024, 1, 2),
      );

      final result = resolver.resolveAnnotation(local, remote);
      expect(result.createdBy, 'b');
    });
  });
}

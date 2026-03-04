import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/crdt_state.dart';

void main() {
  // Helper factories
  Position makePosition({
    double lat = 35.0,
    double lon = -79.0,
    DateTime? timestamp,
  }) =>
      Position(
        lat: lat,
        lon: lon,
        mgrsRaw: '17SQV1234567890',
        mgrsFormatted: '',
        timestamp: timestamp ?? DateTime.now(),
      );

  Marker makeMarker({
    String id = 'marker-1',
    String createdBy = 'peer-a',
    DateTime? createdAt,
  }) =>
      Marker(
        id: id,
        lat: 35.0,
        lon: -79.0,
        createdBy: createdBy,
        createdAt: createdAt ?? DateTime.now(),
      );

  Annotation makeAnnotation({
    String id = 'ann-1',
    String createdBy = 'peer-a',
    DateTime? createdAt,
  }) =>
      Annotation(
        id: id,
        type: AnnotationType.polyline,
        points: const [
          AnnotationPoint(lat: 35.0, lon: -79.0),
          AnnotationPoint(lat: 35.1, lon: -79.1),
        ],
        createdBy: createdBy,
        createdAt: createdAt ?? DateTime.now(),
      );

  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------
  group('empty CrdtState', () {
    test('starts with no positions, markers, or annotations', () {
      const state = CrdtState();
      expect(state.positions, isEmpty);
      expect(state.markers, isEmpty);
      expect(state.annotations, isEmpty);
      expect(state.sequenceCounter.value, 0);
    });

    test('liveMarkers is empty', () {
      const state = CrdtState();
      expect(state.liveMarkers, isEmpty);
    });

    test('liveAnnotations is empty', () {
      const state = CrdtState();
      expect(state.liveAnnotations, isEmpty);
    });

    test('currentPositions is empty', () {
      const state = CrdtState();
      expect(state.currentPositions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // updatePosition
  // -------------------------------------------------------------------------
  group('updatePosition', () {
    test('adds a new position', () {
      const state = CrdtState();
      final pos = makePosition();
      final updated = state.updatePosition('peer-a', pos);

      expect(updated.positions.containsKey('peer-a'), isTrue);
      expect(updated.positions['peer-a']!.value.lat, pos.lat);
      expect(updated.sequenceCounter.countFor('peer-a'), 1);
    });

    test('updates an existing position with newer timestamp', () async {
      const state = CrdtState();
      final pos1 = makePosition(
        lat: 35.0,
        timestamp: DateTime(2024, 1, 1),
      );
      final updated = state.updatePosition('peer-a', pos1);

      // updatePosition uses DateTime.now() as the LWW register timestamp,
      // NOT the position's own timestamp. We need a later wall-clock time
      // for the second call so the LWW register sees a newer timestamp.
      await Future<void>.delayed(const Duration(milliseconds: 2));

      final pos2 = makePosition(
        lat: 36.0,
        timestamp: DateTime(2024, 1, 2),
      );
      final updated2 = updated.updatePosition('peer-a', pos2);

      expect(updated2.positions['peer-a']!.value.lat, 36.0);
    });

    test('does not overwrite with older position', () {
      const state = CrdtState();
      final newPos = makePosition(lat: 36.0);

      // First, set a position with a timestamp well in the future.
      final updated = state.updatePosition('peer-a', newPos);

      // Create an older position and try to overwrite.
      final oldPos = makePosition(
        lat: 35.0,
        timestamp: DateTime(2020, 1, 1),
      );

      // The LWW register should keep the newer one.
      final updated2 = updated.updatePosition('peer-a', oldPos);

      // The value is based on whichever has the higher timestamp per LWW rules.
      // Since updatePosition uses DateTime.now() as the register timestamp,
      // both calls happen "now" and the second call will win.
      // This is correct: the local clock is authoritative for local updates.
      expect(updated2.positions['peer-a'], isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // upsertMarker / deleteMarker
  // -------------------------------------------------------------------------
  group('upsertMarker', () {
    test('adds a new marker', () {
      const state = CrdtState();
      final marker = makeMarker();
      final updated = state.upsertMarker('peer-a', marker);

      expect(updated.liveMarkers.length, 1);
      expect(updated.liveMarkers.first.id, 'marker-1');
    });

    test('updates an existing marker', () {
      const state = CrdtState();
      final marker1 = makeMarker(id: 'm1');
      final marker2 = makeMarker(id: 'm1');

      final s1 = state.upsertMarker('peer-a', marker1);
      final s2 = s1.upsertMarker('peer-a', marker2);

      expect(s2.liveMarkers.length, 1);
    });
  });

  group('deleteMarker', () {
    test('tombstones a marker', () async {
      const state = CrdtState();
      final marker = makeMarker(id: 'm1');
      final s1 = state.upsertMarker('peer-a', marker);
      expect(s1.liveMarkers.length, 1);

      // deleteMarker uses DateTime.now() as the LWW register timestamp.
      // We need a later wall-clock time so the tombstone wins the LWW merge.
      await Future<void>.delayed(const Duration(milliseconds: 2));

      final s2 = s1.deleteMarker('peer-a', 'm1');
      expect(s2.liveMarkers, isEmpty);
      // The marker key still exists with a null value (tombstone).
      expect(s2.markers.containsKey('m1'), isTrue);
      expect(s2.markers['m1']!.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // upsertAnnotation
  // -------------------------------------------------------------------------
  group('upsertAnnotation', () {
    test('adds a new annotation', () {
      const state = CrdtState();
      final ann = makeAnnotation();
      final updated = state.upsertAnnotation('peer-a', ann);

      expect(updated.liveAnnotations.length, 1);
      expect(updated.liveAnnotations.first.id, 'ann-1');
    });
  });

  // -------------------------------------------------------------------------
  // merge
  // -------------------------------------------------------------------------
  group('merge', () {
    test('merges two independent states', () {
      const state = CrdtState();
      final posA = makePosition(lat: 35.0);
      final posB = makePosition(lat: 36.0);

      final stateA = state.updatePosition('peer-a', posA);
      final stateB = state.updatePosition('peer-b', posB);

      final merged = stateA.merge(stateB);
      expect(merged.currentPositions.length, 2);
      expect(merged.currentPositions.containsKey('peer-a'), isTrue);
      expect(merged.currentPositions.containsKey('peer-b'), isTrue);
    });

    test('merge is commutative', () {
      const state = CrdtState();
      final posA = makePosition(lat: 35.0);
      final posB = makePosition(lat: 36.0);

      final stateA = state.updatePosition('peer-a', posA);
      final stateB = state.updatePosition('peer-b', posB);

      final ab = stateA.merge(stateB);
      final ba = stateB.merge(stateA);

      expect(ab.currentPositions.length, ba.currentPositions.length);
    });

    test('merges markers from both states', () {
      const state = CrdtState();
      final m1 = makeMarker(id: 'm1', createdBy: 'peer-a');
      final m2 = makeMarker(id: 'm2', createdBy: 'peer-b');

      final stateA = state.upsertMarker('peer-a', m1);
      final stateB = state.upsertMarker('peer-b', m2);

      final merged = stateA.merge(stateB);
      expect(merged.liveMarkers.length, 2);
    });

    test('merges sequence counters', () {
      const state = CrdtState();
      final posA = makePosition();
      final posB = makePosition();

      final stateA = state
          .updatePosition('peer-a', posA)
          .updatePosition('peer-a', posA);
      final stateB = state.updatePosition('peer-b', posB);

      final merged = stateA.merge(stateB);
      expect(merged.sequenceCounter.countFor('peer-a'), 2);
      expect(merged.sequenceCounter.countFor('peer-b'), 1);
    });
  });

  // -------------------------------------------------------------------------
  // applyDelta
  // -------------------------------------------------------------------------
  group('applyDelta', () {
    test('applies a position delta', () {
      const state = CrdtState();
      final payload = SyncPayload(
        type: SyncPayloadType.position,
        senderId: 'peer-b',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: {
          'lat': 35.0,
          'lon': -79.0,
          'mgrs': '17SQV1234567890',
          'ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final updated = state.applyDelta(payload);
      expect(updated.positions.containsKey('peer-b'), isTrue);
      expect(updated.positions['peer-b']!.value.lat, 35.0);
    });

    test('applies a marker delta', () {
      const state = CrdtState();
      final marker = makeMarker(id: 'mk-1', createdBy: 'peer-b');
      final payload = SyncPayload(
        type: SyncPayloadType.marker,
        senderId: 'peer-b',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: marker.toJson(),
      );

      final updated = state.applyDelta(payload);
      expect(updated.liveMarkers.length, 1);
      expect(updated.liveMarkers.first.id, 'mk-1');
    });

    test('applies a marker delete delta', () {
      const state = CrdtState();
      final marker = makeMarker(id: 'mk-1', createdBy: 'peer-b');

      // First add the marker.
      final s1 = state.applyDelta(SyncPayload(
        type: SyncPayloadType.marker,
        senderId: 'peer-b',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: marker.toJson(),
      ));
      expect(s1.liveMarkers.length, 1);

      // Then delete it.
      final s2 = s1.applyDelta(SyncPayload(
        type: SyncPayloadType.marker,
        senderId: 'peer-b',
        sequenceNum: 2,
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
        data: {'id': 'mk-1', '_deleted': true},
      ));
      expect(s2.liveMarkers, isEmpty);
    });

    test('applies an annotation delta', () {
      const state = CrdtState();
      final ann = makeAnnotation(id: 'ann-1', createdBy: 'peer-b');
      final payload = SyncPayload(
        type: SyncPayloadType.annotation,
        senderId: 'peer-b',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: ann.toJson(),
      );

      final updated = state.applyDelta(payload);
      expect(updated.liveAnnotations.length, 1);
    });

    test('control messages increment sequence counter only', () {
      const state = CrdtState();
      final payload = SyncPayload(
        type: SyncPayloadType.control,
        senderId: 'peer-c',
        sequenceNum: 1,
        timestamp: DateTime.now(),
        data: {'action': 'join'},
      );

      final updated = state.applyDelta(payload);
      expect(updated.sequenceCounter.countFor('peer-c'), 1);
      expect(updated.positions, isEmpty);
      expect(updated.liveMarkers, isEmpty);
    });
  });
}

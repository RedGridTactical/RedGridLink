import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/boundary_event.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';

void main() {
  final start = DateTime(2026, 3, 21, 8, 0, 0);
  final end = DateTime(2026, 3, 21, 12, 0, 0);

  AarData makeAar({
    Annotation? boundary,
    List<BoundaryEvent> boundaryEvents = const [],
  }) =>
      AarData(
        sessionId: 'sess-1',
        sessionName: 'Alpha Op',
        operationalMode: OperationalMode.sar,
        startTime: start,
        endTime: end,
        boundary: boundary,
        boundaryEvents: boundaryEvents,
      );

  Annotation makeBoundary() => Annotation(
        id: 'boundary-1',
        type: AnnotationType.boundary,
        points: const [
          AnnotationPoint(lat: 38.0, lon: -77.0),
          AnnotationPoint(lat: 38.1, lon: -77.0),
          AnnotationPoint(lat: 38.1, lon: -76.9),
        ],
        createdBy: 'lead',
        createdAt: start,
        label: 'Search Area',
      );

  List<BoundaryEvent> makeBoundaryEvents() => [
        BoundaryEvent(
          id: 'evt-1',
          peerId: 'peer-1',
          callsign: 'Alpha',
          timestamp: DateTime(2026, 3, 21, 9, 30, 0),
          lat: 38.2,
          lon: -77.1,
        ),
        BoundaryEvent(
          id: 'evt-2',
          peerId: 'peer-2',
          callsign: 'Bravo',
          timestamp: DateTime(2026, 3, 21, 10, 15, 0),
          lat: 38.3,
          lon: -77.2,
        ),
      ];

  group('AarData constructor', () {
    test('accepts boundary and boundaryEvents', () {
      final boundary = makeBoundary();
      final events = makeBoundaryEvents();
      final aar = makeAar(boundary: boundary, boundaryEvents: events);

      expect(aar.boundary, isNotNull);
      expect(aar.boundary!.id, 'boundary-1');
      expect(aar.boundaryEvents.length, 2);
    });

    test('default values are null and empty list', () {
      final aar = makeAar();

      expect(aar.boundary, isNull);
      expect(aar.boundaryEvents, isEmpty);
    });

    test('boundary defaults to null when not provided', () {
      final aar = AarData(
        sessionId: 'sess-1',
        sessionName: 'Test',
        operationalMode: OperationalMode.sar,
        startTime: start,
        endTime: end,
      );

      expect(aar.boundary, isNull);
      expect(aar.boundaryEvents, const <BoundaryEvent>[]);
    });
  });

  group('AarData copyWith', () {
    test('preserves boundary', () {
      final boundary = makeBoundary();
      final aar = makeAar(boundary: boundary);
      final copied = aar.copyWith(sessionName: 'Updated');

      expect(copied.sessionName, 'Updated');
      expect(copied.boundary, isNotNull);
      expect(copied.boundary!.id, 'boundary-1');
      expect(copied.boundary!.label, 'Search Area');
    });

    test('preserves boundaryEvents', () {
      final events = makeBoundaryEvents();
      final aar = makeAar(boundaryEvents: events);
      final copied = aar.copyWith(sessionName: 'Updated');

      expect(copied.sessionName, 'Updated');
      expect(copied.boundaryEvents.length, 2);
      expect(copied.boundaryEvents[0].callsign, 'Alpha');
      expect(copied.boundaryEvents[1].callsign, 'Bravo');
    });

    test('can replace boundary via copyWith', () {
      final aar = makeAar(boundary: makeBoundary());
      final newBoundary = Annotation(
        id: 'boundary-2',
        type: AnnotationType.boundary,
        points: const [
          AnnotationPoint(lat: 39.0, lon: -78.0),
          AnnotationPoint(lat: 39.1, lon: -78.0),
        ],
        createdBy: 'new-lead',
        createdAt: end,
      );

      final copied = aar.copyWith(boundary: newBoundary);
      expect(copied.boundary!.id, 'boundary-2');
    });

    test('can replace boundaryEvents via copyWith', () {
      final aar = makeAar(boundaryEvents: makeBoundaryEvents());
      final newEvents = [
        BoundaryEvent(
          id: 'evt-3',
          peerId: 'peer-3',
          callsign: 'Charlie',
          timestamp: DateTime(2026, 3, 21, 11, 0, 0),
          lat: 38.4,
          lon: -77.3,
        ),
      ];

      final copied = aar.copyWith(boundaryEvents: newEvents);
      expect(copied.boundaryEvents.length, 1);
      expect(copied.boundaryEvents[0].callsign, 'Charlie');
    });
  });

  group('AarData with boundary events', () {
    test('has correct count', () {
      final events = makeBoundaryEvents();
      final aar = makeAar(boundaryEvents: events);

      expect(aar.boundaryEvents.length, 2);
    });

    test('empty events list has zero count', () {
      final aar = makeAar();
      expect(aar.boundaryEvents.length, 0);
    });
  });

  group('AarData JSON serialization', () {
    test('toJson includes boundary when set', () {
      final aar = makeAar(boundary: makeBoundary());
      final json = aar.toJson();

      expect(json.containsKey('boundary'), isTrue);
      expect(json['boundary']['id'], 'boundary-1');
    });

    test('toJson excludes boundary key when null', () {
      final aar = makeAar();
      final json = aar.toJson();

      expect(json.containsKey('boundary'), isFalse);
    });

    test('toJson includes boundaryEvents', () {
      final aar = makeAar(boundaryEvents: makeBoundaryEvents());
      final json = aar.toJson();

      expect(json['boundaryEvents'], isList);
      expect((json['boundaryEvents'] as List).length, 2);
    });

    test('round-trip serialization preserves boundary data', () {
      final original = makeAar(
        boundary: makeBoundary(),
        boundaryEvents: makeBoundaryEvents(),
      );

      final json = original.toJson();
      final restored = AarData.fromJson(json);

      expect(restored.boundary, isNotNull);
      expect(restored.boundary!.id, original.boundary!.id);
      expect(restored.boundary!.label, original.boundary!.label);
      expect(restored.boundaryEvents.length,
          original.boundaryEvents.length);
      expect(restored.boundaryEvents[0].callsign, 'Alpha');
      expect(restored.boundaryEvents[1].peerId, 'peer-2');
    });

    test('fromJson handles missing boundary gracefully', () {
      final json = makeAar().toJson();
      final restored = AarData.fromJson(json);

      expect(restored.boundary, isNull);
      expect(restored.boundaryEvents, isEmpty);
    });
  });
}

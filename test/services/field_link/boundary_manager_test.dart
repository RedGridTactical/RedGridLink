import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/services/field_link/boundary_manager.dart';

void main() {
  late BoundaryManager manager;

  // A simple square boundary: (0,0), (0,10), (10,10), (10,0)
  Annotation makeSquareBoundary() => Annotation(
        id: 'boundary-1',
        type: AnnotationType.boundary,
        points: const [
          AnnotationPoint(lat: 0, lon: 0),
          AnnotationPoint(lat: 0, lon: 10),
          AnnotationPoint(lat: 10, lon: 10),
          AnnotationPoint(lat: 10, lon: 0),
        ],
        createdBy: 'test-user',
        createdAt: DateTime(2026),
      );

  setUp(() {
    manager = BoundaryManager();
  });

  group('BoundaryManager', () {
    test('isInsideBoundary returns true for point inside polygon', () {
      manager.setBoundary(makeSquareBoundary());
      expect(manager.isInsideBoundary(5, 5), isTrue);
    });

    test('isInsideBoundary returns false for point outside polygon', () {
      manager.setBoundary(makeSquareBoundary());
      expect(manager.isInsideBoundary(15, 5), isFalse);
    });

    test('isInsideBoundary returns true when no boundary is set', () {
      expect(manager.isInsideBoundary(100, 100), isTrue);
    });

    test('checkBoundaryCrossing detects exit transition (inside→outside)', () {
      manager.setBoundary(makeSquareBoundary());

      // First check: peer is inside — no crossing
      final first = manager.checkBoundaryCrossing('peer-1', 5, 5);
      expect(first, isFalse);

      // Second check: peer moved outside — crossing detected
      final second = manager.checkBoundaryCrossing('peer-1', 15, 5);
      expect(second, isTrue);
    });

    test('checkBoundaryCrossing does NOT trigger for outside→outside', () {
      manager.setBoundary(makeSquareBoundary());

      // First check: outside (assumes was inside → triggers)
      manager.checkBoundaryCrossing('peer-1', 15, 5);

      // Second check: still outside — no re-alert
      final result = manager.checkBoundaryCrossing('peer-1', 20, 5);
      expect(result, isFalse);
    });

    test(
        'checkBoundaryCrossing triggers on first check when outside '
        '(assumes inside initially)', () {
      manager.setBoundary(makeSquareBoundary());

      // First check: peer is outside, but we assumed inside → crossing
      final result = manager.checkBoundaryCrossing('peer-1', 15, 5);
      expect(result, isTrue);
    });

    test('no boundary means no crossing detected', () {
      // No boundary set
      final result = manager.checkBoundaryCrossing('peer-1', 15, 5);
      expect(result, isFalse);
    });

    test('setting new boundary clears previous state', () {
      manager.setBoundary(makeSquareBoundary());

      // Mark peer as outside
      manager.checkBoundaryCrossing('peer-1', 15, 5);

      // Set a new boundary — state should be cleared
      manager.setBoundary(makeSquareBoundary());

      // Now first check outside should trigger again (fresh state)
      final result = manager.checkBoundaryCrossing('peer-1', 15, 5);
      expect(result, isTrue);
    });

    test('polygon with < 3 points always returns false for isInside', () {
      final twoPointBoundary = Annotation(
        id: 'boundary-small',
        type: AnnotationType.boundary,
        points: const [
          AnnotationPoint(lat: 0, lon: 0),
          AnnotationPoint(lat: 10, lon: 10),
        ],
        createdBy: 'test-user',
        createdAt: DateTime(2026),
      );

      manager.setBoundary(twoPointBoundary);
      expect(manager.isInsideBoundary(5, 5), isFalse);
    });

    test('clearBoundary resets everything', () {
      manager.setBoundary(makeSquareBoundary());
      expect(manager.hasBoundary, isTrue);

      // Register peer state
      manager.checkBoundaryCrossing('peer-1', 5, 5);

      manager.clearBoundary();

      expect(manager.hasBoundary, isFalse);
      expect(manager.boundary, isNull);
      // After clear, isInsideBoundary returns true (no restriction)
      expect(manager.isInsideBoundary(100, 100), isTrue);
      // After clear, no crossing detected
      expect(manager.checkBoundaryCrossing('peer-1', 15, 5), isFalse);
    });

    test('hasBoundary reflects current state', () {
      expect(manager.hasBoundary, isFalse);
      manager.setBoundary(makeSquareBoundary());
      expect(manager.hasBoundary, isTrue);
      manager.clearBoundary();
      expect(manager.hasBoundary, isFalse);
    });

    test('boundary getter returns set annotation', () {
      expect(manager.boundary, isNull);
      final boundary = makeSquareBoundary();
      manager.setBoundary(boundary);
      expect(manager.boundary, equals(boundary));
    });

    test('re-entering then exiting triggers crossing again', () {
      manager.setBoundary(makeSquareBoundary());

      // Inside first
      expect(manager.checkBoundaryCrossing('peer-1', 5, 5), isFalse);

      // Exit — triggers
      expect(manager.checkBoundaryCrossing('peer-1', 15, 5), isTrue);

      // Re-enter
      expect(manager.checkBoundaryCrossing('peer-1', 5, 5), isFalse);

      // Exit again — triggers again
      expect(manager.checkBoundaryCrossing('peer-1', 15, 5), isTrue);
    });

    test('peer tracking is independent from other peers', () {
      manager.setBoundary(makeSquareBoundary());

      // peer-1 exits
      expect(manager.checkBoundaryCrossing('peer-1', 15, 5), isTrue);

      // peer-2 is still inside — no crossing
      expect(manager.checkBoundaryCrossing('peer-2', 5, 5), isFalse);

      // peer-2 exits — triggers independently
      expect(manager.checkBoundaryCrossing('peer-2', 15, 5), isTrue);

      // peer-1 stays outside — no re-trigger
      expect(manager.checkBoundaryCrossing('peer-1', 20, 5), isFalse);
    });
  });
}

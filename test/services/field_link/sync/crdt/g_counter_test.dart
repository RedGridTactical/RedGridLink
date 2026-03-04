import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/g_counter.dart';

void main() {
  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------
  group('GCounter construction', () {
    test('zero counter has value 0', () {
      const counter = GCounter.zero();
      expect(counter.value, 0);
    });

    test('counter from map sums correctly', () {
      final counter = GCounter({'a': 3, 'b': 5});
      expect(counter.value, 8);
    });
  });

  // -------------------------------------------------------------------------
  // increment
  // -------------------------------------------------------------------------
  group('increment', () {
    test('increments a new node from 0 to 1', () {
      const counter = GCounter.zero();
      final incremented = counter.increment('node-a');
      expect(incremented.value, 1);
      expect(incremented.countFor('node-a'), 1);
    });

    test('increments an existing node', () {
      final counter = GCounter({'node-a': 5});
      final incremented = counter.increment('node-a');
      expect(incremented.countFor('node-a'), 6);
      expect(incremented.value, 6);
    });

    test('incrementing one node does not affect others', () {
      final counter = GCounter({'a': 3, 'b': 5});
      final incremented = counter.increment('a');
      expect(incremented.countFor('a'), 4);
      expect(incremented.countFor('b'), 5);
      expect(incremented.value, 9);
    });

    test('original counter is not mutated', () {
      final counter = GCounter({'a': 3});
      final incremented = counter.increment('a');
      expect(counter.countFor('a'), 3);
      expect(incremented.countFor('a'), 4);
    });
  });

  // -------------------------------------------------------------------------
  // merge — CRDT properties
  // -------------------------------------------------------------------------
  group('merge', () {
    test('merge takes per-node max', () {
      final a = GCounter({'x': 3, 'y': 7});
      final b = GCounter({'x': 5, 'y': 2});
      final merged = a.merge(b);
      expect(merged.countFor('x'), 5);
      expect(merged.countFor('y'), 7);
      expect(merged.value, 12);
    });

    test('merge includes nodes only in one counter', () {
      final a = GCounter({'x': 3});
      final b = GCounter({'y': 5});
      final merged = a.merge(b);
      expect(merged.countFor('x'), 3);
      expect(merged.countFor('y'), 5);
      expect(merged.value, 8);
    });

    test('commutative: merge(a, b) == merge(b, a)', () {
      final a = GCounter({'x': 3, 'y': 7});
      final b = GCounter({'x': 5, 'z': 2});
      final ab = a.merge(b);
      final ba = b.merge(a);
      expect(ab.value, ba.value);
      expect(ab.countFor('x'), ba.countFor('x'));
      expect(ab.countFor('y'), ba.countFor('y'));
      expect(ab.countFor('z'), ba.countFor('z'));
    });

    test('associative: merge(merge(a, b), c) == merge(a, merge(b, c))', () {
      final a = GCounter({'x': 1, 'y': 2});
      final b = GCounter({'x': 3, 'z': 4});
      final c = GCounter({'y': 5, 'z': 1});
      final left = a.merge(b).merge(c);
      final right = a.merge(b.merge(c));
      expect(left.value, right.value);
      expect(left.countFor('x'), right.countFor('x'));
      expect(left.countFor('y'), right.countFor('y'));
      expect(left.countFor('z'), right.countFor('z'));
    });

    test('idempotent: merge(a, a) == a', () {
      final a = GCounter({'x': 3, 'y': 7});
      final merged = a.merge(a);
      expect(merged.value, a.value);
      expect(merged.countFor('x'), a.countFor('x'));
      expect(merged.countFor('y'), a.countFor('y'));
    });

    test('merge with zero counter returns original', () {
      final a = GCounter({'x': 3, 'y': 7});
      const zero = GCounter.zero();
      final merged = a.merge(zero);
      expect(merged.value, a.value);
    });
  });

  // -------------------------------------------------------------------------
  // countFor / nodeIds
  // -------------------------------------------------------------------------
  group('countFor and nodeIds', () {
    test('countFor returns 0 for unknown node', () {
      const counter = GCounter.zero();
      expect(counter.countFor('nonexistent'), 0);
    });

    test('nodeIds returns all known nodes', () {
      final counter = GCounter({'a': 1, 'b': 2, 'c': 3});
      expect(counter.nodeIds, containsAll(['a', 'b', 'c']));
      expect(counter.nodeIds.length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // JSON serialization
  // -------------------------------------------------------------------------
  group('JSON serialization', () {
    test('toJson returns a map of counts', () {
      final counter = GCounter({'a': 3, 'b': 5});
      final json = counter.toJson();
      expect(json, {'a': 3, 'b': 5});
    });

    test('fromJson reconstructs the counter', () {
      final original = GCounter({'a': 3, 'b': 5});
      final json = original.toJson();
      final reconstructed = GCounter.fromJson(json);
      expect(reconstructed.value, original.value);
      expect(reconstructed.countFor('a'), 3);
      expect(reconstructed.countFor('b'), 5);
    });

    test('roundtrip preserves equality', () {
      final original = GCounter({'x': 10, 'y': 20});
      final json = original.toJson();
      final restored = GCounter.fromJson(json);
      expect(restored, equals(original));
    });
  });

  // -------------------------------------------------------------------------
  // equality
  // -------------------------------------------------------------------------
  group('equality', () {
    test('equal counters are ==', () {
      final a = GCounter({'x': 3, 'y': 5});
      final b = GCounter({'x': 3, 'y': 5});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('counters with different values are !=', () {
      final a = GCounter({'x': 3, 'y': 5});
      final b = GCounter({'x': 3, 'y': 6});
      expect(a, isNot(equals(b)));
    });

    test('counters with different keys are !=', () {
      final a = GCounter({'x': 3});
      final b = GCounter({'y': 3});
      expect(a, isNot(equals(b)));
    });
  });
}

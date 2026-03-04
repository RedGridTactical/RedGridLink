import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/lww_register.dart';

void main() {
  // -------------------------------------------------------------------------
  // Basic construction
  // -------------------------------------------------------------------------
  group('LwwRegister construction', () {
    test('stores nodeId, timestamp, and value', () {
      final reg = LwwRegister<int>(
        nodeId: 'node-a',
        timestamp: 1000,
        value: 42,
      );
      expect(reg.nodeId, 'node-a');
      expect(reg.timestamp, 1000);
      expect(reg.value, 42);
    });
  });

  // -------------------------------------------------------------------------
  // isNewerThan
  // -------------------------------------------------------------------------
  group('isNewerThan', () {
    test('newer timestamp wins', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 200, value: 1);
      final b = LwwRegister<int>(nodeId: 'b', timestamp: 100, value: 2);
      expect(a.isNewerThan(b), isTrue);
      expect(b.isNewerThan(a), isFalse);
    });

    test('equal timestamps — higher nodeId wins', () {
      final a = LwwRegister<int>(nodeId: 'b', timestamp: 100, value: 1);
      final b = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 2);
      expect(a.isNewerThan(b), isTrue);
      expect(b.isNewerThan(a), isFalse);
    });

    test('identical registers — neither is newer', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 1);
      final b = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 1);
      expect(a.isNewerThan(b), isFalse);
      expect(b.isNewerThan(a), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // merge — CRDT properties
  // -------------------------------------------------------------------------
  group('merge', () {
    test('keeps register with newer timestamp', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 200, value: 42);
      final b = LwwRegister<int>(nodeId: 'b', timestamp: 100, value: 99);
      final merged = a.merge(b);
      expect(merged.value, 42);
      expect(merged.timestamp, 200);
    });

    test('keeps register with newer timestamp (reversed)', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 42);
      final b = LwwRegister<int>(nodeId: 'b', timestamp: 200, value: 99);
      final merged = a.merge(b);
      expect(merged.value, 99);
      expect(merged.timestamp, 200);
    });

    test('tiebreaker: higher nodeId wins on equal timestamps', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 42);
      final b = LwwRegister<int>(nodeId: 'b', timestamp: 100, value: 99);
      final merged = a.merge(b);
      expect(merged.value, 99);
      expect(merged.nodeId, 'b');
    });

    test('commutative: merge(a, b) == merge(b, a)', () {
      final a = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 10);
      final b = LwwRegister<int>(nodeId: 'y', timestamp: 200, value: 20);
      final ab = a.merge(b);
      final ba = b.merge(a);
      expect(ab.value, ba.value);
      expect(ab.timestamp, ba.timestamp);
      expect(ab.nodeId, ba.nodeId);
    });

    test('commutative with equal timestamps', () {
      final a = LwwRegister<int>(nodeId: 'alpha', timestamp: 500, value: 1);
      final b = LwwRegister<int>(nodeId: 'beta', timestamp: 500, value: 2);
      final ab = a.merge(b);
      final ba = b.merge(a);
      expect(ab.value, ba.value);
      expect(ab.nodeId, ba.nodeId);
    });

    test('associative: merge(merge(a, b), c) == merge(a, merge(b, c))', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 1);
      final b = LwwRegister<int>(nodeId: 'b', timestamp: 200, value: 2);
      final c = LwwRegister<int>(nodeId: 'c', timestamp: 150, value: 3);
      final left = a.merge(b).merge(c);
      final right = a.merge(b.merge(c));
      expect(left.value, right.value);
      expect(left.timestamp, right.timestamp);
      expect(left.nodeId, right.nodeId);
    });

    test('idempotent: merge(a, a) == a', () {
      final a = LwwRegister<int>(nodeId: 'a', timestamp: 100, value: 42);
      final merged = a.merge(a);
      expect(merged.value, a.value);
      expect(merged.timestamp, a.timestamp);
      expect(merged.nodeId, a.nodeId);
    });
  });

  // -------------------------------------------------------------------------
  // withValue
  // -------------------------------------------------------------------------
  group('withValue', () {
    test('creates new register with same nodeId and updated value', () {
      final original =
          LwwRegister<int>(nodeId: 'node-1', timestamp: 100, value: 1);
      final updated = original.withValue(999);
      expect(updated.nodeId, 'node-1');
      expect(updated.value, 999);
      expect(updated.timestamp, greaterThanOrEqualTo(original.timestamp));
    });
  });

  // -------------------------------------------------------------------------
  // equality
  // -------------------------------------------------------------------------
  group('equality', () {
    test('equal registers are ==', () {
      final a = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 5);
      final b = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 5);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different values are !=', () {
      final a = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 5);
      final b = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 6);
      expect(a, isNot(equals(b)));
    });

    test('different timestamps are !=', () {
      final a = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 5);
      final b = LwwRegister<int>(nodeId: 'x', timestamp: 200, value: 5);
      expect(a, isNot(equals(b)));
    });

    test('different nodeIds are !=', () {
      final a = LwwRegister<int>(nodeId: 'x', timestamp: 100, value: 5);
      final b = LwwRegister<int>(nodeId: 'y', timestamp: 100, value: 5);
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------
  group('toString', () {
    test('produces readable output', () {
      final reg = LwwRegister<int>(nodeId: 'n', timestamp: 100, value: 7);
      expect(reg.toString(), contains('LwwRegister'));
      expect(reg.toString(), contains('n'));
      expect(reg.toString(), contains('100'));
    });
  });

  // -------------------------------------------------------------------------
  // Generic type support
  // -------------------------------------------------------------------------
  group('generic types', () {
    test('works with String values', () {
      final a = LwwRegister<String>(
        nodeId: 'a',
        timestamp: 100,
        value: 'hello',
      );
      final b = LwwRegister<String>(
        nodeId: 'b',
        timestamp: 200,
        value: 'world',
      );
      expect(a.merge(b).value, 'world');
    });

    test('works with nullable types', () {
      final a = LwwRegister<int?>(nodeId: 'a', timestamp: 100, value: null);
      final b = LwwRegister<int?>(nodeId: 'b', timestamp: 200, value: 42);
      expect(a.merge(b).value, 42);
    });

    test('tombstone wins with newer timestamp', () {
      final a = LwwRegister<int?>(nodeId: 'a', timestamp: 100, value: 42);
      final b = LwwRegister<int?>(nodeId: 'b', timestamp: 200, value: null);
      expect(a.merge(b).value, isNull);
    });
  });
}

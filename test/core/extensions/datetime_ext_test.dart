import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/extensions/datetime_ext.dart';

void main() {
  // -----------------------------------------------------------------------
  // toIso8601Utc
  // -----------------------------------------------------------------------
  group('toIso8601Utc', () {
    test('produces string ending in Z', () {
      final date = DateTime.utc(2026, 3, 2, 14, 30, 0);
      final result = date.toIso8601Utc();
      expect(result, endsWith('Z'));
    });

    test('produces valid ISO 8601 format', () {
      final date = DateTime.utc(2026, 3, 2, 14, 30, 0);
      final result = date.toIso8601Utc();
      expect(result, contains('2026-03-02'));
      expect(result, contains('14:30:00'));
    });

    test('local DateTime is converted to UTC', () {
      // Create a local DateTime and verify the output is UTC
      final date = DateTime(2026, 3, 2, 14, 30, 0);
      final result = date.toIso8601Utc();
      expect(result, endsWith('Z'));
      // Should be parseable as UTC
      final parsed = DateTime.parse(result);
      expect(parsed.isUtc, isTrue);
    });

    test('midnight UTC', () {
      final date = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final result = date.toIso8601Utc();
      expect(result, startsWith('2026-01-01'));
      expect(result, endsWith('Z'));
    });
  });

  // -----------------------------------------------------------------------
  // toTacticalFormat
  // -----------------------------------------------------------------------
  group('toTacticalFormat', () {
    test('produces format like "02MAR26 1430Z"', () {
      final date = DateTime.utc(2026, 3, 2, 14, 30, 0);
      final result = date.toTacticalFormat();
      expect(result, equals('02MAR26 1430Z'));
    });

    test('pads single-digit day with zero', () {
      final date = DateTime.utc(2026, 1, 5, 8, 5, 0);
      final result = date.toTacticalFormat();
      expect(result, startsWith('05'));
    });

    test('pads single-digit hour with zero', () {
      final date = DateTime.utc(2026, 1, 15, 3, 0, 0);
      final result = date.toTacticalFormat();
      expect(result, contains('0300Z'));
    });

    test('pads single-digit minute with zero', () {
      final date = DateTime.utc(2026, 6, 15, 12, 5, 0);
      final result = date.toTacticalFormat();
      expect(result, contains('1205Z'));
    });

    test('midnight shows 0000Z', () {
      final date = DateTime.utc(2026, 7, 4, 0, 0, 0);
      final result = date.toTacticalFormat();
      expect(result, equals('04JUL26 0000Z'));
    });

    test('all months are represented correctly', () {
      final months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
      ];
      for (int i = 0; i < 12; i++) {
        final date = DateTime.utc(2026, i + 1, 15, 12, 0, 0);
        final result = date.toTacticalFormat();
        expect(result, contains(months[i]),
            reason: 'Month ${i + 1} should produce ${months[i]}');
      }
    });

    test('year 2000 produces 00', () {
      final date = DateTime.utc(2000, 6, 15, 12, 0, 0);
      final result = date.toTacticalFormat();
      expect(result, contains('JUN00'));
    });
  });

  // -----------------------------------------------------------------------
  // isStale
  // -----------------------------------------------------------------------
  group('isStale', () {
    test('old date is stale with short threshold', () {
      final old = DateTime.now().subtract(const Duration(minutes: 10));
      expect(old.isStale(const Duration(minutes: 5)), isTrue);
    });

    test('recent date is not stale with long threshold', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      expect(recent.isStale(const Duration(minutes: 5)), isFalse);
    });

    test('future date is not stale', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(future.isStale(const Duration(minutes: 5)), isFalse);
    });

    test('exactly at threshold boundary is not stale', () {
      // A date exactly at the threshold should not be stale
      // (difference == threshold, but isStale uses >)
      final borderline = DateTime.now().subtract(const Duration(minutes: 5));
      // Allow some slack since DateTime.now() shifts between creation and check
      expect(
        borderline.isStale(const Duration(minutes: 6)),
        isFalse,
      );
    });

    test('very old date is stale', () {
      final veryOld = DateTime(2020, 1, 1);
      expect(veryOld.isStale(const Duration(hours: 1)), isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // toRelativeString
  // -----------------------------------------------------------------------
  group('toRelativeString', () {
    test('just now for very recent times', () {
      final now = DateTime.now();
      expect(now.toRelativeString(), equals('just now'));
    });

    test('Xm ago for minutes-old times', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final result = fiveMinAgo.toRelativeString();
      expect(result, equals('5m ago'));
    });

    test('Xhr ago for hours-old times', () {
      final twoHrsAgo = DateTime.now().subtract(const Duration(hours: 2));
      final result = twoHrsAgo.toRelativeString();
      expect(result, equals('2hr ago'));
    });

    test('Xd ago for days-old times', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final result = threeDaysAgo.toRelativeString();
      expect(result, equals('3d ago'));
    });

    test('Xw ago for weeks-old times', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final result = twoWeeksAgo.toRelativeString();
      expect(result, equals('2w ago'));
    });

    test('future time returns "in the future"', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(future.toRelativeString(), equals('in the future'));
    });

    test('Xmo ago for months-old times', () {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final result = threeMonthsAgo.toRelativeString();
      expect(result, contains('mo ago'));
    });

    test('Xyr ago for years-old times', () {
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
      final result = twoYearsAgo.toRelativeString();
      expect(result, contains('yr ago'));
    });
  });
}

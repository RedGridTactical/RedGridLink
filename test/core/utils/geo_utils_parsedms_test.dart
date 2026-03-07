import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/geo_utils.dart';

void main() {
  // -----------------------------------------------------------------------
  // parseDMS
  // -----------------------------------------------------------------------
  group('parseDMS', () {
    test('parses N 38 53 51.7 as positive latitude', () {
      final result = parseDMS('N 38 53 51.7');
      expect(result, isNotNull);
      expect(result!, closeTo(38.8977, 0.001));
    });

    test('parses S 33 52 7.7 as negative latitude', () {
      final result = parseDMS('S 33 52 7.7');
      expect(result, isNotNull);
      expect(result!, closeTo(-33.8688, 0.001));
    });

    test('parses W 77 02 11.4 as negative longitude', () {
      final result = parseDMS('W 77 02 11.4');
      expect(result, isNotNull);
      expect(result!, closeTo(-77.0365, 0.001));
    });

    test('parses E 151 12 33.5 as positive longitude', () {
      final result = parseDMS('E 151 12 33.5');
      expect(result, isNotNull);
      expect(result!, closeTo(151.2093, 0.001));
    });

    test('parses with degree/minute/second symbols', () {
      final result = parseDMS("N 38\u00B0 53' 51.7\"");
      expect(result, isNotNull);
      expect(result!, closeTo(38.8977, 0.001));
    });

    test('parses numbers only (no hemisphere)', () {
      final result = parseDMS('38 53 51.7');
      expect(result, isNotNull);
      expect(result!, closeTo(38.8977, 0.001));
    });

    test('hemisphere suffix works', () {
      final result = parseDMS('77 02 11.4 W');
      expect(result, isNotNull);
      expect(result!, closeTo(-77.0365, 0.001));
    });

    test('handles only degrees and minutes', () {
      final result = parseDMS('38 53');
      expect(result, isNotNull);
      // 38 + 53/60 = 38.8833...
      expect(result!, closeTo(38.8833, 0.001));
    });

    test('returns null for empty string', () {
      expect(parseDMS(''), isNull);
    });

    test('returns null for whitespace only', () {
      expect(parseDMS('   '), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(parseDMS('abc xyz'), isNull);
    });

    test('round-trip: formatCoordinate then parseDMS', () {
      const originalLat = 38.8977;
      final dmsStr = formatCoordinate(originalLat, true);
      final parsed = parseDMS(dmsStr);
      expect(parsed, isNotNull);
      expect(parsed!, closeTo(originalLat, 0.01));
    });

    test('round-trip: negative longitude', () {
      const originalLon = -77.0365;
      final dmsStr = formatCoordinate(originalLon, false);
      final parsed = parseDMS(dmsStr);
      expect(parsed, isNotNull);
      expect(parsed!, closeTo(originalLon, 0.01));
    });
  });
}

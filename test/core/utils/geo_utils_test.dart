import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/geo_utils.dart';

void main() {
  // -----------------------------------------------------------------------
  // metersToFeet / feetToMeters
  // -----------------------------------------------------------------------
  group('metersToFeet / feetToMeters', () {
    test('1 meter = 3.28084 feet', () {
      expect(metersToFeet(1.0), closeTo(3.28084, 0.0001));
    });

    test('0 meters = 0 feet', () {
      expect(metersToFeet(0.0), closeTo(0.0, 0.0001));
    });

    test('1000 meters = 3280.84 feet', () {
      expect(metersToFeet(1000.0), closeTo(3280.84, 0.1));
    });

    test('round-trip: meters -> feet -> meters', () {
      const original = 123.456;
      final feet = metersToFeet(original);
      final backToMeters = feetToMeters(feet);
      expect(backToMeters, closeTo(original, 0.001));
    });

    test('round-trip: feet -> meters -> feet', () {
      const original = 500.0;
      final meters = feetToMeters(original);
      final backToFeet = metersToFeet(meters);
      expect(backToFeet, closeTo(original, 0.001));
    });
  });

  // -----------------------------------------------------------------------
  // metersToMiles / milesToMeters
  // -----------------------------------------------------------------------
  group('metersToMiles / milesToMeters', () {
    test('1609.344 meters = 1 mile', () {
      expect(metersToMiles(1609.344), closeTo(1.0, 0.0001));
    });

    test('0 meters = 0 miles', () {
      expect(metersToMiles(0.0), closeTo(0.0, 0.0001));
    });

    test('1 mile = 1609.344 meters', () {
      expect(milesToMeters(1.0), closeTo(1609.344, 0.001));
    });

    test('round-trip: meters -> miles -> meters', () {
      const original = 5000.0;
      final miles = metersToMiles(original);
      final backToMeters = milesToMeters(miles);
      expect(backToMeters, closeTo(original, 0.001));
    });

    test('round-trip: miles -> meters -> miles', () {
      const original = 3.5;
      final meters = milesToMeters(original);
      final backToMiles = metersToMiles(meters);
      expect(backToMiles, closeTo(original, 0.0001));
    });
  });

  // -----------------------------------------------------------------------
  // kphToMph / mphToKph
  // -----------------------------------------------------------------------
  group('kphToMph / mphToKph', () {
    test('1 kph = 0.621371 mph', () {
      expect(kphToMph(1.0), closeTo(0.621371, 0.0001));
    });

    test('100 kph ~ 62.14 mph', () {
      expect(kphToMph(100.0), closeTo(62.1371, 0.01));
    });

    test('0 kph = 0 mph', () {
      expect(kphToMph(0.0), closeTo(0.0, 0.0001));
    });

    test('round-trip: kph -> mph -> kph', () {
      const original = 80.0;
      final mph = kphToMph(original);
      final backToKph = mphToKph(mph);
      expect(backToKph, closeTo(original, 0.001));
    });

    test('round-trip: mph -> kph -> mph', () {
      const original = 60.0;
      final kph = mphToKph(original);
      final backToMph = kphToMph(kph);
      expect(backToMph, closeTo(original, 0.001));
    });
  });

  // -----------------------------------------------------------------------
  // formatCoordinate
  // -----------------------------------------------------------------------
  group('formatCoordinate', () {
    test('positive latitude uses N', () {
      final result = formatCoordinate(38.8977, true);
      expect(result, startsWith('N'));
    });

    test('negative latitude uses S', () {
      final result = formatCoordinate(-33.8688, true);
      expect(result, startsWith('S'));
    });

    test('positive longitude uses E', () {
      final result = formatCoordinate(151.2093, false);
      expect(result, startsWith('E'));
    });

    test('negative longitude uses W', () {
      final result = formatCoordinate(-77.0365, false);
      expect(result, startsWith('W'));
    });

    test('zero latitude uses N', () {
      final result = formatCoordinate(0.0, true);
      expect(result, startsWith('N'));
    });

    test('zero longitude uses E', () {
      final result = formatCoordinate(0.0, false);
      expect(result, startsWith('E'));
    });

    test('contains degree symbol', () {
      final result = formatCoordinate(38.8977, true);
      expect(result, contains('\u00B0'));
    });

    test('contains minute mark', () {
      final result = formatCoordinate(38.8977, true);
      expect(result, contains("'"));
    });

    test('contains second mark', () {
      final result = formatCoordinate(38.8977, true);
      expect(result, contains('"'));
    });

    test('known conversion: 38.8977 lat', () {
      // 38.8977 = 38 degrees, 53.862 minutes = 38 53' 51.7"
      final result = formatCoordinate(38.8977, true);
      expect(result, startsWith('N 38'));
    });
  });

  // -----------------------------------------------------------------------
  // compassDirection
  // -----------------------------------------------------------------------
  group('compassDirection', () {
    test('0 degrees = N', () {
      expect(compassDirection(0), equals('N'));
    });

    test('360 degrees = N', () {
      expect(compassDirection(360), equals('N'));
    });

    test('45 degrees = NE', () {
      expect(compassDirection(45), equals('NE'));
    });

    test('90 degrees = E', () {
      expect(compassDirection(90), equals('E'));
    });

    test('135 degrees = SE', () {
      expect(compassDirection(135), equals('SE'));
    });

    test('180 degrees = S', () {
      expect(compassDirection(180), equals('S'));
    });

    test('225 degrees = SW', () {
      expect(compassDirection(225), equals('SW'));
    });

    test('270 degrees = W', () {
      expect(compassDirection(270), equals('W'));
    });

    test('315 degrees = NW', () {
      expect(compassDirection(315), equals('NW'));
    });

    test('boundary: 22 degrees = N (just inside N sector)', () {
      expect(compassDirection(22), equals('N'));
    });

    test('boundary: 23 degrees = NE (just inside NE sector)', () {
      expect(compassDirection(23), equals('NE'));
    });

    test('negative bearing wraps correctly', () {
      // -90 should be equivalent to 270 = W
      expect(compassDirection(-90), equals('W'));
    });

    test('bearing > 360 wraps correctly', () {
      expect(compassDirection(450), equals('E')); // 450 - 360 = 90 = E
    });
  });
}

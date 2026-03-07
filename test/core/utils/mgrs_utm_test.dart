import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';

void main() {
  // -----------------------------------------------------------------------
  // latLonToUTM
  // -----------------------------------------------------------------------
  group('latLonToUTM', () {
    test('Fort Liberty produces zone 17', () {
      final utm = latLonToUTM(35.1390, -79.0006);
      expect(utm.zoneNum, equals(17));
    });

    test('Washington DC produces zone 18', () {
      final utm = latLonToUTM(38.8977, -77.0365);
      expect(utm.zoneNum, equals(18));
    });

    test('London produces zone 30', () {
      final utm = latLonToUTM(51.5074, -0.1278);
      expect(utm.zoneNum, equals(30));
    });

    test('easting is in valid UTM range (100000-900000)', () {
      final utm = latLonToUTM(38.8977, -77.0365);
      expect(utm.easting, greaterThanOrEqualTo(100000));
      expect(utm.easting, lessThanOrEqualTo(900000));
    });

    test('northing is positive for northern hemisphere', () {
      final utm = latLonToUTM(38.8977, -77.0365);
      expect(utm.northing, greaterThan(0));
    });

    test('zone letter for mid-latitude north is S', () {
      final utm = latLonToUTM(35.0, -79.0);
      expect(utm.zoneLetter, equals('S'));
    });
  });

  // -----------------------------------------------------------------------
  // formatUTM
  // -----------------------------------------------------------------------
  group('formatUTM', () {
    test('produces space-separated format', () {
      final result = formatUTM(38.8977, -77.0365);
      // Should look like "18S 323378 4306446" (approximately)
      expect(result, startsWith('18S'));
      final parts = result.split(' ');
      expect(parts.length, equals(3));
    });

    test('zone number + letter + easting + northing', () {
      final result = formatUTM(35.0, -79.0);
      expect(result, startsWith('17S'));
      final parts = result.split(' ');
      expect(parts.length, equals(3));
      // easting and northing should be numeric
      expect(int.tryParse(parts[1]), isNotNull);
      expect(int.tryParse(parts[2]), isNotNull);
    });
  });
}

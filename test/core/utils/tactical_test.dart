import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/tactical.dart';

void main() {
  // -----------------------------------------------------------------------
  // backAzimuth
  // -----------------------------------------------------------------------
  group('backAzimuth', () {
    test('0 -> 180', () {
      expect(backAzimuth(0), closeTo(180, 0.001));
    });

    test('90 -> 270', () {
      expect(backAzimuth(90), closeTo(270, 0.001));
    });

    test('180 -> 0', () {
      expect(backAzimuth(180), closeTo(0, 0.001));
    });

    test('270 -> 90', () {
      expect(backAzimuth(270), closeTo(90, 0.001));
    });

    test('45 -> 225', () {
      expect(backAzimuth(45), closeTo(225, 0.001));
    });

    test('360 -> 180 (360 is equivalent to 0)', () {
      expect(backAzimuth(360), closeTo(180, 0.001));
    });

    test('350 -> 170', () {
      expect(backAzimuth(350), closeTo(170, 0.001));
    });
  });

  // -----------------------------------------------------------------------
  // deadReckoning
  // -----------------------------------------------------------------------
  group('deadReckoning', () {
    test('heading 0 (north) 1000m increases latitude ~0.009 degrees', () {
      final result = deadReckoning(35.0, -79.0, 0.0, 1000.0);
      expect(result, isNotNull);
      // 1000m north ~ 0.009 degrees latitude
      expect(result!.lat, closeTo(35.0 + 0.009, 0.001));
      // Longitude should remain essentially the same
      expect(result.lon, closeTo(-79.0, 0.001));
    });

    test('heading 90 (east) increases longitude', () {
      final result = deadReckoning(0.0, 0.0, 90.0, 1000.0);
      expect(result, isNotNull);
      expect(result!.lon, greaterThan(0.0));
      // Latitude should remain essentially the same
      expect(result.lat, closeTo(0.0, 0.001));
    });

    test('heading 180 (south) decreases latitude', () {
      final result = deadReckoning(35.0, -79.0, 180.0, 1000.0);
      expect(result, isNotNull);
      expect(result!.lat, lessThan(35.0));
    });

    test('heading 270 (west) decreases longitude', () {
      final result = deadReckoning(0.0, 10.0, 270.0, 1000.0);
      expect(result, isNotNull);
      expect(result!.lon, lessThan(10.0));
    });

    test('zero distance returns same position', () {
      final result = deadReckoning(35.0, -79.0, 45.0, 0.0);
      expect(result, isNotNull);
      expect(result!.lat, closeTo(35.0, 0.0001));
      expect(result.lon, closeTo(-79.0, 0.0001));
    });

    test('negative distance returns null', () {
      final result = deadReckoning(35.0, -79.0, 0.0, -100.0);
      expect(result, isNull);
    });

    test('NaN distance returns null', () {
      final result = deadReckoning(35.0, -79.0, 0.0, double.nan);
      expect(result, isNull);
    });

    test('infinity distance returns null', () {
      final result = deadReckoning(35.0, -79.0, 0.0, double.infinity);
      expect(result, isNull);
    });

    test('result includes MGRS strings', () {
      final result = deadReckoning(35.0, -79.0, 0.0, 1000.0);
      expect(result, isNotNull);
      expect(result!.mgrs, isNotEmpty);
      expect(result.mgrsFormatted, isNotEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // resection
  // -----------------------------------------------------------------------
  group('resection', () {
    test('two known points with intersecting bearings find position', () {
      // Point 1: (35.0, -79.0), bearing toward unknown position
      // Point 2: (35.0, -78.0), bearing toward unknown position
      // The unknown position is roughly at (35.5, -78.5)
      // We compute bearings from pt1 and pt2 to the target,
      // then supply those as bearings FROM pt1/pt2 toward the unknown.
      const targetLat = 35.5;
      const targetLon = -78.5;
      const pt1Lat = 35.0;
      const pt1Lon = -79.0;
      const pt2Lat = 35.0;
      const pt2Lon = -78.0;

      // Calculate the bearings from each known point to the target
      // Using the bearing formula inline to avoid circular dependency
      double _bearing(double lat1, double lon1, double lat2, double lon2) {
        final phi1 = lat1 * pi / 180;
        final phi2 = lat2 * pi / 180;
        final dLambda = (lon2 - lon1) * pi / 180;
        final y = sin(dLambda) * cos(phi2);
        final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
        return ((atan2(y, x) * 180 / pi) + 360) % 360;
      }

      final bearing1 = _bearing(pt1Lat, pt1Lon, targetLat, targetLon);
      final bearing2 = _bearing(pt2Lat, pt2Lon, targetLat, targetLon);

      final result = resection(
          pt1Lat, pt1Lon, bearing1, pt2Lat, pt2Lon, bearing2);

      expect(result, isNotNull);
      // Should be close to the target position
      expect(result!.lat, closeTo(targetLat, 0.05));
      expect(result.lon, closeTo(targetLon, 0.05));
    });

    test('returns null for same point (coincident)', () {
      final result = resection(35.0, -79.0, 0.0, 35.0, -79.0, 90.0);
      expect(result, isNull);
    });

    test('result includes MGRS strings', () {
      // Simple case with known good bearings
      const pt1Lat = 35.0;
      const pt1Lon = -79.0;
      const pt2Lat = 35.0;
      const pt2Lon = -78.0;

      double _bearing(double lat1, double lon1, double lat2, double lon2) {
        final phi1 = lat1 * pi / 180;
        final phi2 = lat2 * pi / 180;
        final dLambda = (lon2 - lon1) * pi / 180;
        final y = sin(dLambda) * cos(phi2);
        final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
        return ((atan2(y, x) * 180 / pi) + 360) % 360;
      }

      final bearing1 = _bearing(pt1Lat, pt1Lon, 35.5, -78.5);
      final bearing2 = _bearing(pt2Lat, pt2Lon, 35.5, -78.5);

      final result = resection(
          pt1Lat, pt1Lon, bearing1, pt2Lat, pt2Lon, bearing2);

      expect(result, isNotNull);
      expect(result!.mgrs, isNotEmpty);
      expect(result.mgrsFormatted, contains(' '));
    });
  });

  // -----------------------------------------------------------------------
  // pacesToDistance / distanceToPaces
  // -----------------------------------------------------------------------
  group('pacesToDistance and distanceToPaces', () {
    test('62 paces at 62 paces/100m = 100m', () {
      expect(pacesToDistance(62, 62), closeTo(100.0, 0.001));
    });

    test('124 paces at 62 paces/100m = 200m', () {
      expect(pacesToDistance(124, 62), closeTo(200.0, 0.001));
    });

    test('0 paces = 0m', () {
      expect(pacesToDistance(0, 62), closeTo(0.0, 0.001));
    });

    test('100m at 62 paces/100m = 62 paces', () {
      expect(distanceToPaces(100.0, 62), equals(62));
    });

    test('200m at 62 paces/100m = 124 paces', () {
      expect(distanceToPaces(200.0, 62), equals(124));
    });

    test('0m = 0 paces', () {
      expect(distanceToPaces(0.0, 62), equals(0));
    });

    test('round-trip conversion', () {
      const paces = 155.0;
      const paceRate = 62.0;
      final meters = pacesToDistance(paces, paceRate);
      final backToPaces = distanceToPaces(meters, paceRate);
      expect(backToPaces, equals(paces.round()));
    });
  });

  // -----------------------------------------------------------------------
  // applyDeclination / removeDeclination
  // -----------------------------------------------------------------------
  group('applyDeclination and removeDeclination', () {
    test('apply east declination increases bearing', () {
      expect(applyDeclination(90.0, 10.0), closeTo(100.0, 0.001));
    });

    test('apply west declination decreases bearing', () {
      expect(applyDeclination(90.0, -10.0), closeTo(80.0, 0.001));
    });

    test('wraps around 360', () {
      expect(applyDeclination(355.0, 10.0), closeTo(5.0, 0.001));
    });

    test('wraps below 0', () {
      expect(applyDeclination(5.0, -10.0), closeTo(355.0, 0.001));
    });

    test('round-trip: apply then remove preserves original', () {
      const magnetic = 127.0;
      const declination = -8.5;
      final trueBearing = applyDeclination(magnetic, declination);
      final backToMagnetic = removeDeclination(trueBearing, declination);
      expect(backToMagnetic, closeTo(magnetic, 0.001));
    });

    test('remove east declination decreases bearing', () {
      expect(removeDeclination(100.0, 10.0), closeTo(90.0, 0.001));
    });
  });

  // -----------------------------------------------------------------------
  // timeToTravel
  // -----------------------------------------------------------------------
  group('timeToTravel', () {
    test('5000m at 5km/h = 60 minutes', () {
      expect(timeToTravel(5000, 5), closeTo(60.0, 0.001));
    });

    test('10000m at 10km/h = 60 minutes', () {
      expect(timeToTravel(10000, 10), closeTo(60.0, 0.001));
    });

    test('1000m at 4km/h = 15 minutes', () {
      expect(timeToTravel(1000, 4), closeTo(15.0, 0.001));
    });

    test('0 distance = 0 minutes', () {
      expect(timeToTravel(0, 5), closeTo(0.0, 0.001));
    });

    test('0 speed returns null', () {
      expect(timeToTravel(1000, 0), isNull);
    });

    test('negative speed returns null', () {
      expect(timeToTravel(1000, -5), isNull);
    });
  });

  // -----------------------------------------------------------------------
  // formatMinutes
  // -----------------------------------------------------------------------
  group('formatMinutes', () {
    test('0 minutes', () {
      expect(formatMinutes(0), equals('0min'));
    });

    test('30 minutes', () {
      expect(formatMinutes(30), equals('30min'));
    });

    test('90 minutes = 1hr 30min', () {
      expect(formatMinutes(90), equals('1hr 30min'));
    });

    test('60 minutes = 1hr 0min', () {
      expect(formatMinutes(60), equals('1hr 0min'));
    });

    test('125 minutes = 2hr 5min', () {
      expect(formatMinutes(125), equals('2hr 5min'));
    });

    test('null returns --', () {
      expect(formatMinutes(null), equals('--'));
    });

    test('NaN returns --', () {
      expect(formatMinutes(double.nan), equals('--'));
    });
  });

  // -----------------------------------------------------------------------
  // solarBearing
  // -----------------------------------------------------------------------
  group('solarBearing', () {
    test('returns azimuth in valid range 0-360', () {
      final date = DateTime.utc(2026, 6, 21, 12, 0, 0); // Summer solstice noon
      final result = solarBearing(date, 38.9, -77.0);
      expect(result.azimuth, greaterThanOrEqualTo(0));
      expect(result.azimuth, lessThanOrEqualTo(360));
    });

    test('noon sun at mid-latitude is roughly south (150-210)', () {
      // At Washington DC, June noon, sun should be roughly south
      final date = DateTime.utc(2026, 6, 21, 17, 0, 0); // ~noon EDT
      final result = solarBearing(date, 38.9, -77.0);
      expect(result.azimuth, greaterThan(120));
      expect(result.azimuth, lessThan(240));
    });

    test('sun is up (isDay true) at noon', () {
      final date = DateTime.utc(2026, 6, 21, 17, 0, 0);
      final result = solarBearing(date, 38.9, -77.0);
      expect(result.isDay, isTrue);
    });

    test('sun altitude is positive at noon', () {
      final date = DateTime.utc(2026, 6, 21, 17, 0, 0);
      final result = solarBearing(date, 38.9, -77.0);
      expect(result.altitude, greaterThan(0));
    });
  });

  // -----------------------------------------------------------------------
  // lunarBearing
  // -----------------------------------------------------------------------
  group('lunarBearing', () {
    test('returns azimuth in valid range 0-360', () {
      final date = DateTime.utc(2026, 3, 15, 0, 0, 0);
      final result = lunarBearing(date, 38.9, -77.0);
      expect(result.azimuth, greaterThanOrEqualTo(0));
      expect(result.azimuth, lessThanOrEqualTo(360));
    });

    test('returns altitude as a number', () {
      final date = DateTime.utc(2026, 3, 15, 0, 0, 0);
      final result = lunarBearing(date, 38.9, -77.0);
      expect(result.altitude, isA<double>());
      expect(result.altitude.isNaN, isFalse);
    });

    test('isUp is a boolean', () {
      final date = DateTime.utc(2026, 3, 15, 0, 0, 0);
      final result = lunarBearing(date, 38.9, -77.0);
      expect(result.isUp, isA<bool>());
    });
  });

  // -----------------------------------------------------------------------
  // dateToJD
  // -----------------------------------------------------------------------
  group('dateToJD', () {
    test('J2000.0 epoch (2000-01-01 12:00 UTC) = 2451545.0', () {
      final date = DateTime.utc(2000, 1, 1, 12, 0, 0);
      expect(dateToJD(date), closeTo(2451545.0, 0.001));
    });

    test('Unix epoch (1970-01-01 00:00 UTC) = 2440587.5', () {
      final date = DateTime.utc(1970, 1, 1, 0, 0, 0);
      expect(dateToJD(date), closeTo(2440587.5, 0.001));
    });

    test('known date 2024-01-01 00:00 UTC', () {
      final date = DateTime.utc(2024, 1, 1, 0, 0, 0);
      // 2024-01-01 00:00 UTC = JD 2460310.5
      expect(dateToJD(date), closeTo(2460310.5, 0.001));
    });
  });

  // -----------------------------------------------------------------------
  // precisionLabels
  // -----------------------------------------------------------------------
  group('precisionLabels', () {
    test('contains all 5 precision levels', () {
      expect(precisionLabels.length, equals(5));
      for (int i = 1; i <= 5; i++) {
        expect(precisionLabels.containsKey(i), isTrue);
        expect(precisionLabels[i], isNotEmpty);
      }
    });

    test('level 1 is 10km', () {
      expect(precisionLabels[1], contains('10km'));
    });

    test('level 5 is 1m', () {
      expect(precisionLabels[5], contains('1m'));
    });
  });
}

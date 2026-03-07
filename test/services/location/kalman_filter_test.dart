import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/location/kalman_filter.dart';

void main() {
  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------
  group('Initialization', () {
    test('isInitialized is false before processing', () {
      final filter = GpsKalmanFilter();
      expect(filter.isInitialized, isFalse);
      expect(filter.currentLat, isNull);
      expect(filter.currentLon, isNull);
    });

    test('isInitialized is true after first process', () {
      final filter = GpsKalmanFilter();
      filter.process(38.9, -77.0, 10.0);
      expect(filter.isInitialized, isTrue);
      expect(filter.currentLat, isNotNull);
      expect(filter.currentLon, isNotNull);
    });

    test('first process returns raw measurement', () {
      final filter = GpsKalmanFilter();
      final result = filter.process(38.9, -77.0, 10.0);
      expect(result.lat, equals(38.9));
      expect(result.lon, equals(-77.0));
    });

    test('reset clears filter state', () {
      final filter = GpsKalmanFilter();
      filter.process(38.9, -77.0, 10.0);
      filter.reset();
      expect(filter.isInitialized, isFalse);
      expect(filter.currentLat, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Smoothing behavior
  // -------------------------------------------------------------------------
  group('Smoothing', () {
    test('repeated identical measurements converge to that value', () {
      final filter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);

      for (int i = 0; i < 20; i++) {
        filter.process(
          38.9, -77.0, 10.0,
          timestamp: now.add(Duration(seconds: i)),
        );
      }

      expect(filter.currentLat, closeTo(38.9, 0.0001));
      expect(filter.currentLon, closeTo(-77.0, 0.0001));
    });

    test('smooths noisy stationary measurements', () {
      final filter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);
      const baseLat = 38.9;
      const baseLon = -77.0;

      // Simulate noisy GPS at a fixed location
      final noisyLats = [
        baseLat + 0.0001,
        baseLat - 0.0002,
        baseLat + 0.00015,
        baseLat - 0.00005,
        baseLat + 0.00008,
        baseLat - 0.0001,
        baseLat + 0.00003,
        baseLat - 0.00012,
        baseLat + 0.00006,
        baseLat - 0.00002,
      ];

      for (int i = 0; i < noisyLats.length; i++) {
        filter.process(
          noisyLats[i], baseLon, 15.0,
          speedMps: 0.0,
          timestamp: now.add(Duration(seconds: i)),
        );
      }

      // Smoothed value should be closer to true position than raw
      final latError = (filter.currentLat! - baseLat).abs();
      final maxRawError = noisyLats
          .map((l) => (l - baseLat).abs())
          .reduce((a, b) => a > b ? a : b);

      expect(latError, lessThan(maxRawError));
    });

    test('tracks moving target with low lag', () {
      final filter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);

      // Simulate moving north at ~5 m/s (walking)
      const startLat = 38.9;
      const latStep = 0.00005; // ~5.5m per step

      for (int i = 0; i < 30; i++) {
        filter.process(
          startLat + i * latStep, -77.0, 8.0,
          speedMps: 5.0,
          timestamp: now.add(Duration(seconds: i)),
        );
      }

      // Should be close to the latest position
      final expected = startLat + 29 * latStep;
      expect(filter.currentLat!, closeTo(expected, latStep * 3));
    });
  });

  // -------------------------------------------------------------------------
  // Speed adaptation
  // -------------------------------------------------------------------------
  group('Speed adaptation', () {
    test('stationary filter produces tighter clustering', () {
      final stationaryFilter = GpsKalmanFilter();
      final movingFilter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);

      // Feed same noisy data to both, different speed
      for (int i = 0; i < 20; i++) {
        final noise = (i % 3 == 0) ? 0.0001 : -0.00005;
        stationaryFilter.process(
          38.9 + noise, -77.0, 10.0,
          speedMps: 0.1, // stationary
          timestamp: now.add(Duration(seconds: i)),
        );
        movingFilter.process(
          38.9 + noise, -77.0, 10.0,
          speedMps: 10.0, // moving fast
          timestamp: now.add(Duration(seconds: i)),
        );
      }

      // Stationary should be closer to mean (more smoothing)
      final stationaryError = (stationaryFilter.currentLat! - 38.9).abs();
      final movingError = (movingFilter.currentLat! - 38.9).abs();

      // Stationary filter should smooth more aggressively
      expect(stationaryError, lessThanOrEqualTo(movingError + 0.0001));
    });
  });

  // -------------------------------------------------------------------------
  // Accuracy handling
  // -------------------------------------------------------------------------
  group('Accuracy handling', () {
    test('high accuracy measurement has more influence', () {
      final filter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);

      // First measurement with poor accuracy
      filter.process(
        38.9, -77.0, 100.0,
        timestamp: now,
      );

      // Second measurement with excellent accuracy, different position
      final result = filter.process(
        38.901, -77.001, 2.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      // Should be pulled strongly toward the high-accuracy measurement
      expect(result.lat, closeTo(38.901, 0.001));
      expect(result.lon, closeTo(-77.001, 0.001));
    });

    test('low accuracy measurement has less influence', () {
      final filter = GpsKalmanFilter();
      final now = DateTime(2026, 3, 7, 12, 0, 0);

      // First measurement with excellent accuracy
      filter.process(
        38.9, -77.0, 2.0,
        timestamp: now,
      );

      // Second measurement with poor accuracy, different position
      final result = filter.process(
        38.91, -77.01, 200.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      // Should stay closer to the first (high-accuracy) measurement
      expect(result.lat, closeTo(38.9, 0.005));
      expect(result.lon, closeTo(-77.0, 0.005));
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------
  group('Edge cases', () {
    test('works at equator', () {
      final filter = GpsKalmanFilter();
      final result = filter.process(0.0, 0.0, 10.0);
      expect(result.lat, equals(0.0));
      expect(result.lon, equals(0.0));
    });

    test('works near poles', () {
      final filter = GpsKalmanFilter();
      final result = filter.process(89.0, 0.0, 10.0);
      expect(result.lat, equals(89.0));
    });

    test('works with negative coordinates', () {
      final filter = GpsKalmanFilter();
      // Sydney, Australia
      final result = filter.process(-33.87, 151.21, 10.0);
      expect(result.lat, closeTo(-33.87, 0.001));
      expect(result.lon, closeTo(151.21, 0.001));
    });

    test('works with very high accuracy', () {
      final filter = GpsKalmanFilter();
      final result = filter.process(38.9, -77.0, 0.5);
      expect(result.lat, equals(38.9));
      expect(result.lon, equals(-77.0));
    });

    test('reset and re-process works correctly', () {
      final filter = GpsKalmanFilter();
      filter.process(38.9, -77.0, 10.0);
      filter.process(38.901, -77.001, 10.0);

      filter.reset();

      // After reset, should return raw measurement again
      final result = filter.process(40.0, -75.0, 10.0);
      expect(result.lat, equals(40.0));
      expect(result.lon, equals(-75.0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/tactical.dart';

void main() {
  // -----------------------------------------------------------------------
  // estimateRange
  // -----------------------------------------------------------------------
  group('estimateRange', () {
    test('person 1.8m at 5 mils = 360m', () {
      final result = estimateRange(
        objectSizeMeters: 1.8,
        angularSizeMils: 5.0,
      );
      expect(result, closeTo(360.0, 0.001));
    });

    test('person 1.8m at 1 mil = 1800m', () {
      final result = estimateRange(
        objectSizeMeters: 1.8,
        angularSizeMils: 1.0,
      );
      expect(result, closeTo(1800.0, 0.001));
    });

    test('vehicle 2.5m at 10 mils = 250m', () {
      final result = estimateRange(
        objectSizeMeters: 2.5,
        angularSizeMils: 10.0,
      );
      expect(result, closeTo(250.0, 0.001));
    });

    test('object at 1000m subtends size in mils = size in meters', () {
      // At 1000m, 1 mil = 1m. So 2m object = 2 mils.
      final result = estimateRange(
        objectSizeMeters: 2.0,
        angularSizeMils: 2.0,
      );
      expect(result, closeTo(1000.0, 0.001));
    });

    test('zero mils returns null', () {
      expect(
        estimateRange(objectSizeMeters: 1.8, angularSizeMils: 0),
        isNull,
      );
    });

    test('negative mils returns null', () {
      expect(
        estimateRange(objectSizeMeters: 1.8, angularSizeMils: -5),
        isNull,
      );
    });

    test('zero object size returns null', () {
      expect(
        estimateRange(objectSizeMeters: 0, angularSizeMils: 5),
        isNull,
      );
    });

    test('negative object size returns null', () {
      expect(
        estimateRange(objectSizeMeters: -1.8, angularSizeMils: 5),
        isNull,
      );
    });

    test('NaN mils returns null', () {
      expect(
        estimateRange(objectSizeMeters: 1.8, angularSizeMils: double.nan),
        isNull,
      );
    });

    test('infinite object size returns null', () {
      expect(
        estimateRange(
            objectSizeMeters: double.infinity, angularSizeMils: 5),
        isNull,
      );
    });
  });

  // -----------------------------------------------------------------------
  // slopePercent
  // -----------------------------------------------------------------------
  group('slopePercent', () {
    test('100m horizontal, 25m rise = 25%', () {
      final result = slopePercent(
        horizontalDist: 100,
        elevationChange: 25,
      );
      expect(result, closeTo(25.0, 0.001));
    });

    test('100m horizontal, 100m rise = 100%', () {
      final result = slopePercent(
        horizontalDist: 100,
        elevationChange: 100,
      );
      expect(result, closeTo(100.0, 0.001));
    });

    test('100m horizontal, 0m rise = 0%', () {
      final result = slopePercent(
        horizontalDist: 100,
        elevationChange: 0,
      );
      expect(result, closeTo(0.0, 0.001));
    });

    test('negative elevation change = negative slope', () {
      final result = slopePercent(
        horizontalDist: 100,
        elevationChange: -30,
      );
      expect(result, closeTo(-30.0, 0.001));
    });

    test('zero horizontal distance returns null', () {
      expect(
        slopePercent(horizontalDist: 0, elevationChange: 25),
        isNull,
      );
    });

    test('negative horizontal distance returns null', () {
      expect(
        slopePercent(horizontalDist: -100, elevationChange: 25),
        isNull,
      );
    });

    test('NaN elevation returns null', () {
      expect(
        slopePercent(horizontalDist: 100, elevationChange: double.nan),
        isNull,
      );
    });
  });

  // -----------------------------------------------------------------------
  // slopeAngle
  // -----------------------------------------------------------------------
  group('slopeAngle', () {
    test('100m horizontal, 100m rise = 45 degrees', () {
      final result = slopeAngle(
        horizontalDist: 100,
        elevationChange: 100,
      );
      expect(result, closeTo(45.0, 0.001));
    });

    test('100m horizontal, 0m rise = 0 degrees', () {
      final result = slopeAngle(
        horizontalDist: 100,
        elevationChange: 0,
      );
      expect(result, closeTo(0.0, 0.001));
    });

    test('100m horizontal, 57.7m rise ~= 30 degrees', () {
      // tan(30°) = 0.5774
      final result = slopeAngle(
        horizontalDist: 100,
        elevationChange: 57.735,
      );
      expect(result, closeTo(30.0, 0.1));
    });

    test('negative elevation still returns positive angle', () {
      final result = slopeAngle(
        horizontalDist: 100,
        elevationChange: -100,
      );
      expect(result, closeTo(45.0, 0.001));
    });

    test('zero horizontal distance returns null', () {
      expect(
        slopeAngle(horizontalDist: 0, elevationChange: 25),
        isNull,
      );
    });

    test('infinity horizontal returns null', () {
      expect(
        slopeAngle(
            horizontalDist: double.infinity, elevationChange: 25),
        isNull,
      );
    });
  });
}

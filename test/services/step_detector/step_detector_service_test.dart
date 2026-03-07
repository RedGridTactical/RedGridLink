import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/step_detector/step_detector_service.dart';

void main() {
  group('StepDetectorConfig', () {
    test('has sensible defaults', () {
      const config = StepDetectorConfig();
      expect(config.magnitudeThreshold, 10.8);
      expect(config.minStepInterval, const Duration(milliseconds: 300));
    });

    test('accepts custom values', () {
      const config = StepDetectorConfig(
        magnitudeThreshold: 12.0,
        minStepInterval: Duration(milliseconds: 500),
      );
      expect(config.magnitudeThreshold, 12.0);
      expect(config.minStepInterval.inMilliseconds, 500);
    });
  });

  group('StepDetectorService', () {
    late StepDetectorService service;

    setUp(() {
      service = StepDetectorService(
        config: const StepDetectorConfig(
          magnitudeThreshold: 10.8,
          minStepInterval: Duration(milliseconds: 300),
        ),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initial step count is zero', () {
      expect(service.stepCount, 0);
    });

    test('isActive is false before start', () {
      expect(service.isActive, false);
    });

    test('detects step on rising edge above threshold', () {
      // At rest: magnitude ~ 9.8 (below threshold of 10.8)
      service.processAccelerationForTesting(0, 0, 9.8);
      expect(service.stepCount, 0);

      // Walking peak: magnitude ~ 12.0 (above threshold)
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 1);
    });

    test('does not double-count while above threshold', () {
      // Below threshold
      service.processAccelerationForTesting(0, 0, 9.8);

      // First crossing above threshold
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 1);

      // Still above threshold — should NOT count again
      service.processAccelerationForTesting(0, 0, 13.0);
      expect(service.stepCount, 1);

      // Still above threshold
      service.processAccelerationForTesting(0, 0, 11.5);
      expect(service.stepCount, 1);
    });

    test('counts second step after dropping below then rising above', () {
      // Step 1: below → above
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 1);

      // Need to advance time past debounce interval
      service.lastStepTimeForTesting =
          DateTime.now().subtract(const Duration(milliseconds: 400));

      // Drop below threshold
      service.processAccelerationForTesting(0, 0, 9.5);

      // Step 2: below → above again
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 2);
    });

    test('respects minimum step interval (debounce)', () {
      // First step
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 1);

      // Immediately drop and rise again (within 300ms debounce)
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);
      // Should still be 1 because debounce hasn't expired
      expect(service.stepCount, 1);
    });

    test('works with multi-axis acceleration', () {
      // Magnitude = sqrt(3^2 + 4^2 + 10^2) = sqrt(125) ≈ 11.18
      // This is above threshold of 10.8
      service.processAccelerationForTesting(0, 0, 9.8); // rest first
      service.processAccelerationForTesting(3.0, 4.0, 10.0);
      expect(service.stepCount, 1);
    });

    test('below-threshold acceleration does not trigger step', () {
      // Magnitude = sqrt(1^2 + 1^2 + 9.5^2) = sqrt(92.25) ≈ 9.6
      service.processAccelerationForTesting(1.0, 1.0, 9.5);
      expect(service.stepCount, 0);
    });

    test('exactly at threshold does not trigger step', () {
      // Need to be ABOVE threshold, not equal
      const threshold = 10.8;
      service.processAccelerationForTesting(0, 0, 9.8); // below
      service.processAccelerationForTesting(0, 0, threshold); // exactly at
      expect(service.stepCount, 0);
    });

    test('reset sets count to zero', () {
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);
      expect(service.stepCount, 1);

      service.reset();
      expect(service.stepCount, 0);
    });

    test('step stream emits cumulative step counts', () async {
      final steps = <int>[];
      service.stepStream.listen(steps.add);

      // Step 1
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);

      // Advance past debounce
      service.lastStepTimeForTesting =
          DateTime.now().subtract(const Duration(milliseconds: 400));

      // Step 2
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);

      // Allow stream to deliver
      await Future<void>.delayed(Duration.zero);

      expect(steps, [1, 2]);
    });

    test('step stream emits zero on reset', () async {
      final steps = <int>[];
      service.stepStream.listen(steps.add);

      // Count a step
      service.processAccelerationForTesting(0, 0, 9.8);
      service.processAccelerationForTesting(0, 0, 12.0);

      // Reset
      service.reset();

      await Future<void>.delayed(Duration.zero);

      expect(steps, [1, 0]);
    });

    test('custom threshold is respected', () {
      final sensitive = StepDetectorService(
        config: const StepDetectorConfig(
          magnitudeThreshold: 10.0,
          minStepInterval: Duration(milliseconds: 0),
        ),
      );
      addTearDown(sensitive.dispose);

      // Magnitude 10.5 is above custom threshold of 10.0
      sensitive.processAccelerationForTesting(0, 0, 9.0); // below
      sensitive.processAccelerationForTesting(0, 0, 10.5);
      expect(sensitive.stepCount, 1);
    });

    test('custom debounce interval is respected', () {
      final slowDebounce = StepDetectorService(
        config: const StepDetectorConfig(
          magnitudeThreshold: 10.8,
          minStepInterval: Duration(seconds: 1),
        ),
      );
      addTearDown(slowDebounce.dispose);

      // Step 1
      slowDebounce.processAccelerationForTesting(0, 0, 9.8);
      slowDebounce.processAccelerationForTesting(0, 0, 12.0);
      expect(slowDebounce.stepCount, 1);

      // Advance only 500ms (less than 1s debounce)
      slowDebounce.lastStepTimeForTesting =
          DateTime.now().subtract(const Duration(milliseconds: 500));
      slowDebounce.processAccelerationForTesting(0, 0, 9.8);
      slowDebounce.processAccelerationForTesting(0, 0, 12.0);
      expect(slowDebounce.stepCount, 1); // Still 1

      // Advance past 1s debounce
      slowDebounce.lastStepTimeForTesting =
          DateTime.now().subtract(const Duration(seconds: 2));
      slowDebounce.processAccelerationForTesting(0, 0, 9.8);
      slowDebounce.processAccelerationForTesting(0, 0, 12.0);
      expect(slowDebounce.stepCount, 2); // Now 2
    });

    test('orientation independence — phone held sideways', () {
      // Phone on its side: gravity is mostly on X axis
      // Magnitude = sqrt(9.8^2 + 0^2 + 0^2) = 9.8 (rest)
      service.processAccelerationForTesting(9.8, 0, 0);
      expect(service.stepCount, 0);

      // Walking peak on side: magnitude > threshold
      // sqrt(11^2 + 2^2 + 1^2) = sqrt(126) ≈ 11.22
      service.processAccelerationForTesting(11.0, 2.0, 1.0);
      expect(service.stepCount, 1);
    });

    test('orientation independence — phone upside down', () {
      // Phone upside down: negative Z
      service.processAccelerationForTesting(0, 0, -9.8);
      expect(service.stepCount, 0);

      // Walking peak upside down: magnitude > threshold
      // sqrt(0 + 0 + (-12)^2) = 12
      service.processAccelerationForTesting(0, 0, -12.0);
      expect(service.stepCount, 1);
    });

    test('simulated walking produces correct step count', () {
      // Simulate 5 walking steps with realistic acceleration pattern:
      // rest → peak → rest → peak → ...
      // Each cycle is > 300ms apart (via lastStepTimeForTesting)

      int expectedSteps = 0;
      for (var i = 0; i < 5; i++) {
        // Ensure debounce has passed
        if (i > 0) {
          service.lastStepTimeForTesting =
              DateTime.now().subtract(const Duration(milliseconds: 400));
        }

        // Swing phase (below threshold)
        service.processAccelerationForTesting(0, 0, 9.2 + (i * 0.1));

        // Strike phase (above threshold)
        service.processAccelerationForTesting(
            0, 0, 11.5 + (i * 0.3));
        expectedSteps++;
        expect(service.stepCount, expectedSteps);
      }

      expect(service.stepCount, 5);
    });

    test('zero debounce allows rapid step detection', () {
      final rapid = StepDetectorService(
        config: const StepDetectorConfig(
          magnitudeThreshold: 10.8,
          minStepInterval: Duration.zero,
        ),
      );
      addTearDown(rapid.dispose);

      // Rapid oscillation should count each crossing
      for (var i = 0; i < 10; i++) {
        rapid.processAccelerationForTesting(0, 0, 9.0);
        rapid.processAccelerationForTesting(0, 0, 12.0);
      }
      expect(rapid.stepCount, 10);
    });

    test('gravity-only readings never trigger steps', () {
      // Feed many readings of just gravity — no steps should register
      for (var i = 0; i < 100; i++) {
        service.processAccelerationForTesting(
          0.1 * sin(i * 0.1), // tiny noise
          0.05 * cos(i * 0.15),
          9.81 + 0.02 * sin(i * 0.2), // gravity with noise
        );
      }
      expect(service.stepCount, 0);
    });
  });
}

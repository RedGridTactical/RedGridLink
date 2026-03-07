// Accelerometer-based step detection service.
//
// Uses raw accelerometer data from sensors_plus to detect walking steps
// via peak detection on the acceleration magnitude signal. This provides
// a platform-agnostic step counter that doesn't require special permissions
// beyond what the app already has.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sensors_plus/sensors_plus.dart';

/// Configuration for the step detection algorithm.
class StepDetectorConfig {
  /// Minimum acceleration magnitude to register as a step peak.
  ///
  /// At rest, magnitude ~ 9.8 m/s^2 (gravity). Walking produces peaks
  /// typically between 10.5 and 15 m/s^2. Default threshold of 10.8
  /// balances sensitivity (catching light steps) with rejecting noise.
  final double magnitudeThreshold;

  /// Minimum time between detected steps (debounce).
  ///
  /// Normal walking cadence is ~2 steps/second (500ms between steps).
  /// Minimum of 300ms allows up to ~3.3 steps/second for running,
  /// while filtering out sensor jitter and double-counts.
  final Duration minStepInterval;

  const StepDetectorConfig({
    this.magnitudeThreshold = 10.8,
    this.minStepInterval = const Duration(milliseconds: 300),
  });
}

/// Detects walking steps using raw accelerometer data.
///
/// The algorithm:
/// 1. Receives accelerometer events (x, y, z) from [sensors_plus].
/// 2. Computes the acceleration magnitude: sqrt(x^2 + y^2 + z^2).
/// 3. Detects upward threshold crossings (low→high transition).
/// 4. Enforces a minimum interval between steps to prevent jitter.
///
/// This approach is orientation-independent — it works regardless of
/// how the phone is held because it uses total magnitude, not any
/// single axis.
class StepDetectorService {
  final StepDetectorConfig config;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();

  int _stepCount = 0;
  DateTime? _lastStepTime;
  bool _wasAboveThreshold = false;

  /// Current step count since [start] was called.
  int get stepCount => _stepCount;

  /// Stream of step counts. Emits the cumulative count on each new step.
  Stream<int> get stepStream => _stepController.stream;

  /// Whether the detector is currently listening to accelerometer events.
  bool get isActive => _accelSub != null;

  StepDetectorService({
    this.config = const StepDetectorConfig(),
  });

  /// Start listening to accelerometer events and detecting steps.
  ///
  /// Resets the step count to zero. Call [stop] to cease detection.
  void start() {
    _stepCount = 0;
    _lastStepTime = null;
    _wasAboveThreshold = false;

    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20 Hz
    ).listen(_onAccelerometerEvent);
  }

  /// Stop listening to accelerometer events.
  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// Reset step count to zero without stopping detection.
  void reset() {
    _stepCount = 0;
    if (!_stepController.isClosed) {
      _stepController.add(_stepCount);
    }
  }

  /// Process a single accelerometer event for step detection.
  ///
  /// Exposed for testing via [processEventForTesting].
  void _onAccelerometerEvent(AccelerometerEvent event) {
    _processAcceleration(event.x, event.y, event.z);
  }

  /// Core step detection algorithm.
  ///
  /// Computes acceleration magnitude and detects upward threshold
  /// crossings with debounce.
  void _processAcceleration(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    final now = DateTime.now();

    final isAbove = magnitude > config.magnitudeThreshold;

    // Detect rising edge: was below threshold, now above it.
    if (isAbove && !_wasAboveThreshold) {
      // Check debounce interval.
      if (_lastStepTime == null ||
          now.difference(_lastStepTime!) >= config.minStepInterval) {
        _stepCount++;
        _lastStepTime = now;
        if (!_stepController.isClosed) {
          _stepController.add(_stepCount);
        }
      }
    }

    _wasAboveThreshold = isAbove;
  }

  /// Process raw acceleration values for testing purposes.
  ///
  /// Allows unit tests to feed synthetic data without needing a real
  /// accelerometer sensor.
  @visibleForTesting
  void processAccelerationForTesting(double x, double y, double z) {
    _processAcceleration(x, y, z);
  }

  /// Override the last step time for testing debounce behavior.
  @visibleForTesting
  set lastStepTimeForTesting(DateTime? time) {
    _lastStepTime = time;
  }

  /// Dispose all resources.
  void dispose() {
    stop();
    _stepController.close();
  }
}

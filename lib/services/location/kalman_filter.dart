/// Simple 1D Kalman filter for GPS coordinate smoothing.
///
/// Applies independent Kalman filtering to latitude and longitude.
/// Process noise adapts based on movement speed: higher noise when
/// moving allows the filter to track fast changes, while lower noise
/// when stationary smooths out GPS jitter.
///
/// Reference: Optimal filtering by Anderson & Moore (simplified 1D).

import 'dart:math';

/// 1D Kalman filter state for a single dimension (lat or lon).
class _KalmanState {
  /// Current estimated value.
  double x;

  /// Current estimate uncertainty (error covariance).
  double p;

  _KalmanState({required this.x, required this.p});
}

/// GPS Kalman filter that smooths noisy position updates.
///
/// Usage:
/// ```dart
/// final filter = GpsKalmanFilter();
/// final smoothed = filter.process(rawLat, rawLon, accuracy, speed);
/// ```
class GpsKalmanFilter {
  _KalmanState? _latState;
  _KalmanState? _lonState;
  DateTime? _lastTimestamp;

  /// Minimum process noise per second (degrees²/s).
  /// Prevents the filter from becoming too rigid.
  static const double _minProcessNoise = 1e-9;

  /// Process noise scaling factor for walking speed (~1.5 m/s).
  /// Higher values make the filter more responsive to movement.
  static const double _walkingNoiseScale = 3e-7;

  /// Process noise scaling factor for running/driving.
  static const double _fastNoiseScale = 1e-5;

  /// Speed threshold (m/s) below which we consider stationary.
  static const double _stationaryThreshold = 0.3;

  /// Speed threshold (m/s) above which we use fast noise.
  static const double _fastThreshold = 5.0;

  /// Reset the filter state. Next call to [process] will
  /// initialize from the raw measurement.
  void reset() {
    _latState = null;
    _lonState = null;
    _lastTimestamp = null;
  }

  /// Process a raw GPS measurement and return smoothed coordinates.
  ///
  /// [lat] Raw latitude in decimal degrees.
  /// [lon] Raw longitude in decimal degrees.
  /// [accuracyMeters] GPS-reported horizontal accuracy (meters).
  /// [speedMps] Current speed in meters per second.
  /// [timestamp] Measurement timestamp (defaults to now).
  ///
  /// Returns `({double lat, double lon})` with smoothed coordinates.
  ({double lat, double lon}) process(
    double lat,
    double lon,
    double accuracyMeters, {
    double speedMps = 0.0,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // Convert accuracy from meters to approximate degrees.
    // 1 degree latitude ≈ 111,320 m. Longitude varies by cos(lat).
    final accuracyDegLat = accuracyMeters / 111320.0;
    final accuracyDegLon =
        accuracyMeters / (111320.0 * cos(lat * pi / 180.0)).abs();

    // Measurement noise (R) — from GPS accuracy.
    final rLat = accuracyDegLat * accuracyDegLat;
    final rLon = accuracyDegLon * accuracyDegLon;

    // Time delta for process noise scaling.
    final dt = _lastTimestamp != null
        ? now.difference(_lastTimestamp!).inMilliseconds / 1000.0
        : 1.0;
    _lastTimestamp = now;

    // Process noise (Q) — adapts to movement speed.
    final q = _computeProcessNoise(speedMps, dt);

    // Initialize or update lat filter.
    if (_latState == null) {
      _latState = _KalmanState(x: lat, p: rLat);
    } else {
      _update(_latState!, lat, rLat, q);
    }

    // Initialize or update lon filter.
    if (_lonState == null) {
      _lonState = _KalmanState(x: lon, p: rLon);
    } else {
      _update(_lonState!, lon, rLon, q);
    }

    return (lat: _latState!.x, lon: _lonState!.x);
  }

  /// Run a single Kalman filter predict+update cycle.
  void _update(_KalmanState state, double measurement, double r, double q) {
    // Predict step: add process noise to uncertainty.
    state.p += q;

    // Update step: compute Kalman gain.
    final k = state.p / (state.p + r);

    // Update estimate with measurement.
    state.x += k * (measurement - state.x);

    // Update uncertainty.
    state.p *= (1 - k);
  }

  /// Compute process noise based on movement speed and time delta.
  ///
  /// Stationary: very low noise → strong smoothing.
  /// Walking: moderate noise → balanced tracking.
  /// Fast movement: high noise → responsive tracking.
  double _computeProcessNoise(double speedMps, double dt) {
    final double scale;
    if (speedMps < _stationaryThreshold) {
      scale = _minProcessNoise;
    } else if (speedMps < _fastThreshold) {
      // Linear interpolation between walking and fast.
      final t = (speedMps - _stationaryThreshold) /
          (_fastThreshold - _stationaryThreshold);
      scale = _walkingNoiseScale + t * (_fastNoiseScale - _walkingNoiseScale);
    } else {
      scale = _fastNoiseScale;
    }

    return scale * dt;
  }

  /// Current smoothed latitude, or null if no data processed.
  double? get currentLat => _latState?.x;

  /// Current smoothed longitude, or null if no data processed.
  double? get currentLon => _lonState?.x;

  /// Whether the filter has been initialized with at least one measurement.
  bool get isInitialized => _latState != null && _lonState != null;
}

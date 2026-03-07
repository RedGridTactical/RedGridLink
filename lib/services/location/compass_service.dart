// Compass heading service using magnetometer + accelerometer from sensors_plus.
//
// Provides a stream of heading degrees (0-360, 0=North) for use when
// the device is stationary and GPS heading is unavailable/stale.
//
// Uses the tilt-compensated approach: combines accelerometer gravity
// vector with magnetometer readings to compute true compass heading.

import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Service that provides a stream of compass headings in degrees (0-360).
///
/// This is derived from the device magnetometer and accelerometer,
/// making it work even when the device is stationary (unlike GPS heading).
class CompassService {
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final StreamController<double> _headingController =
      StreamController<double>.broadcast();

  /// Latest accelerometer readings for tilt compensation.
  double _ax = 0, _ay = 0, _az = -9.8;

  /// Latest magnetometer readings.
  double _mx = 0, _my = 0, _mz = 0;

  /// Low-pass filter alpha (smoothing factor, 0-1).
  /// Lower = smoother but slower to respond.
  static const double _alpha = 0.15;

  /// Smoothed heading value.
  double _smoothedHeading = 0;

  /// Whether the service has been initialized.
  bool _isRunning = false;

  /// Stream of compass heading in degrees (0-360, 0 = North).
  Stream<double> get headingStream => _headingController.stream;

  /// Current smoothed heading.
  double get currentHeading => _smoothedHeading;

  /// Start listening to sensor streams.
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      _ax = event.x;
      _ay = event.y;
      _az = event.z;
    });

    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      _mx = event.x;
      _my = event.y;
      _mz = event.z;
      _computeHeading();
    });
  }

  /// Stop listening to sensor streams.
  void stop() {
    _isRunning = false;
    _magSub?.cancel();
    _magSub = null;
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// Compute tilt-compensated heading from accelerometer + magnetometer.
  void _computeHeading() {
    // Normalize gravity vector
    final norm = sqrt(_ax * _ax + _ay * _ay + _az * _az);
    if (norm < 0.1) return; // No valid gravity

    final gx = _ax / norm;
    final gy = _ay / norm;
    final gz = _az / norm;

    // East vector = cross product of magnetic field with gravity
    final ex = _my * gz - _mz * gy;
    final ey = _mz * gx - _mx * gz;

    // North vector (x-component only — sufficient for 2D heading).
    // The y-component (gz*ex - gx*ey) is unused because atan2(east_x, north_x)
    // gives us the heading angle directly in the horizontal plane.
    final nx = gy * ey - gz * ex;

    // Heading from atan2
    var heading = atan2(ex, nx) * 180.0 / pi;

    // Normalize to 0-360
    if (heading < 0) heading += 360;

    // Apply low-pass filter for smooth compass
    heading = _lowPassFilter(heading, _smoothedHeading);
    _smoothedHeading = heading;

    if (!_headingController.isClosed) {
      _headingController.add(heading);
    }
  }

  /// Low-pass filter that handles the 0/360 degree wrap-around.
  double _lowPassFilter(double newValue, double oldValue) {
    // Handle wrap-around (e.g., jumping from 350 to 10)
    var diff = newValue - oldValue;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    var result = oldValue + _alpha * diff;
    if (result < 0) result += 360;
    if (result >= 360) result -= 360;
    return result;
  }

  /// Release resources.
  void dispose() {
    stop();
    _headingController.close();
  }
}

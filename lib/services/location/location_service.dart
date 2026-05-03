import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:red_grid_link/core/logging/red_log.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';
import 'package:red_grid_link/services/location/kalman_filter.dart';
import 'package:red_grid_link/services/location/permission_handler_service.dart';

/// Main location service providing GPS stream, permission handling,
/// and track recording.
///
/// Wraps the geolocator package and enriches every position with
/// MGRS coordinates. Optionally records [TrackPoint]s to the database
/// via [TrackRepository] when tracking is active.
class LocationService {
  final TrackRepository _trackRepository;
  final PermissionHandlerService _permissionHandler;

  /// Broadcast controller that re-publishes filtered positions
  /// with MGRS data populated.
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  /// Subscription to the underlying geolocator position stream.
  StreamSubscription<geo.Position>? _geoSubscription;

  /// Whether track recording is currently active.
  bool _isTracking = false;

  /// The session ID associated with the current track recording.
  String? _currentSessionId;

  /// The most recently received position.
  Position? _lastPosition;

  /// Kalman filter for GPS smoothing.
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter();

  /// Whether GPS smoothing via Kalman filter is enabled.
  bool _smoothingEnabled = true;

  /// GPS accuracy level.
  geo.LocationAccuracy _accuracy = geo.LocationAccuracy.best;

  /// Minimum distance (in meters) between position updates.
  /// Lower values drain battery faster; 5m is a good balance for
  /// outdoor movement on foot.
  int _distanceFilter = 5;

  /// Minimum time interval between position updates.
  Duration _updateInterval = const Duration(seconds: 1);

  LocationService({
    required TrackRepository trackRepository,
    PermissionHandlerService? permissionHandler,
  })  : _trackRepository = trackRepository,
        _permissionHandler = permissionHandler ?? PermissionHandlerService();

  // ---------------------------------------------------------------------------
  // GPS stream
  // ---------------------------------------------------------------------------

  /// Continuous stream of [Position] updates with MGRS populated.
  ///
  /// Positions are broadcast — multiple listeners are supported.
  /// The stream will not emit until [initialize] has been called and
  /// location permission is granted.
  Stream<Position> get positionStream => _positionController.stream;

  /// The last known position, or null if no fix has been obtained.
  Position? get lastPosition => _lastPosition;

  /// Obtain a single GPS fix and return it as a [Position] with MGRS.
  ///
  /// Returns null if permissions are denied or the service is disabled.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      final geoPos = await geo.GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: _accuracy,
        ),
      );
      final position = _convertPosition(geoPos);
      _lastPosition = position;
      return position;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Track recording
  // ---------------------------------------------------------------------------

  /// Whether track recording is currently active.
  bool get isTracking => _isTracking;

  /// The session ID for the current track, or null if not tracking.
  String? get currentSessionId => _currentSessionId;

  /// Start recording track points to the database.
  ///
  /// Each position update while tracking is active will be persisted
  /// as a [TrackPoint] via [TrackRepository].
  /// [sessionId] ties the track points to a particular session.
  /// If null, points are recorded without a session association.
  Future<void> startTracking(String? sessionId) async {
    _isTracking = true;
    _currentSessionId = sessionId;
  }

  /// Stop recording track points.
  ///
  /// The GPS stream continues; only database persistence stops.
  Future<void> stopTracking() async {
    _isTracking = false;
    _currentSessionId = null;
  }

  // ---------------------------------------------------------------------------
  // Permission handling
  // ---------------------------------------------------------------------------

  /// Check whether location permission is currently granted.
  Future<bool> checkPermission() async {
    final status = await _permissionHandler.checkStatus();
    return status == LocationPermissionStatus.granted;
  }

  /// Request location permission from the user.
  ///
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    final status = await _permissionHandler.requestPermission();
    return status == LocationPermissionStatus.granted;
  }

  /// Check whether the device's location service is enabled.
  Future<bool> isLocationEnabled() async {
    try {
      return await geo.GeolocatorPlatform.instance.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Get the detailed permission status.
  Future<LocationPermissionStatus> getPermissionStatus() =>
      _permissionHandler.checkStatus();

  /// Open the OS app settings (for permanently denied permissions).
  Future<bool> openAppSettings() => _permissionHandler.openSettings();

  /// Open the OS location settings (when GPS is disabled).
  Future<bool> openLocationSettings() =>
      _permissionHandler.openLocationSettings();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Set the minimum time interval between position updates.
  void setUpdateInterval(Duration interval) {
    _updateInterval = interval;
    // Restart the stream if it's currently active.
    if (_geoSubscription != null) {
      _restartStream();
    }
  }

  /// Set the GPS accuracy level.
  void setAccuracy(geo.LocationAccuracy accuracy) {
    _accuracy = accuracy;
    // Restart the stream if it's currently active.
    if (_geoSubscription != null) {
      _restartStream();
    }
  }

  /// Enable or disable Kalman filter GPS smoothing.
  void setSmoothing(bool enabled) {
    _smoothingEnabled = enabled;
    if (!enabled) {
      _kalmanFilter.reset();
    }
  }

  /// Whether GPS smoothing is currently enabled.
  bool get isSmoothingEnabled => _smoothingEnabled;

  /// Set the minimum distance filter in meters.
  void setDistanceFilter(int meters) {
    _distanceFilter = meters;
    if (_geoSubscription != null) {
      _restartStream();
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the location service.
  ///
  /// Checks current permission status and starts the GPS position
  /// stream only if permission is already granted.
  ///
  /// IMPORTANT: This method deliberately does NOT request permission.
  /// Permission may only be requested from UI surfaces that first
  /// display an in-app Prominent Disclosure explaining what location
  /// data is accessed, how it is used, and how it is handled (e.g.
  /// the onboarding PermissionsPage). Requesting permission silently
  /// on app launch — without a prior disclosure — violates the Google
  /// Play "Prominent Disclosure and Consent" policy and has been the
  /// cause of prior review rejections.
  ///
  /// If permission is not yet granted, the stream stays empty. The
  /// user can grant it explicitly from onboarding or device Settings,
  /// and [initialize] will start the stream on next invocation.
  Future<void> initialize() async {
    final status = await _permissionHandler.checkStatus();
    RedLog.d('LocationService', 'initialize: permission status = $status');
    if (status != LocationPermissionStatus.granted) {
      RedLog.d(
        'LocationService',
        'initialize: NOT starting stream — permission $status '
            '(waiting for user grant via PermissionsPage)',
      );
      return;
    }

    _startStream();
  }

  /// Whether the GPS position stream is currently subscribed.
  ///
  /// Used by callers (notably HomeScreen on app resume) to detect a
  /// stalled stream and call [initialize] again.
  bool get isStreamRunning => _geoSubscription != null;

  /// Start the underlying geolocator position stream.
  void _startStream() {
    _geoSubscription?.cancel();

    // CRITICAL: use platform-specific settings. The previous code passed
    // `AndroidSettings` on iOS too, on the (incorrect) assumption that
    // iOS would fall back to the base `LocationSettings` fields and
    // ignore the rest. In practice this leaves CLLocationManager at its
    // default `pausesLocationUpdatesAutomatically = YES`, which means a
    // stationary iPad on a desk DURING TESTING sees iOS auto-pause the
    // location stream after a few seconds and the app NEVER receives a
    // position fix. Setting `pauseLocationUpdatesAutomatically: false`
    // via `AppleSettings` is the only way to override this — bug
    // discovered in v1.5.4 TestFlight, fixed in v1.5.4+310.
    //
    // Also explicitly set `activityType` so iOS chooses correct power
    // management (otherwise it assumes "automotive" which uses different
    // accuracy/cadence rules).
    final geo.LocationSettings locationSettings;
    if (Platform.isIOS) {
      locationSettings = geo.AppleSettings(
        accuracy: _accuracy,
        distanceFilter: _distanceFilter,
        activityType: geo.ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
        // We do NOT set allowBackgroundLocationUpdates: only the
        // "WhileInUse" entitlement is in our Info.plist; setting this
        // to true would crash on apps without "Always" auth.
      );
    } else if (Platform.isAndroid) {
      locationSettings = geo.AndroidSettings(
        accuracy: _accuracy,
        distanceFilter: _distanceFilter,
        intervalDuration: _updateInterval,
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationTitle: 'Red Grid Link',
          notificationText: 'Tracking your position',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = geo.LocationSettings(
        accuracy: _accuracy,
        distanceFilter: _distanceFilter,
      );
    }

    RedLog.d(
      'LocationService',
      '_startStream: platform=${Platform.operatingSystem} '
          'accuracy=$_accuracy distanceFilter=$_distanceFilter',
    );

    final stream = geo.GeolocatorPlatform.instance.getPositionStream(
      locationSettings: locationSettings,
    );

    _geoSubscription = stream.listen(
      _onPositionUpdate,
      onError: _onPositionError,
    );

    RedLog.d('LocationService', '_startStream: subscription created');
  }

  /// Restart the GPS stream (e.g., after configuration changes).
  void _restartStream() {
    _geoSubscription?.cancel();
    _geoSubscription = null;
    _startStream();
  }

  /// Handle an incoming geolocator position update.
  void _onPositionUpdate(geo.Position geoPos) {
    if (_lastPosition == null) {
      // Log only the FIRST fix — subsequent updates would spam.
      // Coordinates are intentionally NOT logged here; per the audit's
      // privacy guidance, we log accuracy class only so a debug session
      // does not become a location trail. Use the in-app diagnostics
      // panel (planned) for a redacted live position view if needed.
      RedLog.i(
        'LocationService',
        'FIRST FIX: accuracy=${geoPos.accuracy.toStringAsFixed(1)}m',
      );
    }
    final position = _convertPosition(geoPos);
    _lastPosition = position;
    _positionController.add(position);

    // Record to database if tracking is active.
    if (_isTracking) {
      _recordTrackPoint(position);
    }
  }

  /// Handle a geolocator stream error.
  void _onPositionError(Object error) {
    // Errors are typically transient (e.g., brief GPS loss).
    // We do not forward them to the position stream; the UI
    // can detect staleness by checking the last position timestamp.
  }

  /// Persist a position as a [TrackPoint].
  Future<void> _recordTrackPoint(Position position) async {
    final trackPoint = TrackPoint(
      lat: position.lat,
      lon: position.lon,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );

    try {
      await _trackRepository.recordTrackPoint(
        trackPoint,
        sessionId: _currentSessionId,
      );
    } catch (_) {
      // Database write failures are non-fatal.
      // Track recording continues; the point is simply dropped.
    }
  }

  /// Convert a geolocator position to our application [Position] model
  /// with MGRS fields populated and optional Kalman smoothing.
  Position _convertPosition(geo.Position geoPos) {
    double lat = geoPos.latitude;
    double lon = geoPos.longitude;

    // Apply Kalman filter smoothing if enabled.
    if (_smoothingEnabled) {
      final smoothed = _kalmanFilter.process(
        lat,
        lon,
        geoPos.accuracy,
        speedMps: geoPos.speed,
        timestamp: geoPos.timestamp,
      );
      lat = smoothed.lat;
      lon = smoothed.lon;
    }

    final mgrsRaw = toMGRS(lat, lon);
    final mgrsFormatted = formatMGRS(mgrsRaw);

    return Position(
      lat: lat,
      lon: lon,
      altitude: geoPos.altitude,
      speed: geoPos.speed,
      heading: geoPos.heading,
      accuracy: geoPos.accuracy,
      mgrsRaw: mgrsRaw,
      mgrsFormatted: mgrsFormatted,
      timestamp: geoPos.timestamp,
    );
  }

  /// Release resources held by this service.
  ///
  /// Cancels the GPS stream subscription and closes the broadcast
  /// controller. The service should not be used after calling dispose.
  void dispose() {
    _geoSubscription?.cancel();
    _geoSubscription = null;
    _positionController.close();
  }
}

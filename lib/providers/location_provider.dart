import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/waypoint.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';
import 'package:red_grid_link/data/repositories/waypoint_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/location/compass_service.dart';
import 'package:red_grid_link/services/location/location_service.dart';
import 'package:red_grid_link/services/location/permission_handler_service.dart';

// ---------------------------------------------------------------------------
// Dependencies — these must be overridden before use.
// ---------------------------------------------------------------------------

/// Provider for [TrackRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance that holds a reference to the initialized [AppDatabase].
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  throw UnimplementedError(
    'trackRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

/// Provider for [PermissionHandlerService].
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((ref) {
  return PermissionHandlerService();
});

// ---------------------------------------------------------------------------
// Location service (singleton)
// ---------------------------------------------------------------------------

/// Singleton [LocationService] provider.
///
/// Depends on [TrackRepository] and [PermissionHandlerService].
/// The service is created lazily and disposed when the provider
/// container is destroyed.
final locationServiceProvider = Provider<LocationService>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final permissionHandler = ref.watch(permissionHandlerServiceProvider);

  final service = LocationService(
    trackRepository: trackRepo,
    permissionHandler: permissionHandler,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

// ---------------------------------------------------------------------------
// Position stream
// ---------------------------------------------------------------------------

/// Stream of [Position] updates from the GPS with MGRS populated.
///
/// The stream begins emitting after [LocationService.initialize] has
/// been called. Multiple widgets can listen without duplicating GPS work.
final positionStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.positionStream;
});

// ---------------------------------------------------------------------------
// Current position (latest snapshot)
// ---------------------------------------------------------------------------

/// Fixed demo position: Washington Monument, Washington DC.
///
/// Used when demo mode is active to avoid displaying real GPS data
/// (e.g., for screenshots).
Position _buildDemoPosition() {
  const lat = 38.8895;
  const lon = -77.0353;
  final mgrsRaw = toMGRS(lat, lon);
  final mgrsFormatted = formatMGRS(mgrsRaw);

  return Position(
    lat: lat,
    lon: lon,
    altitude: 15.0,
    speed: 0.0,
    heading: 45.0,
    accuracy: 3.0,
    mgrsRaw: mgrsRaw,
    mgrsFormatted: mgrsFormatted,
    timestamp: DateTime.now(),
  );
}

/// The most recent [Position] from the GPS stream, or null if no fix
/// has been obtained yet.
///
/// When demo mode is active, returns a fixed Washington DC position
/// instead of real GPS data.
final currentPositionProvider = Provider<Position?>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  if (isDemo) return _buildDemoPosition();

  final asyncPosition = ref.watch(positionStreamProvider);
  return asyncPosition.whenData((p) => p).valueOrNull;
});

// ---------------------------------------------------------------------------
// Location initialization
// ---------------------------------------------------------------------------

/// Initializes the [LocationService] (requests permission and starts GPS).
///
/// Watch this provider from [HomeScreen] to trigger initialization once
/// the user has passed onboarding. The stream will begin emitting after
/// this completes successfully.
final locationInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(locationServiceProvider);
  await service.initialize();
});

// ---------------------------------------------------------------------------
// Permission status
// ---------------------------------------------------------------------------

/// Current location permission status.
///
/// Returns a [LocationPermissionStatus] indicating whether the app
/// has location access, has been denied, or if the service is disabled.
final locationPermissionProvider =
    FutureProvider<LocationPermissionStatus>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getPermissionStatus();
});

// ---------------------------------------------------------------------------
// Tracking state
// ---------------------------------------------------------------------------

/// Whether track recording is currently active.
final isTrackingProvider = Provider<bool>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.isTracking;
});

// ---------------------------------------------------------------------------
// Waypoints (saved navigation points)
// ---------------------------------------------------------------------------

/// Provider for [WaypointRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by an initialized [SharedPreferences].
final waypointRepositoryProvider = Provider<WaypointRepository>((ref) {
  throw UnimplementedError(
    'waypointRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

/// Notifier managing the saved waypoints list and active waypoint selection.
class WaypointListNotifier extends StateNotifier<List<Waypoint>> {
  final WaypointRepository _repo;

  WaypointListNotifier(this._repo) : super(_repo.getAll());

  /// Add a new waypoint and refresh the list.
  Future<void> add(Waypoint waypoint) async {
    await _repo.add(waypoint);
    state = _repo.getAll();
  }

  /// Remove a waypoint by ID.
  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  /// Rename a waypoint.
  Future<void> rename(String id, String newName) async {
    await _repo.rename(id, newName);
    state = _repo.getAll();
  }
}

/// All saved waypoints, newest first.
final waypointListProvider =
    StateNotifierProvider<WaypointListNotifier, List<Waypoint>>((ref) {
  final repo = ref.watch(waypointRepositoryProvider);
  return WaypointListNotifier(repo);
});

/// The currently active waypoint for navigation (bearing/distance display).
///
/// This is an in-memory selection — the active waypoint is not persisted
/// across app restarts. The saved list is persistent.
final activeWaypointProvider = StateProvider<Waypoint?>((ref) => null);

// ---------------------------------------------------------------------------
// Compass heading (magnetometer-based)
// ---------------------------------------------------------------------------

/// Singleton [CompassService] provider.
///
/// Provides device heading from the magnetometer — works even when
/// stationary, unlike GPS heading which requires movement.
final compassServiceProvider = Provider<CompassService>((ref) {
  final service = CompassService();
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of compass heading in degrees (0-360, 0 = North).
///
/// Updates at ~20Hz from the magnetometer with low-pass smoothing.
final compassHeadingStreamProvider = StreamProvider<double>((ref) {
  final service = ref.watch(compassServiceProvider);
  return service.headingStream;
});

/// The most recent compass heading, or null if magnetometer is unavailable.
final compassHeadingProvider = Provider<double?>((ref) {
  final asyncHeading = ref.watch(compassHeadingStreamProvider);
  return asyncHeading.whenData((h) => h).valueOrNull;
});

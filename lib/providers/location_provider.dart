import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';
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

/// The most recent [Position] from the GPS stream, or null if no fix
/// has been obtained yet.
///
/// Derived from [positionStreamProvider] so it updates reactively.
final currentPositionProvider = Provider<Position?>((ref) {
  final asyncPosition = ref.watch(positionStreamProvider);
  return asyncPosition.whenData((p) => p).valueOrNull;
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

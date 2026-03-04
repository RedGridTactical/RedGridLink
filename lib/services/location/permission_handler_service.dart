import 'package:geolocator/geolocator.dart' as geo;

/// Permission status for location access.
///
/// Wraps the geolocator permission types into a single
/// application-level enum that includes service availability.
enum LocationPermissionStatus {
  /// Location access has been granted.
  granted,

  /// Location access has been denied (can still ask again).
  denied,

  /// Location access has been permanently denied.
  /// User must open OS settings to re-enable.
  deniedForever,

  /// Location services (GPS) are turned off at the system level.
  serviceDisabled,

  /// Status could not be determined.
  unknown,
}

/// Dedicated service for checking and requesting location permissions.
///
/// Uses the geolocator package for permission management.
/// Provides a clean abstraction over platform-specific permission handling.
class PermissionHandlerService {
  /// Check the current location permission status.
  ///
  /// Also verifies that the device's location service is enabled.
  /// Returns [LocationPermissionStatus.serviceDisabled] if GPS is off,
  /// regardless of the app-level permission state.
  Future<LocationPermissionStatus> checkStatus() async {
    try {
      final serviceEnabled = await geo.GeolocatorPlatform.instance
          .isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      final permission = await geo.GeolocatorPlatform.instance
          .checkPermission();
      return _mapPermission(permission);
    } catch (_) {
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request location permission from the user.
  ///
  /// If permission has already been granted this returns immediately.
  /// If the service is disabled, returns [LocationPermissionStatus.serviceDisabled]
  /// without prompting.
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final serviceEnabled = await geo.GeolocatorPlatform.instance
          .isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      final current = await geo.GeolocatorPlatform.instance.checkPermission();
      if (current == geo.LocationPermission.always ||
          current == geo.LocationPermission.whileInUse) {
        return LocationPermissionStatus.granted;
      }

      if (current == geo.LocationPermission.deniedForever) {
        return LocationPermissionStatus.deniedForever;
      }

      final result = await geo.GeolocatorPlatform.instance
          .requestPermission();
      return _mapPermission(result);
    } catch (_) {
      return LocationPermissionStatus.unknown;
    }
  }

  /// Open the OS-level app settings page.
  ///
  /// Use this when the user has permanently denied location permission
  /// and needs to manually re-enable it.
  /// Returns true if the settings page was opened successfully.
  Future<bool> openSettings() async {
    try {
      return await geo.GeolocatorPlatform.instance.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open the OS-level location settings page.
  ///
  /// Use this when the device's location service is disabled
  /// and the user needs to turn it on.
  /// Returns true if the settings page was opened successfully.
  Future<bool> openLocationSettings() async {
    try {
      return await geo.GeolocatorPlatform.instance.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Map geolocator's [geo.LocationPermission] to our application enum.
  LocationPermissionStatus _mapPermission(geo.LocationPermission permission) {
    switch (permission) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case geo.LocationPermission.denied:
      case geo.LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
      case geo.LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
    }
  }
}

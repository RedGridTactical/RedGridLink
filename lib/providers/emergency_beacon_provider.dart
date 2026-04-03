import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'field_link_provider.dart';
import '../services/field_link/emergency_beacon_service.dart';

/// Provides the emergency beacon service from the active [FieldLinkService].
///
/// Falls back to a standalone instance when the service is not overridden
/// (e.g., in widget tests).
final emergencyBeaconServiceProvider = Provider<EmergencyBeaconService>(
  (ref) {
    try {
      return ref.watch(fieldLinkServiceProvider).emergencyBeacon;
    } catch (_) {
      return EmergencyBeaconService();
    }
  },
);

/// Whether an emergency beacon is currently active.
final emergencyActiveProvider = StateProvider<bool>((ref) => false);

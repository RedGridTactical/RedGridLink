import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/field_link/emergency_beacon_service.dart';

/// Provides the emergency beacon service as a singleton.
final emergencyBeaconServiceProvider = Provider<EmergencyBeaconService>(
  (ref) => EmergencyBeaconService(),
);

/// Whether an emergency beacon is currently active.
final emergencyActiveProvider = StateProvider<bool>((ref) => false);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/field_link/transport/ble_phy_service.dart';

/// Provides a singleton BlePhyService instance.
final blePhyServiceProvider = Provider<BlePhyService>((ref) => BlePhyService());

/// Whether the current device supports BLE Coded PHY (Long Range).
final isCodedPhySupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(blePhyServiceProvider);
  return service.isCodedPhySupported();
});

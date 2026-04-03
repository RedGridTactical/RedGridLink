import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/field_link/transport/ble_phy_service.dart';

/// Provides a singleton BlePhyService instance.
final blePhyServiceProvider = Provider<BlePhyService>((ref) => BlePhyService());

/// Whether the current device supports BLE Coded PHY (Long Range).
final isCodedPhySupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(blePhyServiceProvider);
  return service.isCodedPhySupported();
});

/// Tracks which peers have had Coded PHY successfully requested.
///
/// Updated by [BleTransport] after each connection. The set contains device
/// IDs for which `setPreferredPhy(coded, s8)` was called without error.
/// Note: "requested" does not guarantee Coded PHY is in use — the remote
/// peripheral must also support it for the stack to negotiate Coded PHY.
final peerCodedPhyProvider =
    StateNotifierProvider<PeerCodedPhyNotifier, Set<String>>(
  (ref) => PeerCodedPhyNotifier(),
);

/// Notifier that tracks device IDs with Coded PHY requested.
class PeerCodedPhyNotifier extends StateNotifier<Set<String>> {
  PeerCodedPhyNotifier() : super(const {});

  /// Mark a peer as having Coded PHY requested.
  void add(String deviceId) {
    if (!state.contains(deviceId)) {
      state = {...state, deviceId};
    }
  }

  /// Remove a peer (e.g., on disconnect).
  void remove(String deviceId) {
    if (state.contains(deviceId)) {
      state = Set.from(state)..remove(deviceId);
    }
  }

  /// Whether a specific peer has Coded PHY requested.
  bool isPeerCodedPhy(String deviceId) => state.contains(deviceId);
}

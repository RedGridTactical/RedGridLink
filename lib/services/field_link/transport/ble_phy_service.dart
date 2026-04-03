import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Manages BLE Coded PHY (Long Range) support detection and negotiation.
///
/// Support detection uses a native platform channel to check
/// `BluetoothAdapter.isLeCodedPhySupported()` on Android.
///
/// PHY negotiation uses flutter_blue_plus's `setPreferredPhy()` directly on
/// connected [BluetoothDevice] instances (Android only — iOS auto-negotiates
/// Coded PHY when both endpoints support it).
class BlePhyService {
  static const _channel = MethodChannel('com.redgrid.link/ble_phy');

  /// Device IDs for which Coded PHY has been successfully requested.
  ///
  /// Note: "requested" means we called `setPreferredPhy` without error.
  /// The actual negotiated PHY depends on what the remote peripheral supports.
  final Set<String> _codedPhyRequested = {};

  /// Whether Coded PHY was requested for a given peer.
  bool isCodedPhyRequested(String deviceId) =>
      _codedPhyRequested.contains(deviceId);

  /// All device IDs that have had Coded PHY requested.
  Set<String> get codedPhyPeers => Set.unmodifiable(_codedPhyRequested);

  /// Remove a device from the Coded PHY tracking set (e.g., on disconnect).
  void clearDevice(String deviceId) => _codedPhyRequested.remove(deviceId);

  /// Check if the device hardware supports BLE Coded PHY.
  Future<bool> isCodedPhySupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isCodedPhySupported');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Request Coded PHY for a connected device (legacy platform channel).
  ///
  /// Returns true if the platform supports Coded PHY. Prefer
  /// [requestCodedPhyOnDevice] which actually negotiates PHY on the GATT
  /// connection via flutter_blue_plus.
  Future<bool> requestCodedPhy(String deviceAddress) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestCodedPhy',
        {'deviceAddress': deviceAddress},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Request Coded PHY (S8 coding, maximum range) on a connected
  /// [BluetoothDevice] via flutter_blue_plus.
  ///
  /// Returns true if the request was made successfully. The actual PHY
  /// negotiation is asynchronous — the Bluetooth stack will use Coded PHY
  /// if both endpoints support it, otherwise falls back to LE 1M.
  ///
  /// On iOS this is a no-op that returns false (iOS auto-negotiates PHY).
  Future<bool> requestCodedPhyOnDevice(BluetoothDevice device) async {
    try {
      // Only Android supports explicit PHY selection.
      if (kIsWeb || !Platform.isAndroid) return false;

      final supported = await isCodedPhySupported();
      if (!supported) return false;

      // Phy.leCoded.mask = 3 (LE Coded PHY bitmask).
      // PhyCoding.s8 = maximum range (~4x standard BLE range).
      await device.setPreferredPhy(
        txPhy: Phy.leCoded.mask,
        rxPhy: Phy.leCoded.mask,
        option: PhyCoding.s8,
      );

      _codedPhyRequested.add(device.remoteId.str);
      debugPrint(
        '[BlePhyService] Coded PHY (S8) requested for ${device.remoteId.str}',
      );
      return true;
    } catch (e) {
      // PHY request is best-effort — connection works fine on standard PHY.
      debugPrint('[BlePhyService] Coded PHY request failed: $e');
      return false;
    }
  }
}

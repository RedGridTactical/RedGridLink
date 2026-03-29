import 'package:flutter/services.dart';

/// Manages BLE Coded PHY (Long Range) via native platform channels.
///
/// On Android, checks `BluetoothAdapter.isLeCodedPhySupported()`.
/// On iOS, CoreBluetooth auto-negotiates Coded PHY (iPhone 8+ / iOS 14+).
class BlePhyService {
  static const _channel = MethodChannel('com.redgrid.link/ble_phy');

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

  /// Request Coded PHY for a connected device.
  ///
  /// Returns true if the platform supports Coded PHY (actual negotiation
  /// happens at the GATT level managed by flutter_blue_plus).
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
}

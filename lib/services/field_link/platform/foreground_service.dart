import 'package:flutter/services.dart';

/// Manages the Android foreground service for Field Link.
///
/// On iOS, this is a no-op since iOS handles background BLE differently
/// (via bluetooth-central/bluetooth-peripheral background modes).
class ForegroundService {
  static const _channel = MethodChannel('com.redgrid.link/main');

  /// Start the foreground service with the current peer count.
  static Future<void> start({int peerCount = 0}) async {
    try {
      await _channel.invokeMethod('startForegroundService', {
        'peerCount': peerCount,
      });
    } on PlatformException {
      // Not on Android or service not available
    }
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } on PlatformException {
      // Not on Android or service not available
    }
  }

  /// Update the notification with new peer count.
  static Future<void> updatePeerCount(int peerCount) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'peerCount': peerCount,
      });
    } on PlatformException {
      // Not on Android or service not available
    }
  }
}

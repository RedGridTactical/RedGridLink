import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Manages the Android foreground service for Field Link.
///
/// On iOS this is a hard no-op; iOS keeps Field Link running in the
/// background through the bluetooth-central / bluetooth-peripheral
/// background modes declared in Info.plist, and the corresponding
/// platform channel does not exist.
///
/// Codex review 2026-05-03 P1 fix: every entry point now early-returns
/// on non-Android platforms AND catches both [PlatformException] and
/// [MissingPluginException]. Previously only [PlatformException] was
/// caught, so iOS sessions threw on `invokeMethod`'s
/// `MissingPluginException` and `FieldLinkService.createSession` /
/// `joinSession` would fail to start instead of being a no-op.
class ForegroundService {
  static const _channel = MethodChannel('com.redgrid.link/main');

  /// Start the foreground service with the current peer count.
  static Future<void> start({int peerCount = 0}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startForegroundService', {
        'peerCount': peerCount,
      });
    } on PlatformException {
      // Service unavailable on this build (e.g. plugin not registered).
    } on MissingPluginException {
      // Method channel not registered (older build, debug, or non-Android
      // path slipped through). Treat as no-op.
    }
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopForegroundService');
    } on PlatformException {
      // Service unavailable on this build.
    } on MissingPluginException {
      // No-op when the channel isn't registered.
    }
  }

  /// Update the notification with new peer count.
  static Future<void> updatePeerCount(int peerCount) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateNotification', {
        'peerCount': peerCount,
      });
    } on PlatformException {
      // Service unavailable on this build.
    } on MissingPluginException {
      // No-op when the channel isn't registered.
    }
  }
}

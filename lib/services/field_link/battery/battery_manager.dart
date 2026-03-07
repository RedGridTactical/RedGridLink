import 'dart:async';

import 'package:flutter/services.dart';
import 'package:red_grid_link/core/constants/sync_constants.dart';

/// Battery mode for sync power management.
enum BatteryMode {
  /// BLE only, 60-second updates, minimal power (<2%/hr).
  /// Scan 1s / pause 59s. WiFi Direct suspended.
  ultraExpedition,

  /// BLE only, 30-second updates, low power (<3%/hr).
  expedition,

  /// BLE + P2P, 5-15 second updates, higher power consumption.
  active,
}

/// Battery-conscious sync management.
///
/// Monitors the device battery level and provides:
/// - [BatteryMode] switching between expedition (low-power) and active.
/// - Recommended sync intervals based on the current mode.
/// - Battery drain projection estimating remaining session time.
///
/// **Ultra Expedition Mode**: BLE only, 60 s updates, minimal power.
/// **Expedition Mode**: BLE only, 30 s updates, low power.
/// **Active Mode**: BLE + P2P, 5-15 s updates, higher power.
class BatteryManager {
  /// Platform channel for native battery level queries.
  static const MethodChannel _batteryChannel =
      MethodChannel('com.redgrid.link/battery');

  BatteryMode _currentMode;

  final StreamController<BatteryMode> _modeController =
      StreamController<BatteryMode>.broadcast();

  /// The current battery mode.
  BatteryMode get currentMode => _currentMode;

  /// Stream of battery mode changes.
  Stream<BatteryMode> get modeStream => _modeController.stream;

  /// Current battery level (0-100), or null if unknown.
  int? currentBatteryLevel;

  /// When the current session started.
  DateTime? sessionStartTime;

  /// Battery level when the session started (0-100).
  int? batteryAtStart;

  /// History of battery readings for drain rate calculation.
  /// Each entry is (timestamp, level).
  final List<({DateTime time, int level})> _batteryHistory = [];

  BatteryManager({
    BatteryMode initialMode = BatteryMode.expedition,
  }) : _currentMode = initialMode;

  // ---------------------------------------------------------------------------
  // Mode management
  // ---------------------------------------------------------------------------

  /// Set the battery mode and notify listeners.
  void setMode(BatteryMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    if (!_modeController.isClosed) {
      _modeController.add(mode);
    }
  }

  /// Get the recommended sync interval (in milliseconds) for the
  /// current mode.
  int get recommendedIntervalMs {
    switch (_currentMode) {
      case BatteryMode.ultraExpedition:
        return SyncConstants.ultraExpeditionIntervalMs; // 60s
      case BatteryMode.expedition:
        return SyncConstants.expeditionIntervalMs; // 30s
      case BatteryMode.active:
        return SyncConstants.activeIntervalMs; // 5s
    }
  }

  // ---------------------------------------------------------------------------
  // Battery projection
  // ---------------------------------------------------------------------------

  /// Calculate the battery drain rate in percent per hour.
  ///
  /// Uses the recorded battery history to compute a linear drain rate.
  /// Returns 0.0 if insufficient data is available.
  double get drainRatePerHour {
    if (_batteryHistory.length < 2) return 0.0;

    final first = _batteryHistory.first;
    final last = _batteryHistory.last;

    final elapsedHours =
        last.time.difference(first.time).inSeconds / 3600.0;
    if (elapsedHours < 0.01) return 0.0; // Avoid division by near-zero.

    final droppedPercent = first.level - last.level;
    if (droppedPercent <= 0) return 0.0; // Battery hasn't drained.

    return droppedPercent / elapsedHours;
  }

  /// Human-readable projected remaining battery time.
  ///
  /// Returns a string like "8hr 12min remaining" based on the current
  /// drain rate. Returns "Charging" if battery level is rising, or
  /// "Calculating..." if insufficient data is available.
  String get projectedRemainingTime {
    if (currentBatteryLevel == null) return 'Calculating...';
    final rate = drainRatePerHour;
    if (rate <= 0) {
      // Battery is stable or charging — not draining.
      if (_batteryHistory.length >= 2 &&
          _batteryHistory.last.level >= _batteryHistory.first.level) {
        return 'Charging';
      }
      return 'Calculating...';
    }

    final hoursRemaining = currentBatteryLevel! / rate;
    final hours = hoursRemaining.floor();
    final minutes = ((hoursRemaining - hours) * 60).round();

    if (hours <= 0 && minutes <= 0) return '<1min remaining';
    if (hours <= 0) return '${minutes}min remaining';
    return '${hours}hr ${minutes}min remaining';
  }

  // ---------------------------------------------------------------------------
  // Battery level updates
  // ---------------------------------------------------------------------------

  /// Record a new battery level reading.
  ///
  /// Called periodically by the [FieldLinkService] to track drain rate.
  void updateBatteryLevel(int level) {
    currentBatteryLevel = level;
    _batteryHistory.add((time: DateTime.now(), level: level));

    // Keep only the last 60 readings (to avoid unbounded growth).
    if (_batteryHistory.length > 60) {
      _batteryHistory.removeRange(0, _batteryHistory.length - 60);
    }
  }

  /// Mark the start of a session for drain-rate tracking.
  void startSession(int batteryLevel) {
    sessionStartTime = DateTime.now();
    batteryAtStart = batteryLevel;
    currentBatteryLevel = batteryLevel;
    _batteryHistory.clear();
    _batteryHistory.add((time: DateTime.now(), level: batteryLevel));
  }

  /// Read the current battery level from the platform.
  ///
  /// Uses a method channel call to the native layer. Returns null if
  /// the platform does not support battery level reporting.
  Future<int?> getBatteryLevel() async {
    try {
      final level =
          await _batteryChannel.invokeMethod<int>('getBatteryLevel');
      if (level != null) {
        updateBatteryLevel(level);
      }
      return level;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // Platform channel not registered (e.g., in tests).
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Dispose all resources.
  void dispose() {
    _modeController.close();
    _batteryHistory.clear();
  }
}

import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signal strength tier based on RSSI dBm value.
enum SignalTier { excellent, good, fair, weak }

/// Tracks rolling RSSI readings for a single peer connection.
class ConnectionQuality {
  static const int _maxReadings = 5;
  static const int _warningThresholdDbm = -85;
  static const int _warningConsecutiveCount = 3;

  final _readings = Queue<int>();

  /// Add a new RSSI reading (negative dBm value).
  void addReading(int rssi) {
    _readings.addLast(rssi);
    if (_readings.length > _maxReadings) _readings.removeFirst();
  }

  /// Rolling average of recent RSSI readings.
  int get averageRssi {
    if (_readings.isEmpty) return -100;
    return (_readings.reduce((a, b) => a + b) / _readings.length).round();
  }

  /// Current signal tier based on rolling average.
  SignalTier get tier => tierFor(averageRssi);

  /// Whether the connection is in a warning state (consistently weak).
  bool get isWarning {
    if (_readings.length < _warningConsecutiveCount) return false;
    return _readings
        .toList()
        .reversed
        .take(_warningConsecutiveCount)
        .every((r) => r <= _warningThresholdDbm);
  }

  /// Number of signal bars (1-4) for display.
  int get bars {
    switch (tier) {
      case SignalTier.excellent:
        return 4;
      case SignalTier.good:
        return 3;
      case SignalTier.fair:
        return 2;
      case SignalTier.weak:
        return 1;
    }
  }

  /// Classify an RSSI value into a signal tier.
  static SignalTier tierFor(int rssi) {
    if (rssi >= -60) return SignalTier.excellent;
    if (rssi >= -70) return SignalTier.good;
    if (rssi >= -80) return SignalTier.fair;
    return SignalTier.weak;
  }
}

/// Connection quality per peer, keyed by device ID.
final connectionQualityProvider =
    StateNotifierProvider<ConnectionQualityNotifier, Map<String, ConnectionQuality>>(
  (ref) => ConnectionQualityNotifier(),
);

/// Manages RSSI quality state for all connected peers.
class ConnectionQualityNotifier extends StateNotifier<Map<String, ConnectionQuality>> {
  ConnectionQualityNotifier() : super({});

  /// Update RSSI for a peer. Creates entry if first reading.
  void updateRssi(String deviceId, int rssi) {
    final current = Map<String, ConnectionQuality>.from(state);
    final cq = current[deviceId] ?? ConnectionQuality();
    cq.addReading(rssi);
    current[deviceId] = cq;
    state = current;
  }

  /// Remove a peer (on disconnect).
  void removePeer(String deviceId) {
    final current = Map<String, ConnectionQuality>.from(state);
    current.remove(deviceId);
    state = current;
  }

  /// Clear all peer data (on session end).
  void clear() {
    state = {};
  }
}

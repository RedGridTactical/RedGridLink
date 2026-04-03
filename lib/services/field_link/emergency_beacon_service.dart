import 'dart:async';

/// Manages emergency beacon state and periodic retransmission.
class EmergencyBeaconService {
  Timer? _retransmitTimer;
  bool _isActive = false;
  String? _activeSenderId;
  double? _activeLat;
  double? _activeLon;
  DateTime? _activeTimestamp;

  /// Whether an emergency beacon is currently active (local or remote).
  bool get isActive => _isActive;
  String? get activeSenderId => _activeSenderId;
  double? get activeLat => _activeLat;
  double? get activeLon => _activeLon;
  DateTime? get activeTimestamp => _activeTimestamp;

  /// Activate the local emergency beacon.
  /// Calls [onBroadcast] immediately and every 30 seconds.
  void activate({
    required String localDeviceId,
    required double lat,
    required double lon,
    required void Function(Map<String, dynamic>) onBroadcast,
  }) {
    _isActive = true;
    _activeSenderId = localDeviceId;
    _activeLat = lat;
    _activeLon = lon;
    _activeTimestamp = DateTime.now();

    final payload = {
      'evt': 'emergency',
      'lat': lat,
      'lon': lon,
      'ts': _activeTimestamp!.millisecondsSinceEpoch,
    };

    // Broadcast immediately
    onBroadcast(payload);

    // Retransmit every 30 seconds
    _retransmitTimer?.cancel();
    _retransmitTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => onBroadcast(payload),
    );
  }

  /// Deactivate the local emergency beacon.
  void deactivate({
    required void Function(Map<String, dynamic>) onBroadcast,
  }) {
    _retransmitTimer?.cancel();
    _retransmitTimer = null;

    if (_isActive) {
      onBroadcast({'evt': 'emergency_cancel'});
    }

    _isActive = false;
    _activeSenderId = null;
    _activeLat = null;
    _activeLon = null;
    _activeTimestamp = null;
  }

  /// Handle an incoming emergency control message from a remote peer.
  void handleRemoteEmergency(String senderId, Map<String, dynamic> data) {
    _isActive = true;
    _activeSenderId = senderId;
    _activeLat = (data['lat'] as num?)?.toDouble();
    _activeLon = (data['lon'] as num?)?.toDouble();
    final ts = data['ts'] as int?;
    _activeTimestamp = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.now();
  }

  /// Handle an incoming emergency cancel from a remote peer.
  void handleRemoteCancel(String senderId) {
    if (_activeSenderId == senderId) {
      _isActive = false;
      _activeSenderId = null;
      _activeLat = null;
      _activeLon = null;
      _activeTimestamp = null;
    }
  }

  /// Clean up (on session end).
  void dispose() {
    _retransmitTimer?.cancel();
    _retransmitTimer = null;
    _isActive = false;
    _activeSenderId = null;
    _activeLat = null;
    _activeLon = null;
    _activeTimestamp = null;
  }
}

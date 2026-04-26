import 'dart:async';

/// Manages emergency beacon state and periodic retransmission.
///
/// Recipient-side dedup: the originator's `activate()` retransmits the same
/// payload (same `ts`) every 30s so late-joining peers still hear about an
/// active SOS. Without dedup, every retransmit re-fires the UI state callback,
/// and a stale retransmit arriving AFTER a cancel (BLE buffer drain, mesh
/// re-delivery) would flip the alert overlay back on even though the sender
/// has already cancelled. We track the most-recent `ts` per sender; a cancel
/// bumps that high-water-mark forward so any in-flight retransmit is
/// recognised as stale and ignored.
class EmergencyBeaconService {
  Timer? _retransmitTimer;
  bool _isActive = false;
  String? _activeSenderId;
  double? _activeLat;
  double? _activeLon;
  DateTime? _activeTimestamp;

  /// High-water-mark of the most recent emergency / cancel timestamp seen
  /// per sender. Used to suppress duplicate retransmits and stale
  /// post-cancel re-deliveries that would otherwise re-trigger the UI.
  final Map<String, int> _lastSeenTs = {};

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

    final ts = _activeTimestamp!.millisecondsSinceEpoch;
    final payload = {
      'evt': 'emergency',
      'lat': lat,
      'lon': lon,
      'ts': ts,
    };

    // Mark our own emergency as the high-water-mark for this sender so any
    // mesh-echoed copy of our broadcast is treated as a duplicate.
    _lastSeenTs[localDeviceId] = ts;

    // Broadcast immediately
    onBroadcast(payload);

    // Retransmit every 30 seconds
    _retransmitTimer?.cancel();
    _retransmitTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => onBroadcast(payload),
    );
  }

  /// Deactivate the local emergency beacon. Returns true if a cancel was
  /// actually broadcast (i.e. the beacon was active).
  bool deactivate({
    required void Function(Map<String, dynamic>) onBroadcast,
  }) {
    _retransmitTimer?.cancel();
    _retransmitTimer = null;

    final wasActive = _isActive;
    final senderId = _activeSenderId;
    final cancelTs = DateTime.now().millisecondsSinceEpoch;

    if (wasActive) {
      onBroadcast({
        'evt': 'emergency_cancel',
        // Belt-and-suspenders: include sender + ts so recipients can
        // dedupe stale retransmits even if the transport envelope
        // doesn't surface a senderId.
        'sender': senderId,
        'ts': cancelTs,
      });
      // Bump local high-water-mark in case our own emergency is echoed
      // back to us via mesh after cancel.
      if (senderId != null) {
        final existing = _lastSeenTs[senderId] ?? 0;
        if (cancelTs > existing) {
          _lastSeenTs[senderId] = cancelTs;
        }
      }
    }

    _isActive = false;
    _activeSenderId = null;
    _activeLat = null;
    _activeLon = null;
    _activeTimestamp = null;
    return wasActive;
  }

  /// Handle an incoming emergency control message from a remote peer.
  ///
  /// Returns true when this message represents a NEW emergency that the UI
  /// should react to. Returns false for retransmits (same `ts` already seen)
  /// and for stale re-deliveries that arrive after a cancel — neither
  /// should re-trigger the alert overlay.
  bool handleRemoteEmergency(String senderId, Map<String, dynamic> data) {
    final ts = (data['ts'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;
    final lastTs = _lastSeenTs[senderId];

    // Dedup: same-or-older timestamp from this sender means this is a
    // retransmit OR a stale re-delivery after a cancel. Either way, the
    // UI has already seen the latest state — do not re-fire.
    if (lastTs != null && ts <= lastTs) {
      return false;
    }

    _lastSeenTs[senderId] = ts;
    _isActive = true;
    _activeSenderId = senderId;
    _activeLat = (data['lat'] as num?)?.toDouble();
    _activeLon = (data['lon'] as num?)?.toDouble();
    _activeTimestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    return true;
  }

  /// Handle an incoming emergency cancel from a remote peer.
  ///
  /// Bumps the per-sender high-water-mark forward so any in-flight
  /// retransmit of the cancelled emergency is suppressed. Returns true if
  /// the cancel actually applied (i.e. the cancelling sender was the
  /// owner of the active beacon).
  bool handleRemoteCancel(String senderId, [Map<String, dynamic>? data]) {
    // Use the cancel's own ts if provided (originator's clock); fall back
    // to local now. Bump the high-water-mark either way so stale
    // retransmits arriving AFTER this cancel are ignored.
    final cancelTs = (data?['ts'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;
    final existing = _lastSeenTs[senderId] ?? 0;
    if (cancelTs > existing) {
      _lastSeenTs[senderId] = cancelTs;
    }

    if (_activeSenderId == senderId) {
      _isActive = false;
      _activeSenderId = null;
      _activeLat = null;
      _activeLon = null;
      _activeTimestamp = null;
      return true;
    }
    return false;
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
    _lastSeenTs.clear();
  }
}

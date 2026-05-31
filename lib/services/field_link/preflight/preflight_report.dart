/// Field Readiness Preflight — data model.
///
/// A Preflight is the team-coordination answer to "will this actually work
/// when we step off coverage?" It rolls a set of independent device + session
/// checks (GPS, Bluetooth, offline maps, encryption mode, roster, last peer
/// contact, battery) into a single READY / CAUTION / NOT READY verdict so a
/// team can confirm their kit before a mission instead of discovering a gap
/// in the field.
///
/// This file is pure data — no Flutter, no platform calls — so it is trivially
/// unit-testable and safe to serialize for the per-teammate readiness
/// broadcast (Pro/Team).
library;

/// Status of a single readiness check, worst-to-best ordered so a list of
/// statuses can be reduced to an overall verdict with [PreflightStatus.worst].
enum PreflightStatus {
  /// A hard blocker — the team should not rely on this capability.
  notReady,

  /// Works, but degraded or unverified — proceed with awareness.
  caution,

  /// Good to go.
  ready;

  /// The worse (lower-confidence) of two statuses. notReady < caution < ready.
  PreflightStatus worst(PreflightStatus other) =>
      index <= other.index ? this : other;

  /// Reduce a list of statuses to the single worst one. Empty → ready.
  static PreflightStatus rollup(Iterable<PreflightStatus> statuses) {
    var acc = PreflightStatus.ready;
    for (final s in statuses) {
      acc = acc.worst(s);
    }
    return acc;
  }
}

/// Stable identifier for each check, used by the UI to attach the right
/// one-tap remediation (e.g. [gps] → request location permission) and by
/// the broadcast layer to keep wire payloads compact.
enum PreflightCheckId {
  gpsPermission,
  gpsFix,
  bluetooth,
  offlineMaps,
  encryption,
  roster,
  peerContact,
  battery,
}

/// One readiness line item.
class PreflightCheck {
  final PreflightCheckId id;

  /// Short human label, e.g. "GPS fix".
  final String label;

  final PreflightStatus status;

  /// One-line detail shown under the label, e.g. "±4 m" or "No region cached".
  final String detail;

  /// When true, the UI offers an in-app remediation button for this check
  /// (wired by [PreflightCheckId]). When false, the fix is OS-level and the
  /// detail text instructs the user (e.g. "Enable Bluetooth in Settings").
  final bool hasInAppFix;

  const PreflightCheck({
    required this.id,
    required this.label,
    required this.status,
    required this.detail,
    this.hasInAppFix = false,
  });

  /// Compact JSON for the per-teammate broadcast. Only id+status travel over
  /// the wire — labels/details are reconstructed locally by the receiver, so
  /// the payload stays well under the Field Link delta budget.
  Map<String, dynamic> toWire() => {'i': id.index, 's': status.index};

  static PreflightCheck fromWire(Map<String, dynamic> j) {
    final id = PreflightCheckId.values[j['i'] as int];
    return PreflightCheck(
      id: id,
      label: _defaultLabel(id),
      status: PreflightStatus.values[j['s'] as int],
      detail: '',
    );
  }

  /// Full-fidelity JSON for persistence (e.g. the AAR step-off snapshot).
  /// Unlike [toWire], this preserves the human-readable label and detail.
  Map<String, dynamic> toJson() => {
        'id': id.index,
        'label': label,
        'status': status.index,
        'detail': detail,
        'hasInAppFix': hasInAppFix,
      };

  factory PreflightCheck.fromJson(Map<String, dynamic> j) {
    final id = PreflightCheckId.values[j['id'] as int];
    return PreflightCheck(
      id: id,
      label: j['label'] as String? ?? _defaultLabel(id),
      status: PreflightStatus.values[j['status'] as int],
      detail: j['detail'] as String? ?? '',
      hasInAppFix: j['hasInAppFix'] as bool? ?? false,
    );
  }

  static String _defaultLabel(PreflightCheckId id) => switch (id) {
        PreflightCheckId.gpsPermission => 'Location permission',
        PreflightCheckId.gpsFix => 'GPS fix',
        PreflightCheckId.bluetooth => 'Bluetooth',
        PreflightCheckId.offlineMaps => 'Offline maps',
        PreflightCheckId.encryption => 'Encryption',
        PreflightCheckId.roster => 'Team roster',
        PreflightCheckId.peerContact => 'Peer contact',
        PreflightCheckId.battery => 'Battery',
      };
}

/// A complete readiness report for one device (the local user, or a teammate
/// reconstructed from a broadcast).
class PreflightReport {
  final List<PreflightCheck> checks;

  /// Device id this report describes. Null/empty = the local device.
  final String? deviceId;

  /// Optional callsign for display in the team roster board.
  final String? callsign;

  const PreflightReport({
    required this.checks,
    this.deviceId,
    this.callsign,
  });

  /// Overall verdict — the worst single check.
  PreflightStatus get overall =>
      PreflightStatus.rollup(checks.map((c) => c.status));

  int get notReadyCount =>
      checks.where((c) => c.status == PreflightStatus.notReady).length;

  int get cautionCount =>
      checks.where((c) => c.status == PreflightStatus.caution).length;

  /// Compact wire form for the per-teammate readiness broadcast.
  Map<String, dynamic> toWire() => {
        if (callsign != null) 'cs': callsign,
        'c': checks.map((c) => c.toWire()).toList(),
      };

  static PreflightReport fromWire(String deviceId, Map<String, dynamic> j) =>
      PreflightReport(
        deviceId: deviceId,
        callsign: j['cs'] as String?,
        checks: (j['c'] as List<dynamic>)
            .map((e) => PreflightCheck.fromWire(e as Map<String, dynamic>))
            .toList(),
      );

  /// Full-fidelity JSON for persistence (e.g. the AAR step-off snapshot).
  Map<String, dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId,
        if (callsign != null) 'callsign': callsign,
        'checks': checks.map((c) => c.toJson()).toList(),
      };

  factory PreflightReport.fromJson(Map<String, dynamic> j) => PreflightReport(
        deviceId: j['deviceId'] as String?,
        callsign: j['callsign'] as String?,
        checks: (j['checks'] as List<dynamic>)
            .map((e) => PreflightCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/session.dart';

/// Session configuration for creating/joining a Field Link session
class SessionConfig {
  /// Position update interval in milliseconds
  final int updateIntervalMs;

  /// Sync mode: expedition (low-freq) or active (high-freq)
  final SyncMode syncMode;

  /// Security mode for the session
  final SecurityMode securityMode;

  /// Operational mode
  final OperationalMode operationalMode;

  /// Maximum number of devices allowed in session
  final int maxDevices;

  /// Whether new devices can auto-join without approval
  final bool isAutoJoin;

  const SessionConfig({
    this.updateIntervalMs = 10000,
    this.syncMode = SyncMode.expedition,
    this.securityMode = SecurityMode.open,
    this.operationalMode = OperationalMode.sar,
    this.maxDevices = 8,
    this.isAutoJoin = true,
  });

  /// Expedition defaults: 30s update interval
  const SessionConfig.expedition()
      : updateIntervalMs = 30000,
        syncMode = SyncMode.expedition,
        securityMode = SecurityMode.open,
        operationalMode = OperationalMode.backcountry,
        maxDevices = 8,
        isAutoJoin = true;

  /// Active defaults: 5s update interval
  const SessionConfig.active()
      : updateIntervalMs = 5000,
        syncMode = SyncMode.active,
        securityMode = SecurityMode.pin,
        operationalMode = OperationalMode.sar,
        maxDevices = 8,
        isAutoJoin = false;

  Map<String, dynamic> toJson() => {
    'interval': updateIntervalMs,
    'sync': syncMode.name,
    'sec': securityMode.name,
    'mode': operationalMode.id,
    'maxDev': maxDevices,
    'autoJoin': isAutoJoin,
  };

  factory SessionConfig.fromJson(Map<String, dynamic> json) => SessionConfig(
    updateIntervalMs: json['interval'] as int? ?? 10000,
    syncMode: SyncMode.fromString(json['sync'] as String? ?? 'expedition'),
    securityMode:
        SecurityMode.fromString(json['sec'] as String? ?? 'open'),
    operationalMode: OperationalMode.values.firstWhere(
      (m) => m.id == json['mode'],
      orElse: () => OperationalMode.sar,
    ),
    maxDevices: json['maxDev'] as int? ?? 8,
    isAutoJoin: json['autoJoin'] as bool? ?? true,
  );

  SessionConfig copyWith({
    int? updateIntervalMs,
    SyncMode? syncMode,
    SecurityMode? securityMode,
    OperationalMode? operationalMode,
    int? maxDevices,
    bool? isAutoJoin,
  }) =>
      SessionConfig(
        updateIntervalMs: updateIntervalMs ?? this.updateIntervalMs,
        syncMode: syncMode ?? this.syncMode,
        securityMode: securityMode ?? this.securityMode,
        operationalMode: operationalMode ?? this.operationalMode,
        maxDevices: maxDevices ?? this.maxDevices,
        isAutoJoin: isAutoJoin ?? this.isAutoJoin,
      );
}

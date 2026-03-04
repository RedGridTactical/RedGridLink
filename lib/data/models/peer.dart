import 'package:red_grid_link/data/models/position.dart';

/// Device type for a peer
enum DeviceType {
  android,
  ios,
  unknown;

  static DeviceType fromString(String value) =>
      DeviceType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DeviceType.unknown,
      );
}

/// Sync mode for position updates
enum SyncMode {
  /// Low-frequency updates for battery conservation
  expedition,

  /// High-frequency updates for active operations
  active;

  static SyncMode fromString(String value) =>
      SyncMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SyncMode.expedition,
      );
}

/// Peer device in a Field Link session
class Peer {
  final String id;
  final String displayName;
  final DeviceType deviceType;
  final Position? position;
  final DateTime lastSeen;
  final bool isConnected;
  final int? batteryLevel;
  final SyncMode syncMode;

  const Peer({
    required this.id,
    required this.displayName,
    this.deviceType = DeviceType.unknown,
    this.position,
    required this.lastSeen,
    this.isConnected = true,
    this.batteryLevel,
    this.syncMode = SyncMode.expedition,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': displayName,
    'dev': deviceType.name,
    'pos': position?.toJson(),
    'seen': lastSeen.millisecondsSinceEpoch,
    'conn': isConnected,
    'batt': batteryLevel,
    'sync': syncMode.name,
  };

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
    id: json['id'] as String,
    displayName: json['name'] as String,
    deviceType: DeviceType.fromString(json['dev'] as String? ?? 'unknown'),
    position: json['pos'] != null
        ? Position.fromJson(json['pos'] as Map<String, dynamic>)
        : null,
    lastSeen: DateTime.fromMillisecondsSinceEpoch(json['seen'] as int),
    isConnected: json['conn'] as bool? ?? false,
    batteryLevel: json['batt'] as int?,
    syncMode: SyncMode.fromString(json['sync'] as String? ?? 'expedition'),
  );

  Peer copyWith({
    String? displayName,
    DeviceType? deviceType,
    Position? position,
    DateTime? lastSeen,
    bool? isConnected,
    int? batteryLevel,
    SyncMode? syncMode,
  }) =>
      Peer(
        id: id,
        displayName: displayName ?? this.displayName,
        deviceType: deviceType ?? this.deviceType,
        position: position ?? this.position,
        lastSeen: lastSeen ?? this.lastSeen,
        isConnected: isConnected ?? this.isConnected,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        syncMode: syncMode ?? this.syncMode,
      );
}

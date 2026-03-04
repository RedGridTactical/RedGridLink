import 'package:red_grid_link/data/models/peer.dart';

/// Local device information
class DeviceInfo {
  /// Unique device ID (UUID, generated once and persisted)
  final String id;

  /// User-configured display name
  final String displayName;

  /// Device platform
  final DeviceType platform;

  /// Device model string (e.g., "Pixel 8", "iPhone 15")
  final String? model;

  /// Current battery level (0-100)
  final int? batteryLevel;

  /// OS version string
  final String? osVersion;

  const DeviceInfo({
    required this.id,
    required this.displayName,
    this.platform = DeviceType.unknown,
    this.model,
    this.batteryLevel,
    this.osVersion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': displayName,
    'plat': platform.name,
    'model': model,
    'batt': batteryLevel,
    'os': osVersion,
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    id: json['id'] as String,
    displayName: json['name'] as String,
    platform: DeviceType.fromString(json['plat'] as String? ?? 'unknown'),
    model: json['model'] as String?,
    batteryLevel: json['batt'] as int?,
    osVersion: json['os'] as String?,
  );

  DeviceInfo copyWith({
    String? displayName,
    DeviceType? platform,
    String? model,
    int? batteryLevel,
    String? osVersion,
  }) =>
      DeviceInfo(
        id: id,
        displayName: displayName ?? this.displayName,
        platform: platform ?? this.platform,
        model: model ?? this.model,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        osVersion: osVersion ?? this.osVersion,
      );
}

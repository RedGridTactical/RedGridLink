import 'package:red_grid_link/data/models/operational_mode.dart';

/// Security mode for a Field Link session
enum SecurityMode {
  /// Open — anyone can join
  open,

  /// PIN-protected — 4-digit code required
  pin,

  /// QR code — scan to join
  qr;

  static SecurityMode fromString(String value) =>
      SecurityMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SecurityMode.open,
      );
}

/// Field Link session
class Session {
  final String id;
  final String name;
  final SecurityMode securityMode;
  final String? pin;
  final String? sessionKey;
  final DateTime createdAt;
  final OperationalMode operationalMode;
  final List<String> peers;
  final bool isActive;

  const Session({
    required this.id,
    required this.name,
    this.securityMode = SecurityMode.open,
    this.pin,
    this.sessionKey,
    required this.createdAt,
    required this.operationalMode,
    this.peers = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sec': securityMode.name,
    'pin': pin,
    'key': sessionKey,
    'at': createdAt.millisecondsSinceEpoch,
    'mode': operationalMode.id,
    'peers': peers,
    'active': isActive,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    name: json['name'] as String,
    securityMode:
        SecurityMode.fromString(json['sec'] as String? ?? 'open'),
    pin: json['pin'] as String?,
    sessionKey: json['key'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    operationalMode: OperationalMode.values.firstWhere(
      (m) => m.id == json['mode'],
      orElse: () => OperationalMode.sar,
    ),
    peers: (json['peers'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    isActive: json['active'] as bool? ?? false,
  );

  Session copyWith({
    String? name,
    SecurityMode? securityMode,
    String? pin,
    String? sessionKey,
    OperationalMode? operationalMode,
    List<String>? peers,
    bool? isActive,
  }) =>
      Session(
        id: id,
        name: name ?? this.name,
        securityMode: securityMode ?? this.securityMode,
        pin: pin ?? this.pin,
        sessionKey: sessionKey ?? this.sessionKey,
        createdAt: createdAt,
        operationalMode: operationalMode ?? this.operationalMode,
        peers: peers ?? this.peers,
        isActive: isActive ?? this.isActive,
      );
}

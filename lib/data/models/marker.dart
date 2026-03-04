/// Icon type for map markers
enum MarkerIcon {
  waypoint,
  danger,
  camp,
  rally,
  find,
  checkpoint,
  stand,
  custom;

  static MarkerIcon fromString(String value) =>
      MarkerIcon.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MarkerIcon.waypoint,
      );
}

/// Synced map marker
class Marker {
  final String id;
  final double lat;
  final double lon;
  final String mgrs;
  final String label;
  final MarkerIcon icon;
  final String createdBy;
  final DateTime createdAt;
  final int color;
  final bool isSynced;

  const Marker({
    required this.id,
    required this.lat,
    required this.lon,
    this.mgrs = '',
    this.label = '',
    this.icon = MarkerIcon.waypoint,
    required this.createdBy,
    required this.createdAt,
    this.color = 0xFFFF0000,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    'mgrs': mgrs,
    'lbl': label,
    'ico': icon.name,
    'by': createdBy,
    'at': createdAt.millisecondsSinceEpoch,
    'clr': color,
    'syn': isSynced,
  };

  factory Marker.fromJson(Map<String, dynamic> json) => Marker(
    id: json['id'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    mgrs: json['mgrs'] as String? ?? '',
    label: json['lbl'] as String? ?? '',
    icon: MarkerIcon.fromString(json['ico'] as String? ?? 'waypoint'),
    createdBy: json['by'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    color: json['clr'] as int? ?? 0xFFFF0000,
    isSynced: json['syn'] as bool? ?? false,
  );

  Marker copyWith({
    String? label,
    MarkerIcon? icon,
    int? color,
    bool? isSynced,
  }) =>
      Marker(
        id: id,
        lat: lat,
        lon: lon,
        mgrs: mgrs,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        createdBy: createdBy,
        createdAt: createdAt,
        color: color ?? this.color,
        isSynced: isSynced ?? this.isSynced,
      );
}

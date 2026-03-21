/// Icon type for map markers
enum MarkerIcon {
  waypoint,
  hazard, // was 'danger'
  camp,
  rallyPoint, // was 'rally'
  objective, // new
  cache, // new
  find,
  checkpoint,
  stand,
  custom;

  static MarkerIcon fromString(String value) {
    switch (value.toLowerCase()) {
      case 'waypoint':
        return MarkerIcon.waypoint;
      case 'hazard':
      case 'danger':
        return MarkerIcon.hazard; // migration
      case 'camp':
        return MarkerIcon.camp;
      case 'rallypoint':
      case 'rally':
        return MarkerIcon.rallyPoint; // migration
      case 'objective':
        return MarkerIcon.objective;
      case 'cache':
        return MarkerIcon.cache;
      case 'find':
        return MarkerIcon.find;
      case 'checkpoint':
        return MarkerIcon.checkpoint;
      case 'stand':
        return MarkerIcon.stand;
      case 'custom':
        return MarkerIcon.custom;
      default:
        return MarkerIcon.waypoint;
    }
  }
}

/// Origin of a marker (manual placement vs shared waypoint)
enum MarkerOrigin {
  manual,
  sharedWaypoint;

  static MarkerOrigin fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sw':
      case 'sharedwaypoint':
        return MarkerOrigin.sharedWaypoint;
      case 'manual':
      default:
        return MarkerOrigin.manual;
    }
  }

  String toShortString() {
    switch (this) {
      case MarkerOrigin.manual:
        return 'manual';
      case MarkerOrigin.sharedWaypoint:
        return 'sw';
    }
  }
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
  final MarkerOrigin origin;

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
    this.origin = MarkerOrigin.manual,
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
    'o': origin.toShortString(),
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
    origin: MarkerOrigin.fromString(json['o'] as String? ?? 'manual'),
  );

  Marker copyWith({
    String? label,
    MarkerIcon? icon,
    int? color,
    bool? isSynced,
    MarkerOrigin? origin,
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
        origin: origin ?? this.origin,
      );
}

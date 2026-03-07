/// A saved waypoint for navigation.
///
/// Waypoints are personal navigation aids stored locally via
/// SharedPreferences. They are NOT synced between devices (unlike
/// synced markers which use the CRDT system).
class Waypoint {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String mgrs;
  final String mgrsFormatted;
  final DateTime createdAt;

  const Waypoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.mgrs,
    required this.mgrsFormatted,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'mgrs': mgrs,
        'mgrsF': mgrsFormatted,
        'ts': createdAt.millisecondsSinceEpoch,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        mgrs: json['mgrs'] as String,
        mgrsFormatted: json['mgrsF'] as String? ?? json['mgrs'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );

  Waypoint copyWith({String? name}) => Waypoint(
        id: id,
        name: name ?? this.name,
        lat: lat,
        lon: lon,
        mgrs: mgrs,
        mgrsFormatted: mgrsFormatted,
        createdAt: createdAt,
      );
}

/// Position data with MGRS
class Position {
  final double lat;
  final double lon;
  final double? altitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final String mgrsRaw;
  final String mgrsFormatted;
  final DateTime timestamp;

  const Position({
    required this.lat,
    required this.lon,
    this.altitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.mgrsRaw,
    required this.mgrsFormatted,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'alt': altitude,
    'spd': speed,
    'hdg': heading,
    'acc': accuracy,
    'mgrs': mgrsRaw,
    'ts': timestamp.millisecondsSinceEpoch,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    altitude: (json['alt'] as num?)?.toDouble(),
    speed: (json['spd'] as num?)?.toDouble(),
    heading: (json['hdg'] as num?)?.toDouble(),
    accuracy: (json['acc'] as num?)?.toDouble(),
    mgrsRaw: json['mgrs'] as String? ?? '',
    mgrsFormatted: '', // Compute from mgrsRaw after construction
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
  );
}

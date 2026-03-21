/// Lightweight GPS track recording point.
/// No MGRS field — compute on-demand from lat/lon.
class TrackPoint {
  final double lat;
  final double lon;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final double? accuracy;
  final String? peerId;

  const TrackPoint({
    required this.lat,
    required this.lon,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.accuracy,
    this.peerId,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'alt': altitude,
    'spd': speed,
    'hdg': heading,
    'ts': timestamp.millisecondsSinceEpoch,
    'acc': accuracy,
    if (peerId != null) 'pid': peerId,
  };

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    altitude: (json['alt'] as num?)?.toDouble(),
    speed: (json['spd'] as num?)?.toDouble(),
    heading: (json['hdg'] as num?)?.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    accuracy: (json['acc'] as num?)?.toDouble(),
    peerId: json['pid'] as String?,
  );
}

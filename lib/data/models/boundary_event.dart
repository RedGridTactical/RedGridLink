/// A geofence boundary crossing event.
///
/// Recorded when a peer's position transitions from inside to outside
/// the active session boundary annotation.
class BoundaryEvent {
  final String id;
  final String peerId;
  final String callsign;
  final DateTime timestamp;
  final double lat;
  final double lon;

  const BoundaryEvent({
    required this.id,
    required this.peerId,
    required this.callsign,
    required this.timestamp,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pid': peerId,
        'cs': callsign,
        'ts': timestamp.millisecondsSinceEpoch,
        'lat': lat,
        'lon': lon,
      };

  factory BoundaryEvent.fromJson(Map<String, dynamic> json) => BoundaryEvent(
        id: json['id'] as String,
        peerId: json['pid'] as String,
        callsign: json['cs'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
}

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';

/// After-Action Report data — captures a complete session snapshot
/// for export and post-mission review.
class AarData {
  final String sessionId;
  final String sessionName;
  final OperationalMode operationalMode;
  final DateTime startTime;
  final DateTime endTime;
  final List<Peer> peers;
  final List<Marker> markers;
  final List<TrackPoint> trackPoints;
  final List<Annotation> annotations;
  final String? notes;

  const AarData({
    required this.sessionId,
    required this.sessionName,
    required this.operationalMode,
    required this.startTime,
    required this.endTime,
    this.peers = const [],
    this.markers = const [],
    this.trackPoints = const [],
    this.annotations = const [],
    this.notes,
  });

  /// Duration of the session
  Duration get duration => endTime.difference(startTime);

  /// Total number of track points recorded
  int get totalTrackPoints => trackPoints.length;

  /// Total number of markers placed
  int get totalMarkers => markers.length;

  /// Total number of peers that participated
  int get totalPeers => peers.length;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'sessionName': sessionName,
    'mode': operationalMode.id,
    'start': startTime.millisecondsSinceEpoch,
    'end': endTime.millisecondsSinceEpoch,
    'peers': peers.map((p) => p.toJson()).toList(),
    'markers': markers.map((m) => m.toJson()).toList(),
    'track': trackPoints.map((t) => t.toJson()).toList(),
    'annotations': annotations.map((a) => a.toJson()).toList(),
    'notes': notes,
  };

  factory AarData.fromJson(Map<String, dynamic> json) => AarData(
    sessionId: json['sessionId'] as String,
    sessionName: json['sessionName'] as String,
    operationalMode: OperationalMode.values.firstWhere(
      (m) => m.id == json['mode'],
      orElse: () => OperationalMode.sar,
    ),
    startTime: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
    endTime: DateTime.fromMillisecondsSinceEpoch(json['end'] as int),
    peers: (json['peers'] as List<dynamic>?)
            ?.map((p) => Peer.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [],
    markers: (json['markers'] as List<dynamic>?)
            ?.map((m) => Marker.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const [],
    trackPoints: (json['track'] as List<dynamic>?)
            ?.map((t) => TrackPoint.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
    annotations: (json['annotations'] as List<dynamic>?)
            ?.map((a) => Annotation.fromJson(a as Map<String, dynamic>))
            .toList() ??
        const [],
    notes: json['notes'] as String?,
  );
}

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/boundary_event.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';

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
  final Annotation? boundary;
  final List<BoundaryEvent> boundaryEvents;

  /// The local device's Field Readiness preflight captured at step-off
  /// (session start), or null if none was recorded. Rendered as the
  /// "STEP-OFF READINESS" page in the exported PDF.
  final PreflightReport? preflightSnapshot;

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
    this.boundary,
    this.boundaryEvents = const [],
    this.preflightSnapshot,
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
    if (boundary != null) 'boundary': boundary!.toJson(),
    'boundaryEvents': boundaryEvents.map((e) => e.toJson()).toList(),
    if (preflightSnapshot != null) 'preflight': preflightSnapshot!.toJson(),
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
    boundary: json['boundary'] != null
        ? Annotation.fromJson(json['boundary'] as Map<String, dynamic>)
        : null,
    boundaryEvents: (json['boundaryEvents'] as List<dynamic>?)
            ?.map((e) => BoundaryEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    preflightSnapshot: json['preflight'] != null
        ? PreflightReport.fromJson(json['preflight'] as Map<String, dynamic>)
        : null,
  );

  AarData copyWith({
    String? sessionId,
    String? sessionName,
    OperationalMode? operationalMode,
    DateTime? startTime,
    DateTime? endTime,
    List<Peer>? peers,
    List<Marker>? markers,
    List<TrackPoint>? trackPoints,
    List<Annotation>? annotations,
    String? notes,
    Annotation? boundary,
    List<BoundaryEvent>? boundaryEvents,
    PreflightReport? preflightSnapshot,
  }) =>
      AarData(
        sessionId: sessionId ?? this.sessionId,
        sessionName: sessionName ?? this.sessionName,
        operationalMode: operationalMode ?? this.operationalMode,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        peers: peers ?? this.peers,
        markers: markers ?? this.markers,
        trackPoints: trackPoints ?? this.trackPoints,
        annotations: annotations ?? this.annotations,
        notes: notes ?? this.notes,
        boundary: boundary ?? this.boundary,
        boundaryEvents: boundaryEvents ?? this.boundaryEvents,
        preflightSnapshot: preflightSnapshot ?? this.preflightSnapshot,
      );
}

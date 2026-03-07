import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/g_counter.dart';
import 'package:red_grid_link/services/field_link/sync/crdt/lww_register.dart';

/// Combined CRDT state for a Field Link session.
///
/// Holds all replicated data structures needed to maintain a consistent
/// view across peers:
/// - **Positions**: one [LwwRegister] per peer for last-known location.
/// - **Markers**: one [LwwRegister] per marker ID (add/update wins over
///   older writes; deletes are modeled as tombstones with a null value).
/// - **Annotations**: one [LwwRegister] per annotation ID.
/// - **Sequence counter**: [GCounter] for globally-ordered sequencing.
class CrdtState {
  /// Position registers: peerId -> LWW register wrapping a [Position].
  final Map<String, LwwRegister<Position>> positions;

  /// Marker set: markerId -> LWW register wrapping a nullable [Marker].
  /// A null value acts as a tombstone (delete).
  final Map<String, LwwRegister<Marker?>> markers;

  /// Annotation set: annotationId -> LWW register wrapping a nullable
  /// [Annotation]. A null value acts as a tombstone.
  final Map<String, LwwRegister<Annotation?>> annotations;

  /// Sequence counter for global ordering.
  final GCounter sequenceCounter;

  const CrdtState({
    this.positions = const {},
    this.markers = const {},
    this.annotations = const {},
    this.sequenceCounter = const GCounter.zero(),
  });

  /// Merge the full state from [other] into this state.
  ///
  /// Per-key LWW merge for positions, markers, and annotations.
  /// GCounter merge for sequence numbers.
  CrdtState merge(CrdtState other) {
    return CrdtState(
      positions: _mergeMaps(positions, other.positions),
      markers: _mergeMaps(markers, other.markers),
      annotations: _mergeMaps(annotations, other.annotations),
      sequenceCounter: sequenceCounter.merge(other.sequenceCounter),
    );
  }

  /// Apply a single incoming [SyncPayload] delta.
  ///
  /// Decodes the payload type and merges the relevant register.
  CrdtState applyDelta(SyncPayload delta) {
    final ts = delta.timestamp.millisecondsSinceEpoch;
    final senderId = delta.senderId;

    switch (delta.type) {
      case SyncPayloadType.position:
        final pos = Position.fromJson(delta.data);
        final register = LwwRegister<Position>(
          nodeId: senderId,
          timestamp: ts,
          value: pos,
        );
        final updatedPositions = Map<String, LwwRegister<Position>>.from(positions);
        final existing = updatedPositions[senderId];
        updatedPositions[senderId] =
            existing != null ? existing.merge(register) : register;
        return CrdtState(
          positions: updatedPositions,
          markers: markers,
          annotations: annotations,
          sequenceCounter: sequenceCounter.increment(senderId),
        );

      case SyncPayloadType.marker:
        final rawMarkerId = delta.data['id'];
        if (rawMarkerId is! String) return this; // Malformed — skip
        final markerId = rawMarkerId;
        final isDelete = delta.data['_deleted'] == true;
        final LwwRegister<Marker?> register;

        if (isDelete) {
          register = LwwRegister<Marker?>(
            nodeId: senderId,
            timestamp: ts,
            value: null,
          );
        } else {
          register = LwwRegister<Marker?>(
            nodeId: senderId,
            timestamp: ts,
            value: Marker.fromJson(delta.data),
          );
        }

        final updatedMarkers = Map<String, LwwRegister<Marker?>>.from(markers);
        final existing = updatedMarkers[markerId];
        updatedMarkers[markerId] =
            existing != null ? existing.merge(register) : register;
        return CrdtState(
          positions: positions,
          markers: updatedMarkers,
          annotations: annotations,
          sequenceCounter: sequenceCounter.increment(senderId),
        );

      case SyncPayloadType.annotation:
        final rawAnnotationId = delta.data['id'];
        if (rawAnnotationId is! String) return this; // Malformed — skip
        final annotationId = rawAnnotationId;
        final isDelete = delta.data['_deleted'] == true;
        final LwwRegister<Annotation?> register;

        if (isDelete) {
          register = LwwRegister<Annotation?>(
            nodeId: senderId,
            timestamp: ts,
            value: null,
          );
        } else {
          register = LwwRegister<Annotation?>(
            nodeId: senderId,
            timestamp: ts,
            value: Annotation.fromJson(delta.data),
          );
        }

        final updatedAnnotations =
            Map<String, LwwRegister<Annotation?>>.from(annotations);
        final existing = updatedAnnotations[annotationId];
        updatedAnnotations[annotationId] =
            existing != null ? existing.merge(register) : register;
        return CrdtState(
          positions: positions,
          markers: markers,
          annotations: updatedAnnotations,
          sequenceCounter: sequenceCounter.increment(senderId),
        );

      case SyncPayloadType.control:
        // Control messages (join/leave/ping) don't mutate CRDT state
        // beyond bumping the sequence counter.
        return CrdtState(
          positions: positions,
          markers: markers,
          annotations: annotations,
          sequenceCounter: sequenceCounter.increment(senderId),
        );
    }
  }

  /// Update a local peer's position register.
  CrdtState updatePosition(String peerId, Position position) {
    final register = LwwRegister<Position>(
      nodeId: peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      value: position,
    );
    final updatedPositions = Map<String, LwwRegister<Position>>.from(positions);
    final existing = updatedPositions[peerId];
    updatedPositions[peerId] =
        existing != null ? existing.merge(register) : register;
    return CrdtState(
      positions: updatedPositions,
      markers: markers,
      annotations: annotations,
      sequenceCounter: sequenceCounter.increment(peerId),
    );
  }

  /// Upsert a marker into the CRDT state.
  CrdtState upsertMarker(String nodeId, Marker marker) {
    final register = LwwRegister<Marker?>(
      nodeId: nodeId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      value: marker,
    );
    final updatedMarkers = Map<String, LwwRegister<Marker?>>.from(markers);
    final existing = updatedMarkers[marker.id];
    updatedMarkers[marker.id] =
        existing != null ? existing.merge(register) : register;
    return CrdtState(
      positions: positions,
      markers: updatedMarkers,
      annotations: annotations,
      sequenceCounter: sequenceCounter.increment(nodeId),
    );
  }

  /// Tombstone a marker (mark as deleted).
  CrdtState deleteMarker(String nodeId, String markerId) {
    final register = LwwRegister<Marker?>(
      nodeId: nodeId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      value: null,
    );
    final updatedMarkers = Map<String, LwwRegister<Marker?>>.from(markers);
    final existing = updatedMarkers[markerId];
    updatedMarkers[markerId] =
        existing != null ? existing.merge(register) : register;
    return CrdtState(
      positions: positions,
      markers: updatedMarkers,
      annotations: annotations,
      sequenceCounter: sequenceCounter.increment(nodeId),
    );
  }

  /// Upsert an annotation into the CRDT state.
  CrdtState upsertAnnotation(String nodeId, Annotation annotation) {
    final register = LwwRegister<Annotation?>(
      nodeId: nodeId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      value: annotation,
    );
    final updatedAnnotations =
        Map<String, LwwRegister<Annotation?>>.from(annotations);
    final existing = updatedAnnotations[annotation.id];
    updatedAnnotations[annotation.id] =
        existing != null ? existing.merge(register) : register;
    return CrdtState(
      positions: positions,
      markers: markers,
      annotations: updatedAnnotations,
      sequenceCounter: sequenceCounter.increment(nodeId),
    );
  }

  /// Get all live (non-tombstoned) markers.
  List<Marker> get liveMarkers => markers.values
      .where((r) => r.value != null)
      .map((r) => r.value!)
      .toList();

  /// Get all live (non-tombstoned) annotations.
  List<Annotation> get liveAnnotations => annotations.values
      .where((r) => r.value != null)
      .map((r) => r.value!)
      .toList();

  /// Get all current positions as a map of peerId -> Position.
  Map<String, Position> get currentPositions =>
      positions.map((k, v) => MapEntry(k, v.value));

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Merge two maps of LWW registers, per-key.
  static Map<String, LwwRegister<V>> _mergeMaps<V>(
    Map<String, LwwRegister<V>> a,
    Map<String, LwwRegister<V>> b,
  ) {
    final result = Map<String, LwwRegister<V>>.from(a);
    for (final entry in b.entries) {
      final existing = result[entry.key];
      result[entry.key] =
          existing != null ? existing.merge(entry.value) : entry.value;
    }
    return result;
  }
}

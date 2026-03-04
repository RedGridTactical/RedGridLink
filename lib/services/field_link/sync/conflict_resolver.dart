import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';

/// Conflict resolution strategy for Field Link sync.
///
/// Uses a Last-Writer-Wins approach:
/// 1. The update with the newer timestamp wins.
/// 2. If timestamps are equal, the lexicographically greater device ID
///    wins (deterministic tiebreaker ensuring all peers converge).
///
/// This is the same logic as [LwwRegister.merge], but exposed as a
/// standalone utility so the [SyncEngine] can resolve conflicts at the
/// domain-model level without requiring a full CRDT wrapper.
class ConflictResolver {
  const ConflictResolver();

  /// Resolve a position conflict between local and remote values.
  ///
  /// Returns the position with the newer timestamp. If timestamps are
  /// equal, the position from the device with the lexicographically
  /// greater ID wins.
  Position resolvePosition(
    Position local,
    Position remote,
    String localId,
    String remoteId,
  ) {
    if (isRemoteNewer(local.timestamp, localId, remote.timestamp, remoteId)) {
      return remote;
    }
    return local;
  }

  /// Resolve a marker conflict between local and remote values.
  ///
  /// Uses [Marker.createdAt] as the timestamp and [Marker.createdBy]
  /// as the device ID for the tiebreaker.
  Marker resolveMarker(Marker local, Marker remote) {
    if (isRemoteNewer(
      local.createdAt,
      local.createdBy,
      remote.createdAt,
      remote.createdBy,
    )) {
      return remote;
    }
    return local;
  }

  /// Resolve an annotation conflict between local and remote values.
  ///
  /// Uses [Annotation.createdAt] as the timestamp and
  /// [Annotation.createdBy] as the device ID for the tiebreaker.
  Annotation resolveAnnotation(Annotation local, Annotation remote) {
    if (isRemoteNewer(
      local.createdAt,
      local.createdBy,
      remote.createdAt,
      remote.createdBy,
    )) {
      return remote;
    }
    return local;
  }

  /// Check if the remote value is strictly newer than the local value.
  ///
  /// Returns `true` if:
  /// - [remoteTimestamp] is after [localTimestamp], OR
  /// - timestamps are equal and [remoteDeviceId] > [localDeviceId]
  ///   lexicographically.
  bool isRemoteNewer(
    DateTime localTimestamp,
    String localDeviceId,
    DateTime remoteTimestamp,
    String remoteDeviceId,
  ) {
    if (remoteTimestamp.isAfter(localTimestamp)) {
      return true;
    }
    if (remoteTimestamp.isAtSameMomentAs(localTimestamp)) {
      return remoteDeviceId.compareTo(localDeviceId) > 0;
    }
    return false;
  }
}

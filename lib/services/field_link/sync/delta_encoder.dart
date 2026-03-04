import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';

/// Delta encoding for efficient over-the-wire sync.
///
/// Produces ultra-compact [SyncPayload] instances that fit within BLE
/// MTU limits. Position payloads target < 200 bytes by using short JSON
/// keys and omitting null/default values.
///
/// Wire format example for position:
/// ```json
/// {"t":"position","s":"abc","n":42,"ts":1709400000,"d":{"lat":35.139,"lon":-79.001,"spd":1.2,"hdg":45.0}}
/// ```
class DeltaEncoder {
  const DeltaEncoder();

  // ---------------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------------

  /// Encode a position update into a compact payload (< 200 bytes).
  ///
  /// Only includes non-null fields in the data map to minimize size.
  /// Coordinates are rounded to 6 decimal places (~0.11 m precision).
  SyncPayload encodePosition(
    String senderId,
    Position position,
    int sequenceNum,
  ) {
    final data = <String, dynamic>{
      'lat': _round6(position.lat),
      'lon': _round6(position.lon),
    };

    // Only include optional fields if present
    if (position.speed != null) data['spd'] = _round1(position.speed!);
    if (position.heading != null) data['hdg'] = _round1(position.heading!);
    if (position.altitude != null) data['alt'] = _round1(position.altitude!);
    if (position.accuracy != null) data['acc'] = _round1(position.accuracy!);
    if (position.mgrsRaw.isNotEmpty) data['mgrs'] = position.mgrsRaw;

    return SyncPayload(
      type: SyncPayloadType.position,
      senderId: senderId,
      sequenceNum: sequenceNum,
      timestamp: position.timestamp,
      data: data,
    );
  }

  /// Encode a marker create/update.
  SyncPayload encodeMarker(
    String senderId,
    Marker marker,
    int sequenceNum,
  ) {
    return SyncPayload(
      type: SyncPayloadType.marker,
      senderId: senderId,
      sequenceNum: sequenceNum,
      timestamp: marker.createdAt,
      data: marker.toJson(),
    );
  }

  /// Encode a marker deletion (tombstone).
  SyncPayload encodeMarkerDelete(
    String senderId,
    String markerId,
    int sequenceNum,
  ) {
    return SyncPayload(
      type: SyncPayloadType.marker,
      senderId: senderId,
      sequenceNum: sequenceNum,
      timestamp: DateTime.now(),
      data: {'id': markerId, '_deleted': true},
    );
  }

  /// Encode an annotation create/update.
  SyncPayload encodeAnnotation(
    String senderId,
    Annotation annotation,
    int sequenceNum,
  ) {
    return SyncPayload(
      type: SyncPayloadType.annotation,
      senderId: senderId,
      sequenceNum: sequenceNum,
      timestamp: annotation.createdAt,
      data: annotation.toJson(),
    );
  }

  /// Encode a control message (join, leave, ping, etc.).
  SyncPayload encodeControl(
    String senderId,
    String action,
    Map<String, dynamic> data,
    int sequenceNum,
  ) {
    final controlData = <String, dynamic>{
      'action': action,
      ...data,
    };

    return SyncPayload(
      type: SyncPayloadType.control,
      senderId: senderId,
      sequenceNum: sequenceNum,
      timestamp: DateTime.now(),
      data: controlData,
    );
  }

  // ---------------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------------

  /// Decode an incoming [SyncPayload] into its typed data.
  ///
  /// Returns a record containing the payload type and the decoded
  /// domain object.
  ({SyncPayloadType type, dynamic data}) decode(SyncPayload payload) {
    switch (payload.type) {
      case SyncPayloadType.position:
        return (
          type: SyncPayloadType.position,
          data: _decodePosition(payload.data, payload.timestamp),
        );
      case SyncPayloadType.marker:
        if (payload.data['_deleted'] == true) {
          return (
            type: SyncPayloadType.marker,
            data: null, // Tombstone
          );
        }
        return (
          type: SyncPayloadType.marker,
          data: Marker.fromJson(payload.data),
        );
      case SyncPayloadType.annotation:
        if (payload.data['_deleted'] == true) {
          return (
            type: SyncPayloadType.annotation,
            data: null,
          );
        }
        return (
          type: SyncPayloadType.annotation,
          data: Annotation.fromJson(payload.data),
        );
      case SyncPayloadType.control:
        return (
          type: SyncPayloadType.control,
          data: payload.data,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Size verification
  // ---------------------------------------------------------------------------

  /// Verify that a payload is within the BLE size limit (< 200 bytes).
  static bool isWithinSizeLimit(SyncPayload payload) {
    return payload.toBytes().length <= SyncConstants.maxPayloadBytes;
  }

  /// Verify that a payload is within the bulk transfer limit (< 50 KB).
  static bool isWithinBulkSizeLimit(SyncPayload payload) {
    return payload.toBytes().length <= SyncConstants.maxBulkPayloadBytes;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Decode a compact position data map back into a [Position].
  Position _decodePosition(Map<String, dynamic> data, DateTime timestamp) {
    return Position(
      lat: (data['lat'] as num).toDouble(),
      lon: (data['lon'] as num).toDouble(),
      altitude: (data['alt'] as num?)?.toDouble(),
      speed: (data['spd'] as num?)?.toDouble(),
      heading: (data['hdg'] as num?)?.toDouble(),
      accuracy: (data['acc'] as num?)?.toDouble(),
      mgrsRaw: data['mgrs'] as String? ?? '',
      mgrsFormatted: '',
      timestamp: data['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['ts'] as int)
          : timestamp,
    );
  }

  /// Round to 6 decimal places (~0.11 m precision for lat/lon).
  static double _round6(double value) =>
      (value * 1000000).roundToDouble() / 1000000;

  /// Round to 1 decimal place (sufficient for speed/heading/altitude).
  static double _round1(double value) =>
      (value * 10).roundToDouble() / 10;
}

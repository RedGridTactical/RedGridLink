import 'dart:convert';
import 'dart:typed_data';

/// Sync payload type
enum SyncPayloadType {
  position,
  marker,
  annotation,
  control;

  static SyncPayloadType fromString(String value) =>
      SyncPayloadType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SyncPayloadType.control,
      );
}

/// Delta sync payload for Field Link wire protocol.
///
/// Position payloads must be kept under 200 bytes on the wire.
/// Use compact JSON keys and omit null/default values.
class SyncPayload {
  final SyncPayloadType type;
  final String senderId;
  final int sequenceNum;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool compressed;

  const SyncPayload({
    required this.type,
    required this.senderId,
    required this.sequenceNum,
    required this.timestamp,
    required this.data,
    this.compressed = false,
  });

  /// Serialize to compact JSON bytes for wire transmission.
  /// Position payloads target <200 bytes by using short keys
  /// and omitting null values from data.
  Uint8List toBytes() {
    final payload = <String, dynamic>{
      't': type.name,
      's': senderId,
      'n': sequenceNum,
      'ts': timestamp.millisecondsSinceEpoch,
      'd': data,
      if (compressed) 'c': true,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  /// Deserialize from wire bytes.
  factory SyncPayload.fromBytes(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return SyncPayload(
      type: SyncPayloadType.fromString(json['t'] as String),
      senderId: json['s'] as String,
      sequenceNum: json['n'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      data: json['d'] as Map<String, dynamic>,
      compressed: json['c'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'senderId': senderId,
    'seq': sequenceNum,
    'ts': timestamp.millisecondsSinceEpoch,
    'data': data,
    'compressed': compressed,
  };

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
    type: SyncPayloadType.fromString(json['type'] as String),
    senderId: json['senderId'] as String,
    sequenceNum: json['seq'] as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    data: json['data'] as Map<String, dynamic>,
    compressed: json['compressed'] as bool? ?? false,
  );
}

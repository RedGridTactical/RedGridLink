import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/sync_payload.dart';
import 'package:red_grid_link/services/field_link/sync/delta_encoder.dart';

void main() {
  const encoder = DeltaEncoder();

  // Helper factories
  Position makePosition({
    double lat = 35.139,
    double lon = -79.001,
    double? speed,
    double? heading,
    double? altitude,
    double? accuracy,
    String mgrs = '',
    DateTime? timestamp,
  }) =>
      Position(
        lat: lat,
        lon: lon,
        speed: speed,
        heading: heading,
        altitude: altitude,
        accuracy: accuracy,
        mgrsRaw: mgrs,
        mgrsFormatted: '',
        timestamp: timestamp ?? DateTime(2024, 3, 2, 12, 0),
      );

  Marker makeMarker({
    String id = 'marker-1',
    String createdBy = 'node-a',
  }) =>
      Marker(
        id: id,
        lat: 35.0,
        lon: -79.0,
        createdBy: createdBy,
        createdAt: DateTime(2024, 3, 2, 12, 0),
      );

  Annotation makeAnnotation({
    String id = 'ann-1',
    String createdBy = 'node-a',
  }) =>
      Annotation(
        id: id,
        type: AnnotationType.polyline,
        points: const [
          AnnotationPoint(lat: 35.0, lon: -79.0),
          AnnotationPoint(lat: 35.1, lon: -79.1),
        ],
        createdBy: createdBy,
        createdAt: DateTime(2024, 3, 2, 12, 0),
      );

  // -------------------------------------------------------------------------
  // encodePosition
  // -------------------------------------------------------------------------
  group('encodePosition', () {
    test('creates a position payload', () {
      final pos = makePosition(speed: 1.2, heading: 45.0);
      final payload = encoder.encodePosition('abc', pos, 42);

      expect(payload.type, SyncPayloadType.position);
      expect(payload.senderId, 'abc');
      expect(payload.sequenceNum, 42);
      expect(payload.data['lat'], 35.139);
      expect(payload.data['lon'], -79.001);
      expect(payload.data['spd'], 1.2);
      expect(payload.data['hdg'], 45.0);
    });

    test('omits null optional fields', () {
      final pos = makePosition();
      final payload = encoder.encodePosition('abc', pos, 1);

      expect(payload.data.containsKey('spd'), isFalse);
      expect(payload.data.containsKey('hdg'), isFalse);
      expect(payload.data.containsKey('alt'), isFalse);
      expect(payload.data.containsKey('acc'), isFalse);
    });

    test('includes optional fields when present', () {
      final pos = makePosition(
        speed: 1.5,
        heading: 90.0,
        altitude: 200.0,
        accuracy: 5.0,
        mgrs: '17SQV1234567890',
      );
      final payload = encoder.encodePosition('abc', pos, 1);

      expect(payload.data['spd'], 1.5);
      expect(payload.data['hdg'], 90.0);
      expect(payload.data['alt'], 200.0);
      expect(payload.data['acc'], 5.0);
      expect(payload.data['mgrs'], '17SQV1234567890');
    });

    test('position payload fits within 200-byte BLE limit', () {
      final pos = makePosition(
        speed: 1.2,
        heading: 45.0,
        altitude: 150.0,
        accuracy: 3.5,
        mgrs: '17SQV12345',
      );
      final payload = encoder.encodePosition('abc', pos, 42);
      expect(DeltaEncoder.isWithinSizeLimit(payload), isTrue);
    });

    test('minimal position payload fits within limit', () {
      final pos = makePosition();
      final payload = encoder.encodePosition('abc', pos, 1);
      expect(DeltaEncoder.isWithinSizeLimit(payload), isTrue);
    });

    test('coordinates are rounded to 6 decimal places', () {
      final pos = makePosition(
        lat: 35.1234567890,
        lon: -79.0012345678,
      );
      final payload = encoder.encodePosition('x', pos, 1);
      // 6 decimal places
      expect(payload.data['lat'], closeTo(35.123457, 0.000001));
      expect(payload.data['lon'], closeTo(-79.001235, 0.000001));
    });
  });

  // -------------------------------------------------------------------------
  // encodeMarker
  // -------------------------------------------------------------------------
  group('encodeMarker', () {
    test('creates a marker payload', () {
      final marker = makeMarker();
      final payload = encoder.encodeMarker('node-a', marker, 5);

      expect(payload.type, SyncPayloadType.marker);
      expect(payload.senderId, 'node-a');
      expect(payload.data['id'], 'marker-1');
    });
  });

  // -------------------------------------------------------------------------
  // encodeMarkerDelete
  // -------------------------------------------------------------------------
  group('encodeMarkerDelete', () {
    test('creates a tombstone payload', () {
      final payload = encoder.encodeMarkerDelete('node-a', 'marker-1', 6);

      expect(payload.type, SyncPayloadType.marker);
      expect(payload.data['id'], 'marker-1');
      expect(payload.data['_deleted'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // encodeAnnotation
  // -------------------------------------------------------------------------
  group('encodeAnnotation', () {
    test('creates an annotation payload', () {
      final ann = makeAnnotation();
      final payload = encoder.encodeAnnotation('node-a', ann, 7);

      expect(payload.type, SyncPayloadType.annotation);
      expect(payload.data['id'], 'ann-1');
      expect(payload.data['type'], 'polyline');
    });
  });

  // -------------------------------------------------------------------------
  // encodeControl
  // -------------------------------------------------------------------------
  group('encodeControl', () {
    test('creates a control payload', () {
      final payload = encoder.encodeControl(
        'node-a',
        'join',
        {'sessionId': 'session-1'},
        10,
      );

      expect(payload.type, SyncPayloadType.control);
      expect(payload.data['action'], 'join');
      expect(payload.data['sessionId'], 'session-1');
    });
  });

  // -------------------------------------------------------------------------
  // decode
  // -------------------------------------------------------------------------
  group('decode', () {
    test('decodes a position payload', () {
      final pos = makePosition(lat: 35.5, lon: -79.5, speed: 2.0);
      final payload = encoder.encodePosition('abc', pos, 1);
      final decoded = encoder.decode(payload);

      expect(decoded.type, SyncPayloadType.position);
      final decodedPos = decoded.data as Position;
      expect(decodedPos.lat, closeTo(35.5, 0.001));
      expect(decodedPos.lon, closeTo(-79.5, 0.001));
    });

    test('decodes a marker payload', () {
      final marker = makeMarker();
      final payload = encoder.encodeMarker('node-a', marker, 1);
      final decoded = encoder.decode(payload);

      expect(decoded.type, SyncPayloadType.marker);
      final decodedMarker = decoded.data as Marker;
      expect(decodedMarker.id, 'marker-1');
    });

    test('decodes a marker deletion as null', () {
      final payload = encoder.encodeMarkerDelete('node-a', 'marker-1', 1);
      final decoded = encoder.decode(payload);

      expect(decoded.type, SyncPayloadType.marker);
      expect(decoded.data, isNull);
    });

    test('decodes an annotation payload', () {
      final ann = makeAnnotation();
      final payload = encoder.encodeAnnotation('node-a', ann, 1);
      final decoded = encoder.decode(payload);

      expect(decoded.type, SyncPayloadType.annotation);
      final decodedAnn = decoded.data as Annotation;
      expect(decodedAnn.id, 'ann-1');
    });

    test('decodes a control payload', () {
      final payload = encoder.encodeControl(
        'node-a',
        'ping',
        {'extra': 'data'},
        1,
      );
      final decoded = encoder.decode(payload);

      expect(decoded.type, SyncPayloadType.control);
      final data = decoded.data as Map<String, dynamic>;
      expect(data['action'], 'ping');
    });
  });

  // -------------------------------------------------------------------------
  // isWithinSizeLimit
  // -------------------------------------------------------------------------
  group('isWithinSizeLimit', () {
    test('returns true for small payloads', () {
      final pos = makePosition();
      final payload = encoder.encodePosition('a', pos, 1);
      expect(DeltaEncoder.isWithinSizeLimit(payload), isTrue);
    });

    test('size limit is 200 bytes', () {
      expect(SyncConstants.maxPayloadBytes, 200);
    });
  });

  // -------------------------------------------------------------------------
  // isWithinBulkSizeLimit
  // -------------------------------------------------------------------------
  group('isWithinBulkSizeLimit', () {
    test('marker payload is within bulk limit', () {
      final marker = makeMarker();
      final payload = encoder.encodeMarker('node-a', marker, 1);
      expect(DeltaEncoder.isWithinBulkSizeLimit(payload), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Roundtrip: encode -> toBytes -> fromBytes -> decode
  // -------------------------------------------------------------------------
  group('roundtrip serialization', () {
    test('position survives full roundtrip', () {
      final pos = makePosition(lat: 35.5, lon: -79.5, speed: 1.5);
      final payload = encoder.encodePosition('abc', pos, 42);
      final bytes = payload.toBytes();
      final restored = SyncPayload.fromBytes(bytes);

      expect(restored.type, SyncPayloadType.position);
      expect(restored.senderId, 'abc');
      expect(restored.sequenceNum, 42);

      final decoded = encoder.decode(restored);
      final restoredPos = decoded.data as Position;
      expect(restoredPos.lat, closeTo(35.5, 0.001));
      expect(restoredPos.lon, closeTo(-79.5, 0.001));
    });

    test('marker survives full roundtrip', () {
      final marker = makeMarker();
      final payload = encoder.encodeMarker('node-a', marker, 5);
      final bytes = payload.toBytes();
      final restored = SyncPayload.fromBytes(bytes);
      final decoded = encoder.decode(restored);

      expect(decoded.type, SyncPayloadType.marker);
      final restoredMarker = decoded.data as Marker;
      expect(restoredMarker.id, 'marker-1');
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/boundary_event.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/services/session/session_exporter.dart';
import 'package:red_grid_link/services/session/session_importer.dart';

void main() {
  late AarData sampleAar;

  setUp(() {
    final now = DateTime(2026, 3, 21, 14, 0, 0);
    sampleAar = AarData(
      sessionId: 'sess-001',
      sessionName: 'Alpha Sweep',
      operationalMode: OperationalMode.sar,
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      peers: [
        Peer(
          id: 'peer-1',
          displayName: 'Ranger One',
          lastSeen: now,
          callsign: 'R1',
        ),
      ],
      markers: [
        Marker(
          id: 'mkr-1',
          lat: 38.8977,
          lon: -77.0365,
          createdBy: 'peer-1',
          createdAt: now,
        ),
      ],
      annotations: [
        Annotation(
          id: 'ann-1',
          type: AnnotationType.polyline,
          points: [
            const AnnotationPoint(lat: 38.89, lon: -77.03),
            const AnnotationPoint(lat: 38.90, lon: -77.04),
          ],
          createdBy: 'peer-1',
          createdAt: now,
        ),
      ],
      trackPoints: [
        TrackPoint(lat: 38.8977, lon: -77.0365, timestamp: now),
      ],
      boundary: Annotation(
        id: 'bnd-1',
        type: AnnotationType.boundary,
        points: [
          const AnnotationPoint(lat: 38.88, lon: -77.02),
          const AnnotationPoint(lat: 38.90, lon: -77.04),
          const AnnotationPoint(lat: 38.89, lon: -77.05),
        ],
        createdBy: 'peer-1',
        createdAt: now,
      ),
      boundaryEvents: [
        BoundaryEvent(
          id: 'be-1',
          peerId: 'peer-1',
          callsign: 'R1',
          timestamp: now,
          lat: 38.91,
          lon: -77.06,
        ),
      ],
    );
  });

  /// Helper to build a minimal valid export JSON string.
  String _buildJson({
    String version = '1.3',
    Map<String, dynamic>? sessionOverrides,
  }) {
    final session = sampleAar.toJson();
    if (sessionOverrides != null) session.addAll(sessionOverrides);
    final envelope = <String, dynamic>{
      'version': version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'session': session,
    };
    return json.encode(envelope);
  }

  group('SessionImporter', () {
    test('importFromJson parses valid JSON', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.sessionName, 'Alpha Sweep');
    });

    test('parses peers correctly', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.peers, hasLength(1));
      expect(result.data!.peers.first.displayName, 'Ranger One');
    });

    test('parses markers correctly', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.markers, hasLength(1));
      expect(result.data!.markers.first.lat, closeTo(38.8977, 0.001));
    });

    test('parses annotations correctly', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.annotations, hasLength(1));
    });

    test('parses trackPoints correctly', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.trackPoints, hasLength(1));
    });

    test('parses boundary when present', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.boundary, isNotNull);
      expect(result.data!.boundary!.type, AnnotationType.boundary);
      expect(result.data!.boundary!.points, hasLength(3));
    });

    test('parses boundaryEvents', () {
      final jsonStr = _buildJson();
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.data!.boundaryEvents, hasLength(1));
      expect(result.data!.boundaryEvents.first.callsign, 'R1');
    });

    test('rejects unsupported version', () {
      final jsonStr = _buildJson(version: '0.1');
      final result = SessionImporter.importFromJson(jsonStr);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Unsupported version'));
    });

    test('rejects null version', () {
      final envelope = <String, dynamic>{
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'session': sampleAar.toJson(),
      };
      final result = SessionImporter.importFromJson(json.encode(envelope));
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Unsupported version'));
    });

    test('rejects missing session data', () {
      final envelope = <String, dynamic>{
        'version': '1.3',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
      };
      final result = SessionImporter.importFromJson(json.encode(envelope));
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Missing session data'));
    });

    test('rejects invalid JSON string', () {
      final result = SessionImporter.importFromJson('not valid json {{{');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Invalid JSON format'));
    });

    test('rejects invalid track point coordinates', () {
      final session = sampleAar.toJson();
      // Inject an invalid track point
      session['track'] = [
        {'lat': 999.0, 'lon': -77.0, 'ts': 1000000},
      ];
      final envelope = <String, dynamic>{
        'version': '1.3',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'session': session,
      };
      final result = SessionImporter.importFromJson(json.encode(envelope));
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Invalid coordinates'));
    });

    test('rejects invalid marker coordinates', () {
      final session = sampleAar.toJson();
      session['markers'] = [
        {
          'id': 'bad-mkr',
          'lat': 38.0,
          'lon': 999.0,
          'by': 'test',
          'at': 1000000,
        },
      ];
      final envelope = <String, dynamic>{
        'version': '1.3',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'session': session,
      };
      final result = SessionImporter.importFromJson(json.encode(envelope));
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Invalid coordinates in markers'));
    });

    test('defaults empty arrays when missing', () {
      final session = <String, dynamic>{
        'sessionId': 'sess-min',
        'sessionName': 'Minimal',
        'mode': 'sar',
        'start': DateTime(2026).millisecondsSinceEpoch,
        'end': DateTime(2026, 1, 1, 1).millisecondsSinceEpoch,
      };
      final envelope = <String, dynamic>{
        'version': '1.3',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'session': session,
      };
      final result = SessionImporter.importFromJson(json.encode(envelope));
      expect(result.isSuccess, isTrue);
      expect(result.data!.peers, isEmpty);
      expect(result.data!.markers, isEmpty);
      expect(result.data!.annotations, isEmpty);
      expect(result.data!.trackPoints, isEmpty);
      expect(result.data!.boundary, isNull);
      expect(result.data!.boundaryEvents, isEmpty);
    });

    test('round-trip: export then import produces equivalent data', () {
      final exported = SessionExporter.exportToJson(sampleAar);
      final result = SessionImporter.importFromJson(exported);

      expect(result.isSuccess, isTrue);
      final imported = result.data!;

      expect(imported.sessionId, sampleAar.sessionId);
      expect(imported.sessionName, sampleAar.sessionName);
      expect(imported.operationalMode, sampleAar.operationalMode);
      expect(
        imported.startTime.millisecondsSinceEpoch,
        sampleAar.startTime.millisecondsSinceEpoch,
      );
      expect(
        imported.endTime.millisecondsSinceEpoch,
        sampleAar.endTime.millisecondsSinceEpoch,
      );
      expect(imported.peers.length, sampleAar.peers.length);
      expect(imported.peers.first.id, sampleAar.peers.first.id);
      expect(imported.markers.length, sampleAar.markers.length);
      expect(imported.annotations.length, sampleAar.annotations.length);
      expect(imported.trackPoints.length, sampleAar.trackPoints.length);
      expect(imported.boundary, isNotNull);
      expect(imported.boundary!.id, sampleAar.boundary!.id);
      expect(
        imported.boundaryEvents.length,
        sampleAar.boundaryEvents.length,
      );
      expect(
        imported.boundaryEvents.first.id,
        sampleAar.boundaryEvents.first.id,
      );
    });
  });

  group('ImportResult', () {
    test('success has non-null data and null error', () {
      final result = ImportResult.success(sampleAar);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.error, isNull);
    });

    test('failure has null data and non-null error', () {
      const result = ImportResult.failure('something broke');
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.error, 'something broke');
    });
  });
}

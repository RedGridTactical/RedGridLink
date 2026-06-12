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

  group('SessionExporter', () {
    test('exportToJson produces valid JSON', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      expect(() => json.decode(jsonStr), returnsNormally);
    });

    test('JSON contains version 1.3', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      expect(map['version'], '1.3');
    });

    test('JSON contains exportedAt timestamp', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      expect(map['exportedAt'], isNotNull);
      expect(() => DateTime.parse(map['exportedAt'] as String), returnsNormally);
    });

    test('JSON contains session name and mode', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      expect(session['sessionName'], 'Alpha Sweep');
      expect(session['mode'], 'sar');
    });

    test('JSON contains start and end times', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      expect(session['start'], isA<int>());
      expect(session['end'], isA<int>());
    });

    test('JSON contains peers array', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      final peers = session['peers'] as List;
      expect(peers, hasLength(1));
      expect((peers.first as Map)['name'], 'Ranger One');
    });

    test('JSON contains markers array', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      final markers = session['markers'] as List;
      expect(markers, hasLength(1));
    });

    test('JSON contains annotations array', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      final annotations = session['annotations'] as List;
      expect(annotations, hasLength(1));
    });

    test('JSON contains trackPoints array', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      final track = session['track'] as List;
      expect(track, hasLength(1));
    });

    test('JSON contains boundary when present', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      expect(session['boundary'], isNotNull);
    });

    test('JSON contains boundaryEvents array', () {
      final jsonStr = SessionExporter.exportToJson(sampleAar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      final events = session['boundaryEvents'] as List;
      expect(events, hasLength(1));
    });

    test('JSON omits boundary when null', () {
      // copyWith preserves non-null boundary; create fresh
      final aar = AarData(
        sessionId: 'sess-002',
        sessionName: 'No Boundary',
        operationalMode: OperationalMode.backcountry,
        startTime: DateTime(2026),
        endTime: DateTime(2026, 1, 1, 1),
      );
      final jsonStr = SessionExporter.exportToJson(aar);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final session = map['session'] as Map<String, dynamic>;
      expect(session.containsKey('boundary'), isFalse);
    });
  });

  group('generateFilename', () {
    test('sanitizes session name', () {
      final filename = SessionExporter.generateFilename('Alpha Sweep!@#');
      expect(filename, contains('Alpha_Sweep'));
      expect(filename, isNot(contains('!')));
      expect(filename, isNot(contains('@')));
      expect(filename, isNot(contains('#')));
    });

    test('includes date', () {
      final filename = SessionExporter.generateFilename('Test');
      // Should contain a YYYY-MM-DD pattern
      expect(filename, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });

    test('has .json extension', () {
      final filename = SessionExporter.generateFilename('Test');
      expect(filename, endsWith('.json'));
    });

    test('starts with redgridlink_session_', () {
      final filename = SessionExporter.generateFilename('Test');
      expect(filename, startsWith('redgridlink_session_'));
    });

    test('replaces spaces with underscores', () {
      final filename = SessionExporter.generateFilename('My Cool Session');
      expect(filename, contains('My_Cool_Session'));
    });
  });
}

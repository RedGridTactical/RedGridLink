import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/services/aar/pdf_generator.dart';

// ---------------------------------------------------------------------------
// Test data factory (top-level to avoid local underscore lint)
// ---------------------------------------------------------------------------

AarData _createTestAar({
  OperationalMode mode = OperationalMode.sar,
  List<Peer>? peers,
  List<Marker>? markers,
  List<TrackPoint>? trackPoints,
  List<Annotation>? annotations,
}) {
  return AarData(
    sessionId: 'test-session-001',
    sessionName: 'Alpha Search',
    operationalMode: mode,
    startTime: DateTime.utc(2026, 3, 2, 14, 30),
    endTime: DateTime.utc(2026, 3, 2, 18, 45),
    peers: peers ??
        [
          Peer(
            id: 'peer-1',
            displayName: 'Alpha Lead',
            deviceType: DeviceType.android,
            lastSeen: DateTime.utc(2026, 3, 2, 18, 30),
          ),
          Peer(
            id: 'peer-2',
            displayName: 'Bravo Scout',
            deviceType: DeviceType.ios,
            lastSeen: DateTime.utc(2026, 3, 2, 18, 40),
          ),
        ],
    markers: markers ??
        [
          Marker(
            id: 'mkr-1',
            lat: 35.0553,
            lon: -79.0055,
            mgrs: '17SQV1234567890',
            label: 'CP1',
            icon: MarkerIcon.checkpoint,
            createdBy: 'peer-1',
            createdAt: DateTime.utc(2026, 3, 2, 15, 0),
          ),
          Marker(
            id: 'mkr-2',
            lat: 35.0560,
            lon: -79.0060,
            mgrs: '17SQV1235067900',
            label: 'Find 1',
            icon: MarkerIcon.find,
            createdBy: 'peer-2',
            createdAt: DateTime.utc(2026, 3, 2, 16, 30),
          ),
        ],
    trackPoints: trackPoints ??
        [
          TrackPoint(
            lat: 35.0553,
            lon: -79.0055,
            altitude: 100.0,
            speed: 1.2,
            timestamp: DateTime.utc(2026, 3, 2, 14, 30),
          ),
          TrackPoint(
            lat: 35.0580,
            lon: -79.0055,
            altitude: 105.0,
            speed: 1.5,
            timestamp: DateTime.utc(2026, 3, 2, 15, 0),
          ),
          TrackPoint(
            lat: 35.0620,
            lon: -79.0050,
            altitude: 110.0,
            speed: 1.0,
            timestamp: DateTime.utc(2026, 3, 2, 16, 0),
          ),
        ],
    annotations: annotations ??
        [
          Annotation(
            id: 'ann-1',
            type: AnnotationType.polyline,
            points: [
              const AnnotationPoint(lat: 35.0553, lon: -79.0055),
              const AnnotationPoint(lat: 35.0580, lon: -79.0055),
            ],
            label: 'Search Line A',
            createdBy: 'peer-1',
            createdAt: DateTime.utc(2026, 3, 2, 15, 15),
          ),
        ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late PdfGenerator generator;

  setUp(() {
    generator = PdfGenerator();
  });

  group('PdfGenerator.generate', () {
    test('produces non-empty bytes for typical AAR data', () async {
      final aar = _createTestAar();
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
    });

    test('produces valid PDF header', () async {
      final aar = _createTestAar();
      final bytes = await generator.generate(aar);

      // PDF files start with %PDF
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      expect(header, equals('%PDF'));
    });

    test('generates PDF for empty session (no peers, markers, tracks)', () async {
      final aar = _createTestAar(
        peers: [],
        markers: [],
        trackPoints: [],
        annotations: [],
      );
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
      // Should still have cover + stats pages
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      expect(header, equals('%PDF'));
    });

    test('generates PDF for SAR mode', () async {
      final aar = _createTestAar(mode: OperationalMode.sar);
      final bytes = await generator.generate(aar);

      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF for Hunting mode', () async {
      final aar = _createTestAar(mode: OperationalMode.hunting);
      final bytes = await generator.generate(aar);

      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF for Backcountry mode', () async {
      final aar = _createTestAar(mode: OperationalMode.backcountry);
      final bytes = await generator.generate(aar);

      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF for Training mode', () async {
      final aar = _createTestAar(mode: OperationalMode.training);
      final bytes = await generator.generate(aar);

      expect(bytes.length, greaterThan(0));
    });

    test('larger session produces larger PDF', () async {
      // Small session
      final smallAar = _createTestAar(
        peers: [],
        markers: [],
        trackPoints: [],
        annotations: [],
      );
      final smallBytes = await generator.generate(smallAar);

      // Full session with data
      final fullAar = _createTestAar();
      final fullBytes = await generator.generate(fullAar);

      // Full report with markers, annotations, tracks should be larger
      expect(fullBytes.length, greaterThan(smallBytes.length));
    });

    test('generates PDF with many markers', () async {
      final manyMarkers = List.generate(
        20,
        (i) => Marker(
          id: 'mkr-$i',
          lat: 35.0553 + (i * 0.001),
          lon: -79.0055 + (i * 0.001),
          mgrs: '17SQV${(12345 + i * 10).toString().padLeft(5, "0")}67890',
          label: 'Marker $i',
          icon: MarkerIcon.waypoint,
          createdBy: 'peer-1',
          createdAt: DateTime.utc(2026, 3, 2, 14 + (i ~/ 4), (i % 4) * 15),
        ),
      );

      final aar = _createTestAar(markers: manyMarkers);
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF with many track points', () async {
      final manyTrackPoints = List.generate(
        100,
        (i) => TrackPoint(
          lat: 35.0553 + (i * 0.0001),
          lon: -79.0055 + (i * 0.00005),
          altitude: 100.0 + i,
          speed: 1.0 + (i % 5) * 0.2,
          timestamp: DateTime.utc(2026, 3, 2, 14).add(Duration(minutes: i)),
        ),
      );

      final aar = _createTestAar(trackPoints: manyTrackPoints);
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF with markers without MGRS (lat/lon fallback)', () async {
      final noMgrsMarkers = [
        Marker(
          id: 'mkr-no-mgrs',
          lat: 35.0553,
          lon: -79.0055,
          mgrs: '', // Empty MGRS
          label: 'No Grid',
          icon: MarkerIcon.waypoint,
          createdBy: 'peer-1',
          createdAt: DateTime.utc(2026, 3, 2, 15, 0),
        ),
      ];

      final aar = _createTestAar(markers: noMgrsMarkers);
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
    });

    test('generates PDF with track points without speed/altitude', () async {
      final minimalTrackPoints = [
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 14, 30),
        ),
        TrackPoint(
          lat: 35.0580,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 15, 0),
        ),
      ];

      final aar = _createTestAar(trackPoints: minimalTrackPoints);
      final bytes = await generator.generate(aar);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
    });
  });
}

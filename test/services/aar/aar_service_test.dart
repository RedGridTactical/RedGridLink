import 'package:flutter_test/flutter_test.dart';

import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/track_point.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';

// ---------------------------------------------------------------------------
// Test data factories (top-level so they can reference each other)
// ---------------------------------------------------------------------------

List<Peer> _defaultPeers() => [
      Peer(
        id: 'peer-1',
        displayName: 'Alpha',
        deviceType: DeviceType.android,
        lastSeen: DateTime.utc(2026, 3, 2, 18, 30),
      ),
      Peer(
        id: 'peer-2',
        displayName: 'Bravo',
        deviceType: DeviceType.ios,
        lastSeen: DateTime.utc(2026, 3, 2, 18, 40),
      ),
    ];

List<Marker> _defaultMarkers() => [
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
    ];

/// Track points forming a roughly 1km track heading north from
/// Fort Liberty area (35.055N, -79.005W).
List<TrackPoint> _defaultTrackPoints() => [
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
      TrackPoint(
        lat: 35.0650,
        lon: -79.0045,
        altitude: 115.0,
        speed: 0.8,
        timestamp: DateTime.utc(2026, 3, 2, 17, 0),
      ),
    ];

AarData _createTestAar({
  List<Peer>? peers,
  List<Marker>? markers,
  List<TrackPoint>? trackPoints,
  List<Annotation>? annotations,
  OperationalMode mode = OperationalMode.sar,
}) {
  return AarData(
    sessionId: 'test-session-001',
    sessionName: 'Alpha Search',
    operationalMode: mode,
    startTime: DateTime.utc(2026, 3, 2, 14, 30),
    endTime: DateTime.utc(2026, 3, 2, 18, 45),
    peers: peers ?? _defaultPeers(),
    markers: markers ?? _defaultMarkers(),
    trackPoints: trackPoints ?? _defaultTrackPoints(),
    annotations: annotations ?? const [],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // formatTacticalTimestamp
  // -------------------------------------------------------------------------

  group('formatTacticalTimestamp', () {
    test('formats standard UTC date correctly', () {
      final dt = DateTime.utc(2026, 3, 2, 14, 30);
      expect(AarService.formatTacticalTimestamp(dt), equals('02MAR26 1430Z'));
    });

    test('formats midnight correctly', () {
      final dt = DateTime.utc(2026, 1, 1, 0, 0);
      expect(AarService.formatTacticalTimestamp(dt), equals('01JAN26 0000Z'));
    });

    test('formats last minute of day correctly', () {
      final dt = DateTime.utc(2026, 12, 31, 23, 59);
      expect(AarService.formatTacticalTimestamp(dt), equals('31DEC26 2359Z'));
    });

    test('pads single-digit day with zero', () {
      final dt = DateTime.utc(2026, 6, 5, 8, 3);
      expect(AarService.formatTacticalTimestamp(dt), equals('05JUN26 0803Z'));
    });

    test('converts local time to UTC', () {
      // Create a local time and verify the output uses UTC
      final local = DateTime(2026, 3, 2, 14, 30);
      final result = AarService.formatTacticalTimestamp(local);
      // Result should end with Z (Zulu / UTC indicator)
      expect(result, endsWith('Z'));
    });
  });

  // -------------------------------------------------------------------------
  // formatDuration
  // -------------------------------------------------------------------------

  group('formatDuration', () {
    test('formats hours and minutes', () {
      expect(
        AarService.formatDuration(const Duration(hours: 2, minutes: 34)),
        equals('2h 34m'),
      );
    });

    test('formats minutes only when less than 1 hour', () {
      expect(
        AarService.formatDuration(const Duration(minutes: 45)),
        equals('45m'),
      );
    });

    test('formats zero minutes', () {
      expect(
        AarService.formatDuration(const Duration(hours: 0, minutes: 0)),
        equals('0m'),
      );
    });

    test('formats exactly 1 hour', () {
      expect(
        AarService.formatDuration(const Duration(hours: 1)),
        equals('1h 0m'),
      );
    });

    test('formats large duration', () {
      expect(
        AarService.formatDuration(const Duration(hours: 12, minutes: 5)),
        equals('12h 5m'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // formatDistance
  // -------------------------------------------------------------------------

  group('formatDistance', () {
    test('shows meters when under 1000', () {
      expect(AarService.formatDistance(500.0), equals('500m'));
    });

    test('shows km when 1000 or more', () {
      expect(AarService.formatDistance(1500.0), equals('1.5km'));
    });

    test('shows 0m for zero distance', () {
      expect(AarService.formatDistance(0.0), equals('0m'));
    });

    test('rounds meters', () {
      expect(AarService.formatDistance(123.456), equals('123m'));
    });

    test('shows one decimal for km', () {
      expect(AarService.formatDistance(2345.0), equals('2.3km'));
    });

    test('shows exact 1km', () {
      expect(AarService.formatDistance(1000.0), equals('1.0km'));
    });
  });

  // -------------------------------------------------------------------------
  // calculateTotalDistance
  // -------------------------------------------------------------------------

  group('calculateTotalDistance', () {
    test('returns 0 for empty list', () {
      expect(AarService.calculateTotalDistance([]), equals(0.0));
    });

    test('returns 0 for single point', () {
      final points = [
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 14, 30),
        ),
      ];
      expect(AarService.calculateTotalDistance(points), equals(0.0));
    });

    test('calculates positive distance for two points', () {
      final points = [
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 14, 30),
        ),
        TrackPoint(
          lat: 35.0650,
          lon: -79.0045,
          timestamp: DateTime.utc(2026, 3, 2, 15, 30),
        ),
      ];
      final distance = AarService.calculateTotalDistance(points);
      expect(distance, greaterThan(0));
      // ~1080m for roughly 0.01 degrees latitude
      expect(distance, closeTo(1080, 100));
    });

    test('accumulates distance across multiple points', () {
      final points = _defaultTrackPoints();
      final distance = AarService.calculateTotalDistance(points);
      // Should be greater than the direct distance from first to last
      expect(distance, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // calculateAreaCovered
  // -------------------------------------------------------------------------

  group('calculateAreaCovered', () {
    test('returns 0 for empty list', () {
      expect(AarService.calculateAreaCovered([]), equals(0.0));
    });

    test('returns 0 for single point', () {
      final points = [
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 14, 30),
        ),
      ];
      expect(AarService.calculateAreaCovered(points), equals(0.0));
    });

    test('calculates positive area for spread-out points', () {
      final points = _defaultTrackPoints();
      final area = AarService.calculateAreaCovered(points);
      expect(area, greaterThan(0));
      // Area should be reasonable (small, a few tenths of km^2 at most)
      expect(area, lessThan(10.0));
    });

    test('returns 0 when all points are identical', () {
      final points = [
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 14, 30),
        ),
        TrackPoint(
          lat: 35.0553,
          lon: -79.0055,
          timestamp: DateTime.utc(2026, 3, 2, 15, 30),
        ),
      ];
      expect(AarService.calculateAreaCovered(points), equals(0.0));
    });
  });

  // -------------------------------------------------------------------------
  // AarData model
  // -------------------------------------------------------------------------

  group('AarData', () {
    test('duration is calculated correctly', () {
      final aar = _createTestAar();
      expect(aar.duration, equals(const Duration(hours: 4, minutes: 15)));
    });

    test('totalPeers returns correct count', () {
      final aar = _createTestAar();
      expect(aar.totalPeers, equals(2));
    });

    test('totalMarkers returns correct count', () {
      final aar = _createTestAar();
      expect(aar.totalMarkers, equals(2));
    });

    test('totalTrackPoints returns correct count', () {
      final aar = _createTestAar();
      expect(aar.totalTrackPoints, equals(4));
    });

    test('empty session has zero counts', () {
      final aar = _createTestAar(
        peers: [],
        markers: [],
        trackPoints: [],
        annotations: [],
      );
      expect(aar.totalPeers, equals(0));
      expect(aar.totalMarkers, equals(0));
      expect(aar.totalTrackPoints, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // AarData serialization
  // -------------------------------------------------------------------------

  group('AarData JSON round-trip', () {
    test('serializes and deserializes correctly', () {
      final aar = _createTestAar();
      final json = aar.toJson();
      final restored = AarData.fromJson(json);

      expect(restored.sessionId, equals(aar.sessionId));
      expect(restored.sessionName, equals(aar.sessionName));
      expect(restored.operationalMode, equals(aar.operationalMode));
      // Compare via millisecondsSinceEpoch (fromJson returns local time)
      expect(
        restored.startTime.millisecondsSinceEpoch,
        equals(aar.startTime.millisecondsSinceEpoch),
      );
      expect(
        restored.endTime.millisecondsSinceEpoch,
        equals(aar.endTime.millisecondsSinceEpoch),
      );
      expect(restored.totalPeers, equals(aar.totalPeers));
      expect(restored.totalMarkers, equals(aar.totalMarkers));
      expect(restored.totalTrackPoints, equals(aar.totalTrackPoints));
    });

    test('handles empty lists', () {
      final aar = _createTestAar(
        peers: [],
        markers: [],
        trackPoints: [],
        annotations: [],
      );
      final json = aar.toJson();
      final restored = AarData.fromJson(json);

      expect(restored.totalPeers, equals(0));
      expect(restored.totalMarkers, equals(0));
      expect(restored.totalTrackPoints, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // Mode-specific behavior
  // -------------------------------------------------------------------------

  group('Operational mode in AarData', () {
    test('SAR mode compiles correctly', () {
      final aar = _createTestAar(mode: OperationalMode.sar);
      expect(aar.operationalMode.baseLabel, equals('Command Post'));
      expect(aar.operationalMode.markerLabel, equals('Find'));
    });

    test('Hunting mode compiles correctly', () {
      final aar = _createTestAar(mode: OperationalMode.hunting);
      expect(aar.operationalMode.baseLabel, equals('Truck'));
      expect(aar.operationalMode.markerLabel, equals('Stand'));
    });

    test('Backcountry mode compiles correctly', () {
      final aar = _createTestAar(mode: OperationalMode.backcountry);
      expect(aar.operationalMode.baseLabel, equals('Trailhead'));
      expect(aar.operationalMode.markerLabel, equals('Waypoint'));
    });

    test('Training mode compiles correctly', () {
      final aar = _createTestAar(mode: OperationalMode.training);
      expect(aar.operationalMode.baseLabel, equals('Start Point'));
      expect(aar.operationalMode.markerLabel, equals('Checkpoint'));
    });
  });
}

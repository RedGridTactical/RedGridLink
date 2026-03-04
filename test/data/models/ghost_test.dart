import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/position.dart';

void main() {
  // Helper to create a test Position
  Position makePosition({
    double lat = 38.9,
    double lon = -77.0,
  }) {
    return Position(
      lat: lat,
      lon: lon,
      altitude: 100.0,
      speed: 0.0,
      heading: 0.0,
      accuracy: 5.0,
      mgrsRaw: '18SUJ1234567890',
      mgrsFormatted: '18S UJ 12345 67890',
      timestamp: DateTime.now(),
    );
  }

  // -----------------------------------------------------------------------
  // GhostState opacity
  // -----------------------------------------------------------------------
  group('Ghost opacity', () {
    test('full state has opacity 1.0', () {
      final ghost = Ghost(
        peerId: 'test-1',
        displayName: 'Alpha',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.full,
      );
      expect(ghost.opacity, equals(1.0));
    });

    test('faded state has opacity 0.5', () {
      final ghost = Ghost(
        peerId: 'test-2',
        displayName: 'Bravo',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.faded,
      );
      expect(ghost.opacity, equals(0.5));
    });

    test('dim state has opacity 0.25', () {
      final ghost = Ghost(
        peerId: 'test-3',
        displayName: 'Charlie',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.dim,
      );
      expect(ghost.opacity, equals(0.25));
    });

    test('outline state has opacity 0.1', () {
      final ghost = Ghost(
        peerId: 'test-4',
        displayName: 'Delta',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.outline,
      );
      expect(ghost.opacity, equals(0.1));
    });

    test('removed state has opacity 0.0', () {
      final ghost = Ghost(
        peerId: 'test-5',
        displayName: 'Echo',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.removed,
      );
      expect(ghost.opacity, equals(0.0));
    });
  });

  // -----------------------------------------------------------------------
  // GhostState.fromString
  // -----------------------------------------------------------------------
  group('GhostState.fromString', () {
    test('parses "full"', () {
      expect(GhostState.fromString('full'), equals(GhostState.full));
    });

    test('parses "faded"', () {
      expect(GhostState.fromString('faded'), equals(GhostState.faded));
    });

    test('parses "dim"', () {
      expect(GhostState.fromString('dim'), equals(GhostState.dim));
    });

    test('parses "outline"', () {
      expect(GhostState.fromString('outline'), equals(GhostState.outline));
    });

    test('parses "removed"', () {
      expect(GhostState.fromString('removed'), equals(GhostState.removed));
    });

    test('unknown string defaults to full', () {
      expect(GhostState.fromString('invalid'), equals(GhostState.full));
    });
  });

  // -----------------------------------------------------------------------
  // estimatedPosition — no velocity
  // -----------------------------------------------------------------------
  group('estimatedPosition without velocity', () {
    test('returns lastPosition when no velocity data', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-no-vel',
        displayName: 'NoVel',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        velocityBearing: null,
        velocitySpeed: null,
      );

      final estimated = ghost.estimatedPosition;
      expect(estimated.lat, equals(pos.lat));
      expect(estimated.lon, equals(pos.lon));
    });

    test('returns lastPosition when velocity speed is 0', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-zero-speed',
        displayName: 'ZeroSpeed',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        velocityBearing: 90.0,
        velocitySpeed: 0.0,
      );

      final estimated = ghost.estimatedPosition;
      expect(estimated.lat, equals(pos.lat));
      expect(estimated.lon, equals(pos.lon));
    });

    test('returns lastPosition when only bearing is provided (no speed)', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-no-speed',
        displayName: 'NoSpeed',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        velocityBearing: 90.0,
        velocitySpeed: null,
      );

      final estimated = ghost.estimatedPosition;
      expect(estimated.lat, equals(pos.lat));
      expect(estimated.lon, equals(pos.lon));
    });
  });

  // -----------------------------------------------------------------------
  // estimatedPosition — with velocity
  // -----------------------------------------------------------------------
  group('estimatedPosition with velocity', () {
    test('projects position northward with bearing 0', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-north',
        displayName: 'North',
        lastPosition: pos,
        // Disconnected 60 seconds ago
        disconnectedAt: DateTime.now().subtract(const Duration(seconds: 60)),
        velocityBearing: 0.0, // due north
        velocitySpeed: 10.0, // 10 m/s
      );

      final estimated = ghost.estimatedPosition;
      // Should have moved northward (higher latitude)
      expect(estimated.lat, greaterThan(pos.lat));
      // Longitude should be approximately the same
      expect(estimated.lon, closeTo(pos.lon, 0.01));
    });

    test('projects position eastward with bearing 90', () {
      final pos = makePosition(lat: 0.0, lon: 0.0);
      final ghost = Ghost(
        peerId: 'test-east',
        displayName: 'East',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(seconds: 60)),
        velocityBearing: 90.0, // due east
        velocitySpeed: 10.0, // 10 m/s
      );

      final estimated = ghost.estimatedPosition;
      // Should have moved eastward (higher longitude)
      expect(estimated.lon, greaterThan(pos.lon));
      // Latitude should be approximately the same
      expect(estimated.lat, closeTo(pos.lat, 0.01));
    });

    test('estimated position differs from last position when moving', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-moving',
        displayName: 'Moving',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        velocityBearing: 45.0,
        velocitySpeed: 5.0,
      );

      final estimated = ghost.estimatedPosition;
      // With 5 m/s for 5 minutes, should have moved significantly
      final distLat = (estimated.lat - pos.lat).abs();
      final distLon = (estimated.lon - pos.lon).abs();
      expect(distLat + distLon, greaterThan(0.001));
    });

    test('preserves altitude from lastPosition', () {
      final pos = makePosition(lat: 38.9, lon: -77.0);
      final ghost = Ghost(
        peerId: 'test-alt',
        displayName: 'Alt',
        lastPosition: pos,
        disconnectedAt: DateTime.now().subtract(const Duration(seconds: 60)),
        velocityBearing: 0.0,
        velocitySpeed: 10.0,
      );

      final estimated = ghost.estimatedPosition;
      expect(estimated.altitude, equals(pos.altitude));
    });
  });

  // -----------------------------------------------------------------------
  // copyWith
  // -----------------------------------------------------------------------
  group('Ghost copyWith', () {
    test('changes ghostState while preserving other fields', () {
      final ghost = Ghost(
        peerId: 'test-copy',
        displayName: 'Copy',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.full,
        velocityBearing: 90.0,
        velocitySpeed: 5.0,
      );

      final updated = ghost.copyWith(ghostState: GhostState.faded);
      expect(updated.ghostState, equals(GhostState.faded));
      expect(updated.peerId, equals(ghost.peerId));
      expect(updated.displayName, equals(ghost.displayName));
      expect(updated.velocityBearing, equals(90.0));
      expect(updated.velocitySpeed, equals(5.0));
    });

    test('changes velocity while preserving other fields', () {
      final ghost = Ghost(
        peerId: 'test-copy2',
        displayName: 'Copy2',
        lastPosition: makePosition(),
        disconnectedAt: DateTime.now(),
        ghostState: GhostState.full,
      );

      final updated = ghost.copyWith(
        velocityBearing: 180.0,
        velocitySpeed: 3.0,
      );
      expect(updated.velocityBearing, equals(180.0));
      expect(updated.velocitySpeed, equals(3.0));
      expect(updated.ghostState, equals(GhostState.full));
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/providers/demo_data_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('demoSessionProvider', () {
    test('emits a fake active session with realistic metadata', () {
      final session = container.read(demoSessionProvider);

      expect(session.id, 'demo-session-0001');
      expect(session.name, 'DEMO PATROL');
      expect(session.isActive, isTrue);
      expect(session.securityMode, SecurityMode.pin);
      expect(session.pin, '0426');
      expect(session.operationalMode, OperationalMode.sar);
      expect(session.peers.length, 4);
      expect(session.peers, contains('demo-alpha'));
      expect(session.peers, contains('demo-bravo'));
      expect(session.peers, contains('demo-charlie'));
    });
  });

  group('demoPeersProvider', () {
    test('emits three connected peers with distinct callsigns + roles', () {
      final peers = container.read(demoPeersProvider);

      expect(peers.length, 3);
      expect(peers.map((p) => p.callsign).toList(), ['ALPHA', 'BRAVO', 'CHARLIE']);
      expect(peers.map((p) => p.role).toList(), [
        TeamRole.scout,
        TeamRole.medic,
        TeamRole.comms,
      ]);

      for (final p in peers) {
        expect(p.isConnected, isTrue);
        expect(p.position, isNotNull);
        expect(p.batteryLevel, isNotNull);
        expect(p.batteryLevel! > 0 && p.batteryLevel! <= 100, isTrue);
      }
    });

    test('peer positions are distinct and near the Washington Monument', () {
      final peers = container.read(demoPeersProvider);

      // Washington Monument reference
      const refLat = 38.8895;
      const refLon = -77.0353;

      final distances = <double>[];
      for (final p in peers) {
        final pos = p.position!;
        // Rough haversine — at 100m scale, simple pythagorean is fine
        final dLat = (pos.lat - refLat) * 111132.0;
        final dLon = (pos.lon - refLon) * 111320.0 * 0.776;
        final d = (dLat * dLat + dLon * dLon);
        distances.add(d);
        // Within 1 km of reference
        expect(d < 1000000, isTrue,
            reason: '${p.callsign} too far from reference');
      }

      // No two peers at identical distance (ensures they're spread out)
      final uniqueDistances = distances.toSet();
      expect(uniqueDistances.length, distances.length);
    });
  });

  group('demoGhostsProvider', () {
    test('emits one faded DELTA ghost disconnected ~8 minutes ago', () {
      final ghosts = container.read(demoGhostsProvider);

      expect(ghosts.length, 1);
      final ghost = ghosts.first;
      expect(ghost.peerId, 'demo-delta');
      expect(ghost.displayName, 'DELTA');
      expect(ghost.ghostState, GhostState.faded);

      final elapsed = DateTime.now().difference(ghost.disconnectedAt);
      expect(elapsed.inMinutes >= 7 && elapsed.inMinutes <= 9, isTrue);
    });
  });

  group('demoMarkersProvider', () {
    test('emits five markers covering every major icon type', () {
      final markers = container.read(demoMarkersProvider);

      expect(markers.length, 5);
      final icons = markers.map((m) => m.icon).toSet();
      expect(icons, contains(MarkerIcon.rallyPoint));
      expect(icons, contains(MarkerIcon.hazard));
      expect(icons, contains(MarkerIcon.objective));
      expect(icons, contains(MarkerIcon.waypoint));
      expect(icons, contains(MarkerIcon.cache));

      // Every marker must have a non-empty label and MGRS string
      for (final m in markers) {
        expect(m.label.isNotEmpty, isTrue);
        expect(m.mgrs.isNotEmpty, isTrue);
        expect(m.origin, MarkerOrigin.manual);
      }
    });

    test('marker IDs are unique', () {
      final markers = container.read(demoMarkersProvider);
      final ids = markers.map((m) => m.id).toSet();
      expect(ids.length, markers.length);
    });
  });

  group('demoAnnotationsProvider', () {
    test('emits a boundary polygon with four points', () {
      final annotations = container.read(demoAnnotationsProvider);

      expect(annotations.length, 1);
      final boundary = annotations.first;
      expect(boundary.type, AnnotationType.boundary);
      expect(boundary.points.length, 4);
      expect(boundary.label, 'AO BOUNDARY');
      expect(boundary.id, 'demo-b1');
    });
  });
}

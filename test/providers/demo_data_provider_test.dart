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
    test('emits a fake active SAR session with realistic metadata', () {
      final session = container.read(demoSessionProvider);

      expect(session.id, 'demo-session-0001');
      expect(session.name, 'RIDGE SWEEP');
      expect(session.isActive, isTrue);
      expect(session.securityMode, SecurityMode.pin);
      expect(session.pin, '7492');
      expect(session.operationalMode, OperationalMode.sar);
      // demo-local + four connected peers
      expect(session.peers.length, 5);
      expect(session.peers, contains('demo-local'));
      expect(session.peers, contains('demo-viper'));
      expect(session.peers, contains('demo-nomad'));
      expect(session.peers, contains('demo-falcon'));
      expect(session.peers, contains('demo-reaper'));
    });
  });

  group('demoPeersProvider', () {
    test('emits four connected peers with distinct callsigns + roles', () {
      final peers = container.read(demoPeersProvider);

      expect(peers.length, 4);
      expect(peers.map((p) => p.callsign).toList(),
          ['VIPER', 'NOMAD', 'FALCON', 'REAPER']);
      expect(peers.map((p) => p.role).toList(), [
        TeamRole.scout,
        TeamRole.medic,
        TeamRole.comms,
        TeamRole.scout,
      ]);

      for (final p in peers) {
        expect(p.isConnected, isTrue);
        expect(p.position, isNotNull);
        expect(p.batteryLevel, isNotNull);
        expect(p.batteryLevel! > 0 && p.batteryLevel! <= 100, isTrue);
      }
    });

    test('peer positions are distinct and near the Shenandoah NP reference',
        () {
      final peers = container.read(demoPeersProvider);

      // Shenandoah National Park demo reference (matches
      // demo_data_provider.dart).
      const refLat = 38.5225;
      const refLon = -78.4352;

      final distances = <double>[];
      for (final p in peers) {
        final pos = p.position!;
        // Rough squared-distance in metres².  Exact math is unnecessary —
        // we only need a sanity bound ("within ~1 km of reference").
        final dLat = (pos.lat - refLat) * 111132.0;
        final dLon = (pos.lon - refLon) * 111320.0 * 0.783; // cos(38.5°)
        final d = (dLat * dLat + dLon * dLon);
        distances.add(d);
        // Within 1 km (1_000_000 m²).
        expect(d < 1000000, isTrue,
            reason: '${p.callsign} too far from reference');
      }

      // No two peers at identical distance (ensures they're spread out).
      final uniqueDistances = distances.toSet();
      expect(uniqueDistances.length, distances.length);
    });
  });

  group('demoGhostsProvider', () {
    test('emits one faded SPECTER ghost disconnected ~12 minutes ago', () {
      final ghosts = container.read(demoGhostsProvider);

      expect(ghosts.length, 1);
      final ghost = ghosts.first;
      expect(ghost.peerId, 'demo-specter');
      expect(ghost.displayName, 'SPECTER');
      expect(ghost.ghostState, GhostState.faded);

      final elapsed = DateTime.now().difference(ghost.disconnectedAt);
      expect(elapsed.inMinutes >= 11 && elapsed.inMinutes <= 13, isTrue);
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

      // Every marker must have a non-empty label and MGRS string.
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
    test('emits a Search Sector Alpha boundary polygon with four points', () {
      final annotations = container.read(demoAnnotationsProvider);

      expect(annotations.length, 1);
      final boundary = annotations.first;
      expect(boundary.type, AnnotationType.boundary);
      expect(boundary.points.length, 4);
      expect(boundary.label, 'SEARCH SECTOR ALPHA');
      expect(boundary.id, 'demo-b1');
    });
  });
}

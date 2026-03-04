import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/services/field_link/ghost/ghost_manager.dart';

void main() {
  late GhostManager manager;

  Position makePosition({
    double lat = 35.0,
    double lon = -79.0,
    double? speed,
    double? heading,
  }) =>
      Position(
        lat: lat,
        lon: lon,
        speed: speed,
        heading: heading,
        mgrsRaw: '17SQV1234567890',
        mgrsFormatted: '',
        timestamp: DateTime.now(),
      );

  Peer makePeer({
    String id = 'peer-1',
    String name = 'Alpha',
    double? speed,
    double? heading,
  }) =>
      Peer(
        id: id,
        displayName: name,
        position: makePosition(speed: speed, heading: heading),
        lastSeen: DateTime.now(),
        isConnected: true,
      );

  setUp(() {
    manager = GhostManager();
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // onPeerDisconnected
  // -------------------------------------------------------------------------
  group('onPeerDisconnected', () {
    test('creates a ghost from a disconnected peer', () {
      final peer = makePeer();
      manager.onPeerDisconnected(peer);

      expect(manager.currentGhosts.length, 1);
      expect(manager.currentGhosts.first.peerId, 'peer-1');
      expect(manager.currentGhosts.first.displayName, 'Alpha');
      expect(manager.currentGhosts.first.ghostState, GhostState.full);
    });

    test('ignores peer without position', () {
      final peer = Peer(
        id: 'no-pos',
        displayName: 'NoPos',
        lastSeen: DateTime.now(),
      );
      manager.onPeerDisconnected(peer);
      expect(manager.currentGhosts, isEmpty);
    });

    test('records velocity if speed above threshold (0.5 m/s)', () {
      final peer = makePeer(speed: 2.0, heading: 90.0);
      manager.onPeerDisconnected(peer);

      final ghost = manager.currentGhosts.first;
      expect(ghost.velocitySpeed, 2.0);
      expect(ghost.velocityBearing, 90.0);
    });

    test('no velocity if speed below threshold', () {
      final peer = makePeer(speed: 0.3, heading: 45.0);
      manager.onPeerDisconnected(peer);

      final ghost = manager.currentGhosts.first;
      expect(ghost.velocitySpeed, isNull);
      expect(ghost.velocityBearing, isNull);
    });

    test('replaces existing ghost for the same peer', () {
      final peer = makePeer(id: 'peer-1');
      manager.onPeerDisconnected(peer);
      manager.onPeerDisconnected(peer);

      expect(manager.currentGhosts.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // onPeerReconnected
  // -------------------------------------------------------------------------
  group('onPeerReconnected', () {
    test('removes ghost on reconnect (snap-to-live)', () {
      final peer = makePeer(id: 'peer-1');
      manager.onPeerDisconnected(peer);
      expect(manager.currentGhosts.length, 1);

      manager.onPeerReconnected('peer-1');
      expect(manager.currentGhosts, isEmpty);
    });

    test('no-op for unknown peer', () {
      manager.onPeerReconnected('nonexistent');
      expect(manager.currentGhosts, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // removeGhost
  // -------------------------------------------------------------------------
  group('removeGhost', () {
    test('manually removes a specific ghost', () {
      final peer1 = makePeer(id: 'peer-1', name: 'Alpha');
      final peer2 = makePeer(id: 'peer-2', name: 'Bravo');
      manager.onPeerDisconnected(peer1);
      manager.onPeerDisconnected(peer2);
      expect(manager.currentGhosts.length, 2);

      manager.removeGhost('peer-1');
      expect(manager.currentGhosts.length, 1);
      expect(manager.currentGhosts.first.peerId, 'peer-2');
    });

    test('no-op for unknown peer', () {
      manager.removeGhost('nonexistent');
      expect(manager.currentGhosts, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // removeAllGhosts
  // -------------------------------------------------------------------------
  group('removeAllGhosts', () {
    test('clears all ghosts', () {
      manager.onPeerDisconnected(makePeer(id: 'a', name: 'A'));
      manager.onPeerDisconnected(makePeer(id: 'b', name: 'B'));
      manager.onPeerDisconnected(makePeer(id: 'c', name: 'C'));
      expect(manager.currentGhosts.length, 3);

      manager.removeAllGhosts();
      expect(manager.currentGhosts, isEmpty);
    });

    test('no-op when already empty', () {
      manager.removeAllGhosts();
      expect(manager.currentGhosts, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // ghostStream
  // -------------------------------------------------------------------------
  group('ghostStream', () {
    test('emits on peer disconnect', () async {
      final peer = makePeer();

      expectLater(
        manager.ghostStream,
        emits(isA<List<Ghost>>().having((l) => l.length, 'length', 1)),
      );

      manager.onPeerDisconnected(peer);
    });

    test('emits on peer reconnect', () async {
      final peer = makePeer(id: 'peer-1');
      manager.onPeerDisconnected(peer);

      expectLater(
        manager.ghostStream,
        emits(isA<List<Ghost>>().having((l) => l.length, 'length', 0)),
      );

      manager.onPeerReconnected('peer-1');
    });
  });

  // -------------------------------------------------------------------------
  // Initial ghost state
  // -------------------------------------------------------------------------
  group('ghost initial state', () {
    test('new ghost starts in full state with opacity 1.0', () {
      manager.onPeerDisconnected(makePeer());
      final ghost = manager.currentGhosts.first;
      expect(ghost.ghostState, GhostState.full);
      expect(ghost.opacity, 1.0);
    });
  });
}

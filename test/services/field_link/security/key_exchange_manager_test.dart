import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/security/key_exchange_manager.dart';

void main() {
  group('KeyExchangeManager', () {
    test('initialize generates a public key', () {
      final manager = KeyExchangeManager();
      manager.initialize();
      expect(manager.localPublicKey, isNotNull);
      expect(manager.localPublicKey!.length, greaterThan(10));
    });

    test('two managers can exchange keys and derive same shared secret', () {
      final managerA = KeyExchangeManager();
      final managerB = KeyExchangeManager();
      managerA.initialize();
      managerB.initialize();

      // A sends public key to B
      final sharedKeyB =
          managerB.handlePeerPublicKey('peerA', managerA.localPublicKey!);
      // B sends public key to A
      final sharedKeyA =
          managerA.handlePeerPublicKey('peerB', managerB.localPublicKey!);

      expect(sharedKeyA, isNotNull);
      expect(sharedKeyB, isNotNull);
      expect(sharedKeyA, sharedKeyB);
    });

    test('hasKeyForPeer returns correct state', () {
      final managerA = KeyExchangeManager();
      final managerB = KeyExchangeManager();
      managerA.initialize();
      managerB.initialize();

      expect(managerA.hasKeyForPeer('peerB'), isFalse);
      managerA.handlePeerPublicKey('peerB', managerB.localPublicKey!);
      expect(managerA.hasKeyForPeer('peerB'), isTrue);
    });

    test('keyForPeer returns derived key', () {
      final managerA = KeyExchangeManager();
      final managerB = KeyExchangeManager();
      managerA.initialize();
      managerB.initialize();

      managerA.handlePeerPublicKey('peerB', managerB.localPublicKey!);
      expect(managerA.keyForPeer('peerB'), isNotNull);
      expect(managerA.keyForPeer('unknown'), isNull);
    });

    test('removePeer clears key', () {
      final managerA = KeyExchangeManager();
      final managerB = KeyExchangeManager();
      managerA.initialize();
      managerB.initialize();

      managerA.handlePeerPublicKey('peerB', managerB.localPublicKey!);
      managerA.removePeer('peerB');
      expect(managerA.hasKeyForPeer('peerB'), isFalse);
    });

    test('reset clears all state', () {
      final manager = KeyExchangeManager();
      manager.initialize();
      expect(manager.localPublicKey, isNotNull);

      manager.reset();
      expect(manager.localPublicKey, isNull);
    });

    test('handlePeerPublicKey returns null for invalid key', () {
      final manager = KeyExchangeManager();
      manager.initialize();
      final result = manager.handlePeerPublicKey('peer', 'invalid-key');
      expect(result, isNull);
    });

    test('peerKeys returns unmodifiable map', () {
      final managerA = KeyExchangeManager();
      final managerB = KeyExchangeManager();
      managerA.initialize();
      managerB.initialize();

      managerA.handlePeerPublicKey('peerB', managerB.localPublicKey!);
      final keys = managerA.peerKeys;
      expect(keys, isA<Map<String, String>>());
      expect(keys.containsKey('peerB'), isTrue);
      expect(() => keys['peerB'] = 'test', throwsUnsupportedError);
    });
  });
}

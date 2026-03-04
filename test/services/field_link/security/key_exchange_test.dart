import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/security/key_exchange.dart';

void main() {
  group('KeyExchange', () {
    test('generateKeyPair returns base64url encoded public key', () {
      final kx = KeyExchange();
      final pubKey = kx.generateKeyPair();
      expect(pubKey, isNotEmpty);
      // Should be valid base64url
      final bytes = base64Url.decode(pubKey);
      // Uncompressed EC point: 0x04 + 32 bytes X + 32 bytes Y = 65 bytes
      expect(bytes.length, equals(65));
      expect(bytes[0], equals(0x04));
    });

    test('two instances derive the same shared key', () {
      final alice = KeyExchange();
      final bob = KeyExchange();

      final alicePub = alice.generateKeyPair();
      final bobPub = bob.generateKeyPair();

      final aliceShared = alice.deriveSharedKey(bobPub);
      final bobShared = bob.deriveSharedKey(alicePub);

      expect(aliceShared, equals(bobShared));
    });

    test('different key pairs produce different public keys', () {
      final kx1 = KeyExchange();
      final kx2 = KeyExchange();
      final pub1 = kx1.generateKeyPair();
      final pub2 = kx2.generateKeyPair();
      expect(pub1, isNot(equals(pub2)));
    });

    test('shared key is 32 bytes (256-bit) base64url encoded', () {
      final alice = KeyExchange();
      final bob = KeyExchange();
      alice.generateKeyPair();
      final bobPub = bob.generateKeyPair();
      final shared = alice.deriveSharedKey(bobPub);
      final sharedBytes = base64Url.decode(shared);
      expect(sharedBytes.length, equals(32));
    });

    test('localPublicKey returns null before generateKeyPair', () {
      final kx = KeyExchange();
      expect(kx.localPublicKey, isNull);
    });

    test('localPublicKey returns value after generateKeyPair', () {
      final kx = KeyExchange();
      final pub = kx.generateKeyPair();
      expect(kx.localPublicKey, equals(pub));
    });

    test('reset clears key pair', () {
      final kx = KeyExchange();
      kx.generateKeyPair();
      expect(kx.localPublicKey, isNotNull);
      kx.reset();
      expect(kx.localPublicKey, isNull);
    });

    test('shared key is deterministic for same key pairs', () {
      final alice = KeyExchange();
      final bob = KeyExchange();
      alice.generateKeyPair();
      final bobPub = bob.generateKeyPair();

      final shared1 = alice.deriveSharedKey(bobPub);
      final shared2 = alice.deriveSharedKey(bobPub);
      expect(shared1, equals(shared2));
    });
  });
}

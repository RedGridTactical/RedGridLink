import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/security/message_encryptor.dart';

void main() {
  group('MessageEncryptor', () {
    late MessageEncryptor encryptor;

    setUp(() {
      encryptor = MessageEncryptor();
    });

    test('encrypt and decrypt round-trip produces original plaintext', () {
      final plaintext = Uint8List.fromList(utf8.encode('Hello, Field Link!'));
      final key = 'test-session-key-12345';
      final encrypted = encryptor.encrypt(plaintext, key);
      final decrypted = encryptor.decrypt(encrypted, key);
      expect(decrypted, equals(plaintext));
    });

    test('encrypted output is larger than plaintext (IV + tag)', () {
      final plaintext = Uint8List.fromList(utf8.encode('test data'));
      final encrypted = encryptor.encrypt(plaintext, 'key123');
      // 12 bytes IV + plaintext + 16 bytes tag
      expect(encrypted.length, equals(plaintext.length + 12 + 16));
    });

    test('different keys produce different ciphertexts', () {
      final plaintext = Uint8List.fromList(utf8.encode('same message'));
      final enc1 = encryptor.encrypt(plaintext, 'key-one');
      final enc2 = encryptor.encrypt(plaintext, 'key-two');
      // Skip IV comparison (first 12 bytes are random), compare rest
      expect(enc1.sublist(12), isNot(equals(enc2.sublist(12))));
    });

    test('wrong key fails to decrypt (throws)', () {
      final plaintext = Uint8List.fromList(utf8.encode('secret'));
      final encrypted = encryptor.encrypt(plaintext, 'correct-key');
      expect(
        () => encryptor.decrypt(encrypted, 'wrong-key'),
        throwsA(isA<Exception>()),
      );
    });

    test('tampered ciphertext throws on decrypt', () {
      final plaintext = Uint8List.fromList(utf8.encode('important'));
      final encrypted = encryptor.encrypt(plaintext, 'my-key');
      // Tamper with a byte in the ciphertext area (after IV)
      encrypted[15] = encrypted[15] ^ 0xFF;
      expect(
        () => encryptor.decrypt(encrypted, 'my-key'),
        throwsA(isA<Exception>()),
      );
    });

    test('disabled mode passes plaintext through unchanged', () {
      encryptor.setEnabled(false);
      final plaintext = Uint8List.fromList(utf8.encode('no encryption'));
      final result = encryptor.encrypt(plaintext, 'any-key');
      expect(result, equals(plaintext));
      final decResult = encryptor.decrypt(result, 'any-key');
      expect(decResult, equals(plaintext));
    });

    test('wire format has correct structure', () {
      final plaintext = Uint8List.fromList(utf8.encode('format test'));
      final encrypted = encryptor.encrypt(plaintext, 'format-key');
      // First 12 bytes = IV
      // Next bytes = ciphertext (same length as plaintext)
      // Last 16 bytes = GCM authentication tag
      expect(encrypted.length, equals(12 + plaintext.length + 16));
    });

    test('encrypt same plaintext twice produces different ciphertexts (random IV)', () {
      final plaintext = Uint8List.fromList(utf8.encode('determinism check'));
      final key = 'same-key';
      final enc1 = encryptor.encrypt(plaintext, key);
      final enc2 = encryptor.encrypt(plaintext, key);
      // IVs should differ (random)
      expect(enc1.sublist(0, 12), isNot(equals(enc2.sublist(0, 12))));
    });

    test('empty plaintext round-trips correctly', () {
      final plaintext = Uint8List(0);
      final key = 'empty-test';
      final encrypted = encryptor.encrypt(plaintext, key);
      expect(encrypted.length, equals(12 + 0 + 16)); // IV + empty + tag
      final decrypted = encryptor.decrypt(encrypted, key);
      expect(decrypted, equals(plaintext));
    });

    test('large payload round-trips correctly', () {
      final plaintext = Uint8List.fromList(List.generate(10000, (i) => i % 256));
      final key = 'large-payload-key';
      final encrypted = encryptor.encrypt(plaintext, key);
      final decrypted = encryptor.decrypt(encrypted, key);
      expect(decrypted, equals(plaintext));
    });
  });
}

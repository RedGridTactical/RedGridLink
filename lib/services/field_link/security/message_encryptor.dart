import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../../core/errors/app_exceptions.dart';

/// AES-256-GCM message encryption / decryption.
///
/// Uses HKDF-SHA256 to derive a 256-bit key from the session key string,
/// a random 96-bit IV (nonce) per message, and a 128-bit GCM authentication
/// tag for integrity.
///
/// Wire format: `[ IV (12 bytes) | ciphertext | GCM tag (16 bytes) ]`
class MessageEncryptor {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Whether encryption is currently enabled.
  ///
  /// Defaults to true for production use. Can be disabled for debugging
  /// transport issues without the added complexity of crypto.
  bool _encryptionEnabled = true;

  /// Whether encryption is active.
  bool get isEnabled => _encryptionEnabled;

  /// Enable or disable encryption at runtime.
  ///
  /// Disabling encryption is useful for debugging transport issues
  /// without the added complexity of crypto.
  void setEnabled(bool enabled) {
    _encryptionEnabled = enabled;
  }

  // ---------------------------------------------------------------------------
  // Encrypt
  // ---------------------------------------------------------------------------

  /// Encrypt [plaintext] using AES-256-GCM with the given [sessionKey].
  ///
  /// Returns the wire-format bytes: `[IV (12) | ciphertext | GCM tag (16)]`.
  /// If encryption is disabled, returns [plaintext] unmodified.
  Uint8List encrypt(Uint8List plaintext, String sessionKey) {
    if (!_encryptionEnabled) {
      return plaintext;
    }

    final keyBytes = _deriveKeyBytes(sessionKey);
    final iv = _generateIv();

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(keyBytes),
          128, // tag length in bits
          iv,
          Uint8List(0), // no AAD
        ),
      );

    // process() allocates the buffer, processes all bytes, calls doFinal,
    // and returns a correctly-sized Uint8List (plaintext.length + 16 tag).
    final ciphertextWithTag = cipher.process(plaintext);

    // Prepend IV: [IV (12 bytes) | ciphertext + GCM tag (16 bytes)]
    final result = Uint8List(iv.length + ciphertextWithTag.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, ciphertextWithTag);

    return result;
  }

  // ---------------------------------------------------------------------------
  // Decrypt
  // ---------------------------------------------------------------------------

  /// Decrypt [ciphertext] using AES-256-GCM with the given [sessionKey].
  ///
  /// Expects wire-format bytes: `[IV (12) | ciphertext | GCM tag (16)]`.
  /// If encryption is disabled, returns [ciphertext] unmodified.
  ///
  /// Throws [SecurityException] if the GCM authentication tag is invalid
  /// (tampered data or wrong key).
  Uint8List decrypt(Uint8List ciphertext, String sessionKey) {
    if (!_encryptionEnabled) {
      return ciphertext;
    }

    if (ciphertext.length < 12 + 16) {
      throw const SecurityException(
        'Ciphertext too short: must contain at least IV (12) + GCM tag (16)',
      );
    }

    // Extract IV (first 12 bytes) and encrypted data (rest)
    final iv = ciphertext.sublist(0, 12);
    final encryptedData = ciphertext.sublist(12);

    final keyBytes = _deriveKeyBytes(sessionKey);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(keyBytes),
          128, // tag length in bits
          iv,
          Uint8List(0), // no AAD
        ),
      );

    try {
      // process() handles buffer allocation, processBytes, doFinal, and
      // returns a correctly-sized Uint8List containing the plaintext.
      // GCM tag verification happens inside doFinal; if the tag is invalid
      // an InvalidCipherTextException is thrown.
      return cipher.process(encryptedData);
    } on InvalidCipherTextException catch (e) {
      throw SecurityException(
        'GCM authentication failed: message tampered or wrong key',
        e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Key derivation
  // ---------------------------------------------------------------------------

  /// Derive a 32-byte (256-bit) AES key from the session key string
  /// using HKDF with SHA-256.
  Uint8List _deriveKeyBytes(String sessionKey) {
    final ikm = Uint8List.fromList(utf8.encode(sessionKey));
    final info = Uint8List.fromList(utf8.encode('red-grid-link-aes'));

    final hkdf = HKDFKeyDerivator(SHA256Digest())
      ..init(HkdfParameters(ikm, 32, null, info));

    final key = Uint8List(32);
    hkdf.deriveKey(null, 0, key, 0);
    return key;
  }

  // ---------------------------------------------------------------------------
  // IV generation
  // ---------------------------------------------------------------------------

  /// Generate a cryptographically random 96-bit (12-byte) IV.
  Uint8List _generateIv() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(12, (_) => rng.nextInt(256)),
    );
  }
}

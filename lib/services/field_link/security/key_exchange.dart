import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// ECDH key exchange for deriving shared session encryption keys.
///
/// Uses the P-256 (secp256r1) curve via pointycastle to perform a real
/// Elliptic-Curve Diffie-Hellman key agreement.  The derived shared secret
/// is run through HKDF-SHA256 to produce a 256-bit symmetric session key.
class KeyExchange {
  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  ECPrivateKey? _privateKey;
  ECPublicKey? _publicKey;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The local public key as a base64url string, or `null` if
  /// [generateKeyPair] has not been called yet.
  String? get localPublicKey {
    if (_publicKey == null) return null;
    return _encodePublicKey(_publicKey!);
  }

  /// Generate an ephemeral EC key pair on the P-256 curve.
  ///
  /// Returns the public key serialised as a base64url-encoded uncompressed
  /// EC point (0x04 || X || Y, 65 bytes).
  String generateKeyPair() {
    final domain = ECCurve_secp256r1();
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
        ECKeyGeneratorParameters(domain),
        _secureRandom(),
      ));

    final pair = keyGen.generateKeyPair();
    _privateKey = pair.privateKey as ECPrivateKey;
    _publicKey = pair.publicKey as ECPublicKey;

    return _encodePublicKey(_publicKey!);
  }

  /// Derive a 256-bit shared symmetric key from the local private key and
  /// the peer's public key (base64url-encoded uncompressed EC point).
  ///
  /// The raw ECDH shared secret is passed through HKDF-SHA256 with the info
  /// string `red-grid-link-session` to produce the final 32-byte key, which
  /// is returned as a base64url string.
  ///
  /// Throws [StateError] if [generateKeyPair] has not been called.
  String deriveSharedKey(String peerPublicKeyBase64) {
    if (_privateKey == null) {
      throw StateError(
        'generateKeyPair() must be called before deriveSharedKey()',
      );
    }

    final domain = ECCurve_secp256r1();

    // Decode peer public key
    final peerBytes = base64Url.decode(peerPublicKeyBase64);
    final peerPoint = domain.curve.decodePoint(peerBytes);
    final peerPublicKey = ECPublicKey(peerPoint, domain);

    // ECDH basic agreement
    final agreement = ECDHBasicAgreement()..init(_privateKey!);
    final sharedSecretBigInt = agreement.calculateAgreement(peerPublicKey);

    // Convert shared secret BigInt to fixed 32 bytes
    final sharedSecretBytes = _bigIntToBytes(sharedSecretBigInt, 32);

    // HKDF-SHA256 to derive final session key
    final sessionKey = _hkdfSha256(
      ikm: sharedSecretBytes,
      info: utf8.encode('red-grid-link-session'),
      length: 32,
    );

    return base64Url.encode(sessionKey);
  }

  /// Perform a full key exchange: generate a local key pair, accept the
  /// peer's public key, and return the derived shared key.
  ///
  /// Returns a record of `(localPublicKey, sharedKey)`.
  ({String localPublicKey, String sharedKey}) exchange(
    String peerPublicKey,
  ) {
    final localPub = generateKeyPair();
    final shared = deriveSharedKey(peerPublicKey);
    return (localPublicKey: localPub, sharedKey: shared);
  }

  /// Clear all key material.
  void reset() {
    _privateKey = null;
    _publicKey = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Encode an [ECPublicKey] as a base64url uncompressed point (65 bytes).
  String _encodePublicKey(ECPublicKey key) {
    final q = key.Q!;
    final xBytes = _bigIntToBytes(q.x!.toBigInteger()!, 32);
    final yBytes = _bigIntToBytes(q.y!.toBigInteger()!, 32);

    final uncompressed = Uint8List(65);
    uncompressed[0] = 0x04;
    uncompressed.setRange(1, 33, xBytes);
    uncompressed.setRange(33, 65, yBytes);

    return base64Url.encode(uncompressed);
  }

  /// Create a [SecureRandom] seeded from [Random.secure].
  SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Convert a non-negative [BigInt] to a fixed-length big-endian [Uint8List].
  Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = Uint8List(length);
    var n = number;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (n & BigInt.from(0xFF)).toInt();
      n = n >> 8;
    }
    return bytes;
  }

  /// HKDF-SHA256 (extract-then-expand) without an explicit salt.
  ///
  /// Derives [length] bytes from input keying material [ikm] and [info].
  Uint8List _hkdfSha256({
    required Uint8List ikm,
    required List<int> info,
    required int length,
  }) {
    final hmac = HMac(SHA256Digest(), 64);

    // Extract: PRK = HMAC-SHA256(salt, IKM)
    // Use a zero-filled salt of hash-length (32 bytes) when no salt given.
    final salt = Uint8List(32);
    hmac.init(KeyParameter(salt));
    final prk = Uint8List(hmac.macSize);
    hmac.update(ikm, 0, ikm.length);
    hmac.doFinal(prk, 0);

    // Expand: OKM = T(1) || T(2) || ...
    final hashLen = hmac.macSize; // 32
    final n = (length + hashLen - 1) ~/ hashLen;
    final okm = Uint8List(n * hashLen);
    var tPrev = Uint8List(0);

    for (var i = 1; i <= n; i++) {
      hmac.init(KeyParameter(prk));
      hmac.update(tPrev, 0, tPrev.length);
      final infoBytes = Uint8List.fromList(info);
      hmac.update(infoBytes, 0, infoBytes.length);
      final counter = Uint8List.fromList([i]);
      hmac.update(counter, 0, 1);

      final t = Uint8List(hashLen);
      hmac.doFinal(t, 0);
      okm.setRange((i - 1) * hashLen, i * hashLen, t);
      tPrev = t;
    }

    return Uint8List.sublistView(okm, 0, length);
  }
}

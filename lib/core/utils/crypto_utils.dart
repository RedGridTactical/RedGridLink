/// Cryptographic utility stubs for Red Grid Link.
///
/// Phase 1: Random key/PIN generation, SHA-256 hashing, UUID device IDs.
/// Phase 3 (TODO): ECDH key exchange, AES-256-GCM encrypt/decrypt via
/// pointycastle.

import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';

// Singleton secure RNG
final Random _secureRandom = Random.secure();

// Singleton UUID generator
const Uuid _uuid = Uuid();

/// Generate a 32-byte random session key, returned as a base64 string.
///
/// Uses [Random.secure] for cryptographic randomness.
String generateSessionKey() {
  final bytes = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
  return base64Url.encode(bytes);
}

/// Generate a random 4-digit PIN string (0000-9999).
String generatePin() {
  final pin = _secureRandom.nextInt(10000);
  return pin.toString().padLeft(4, '0');
}

/// Hash a PIN string using SHA-256.
///
/// Returns the hex-encoded digest. Uses dart:convert for encoding.
///
/// Note: In production, consider salting and using a KDF (e.g. Argon2).
/// For field use with short-lived sessions, SHA-256 is acceptable.
String hashPin(String pin) {
  final bytes = utf8.encode(pin);
  // dart:convert does not include SHA-256 natively; we implement a
  // minimal SHA-256 here using pointycastle-compatible approach.
  // For Phase 1, we use a simple hash via the crypto building blocks
  // available in Dart.
  return _sha256Hex(bytes);
}

/// Generate a unique device identifier (UUID v4).
String generateDeviceId() {
  return _uuid.v4();
}

// ---------------------------------------------------------------------------
// Internal SHA-256 implementation
// ---------------------------------------------------------------------------

/// Minimal SHA-256 producing hex string. Pure Dart, no dependencies.
String _sha256Hex(List<int> data) {
  // Initial hash values (first 32 bits of fractional parts of square roots
  // of the first 8 primes)
  final List<int> h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  // Round constants
  const List<int> k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
  int _ch(int x, int y, int z) => (x & y) ^ (~x & z);
  int _maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
  int _sigma0(int x) => _rotr(x, 2) ^ _rotr(x, 13) ^ _rotr(x, 22);
  int _sigma1(int x) => _rotr(x, 6) ^ _rotr(x, 11) ^ _rotr(x, 25);
  int _gamma0(int x) => _rotr(x, 7) ^ _rotr(x, 18) ^ (x >>> 3);
  int _gamma1(int x) => _rotr(x, 17) ^ _rotr(x, 19) ^ (x >>> 10);

  // Pre-processing: pad message
  final int bitLen = data.length * 8;
  final padded = List<int>.from(data)..add(0x80);
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  // Append original length as 64-bit big-endian
  for (int i = 56; i >= 0; i -= 8) {
    padded.add((bitLen >> i) & 0xFF);
  }

  // Process each 512-bit (64-byte) chunk
  for (int offset = 0; offset < padded.length; offset += 64) {
    final List<int> w = List<int>.filled(64, 0);
    for (int i = 0; i < 16; i++) {
      w[i] = (padded[offset + i * 4] << 24) |
          (padded[offset + i * 4 + 1] << 16) |
          (padded[offset + i * 4 + 2] << 8) |
          padded[offset + i * 4 + 3];
    }
    for (int i = 16; i < 64; i++) {
      w[i] = (_gamma1(w[i - 2]) + w[i - 7] + _gamma0(w[i - 15]) + w[i - 16]) &
          0xFFFFFFFF;
    }

    int a = h[0], b = h[1], c = h[2], d = h[3];
    int e = h[4], f = h[5], g = h[6], hh = h[7];

    for (int i = 0; i < 64; i++) {
      final int t1 =
          (hh + _sigma1(e) + _ch(e, f, g) + k[i] + w[i]) & 0xFFFFFFFF;
      final int t2 = (_sigma0(a) + _maj(a, b, c)) & 0xFFFFFFFF;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xFFFFFFFF;
    }

    h[0] = (h[0] + a) & 0xFFFFFFFF;
    h[1] = (h[1] + b) & 0xFFFFFFFF;
    h[2] = (h[2] + c) & 0xFFFFFFFF;
    h[3] = (h[3] + d) & 0xFFFFFFFF;
    h[4] = (h[4] + e) & 0xFFFFFFFF;
    h[5] = (h[5] + f) & 0xFFFFFFFF;
    h[6] = (h[6] + g) & 0xFFFFFFFF;
    h[7] = (h[7] + hh) & 0xFFFFFFFF;
  }

  return h.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
}

// ---------------------------------------------------------------------------
// Phase 3 TODOs
// ---------------------------------------------------------------------------

// TODO(Phase 3): Implement ECDH key exchange using pointycastle
// - Generate ephemeral EC key pair (P-256 / secp256r1)
// - Derive shared secret from peer's public key
// - Use HKDF to derive symmetric key from shared secret
//
// Future<({Uint8List publicKey, Uint8List privateKey})> generateECKeyPair()
// Future<Uint8List> deriveSharedSecret(Uint8List peerPublicKey, Uint8List privateKey)

// TODO(Phase 3): Implement AES-256-GCM encrypt/decrypt using pointycastle
// - Encrypt arbitrary payload with session key
// - 96-bit random IV per message
// - 128-bit authentication tag
//
// Uint8List aesEncrypt(Uint8List plaintext, Uint8List key)
// Uint8List aesDecrypt(Uint8List ciphertext, Uint8List key)

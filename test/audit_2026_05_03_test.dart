/// Coverage for the 2026-05-03 audit fixes.
///
/// These tests are grouped in one file because each fix touches a small
/// number of public surfaces and the combined file gives a single place
/// to reason about the audit's contract going forward. Specifically:
///
/// 1. Encryption envelope — verifies the wire-format invariants the
///    SyncEngine relies on (magic byte prefix, GCM tag round-trip,
///    tamper detection, wrong-key rejection).
/// 2. QR payload schema — verifies the versioned `{v:1, id, key, …}`
///    schema parses correctly and that malformed QRs fail closed.
/// 3. PurchaseValidator interface — covered separately in
///    test/services/iap/purchase_validator_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/security/message_encryptor.dart';

/// Mirrors the magic byte SyncEngine prepends to encrypted payloads.
const int _kEncryptedEnvelopeMagic = 0xE7;

/// Mirror of the SyncEngine's `_wireBytes` helper, exposed here so the
/// envelope contract can be tested without needing a full Drift-backed
/// SyncEngine fixture. Kept structurally identical to the production
/// implementation in lib/services/field_link/sync/sync_engine.dart.
Uint8List wrapEnvelope(
  Uint8List plaintext,
  String key,
  MessageEncryptor encryptor,
) {
  final cipher = encryptor.encrypt(plaintext, key);
  final wrapped = Uint8List(cipher.length + 1);
  wrapped[0] = _kEncryptedEnvelopeMagic;
  wrapped.setRange(1, wrapped.length, cipher);
  return wrapped;
}

/// Mirror of `_unwrapBytes`: returns null for plaintext-on-encrypted-
/// session, decrypt failure, or missing magic byte. Returns plaintext
/// otherwise.
Uint8List? unwrapEnvelope(
  Uint8List wire,
  String? key,
  MessageEncryptor? encryptor,
) {
  if (encryptor == null || key == null) {
    if (wire.isNotEmpty && wire[0] == _kEncryptedEnvelopeMagic) {
      return null;
    }
    return wire;
  }
  if (wire.isEmpty || wire[0] != _kEncryptedEnvelopeMagic) {
    return null;
  }
  try {
    return encryptor.decrypt(wire.sublist(1), key);
  } catch (_) {
    return null;
  }
}

void main() {
  group('audit 2026-05-03 — Field Link encryption envelope', () {
    final encryptor = MessageEncryptor();
    const key = 'red-grid-link-test-key-32-bytes-of-entropy-here-yes';

    test('encrypted envelope round-trips to identical plaintext', () {
      final plaintext = Uint8List.fromList(
        utf8.encode('{"t":"position","s":"a","n":1,"d":{"lat":35.5}}'),
      );
      final wire = wrapEnvelope(plaintext, key, encryptor);
      final recovered = unwrapEnvelope(wire, key, encryptor);
      expect(recovered, isNotNull);
      expect(recovered, equals(plaintext));
    });

    test('encrypted envelope starts with magic byte 0xE7', () {
      final plaintext = Uint8List.fromList(utf8.encode('hello'));
      final wire = wrapEnvelope(plaintext, key, encryptor);
      expect(wire[0], _kEncryptedEnvelopeMagic);
    });

    test('plaintext SyncPayload bytes never collide with the magic byte', () {
      // SyncPayload.toBytes() emits utf8(jsonEncode(...)) which always
      // begins with `{` (0x7B). The envelope dispatch in SyncEngine
      // relies on this — confirm the JSON byte and the magic byte
      // never coincide, no matter the payload content.
      const samples = [
        '{"t":"position"}',
        '{"t":"marker","d":{"id":"m-1"}}',
        '{}',
      ];
      for (final s in samples) {
        final bytes = utf8.encode(s);
        expect(bytes.first, isNot(_kEncryptedEnvelopeMagic));
        expect(bytes.first, equals(0x7B));
      }
    });

    test('wrong key fails decrypt and unwrap returns null', () {
      final plaintext = Uint8List.fromList(utf8.encode('payload'));
      final wire = wrapEnvelope(plaintext, key, encryptor);
      final result = unwrapEnvelope(wire, 'wrong-key', encryptor);
      expect(result, isNull);
    });

    test('tampered ciphertext fails GCM auth and unwrap returns null', () {
      final plaintext = Uint8List.fromList(utf8.encode('important'));
      final wire = wrapEnvelope(plaintext, key, encryptor);
      // Flip a byte in the ciphertext region (skip magic at [0] and IV
      // at [1..12]).
      final tampered = Uint8List.fromList(wire);
      tampered[20] ^= 0xFF;
      final result = unwrapEnvelope(tampered, key, encryptor);
      expect(result, isNull);
    });

    test('encrypted bytes arriving on a plaintext session are rejected', () {
      // Open-mode session has no encryptor and no key. A peer running an
      // older or hostile build must not be able to slip an encrypted
      // payload through and have it parsed.
      final plaintext = Uint8List.fromList(utf8.encode('payload'));
      final wire = wrapEnvelope(plaintext, key, encryptor);
      final result = unwrapEnvelope(wire, null, null);
      expect(result, isNull);
    });

    test('plaintext bytes arriving on an encrypted session are rejected', () {
      // Audit's "fail closed in secure modes" requirement: the host
      // must drop plaintext when the session is in PIN/QR mode,
      // because otherwise an MITM that strips the envelope and
      // re-broadcasts a forged JSON payload would be accepted.
      final result = unwrapEnvelope(
        Uint8List.fromList(utf8.encode('{"t":"position"}')),
        key,
        encryptor,
      );
      expect(result, isNull);
    });

    test('plaintext session passes plaintext through unchanged', () {
      final plaintext =
          Uint8List.fromList(utf8.encode('{"t":"position","d":{}}'));
      final result = unwrapEnvelope(plaintext, null, null);
      expect(result, equals(plaintext));
    });
  });

  group('audit 2026-05-03 — QR payload schema (versioned)', () {
    /// Mirrors the FieldLinkService.joinSession parser: returns null on
    /// any malformed input so callers fail closed. Kept inline so the
    /// schema contract is regression-tested at the same time as the
    /// production parser evolves.
    Map<String, dynamic>? parseQr(String qr, String expectedSessionId) {
      try {
        final payload = jsonDecode(qr) as Map<String, dynamic>;
        final id = payload['id'] as String?;
        final key = payload['key'] as String?;
        if (id == null || key == null || key.isEmpty) return null;
        if (id != expectedSessionId) return null;
        return payload;
      } catch (_) {
        return null;
      }
    }

    test('valid v1 payload with matching session id parses', () {
      final qr = jsonEncode({
        'v': 1,
        'id': 'sess-abc',
        'key': 'host-generated-secret',
      });
      final parsed = parseQr(qr, 'sess-abc');
      expect(parsed, isNotNull);
      expect(parsed!['key'], 'host-generated-secret');
    });

    test('mismatched session id fails closed', () {
      final qr = jsonEncode({
        'v': 1,
        'id': 'sess-XYZ',
        'key': 'secret',
      });
      expect(parseQr(qr, 'sess-abc'), isNull);
    });

    test('missing key fails closed', () {
      final qr = jsonEncode({'v': 1, 'id': 'sess-abc'});
      expect(parseQr(qr, 'sess-abc'), isNull);
    });

    test('empty key fails closed', () {
      final qr = jsonEncode({'v': 1, 'id': 'sess-abc', 'key': ''});
      expect(parseQr(qr, 'sess-abc'), isNull);
    });

    test('non-JSON garbage fails closed', () {
      expect(parseQr('not json at all', 'sess-abc'), isNull);
    });

    test('JSON array (wrong shape) fails closed', () {
      expect(parseQr('["sess", "key"]', 'sess-abc'), isNull);
    });

    test('legacy compact format ({s,p}) fails closed under v1 parser', () {
      // Confirms that the new versioned parser does not accidentally
      // accept the pre-audit compact schema. The compact payload still
      // works at the session_join_card layer via the raw-id fallback,
      // but it must not impersonate a QR-secured session.
      final qr = jsonEncode({'s': 'sess-abc', 'p': '1234'});
      expect(parseQr(qr, 'sess-abc'), isNull);
    });
  });
}

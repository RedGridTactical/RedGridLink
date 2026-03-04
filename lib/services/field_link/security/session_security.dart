import 'dart:convert';

import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/core/errors/app_exceptions.dart';
import 'package:red_grid_link/core/utils/crypto_utils.dart' as crypto;

/// Security tier for a Field Link session.
enum SecurityTier {
  /// No authentication.  Devices auto-join when discovered.
  open,

  /// 4-digit PIN required to join.
  pin,

  /// QR code containing an encoded session key + session ID.
  qr,
}

/// Tiered authentication service for Field Link sessions.
///
/// Supports three security tiers:
///   - [SecurityTier.open]: No authentication, auto-join.
///   - [SecurityTier.pin]: A 4-digit PIN that must match.
///   - [SecurityTier.qr]: A QR payload encoding the session ID and a
///     randomly-generated session key.
///
/// The session host selects the tier when creating a session.  Joining
/// devices provide credentials (PIN or QR scan) which are verified
/// locally before the transport connection is accepted.
class SessionSecurity {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// The active security tier for the current session.
  SecurityTier _tier = SecurityTier.open;

  /// The session PIN (only relevant when [_tier] == [SecurityTier.pin]).
  String? _sessionPin;

  /// The session key (used for QR tier and later for encryption).
  String? _sessionKey;

  /// The session ID associated with the current security context.
  String? _sessionId;

  // ---------------------------------------------------------------------------
  // Public accessors
  // ---------------------------------------------------------------------------

  /// The current security tier.
  SecurityTier get currentTier => _tier;

  /// The current session PIN, or null if not using PIN tier.
  String? get sessionPin => _sessionPin;

  /// The current session key, or null if not yet generated.
  String? get sessionKey => _sessionKey;

  /// The current session ID.
  String? get sessionId => _sessionId;

  // ---------------------------------------------------------------------------
  // Session setup
  // ---------------------------------------------------------------------------

  /// Configure the security tier for a new session.
  ///
  /// Generates a PIN (for [SecurityTier.pin]) and a session key
  /// (for [SecurityTier.qr] and general encryption) automatically.
  void configureSession({
    required String sessionId,
    required SecurityTier tier,
    String? pin,
  }) {
    _sessionId = sessionId;
    _tier = tier;

    switch (tier) {
      case SecurityTier.open:
        _sessionPin = null;
        _sessionKey = crypto.generateSessionKey();
      case SecurityTier.pin:
        _sessionPin = pin ?? crypto.generatePin();
        if (_sessionPin!.length != SyncConstants.sessionPinLength) {
          throw const SecurityException(
            'PIN must be exactly ${SyncConstants.sessionPinLength} digits',
          );
        }
        _sessionKey = crypto.generateSessionKey();
      case SecurityTier.qr:
        _sessionPin = null;
        _sessionKey = crypto.generateSessionKey();
    }
  }

  /// Clear the current security context (e.g., when leaving a session).
  void clear() {
    _tier = SecurityTier.open;
    _sessionPin = null;
    _sessionKey = null;
    _sessionId = null;
  }

  // ---------------------------------------------------------------------------
  // Authentication — Open
  // ---------------------------------------------------------------------------

  /// Authenticate for an open session (always succeeds).
  Future<bool> authenticateOpen() => Future.value(true);

  // ---------------------------------------------------------------------------
  // Authentication — PIN
  // ---------------------------------------------------------------------------

  /// Verify that [inputPin] matches the session's [sessionPin].
  ///
  /// Comparison is done on the SHA-256 hashes to avoid timing attacks
  /// on the raw PIN string.
  Future<bool> authenticatePin(String inputPin, String sessionPin) async {
    if (inputPin.length != SyncConstants.sessionPinLength) return false;
    if (sessionPin.length != SyncConstants.sessionPinLength) return false;

    final inputHash = crypto.hashPin(inputPin);
    final sessionHash = crypto.hashPin(sessionPin);

    return _constantTimeEquals(inputHash, sessionHash);
  }

  // ---------------------------------------------------------------------------
  // Authentication — QR
  // ---------------------------------------------------------------------------

  /// Generate a QR payload string for the current session.
  ///
  /// Format: base64url( JSON { "sid": sessionId, "key": sessionKey } )
  ///
  /// This payload is displayed as a QR code by the session host.
  /// Joining devices scan it and call [authenticateQr] with the result.
  String generateQrPayload(String sessionId, String sessionKey) {
    final json = jsonEncode({
      'sid': sessionId,
      'key': sessionKey,
    });
    return base64Url.encode(utf8.encode(json));
  }

  /// Parse a QR payload back into its session ID and session key.
  ///
  /// Returns null if the payload is malformed.
  ({String sessionId, String sessionKey})? parseQrPayload(String qrData) {
    try {
      final decoded = utf8.decode(base64Url.decode(qrData));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final sid = json['sid'] as String?;
      final key = json['key'] as String?;
      if (sid == null || key == null) return null;
      return (sessionId: sid, sessionKey: key);
    } catch (_) {
      return null;
    }
  }

  /// Authenticate using a scanned QR payload.
  ///
  /// Returns true if the QR data is valid and its session ID matches
  /// [expectedSessionId].
  Future<bool> authenticateQr(
    String qrData,
    String expectedSessionId,
  ) async {
    final parsed = parseQrPayload(qrData);
    if (parsed == null) return false;

    if (parsed.sessionId != expectedSessionId) return false;

    // Store the session key from the QR code for subsequent encryption.
    _sessionKey = parsed.sessionKey;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Constant-time string comparison to prevent timing side-channel
  /// attacks on PIN hash comparison.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';

/// Compact QR code widget for session sharing.
///
/// Encodes the session credentials needed for a joiner to authenticate.
/// QR payload schema (must stay in sync with [FieldLinkService.joinSession]):
///
/// ```json
/// {
///   "v": 1,            // schema version
///   "id": "<sessionId>",
///   "key": "<sessionKey>",   // host-generated session secret (QR-only)
///   "pin": "<pin>"           // optional, for PIN sessions
/// }
/// ```
///
/// The `id` and `key` fields drive QR-secured authentication on the host
/// side. Without `key`, the joiner can connect but cannot prove it scanned
/// the actual QR (audit 2026-05-03 P1).
class SessionQrCode extends StatelessWidget {
  const SessionQrCode({
    super.key,
    required this.sessionId,
    this.sessionKey,
    this.pin,
    this.colors,
  });

  /// The session identifier to encode.
  final String sessionId;

  /// Host-generated session secret. Required for QR-secured sessions —
  /// the host validates the joiner's submitted key against this value
  /// in [FieldLinkService] join_request handling. Optional so that PIN
  /// or Open sessions can render a QR without leaking a key they don't
  /// rely on.
  final String? sessionKey;

  /// Optional PIN for PIN-secured sessions.
  final String? pin;

  /// Theme colors. When null, uses default dark styling.
  final TacticalColorScheme? colors;

  /// Build the QR payload.
  ///
  /// Versioned (`v`) so future schema changes can be detected on the
  /// joiner side without falling back to ambiguous parses.
  String _qrPayload() {
    final map = <String, dynamic>{
      'v': 1,
      'id': sessionId,
    };
    if (sessionKey != null && sessionKey!.isNotEmpty) {
      map['key'] = sessionKey;
    }
    if (pin != null && pin!.isNotEmpty) {
      map['pin'] = pin;
    }
    return jsonEncode(map);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR code with white background
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: _qrPayload(),
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF111111),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF111111),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Label
        Text(
          'Scan to Join',
          style: colors != null
              ? TacticalTextStyles.caption(colors!).copyWith(
                  color: colors!.text2,
                )
              : const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
        ),
      ],
    );
  }
}

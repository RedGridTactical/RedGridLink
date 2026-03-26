import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';

/// Compact QR code widget for session sharing.
///
/// Encodes [sessionId] and optional [pin] as a compact JSON payload
/// (`{"s":"<sessionId>","p":"<pin>"}`) and renders a 200x200 QR code
/// with a "Scan to Join" label below.
class SessionQrCode extends StatelessWidget {
  const SessionQrCode({
    super.key,
    required this.sessionId,
    this.pin,
    this.colors,
  });

  /// The session identifier to encode.
  final String sessionId;

  /// Optional PIN for PIN-secured sessions.
  final String? pin;

  /// Theme colors. When null, uses default dark styling.
  final TacticalColorScheme? colors;

  /// Build the compact QR payload.
  String _qrPayload() {
    final map = <String, dynamic>{'s': sessionId};
    if (pin != null && pin!.isNotEmpty) {
      map['p'] = pin;
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

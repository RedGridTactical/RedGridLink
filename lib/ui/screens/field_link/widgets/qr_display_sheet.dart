import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/session.dart';

/// QR code display bottom sheet for session sharing.
///
/// Shows a large QR code with the session payload, session name and PIN
/// below, "Scan this to join" instruction, and share button.
class QrDisplaySheet extends StatelessWidget {
  const QrDisplaySheet({
    super.key,
    required this.session,
    required this.colors,
  });

  final Session session;
  final TacticalColorScheme colors;

  /// Build the QR payload containing session join information.
  String _qrPayload() {
    return jsonEncode({
      'id': session.id,
      'name': session.name,
      'sec': session.securityMode.name,
      'pin': session.pin,
      'mode': session.operationalMode.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'SCAN TO JOIN',
            style: TacticalTextStyles.heading(colors),
          ),
          const SizedBox(height: 8),
          Text(
            'Have teammates scan this QR code to join your session',
            style: TacticalTextStyles.caption(colors),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _qrPayload(),
              version: QrVersions.auto,
              size: 220,
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
          const SizedBox(height: 20),

          // Session name
          Text(
            session.name.toUpperCase(),
            style: TacticalTextStyles.subheading(colors).copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),

          // PIN if applicable
          if (session.securityMode == SecurityMode.pin &&
              session.pin != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pin, size: 16, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'PIN: ${session.pin!.split('').join(' ')}',
                    style: TacticalTextStyles.value(colors).copyWith(
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Share button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: colors.accent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _share(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: AppConstants.minTouchTarget,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'SHARE SESSION DETAILS',
                        style: TacticalTextStyles.buttonText(colors).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Close button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: colors.card,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  tapLight();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: AppConstants.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'CLOSE',
                    style: TacticalTextStyles.buttonText(colors),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    tapMedium();
    final details = StringBuffer()
      ..writeln('Red Grid Link Session: ${session.name}')
      ..writeln('Session ID: ${session.id}');
    if (session.securityMode == SecurityMode.pin && session.pin != null) {
      details.writeln('PIN: ${session.pin}');
    }
    details.writeln('Mode: ${session.operationalMode.label}');

    Clipboard.setData(ClipboardData(text: details.toString()));
    notifySuccess();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SESSION DETAILS COPIED',
            style: TacticalTextStyles.caption(colors).copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

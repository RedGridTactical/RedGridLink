import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';

/// QR code scanner bottom sheet.
///
/// Uses [mobile_scanner] for camera preview with an overlay scan frame.
/// Auto-detects and parses the QR payload (JSON with session id, name,
/// security mode, pin, operational mode). Returns the parsed session ID
/// via [Navigator.pop] on successful scan.
class QrScanSheet extends StatefulWidget {
  const QrScanSheet({
    super.key,
    required this.colors,
  });

  final TacticalColorScheme colors;

  @override
  State<QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<QrScanSheet> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // Try to parse as Red Grid Link session payload.
    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;

      // Validate required fields.
      if (data.containsKey('id') || data.containsKey('name')) {
        _hasScanned = true;
        notifySuccess();

        // Return the raw QR data for the join flow to process.
        Navigator.of(context).pop(rawValue);
        return;
      }
    } catch (_) {
      // Not valid JSON -- might be a plain session ID.
    }

    // If it looks like a UUID, treat it as a session ID.
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidPattern.hasMatch(rawValue)) {
      _hasScanned = true;
      notifySuccess();
      Navigator.of(context).pop(rawValue);
      return;
    }

    // Unrecognized QR code.
    setState(() {
      _error = 'Unrecognized QR code. Please scan a Red Grid Link session code.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Handle bar + title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                const SizedBox(height: 16),
                Text(
                  'SCAN QR CODE',
                  style: TacticalTextStyles.heading(colors),
                ),
                const SizedBox(height: 4),
                Text(
                  'Point camera at a session QR code',
                  style: TacticalTextStyles.caption(colors),
                ),
              ],
            ),
          ),

          // Camera preview with overlay
          Expanded(
            child: Stack(
              children: [
                // Camera
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),

                // Scan frame overlay
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Corner accents
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _CornerPainter(color: colors.accent),
                    ),
                  ),
                ),

                // Error message
                if (_error != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC0000).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Manual entry fallback + close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        tapLight();
                        Navigator.of(context).pop(null);
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
                          'CANCEL',
                          style: TacticalTextStyles.buttonText(colors),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Paints corner accents on the scan frame.
class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double cornerLen = 30;

    // Top-left
    canvas.drawLine(Offset.zero, const Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, cornerLen), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLen, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLen),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLen),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      color != oldDelegate.color;
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Full-screen QR code scanner for joining Field Link sessions.
///
/// Uses the device camera via [MobileScanner] to detect QR codes containing
/// session join data. On successful scan, pops the screen and returns the
/// parsed data as a `Map<String, dynamic>` with keys `s` (sessionId) and
/// optionally `p` (pin).
///
/// Handles invalid QR codes gracefully by showing a brief error message and
/// continuing to scan.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    this.colors,
  });

  /// Optional theme colors for overlay styling.
  final TacticalColorScheme? colors;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
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

    // Try to parse as Red Grid Link compact payload: {"s":"...","p":"..."}
    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;

      if (data.containsKey('s')) {
        _hasScanned = true;
        notifySuccess();
        Navigator.of(context).pop(<String, dynamic>{
          's': data['s'] as String,
          if (data.containsKey('p') && data['p'] != null)
            'p': data['p'] as String,
        });
        return;
      }

      // Also accept the full payload format from QrDisplaySheet.
      if (data.containsKey('id')) {
        _hasScanned = true;
        notifySuccess();
        Navigator.of(context).pop(<String, dynamic>{
          's': data['id'] as String,
          if (data.containsKey('pin') && data['pin'] != null)
            'p': data['pin'] as String,
        });
        return;
      }
    } catch (_) {
      // Not valid JSON.
    }

    // If it looks like a UUID, treat as a session ID with no PIN.
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidPattern.hasMatch(rawValue)) {
      _hasScanned = true;
      notifySuccess();
      Navigator.of(context).pop(<String, dynamic>{'s': rawValue});
      return;
    }

    // Unrecognized QR code -- show error and continue scanning.
    setState(() {
      _error = 'Not a Red Grid Link QR code';
    });

    // Clear error after 2 seconds.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _error = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Semi-transparent overlay with viewfinder cutout
          _ScanOverlay(accentColor: colors?.accent ?? const Color(0xFFCC0000)),

          // Top bar with close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Close button
                  Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        tapLight();
                        Navigator.of(context).pop(null);
                      },
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Title text
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'SCAN SESSION QR',
                  style: colors != null
                      ? TacticalTextStyles.heading(colors).copyWith(
                          color: Colors.white,
                        )
                      : const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),

          // Instruction text below viewfinder
          Align(
            alignment: const Alignment(0, 0.45),
            child: Text(
              'Point camera at a session QR code',
              style: colors != null
                  ? TacticalTextStyles.caption(colors).copyWith(
                      color: Colors.white70,
                    )
                  : const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
            ),
          ),

          // Error message
          if (_error != null)
            Align(
              alignment: const Alignment(0, 0.6),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
    );
  }
}

/// Paints a semi-transparent overlay with a clear viewfinder rectangle
/// and corner accent marks.
class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double frameSize = 260;
        final double left = (constraints.maxWidth - frameSize) / 2;
        final double top = (constraints.maxHeight - frameSize) / 2 - 40;

        return Stack(
          children: [
            // Dark overlay with cutout
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  // Full screen dark layer
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  // Clear cutout
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: frameSize,
                      height: frameSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any opaque color works for cutout
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder border
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
            ),

            // Corner accents
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                child: CustomPaint(
                  painter: _CornerAccentPainter(color: accentColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints corner accent marks on the viewfinder.
class _CornerAccentPainter extends CustomPainter {
  _CornerAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double len = 30;

    // Top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerAccentPainter oldDelegate) =>
      color != oldDelegate.color;
}

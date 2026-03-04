import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// Magnetic declination helper.
///
/// Shows current declination, converts between magnetic and true bearings.
class DeclinationTool extends ConsumerStatefulWidget {
  const DeclinationTool({super.key});

  @override
  ConsumerState<DeclinationTool> createState() => _DeclinationToolState();
}

class _DeclinationToolState extends ConsumerState<DeclinationTool> {
  final _magController = TextEditingController();
  final _trueController = TextEditingController();

  double? _computedTrue;
  double? _computedMag;

  @override
  void dispose() {
    _magController.dispose();
    _trueController.dispose();
    super.dispose();
  }

  void _convertMagToTrue(double declination) {
    tapMedium();
    final mag = double.tryParse(_magController.text);
    if (mag == null || mag < 0 || mag > 360) {
      setState(() => _computedTrue = null);
      return;
    }
    setState(() {
      _computedTrue = applyDeclination(mag, declination);
    });
    notifySuccess();
  }

  void _convertTrueToMag(double declination) {
    tapMedium();
    final trueBearing = double.tryParse(_trueController.text);
    if (trueBearing == null || trueBearing < 0 || trueBearing > 360) {
      setState(() => _computedMag = null);
      return;
    }
    setState(() {
      _computedMag = removeDeclination(trueBearing, declination);
    });
    notifySuccess();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final declination = ref.watch(declinationProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title:
            Text('DECLINATION', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current declination display
            TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('CURRENT DECLINATION',
                      style: TacticalTextStyles.label(colors)),
                  const SizedBox(height: 8),
                  Text(
                    '${declination >= 0 ? "+" : ""}${declination.toStringAsFixed(1)}\u00B0 ${declination >= 0 ? "EAST" : "WEST"}',
                    style: TacticalTextStyles.bearingDisplay(colors),
                  ),
                  const SizedBox(height: 16),
                  // Visual declination diagram
                  _DeclinationDiagram(
                    declination: declination,
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Magnetic to True
            SectionHeader(
                title: 'Magnetic \u2192 True', colors: colors),
            const SizedBox(height: 8),
            _BearingInputRow(
              controller: _magController,
              label: 'MAGNETIC BEARING',
              resultLabel: 'TRUE BEARING',
              result: _computedTrue,
              colors: colors,
              onCalculate: () => _convertMagToTrue(declination),
            ),

            const SizedBox(height: 20),

            // True to Magnetic
            SectionHeader(
                title: 'True \u2192 Magnetic', colors: colors),
            const SizedBox(height: 8),
            _BearingInputRow(
              controller: _trueController,
              label: 'TRUE BEARING',
              resultLabel: 'MAGNETIC BEARING',
              result: _computedMag,
              colors: colors,
              onCalculate: () => _convertTrueToMag(declination),
            ),

            const SizedBox(height: 20),

            TacticalButton(
              label: 'Update Declination in Settings',
              icon: Icons.settings,
              colors: colors,
              onPressed: () {
                tapMedium();
                // Pop back -- user can navigate to settings from nav bar
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Declination diagram
// ---------------------------------------------------------------------------

class _DeclinationDiagram extends StatelessWidget {
  const _DeclinationDiagram({
    required this.declination,
    required this.colors,
  });

  final double declination;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: CustomPaint(
        painter: _DeclinationPainter(
          declination: declination,
          gridNorthColor: colors.accent,
          magNorthColor: colors.text2,
          textColor: colors.text3,
        ),
      ),
    );
  }
}

class _DeclinationPainter extends CustomPainter {
  final double declination;
  final Color gridNorthColor;
  final Color magNorthColor;
  final Color textColor;

  _DeclinationPainter({
    required this.declination,
    required this.gridNorthColor,
    required this.magNorthColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw circle
    final circlePaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, circlePaint);

    // Grid North line (straight up)
    final gnPaint = Paint()
      ..color = gridNorthColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius),
      gnPaint,
    );

    // Magnetic North line (rotated by declination)
    final mnPaint = Paint()
      ..color = magNorthColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mnAngle = -math.pi / 2 + (declination * math.pi / 180);
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(mnAngle),
        center.dy + radius * math.sin(mnAngle),
      ),
      mnPaint,
    );

    // Labels
    final gnTextPainter = TextPainter(
      text: TextSpan(
        text: 'GN',
        style: TextStyle(color: gridNorthColor, fontSize: 10,
            fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gnTextPainter.paint(canvas, Offset(center.dx + 4, center.dy - radius - 14));

    final mnTextPainter = TextPainter(
      text: TextSpan(
        text: 'MN',
        style: TextStyle(color: magNorthColor, fontSize: 10,
            fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final mnLabelAngle = -math.pi / 2 + (declination * math.pi / 180);
    mnTextPainter.paint(
      canvas,
      Offset(
        center.dx + (radius + 4) * math.cos(mnLabelAngle) - 6,
        center.dy + (radius + 4) * math.sin(mnLabelAngle) - 14,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DeclinationPainter oldDelegate) {
    return oldDelegate.declination != declination;
  }
}

// ---------------------------------------------------------------------------
// Bearing input row
// ---------------------------------------------------------------------------

class _BearingInputRow extends StatelessWidget {
  const _BearingInputRow({
    required this.controller,
    required this.label,
    required this.resultLabel,
    required this.result,
    required this.colors,
    required this.onCalculate,
  });

  final TextEditingController controller;
  final String label;
  final String resultLabel;
  final double? result;
  final TacticalColorScheme colors;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TacticalTextStyles.label(colors)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TacticalTextStyles.value(colors),
                    decoration: InputDecoration(
                      hintText: '0 - 360',
                      hintStyle: TacticalTextStyles.dim(colors),
                      filled: true,
                      fillColor: colors.card2,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            BorderSide(color: colors.accent, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: TacticalButton(
                  label: '\u2192',
                  colors: colors,
                  isCompact: true,
                  onPressed: onCalculate,
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Text(resultLabel, style: TacticalTextStyles.label(colors)),
            const SizedBox(height: 4),
            Text(
              '${result!.toStringAsFixed(1)}\u00B0',
              style: TacticalTextStyles.value(colors),
            ),
          ],
        ],
      ),
    );
  }
}

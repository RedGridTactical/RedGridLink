import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Slope Calculator: computes slope percentage and angle from
/// horizontal distance and elevation change.
///
/// Includes a visual slope angle indicator.
class SlopeCalculatorTool extends StatefulWidget {
  const SlopeCalculatorTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  State<SlopeCalculatorTool> createState() => _SlopeCalculatorToolState();
}

class _SlopeCalculatorToolState extends State<SlopeCalculatorTool> {
  final _horizontalController = TextEditingController();
  final _elevationController = TextEditingController();

  double? _slopePercent;
  double? _slopeAngleDeg;
  String? _error;

  TacticalColorScheme get colors => widget.colors;

  @override
  void dispose() {
    _horizontalController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  void _calculate() {
    tapMedium();
    final hDist = double.tryParse(_horizontalController.text);
    final elev = double.tryParse(_elevationController.text);

    if (hDist == null || hDist <= 0) {
      setState(() {
        _error = 'Enter a valid horizontal distance';
        _slopePercent = null;
        _slopeAngleDeg = null;
      });
      return;
    }
    if (elev == null) {
      setState(() {
        _error = 'Enter a valid elevation change';
        _slopePercent = null;
        _slopeAngleDeg = null;
      });
      return;
    }

    final pct = slopePercent(
      horizontalDist: hDist,
      elevationChange: elev,
    );
    final angle = slopeAngle(
      horizontalDist: hDist,
      elevationChange: elev,
    );

    setState(() {
      _slopePercent = pct;
      _slopeAngleDeg = angle;
      _error = null;
    });
    if (pct != null) notifySuccess();
  }

  String _slopeCategory() {
    if (_slopeAngleDeg == null) return '';
    final deg = _slopeAngleDeg!;
    if (deg < 5) return 'Flat / Easy';
    if (deg < 15) return 'Moderate';
    if (deg < 30) return 'Steep';
    if (deg < 45) return 'Very Steep';
    return 'Extreme / Cliff';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('SLOPE CALCULATOR',
            style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Input', colors: colors),
            const SizedBox(height: 8),

            // Horizontal distance
            _buildField(
              controller: _horizontalController,
              label: 'HORIZONTAL DISTANCE (meters)',
              hint: 'e.g., 100',
            ),
            const SizedBox(height: 12),

            // Elevation change
            _buildField(
              controller: _elevationController,
              label: 'ELEVATION CHANGE (meters)',
              hint: 'e.g., 25 (negative = downhill)',
              allowNegative: true,
            ),
            const SizedBox(height: 16),

            // Calculate button
            TacticalButton(
              label: 'Calculate Slope',
              icon: Icons.trending_up,
              colors: colors,
              onPressed: _calculate,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TacticalTextStyles.body(colors).copyWith(
                  color: const Color(0xFFCC0000),
                ),
              ),
            ],

            if (_slopePercent != null && _slopeAngleDeg != null) ...[
              const SizedBox(height: 20),

              // Visual slope indicator
              _SlopeIndicator(
                angleDeg: _slopeAngleDeg!,
                colors: colors,
              ),

              const SizedBox(height: 20),

              // Results
              Row(
                children: [
                  Expanded(
                    child: TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                '${_slopePercent!.toStringAsFixed(1)}%'));
                        notifySuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('SLOPE % COPIED',
                                style: TacticalTextStyles.caption(colors)
                                    .copyWith(color: Colors.white)),
                            backgroundColor: colors.accent,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text('SLOPE %',
                              style: TacticalTextStyles.label(colors)),
                          const SizedBox(height: 4),
                          Text(
                            '${_slopePercent!.toStringAsFixed(1)}%',
                            style:
                                TacticalTextStyles.bearingDisplay(colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                '${_slopeAngleDeg!.toStringAsFixed(1)}\u00B0'));
                        notifySuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ANGLE COPIED',
                                style: TacticalTextStyles.caption(colors)
                                    .copyWith(color: Colors.white)),
                            backgroundColor: colors.accent,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text('ANGLE',
                              style: TacticalTextStyles.label(colors)),
                          const SizedBox(height: 4),
                          Text(
                            '${_slopeAngleDeg!.toStringAsFixed(1)}\u00B0',
                            style:
                                TacticalTextStyles.bearingDisplay(colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Slope category
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _slopeAngleDeg! < 15
                          ? Icons.landscape
                          : _slopeAngleDeg! < 30
                              ? Icons.trending_up
                              : Icons.terrain,
                      color: colors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TERRAIN',
                            style: TacticalTextStyles.label(colors)),
                        Text(_slopeCategory(),
                            style: TacticalTextStyles.value(colors)),
                      ],
                    ),
                  ],
                ),
              ),

              // Direction indicator
              if (double.tryParse(_elevationController.text) != null) ...[
                const SizedBox(height: 8),
                TacticalCard(
                  colors: colors,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        double.parse(_elevationController.text) >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: colors.text2,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        double.parse(_elevationController.text) >= 0
                            ? 'UPHILL'
                            : 'DOWNHILL',
                        style: TacticalTextStyles.value(colors),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool allowNegative = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
                decimal: true, signed: allowNegative),
            style: TacticalTextStyles.value(colors),
            onSubmitted: (_) => _calculate(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TacticalTextStyles.dim(colors),
              filled: true,
              fillColor: colors.card2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Visual slope angle indicator
// ---------------------------------------------------------------------------

class _SlopeIndicator extends StatelessWidget {
  const _SlopeIndicator({
    required this.angleDeg,
    required this.colors,
  });

  final double angleDeg;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 120,
        width: 200,
        child: CustomPaint(
          painter: _SlopePainter(
            angleDeg: angleDeg,
            accentColor: colors.accent,
            lineColor: colors.text3,
          ),
        ),
      ),
    );
  }
}

class _SlopePainter extends CustomPainter {
  final double angleDeg;
  final Color accentColor;
  final Color lineColor;

  _SlopePainter({
    required this.angleDeg,
    required this.accentColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Baseline (horizontal)
    paint.color = lineColor.withValues(alpha: 0.4);
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 20, size.height - 20),
      paint,
    );

    // Slope line (clamped to reasonable visual angle)
    final clampedAngle = angleDeg.clamp(0.0, 80.0);
    final angleRad = clampedAngle * math.pi / 180;
    final lineLength = size.width - 40;
    final endX = 20 + lineLength * math.cos(angleRad);
    final endY = (size.height - 20) - lineLength * math.sin(angleRad);

    paint.color = accentColor;
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(endX, endY),
      paint,
    );

    // Arc showing angle
    final arcRect = Rect.fromCircle(
      center: Offset(20, size.height - 20),
      radius: 30,
    );
    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      arcRect,
      -angleRad, // start at slope line
      angleRad, // sweep to horizontal
      false,
      arcPaint,
    );

    // Origin dot
    canvas.drawCircle(
      Offset(20, size.height - 20),
      4,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SlopePainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg;
  }
}

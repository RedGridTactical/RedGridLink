import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// Back azimuth calculator with visual compass.
///
/// Input: bearing (degrees). Shows back azimuth via [backAzimuth].
class BackAzimuthTool extends StatefulWidget {
  const BackAzimuthTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  State<BackAzimuthTool> createState() => _BackAzimuthToolState();
}

class _BackAzimuthToolState extends State<BackAzimuthTool> {
  final _bearingController = TextEditingController();
  double? _forwardBearing;
  double? _backBearing;

  TacticalColorScheme get colors => widget.colors;

  @override
  void dispose() {
    _bearingController.dispose();
    super.dispose();
  }

  void _calculate() {
    tapMedium();
    final bearing = double.tryParse(_bearingController.text);
    if (bearing == null || bearing < 0 || bearing > 360) {
      setState(() {
        _forwardBearing = null;
        _backBearing = null;
      });
      return;
    }
    setState(() {
      _forwardBearing = bearing;
      _backBearing = backAzimuth(bearing);
    });
    notifySuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title:
            Text('BACK AZIMUTH', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Input', colors: colors),
            const SizedBox(height: 8),

            // Bearing input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FORWARD BEARING (degrees)',
                    style: TacticalTextStyles.label(colors)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: _bearingController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          style: TacticalTextStyles.value(colors),
                          onSubmitted: (_) => _calculate(),
                          decoration: InputDecoration(
                            hintText: '0 - 360',
                            hintStyle: TacticalTextStyles.dim(colors),
                            filled: true,
                            fillColor: colors.card2,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: colors.accent, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: TacticalButton(
                        label: 'Calc',
                        colors: colors,
                        isCompact: true,
                        onPressed: _calculate,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (_forwardBearing != null && _backBearing != null) ...[
              const SizedBox(height: 24),

              // Visual compass
              _CompassDiagram(
                forward: _forwardBearing!,
                back: _backBearing!,
                colors: colors,
              ),

              const SizedBox(height: 24),

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
                                _forwardBearing!.toStringAsFixed(0)));
                        notifySuccess();
                      },
                      child: Column(
                        children: [
                          Text('FORWARD',
                              style: TacticalTextStyles.label(colors)),
                          const SizedBox(height: 4),
                          Text(
                            '${_forwardBearing!.toStringAsFixed(0)}\u00B0',
                            style:
                                TacticalTextStyles.bearingDisplay(colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.swap_horiz,
                        color: colors.text3, size: 24),
                  ),
                  Expanded(
                    child: TacticalCard(
                      colors: colors,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text: _backBearing!.toStringAsFixed(0)));
                        notifySuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('BACK AZIMUTH COPIED',
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
                          Text('BACK',
                              style: TacticalTextStyles.label(colors)),
                          const SizedBox(height: 4),
                          Text(
                            '${_backBearing!.toStringAsFixed(0)}\u00B0',
                            style:
                                TacticalTextStyles.bearingDisplay(colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compass diagram showing forward and back bearings
// ---------------------------------------------------------------------------

class _CompassDiagram extends StatelessWidget {
  const _CompassDiagram({
    required this.forward,
    required this.back,
    required this.colors,
  });

  final double forward;
  final double back;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 180,
        width: 180,
        child: CustomPaint(
          painter: _CompassPainter(
            forward: forward,
            back: back,
            accentColor: colors.accent,
            textColor: colors.text3,
            backColor: colors.text2,
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double forward;
  final double back;
  final Color accentColor;
  final Color textColor;
  final Color backColor;

  _CompassPainter({
    required this.forward,
    required this.back,
    required this.accentColor,
    required this.textColor,
    required this.backColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Draw circle
    final circlePaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, circlePaint);

    // Cardinal labels
    const cardinals = ['N', 'E', 'S', 'W'];
    const cardinalAngles = [0.0, 90.0, 180.0, 270.0];
    for (int i = 0; i < 4; i++) {
      final angle = (cardinalAngles[i] - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + (radius + 10) * math.cos(angle) - tp.width / 2,
          center.dy + (radius + 10) * math.sin(angle) - tp.height / 2,
        ),
      );
    }

    // Forward bearing line
    final fwdAngle = (forward - 90) * math.pi / 180;
    final fwdPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(fwdAngle),
        center.dy + radius * math.sin(fwdAngle),
      ),
      fwdPaint,
    );

    // Back bearing line (dashed effect via shorter line)
    final backAngle = (back - 90) * math.pi / 180;
    final backPaint = Paint()
      ..color = backColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(backAngle),
        center.dy + radius * math.sin(backAngle),
      ),
      backPaint,
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.forward != forward || oldDelegate.back != back;
  }
}

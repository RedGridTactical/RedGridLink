import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';

/// Rotating arrow indicator for bearing / heading display.
///
/// Uses [AnimatedRotation] so changes in [bearingDegrees] animate smoothly
/// rather than snapping.
class BearingArrow extends StatelessWidget {
  const BearingArrow({
    super.key,
    required this.bearingDegrees,
    this.size = 48,
    this.color,
    required this.colors,
  });

  final double bearingDegrees;
  final double size;
  final Color? color;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // AnimatedRotation expects turns (0..1), not degrees.
    final double turns = bearingDegrees / 360.0;

    return AnimatedRotation(
      turns: turns,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Icon(
        Icons.navigation,
        size: size,
        color: color ?? colors.accent,
      ),
    );
  }
}

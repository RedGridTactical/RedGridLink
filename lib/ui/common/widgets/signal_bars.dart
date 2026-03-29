import 'package:flutter/material.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';

/// Displays 1-4 signal strength bars colored by tier.
class SignalBars extends StatelessWidget {
  const SignalBars({
    super.key,
    required this.bars,
    required this.tier,
    this.size = 16,
  });

  final int bars;
  final SignalTier tier;
  final double size;

  Color get _color {
    switch (tier) {
      case SignalTier.excellent:
        return Colors.green;
      case SignalTier.good:
        return Colors.lightGreen;
      case SignalTier.fair:
        return Colors.orange;
      case SignalTier.weak:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final height = size * (0.4 + 0.2 * i);
        final isActive = i < bars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: size * 0.2,
            height: height,
            decoration: BoxDecoration(
              color: isActive ? _color : _color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

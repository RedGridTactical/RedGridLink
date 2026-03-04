import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';

/// Battery level display with colour-coded icon and optional projected time.
///
/// Colour logic:
///  - green  when level > 50 %
///  - yellow when level 20 % .. 50 %
///  - red    when level < 20 %
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.batteryLevel,
    this.projectedTime,
    this.isCompact = false,
    required this.colors,
  });

  final int? batteryLevel;
  final String? projectedTime;
  final bool isCompact;
  final TacticalColorScheme colors;

  Color _levelColor() {
    final int level = batteryLevel ?? 0;
    if (level > 50) return const Color(0xFF00CC00);
    if (level >= 20) return const Color(0xFFCCCC00);
    return const Color(0xFFCC0000);
  }

  IconData _icon() {
    final int level = batteryLevel ?? 0;
    if (level > 87) return Icons.battery_full;
    if (level > 62) return Icons.battery_5_bar;
    if (level > 37) return Icons.battery_3_bar;
    if (level > 12) return Icons.battery_2_bar;
    if (level > 0) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _levelColor();
    final String label = batteryLevel != null ? '$batteryLevel%' : '--';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(), color: color, size: isCompact ? 18 : 22),
        const SizedBox(width: 4),
        Text(
          label,
          style: (isCompact
                  ? TacticalTextStyles.caption(colors)
                  : TacticalTextStyles.body(colors))
              .copyWith(color: color),
        ),
        if (projectedTime != null && !isCompact) ...[
          const SizedBox(width: 6),
          Text(
            projectedTime!,
            style: TacticalTextStyles.caption(colors),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';

/// Horizontal row of selectable chips for MGRS precision level (1-5).
///
/// Each chip shows: level + label (e.g., "5 -- 1m").
/// Uses [precisionLabels] from tactical.dart.
class PrecisionSelector extends StatelessWidget {
  const PrecisionSelector({
    super.key,
    required this.currentPrecision,
    required this.onChanged,
    required this.colors,
  });

  final int currentPrecision;
  final ValueChanged<int> onChanged;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final int level = index + 1;
        final bool selected = level == currentPrecision;
        final String label = precisionLabels[level] ?? '';
        // Extract just the resolution portion (e.g., "10km", "1m")
        final String shortLabel = label.split(' ').first;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              selectionTick();
              onChanged(level);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: selected ? colors.accent : colors.card2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? colors.accent : colors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$level',
                    style: TacticalTextStyles.value(colors).copyWith(
                      fontSize: 16,
                      color: selected ? Colors.white : colors.text,
                    ),
                  ),
                  Text(
                    shortLabel,
                    style: TacticalTextStyles.caption(colors).copyWith(
                      fontSize: 10,
                      color: selected ? Colors.white70 : colors.text3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

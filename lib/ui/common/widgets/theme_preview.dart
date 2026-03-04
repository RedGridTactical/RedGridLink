import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Compact preview card for a tactical colour theme.
///
/// Shows a swatch of the theme's background, text, and accent colours
/// along with the theme label. Displays a "PRO" badge when
/// [TacticalColorScheme.pro] is `true`, and a checkmark when [isSelected].
class ThemePreview extends StatelessWidget {
  const ThemePreview({
    super.key,
    required this.previewColors,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
  });

  /// The colour scheme being previewed.
  final TacticalColorScheme previewColors;

  /// Whether this theme is the currently active one.
  final bool isSelected;

  /// Called when the user taps the preview card.
  final VoidCallback onTap;

  /// The app-level colours (used for the card border / container styling).
  final TacticalColorScheme appColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        tapMedium();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? appColors.accent : appColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colour swatches row.
            Row(
              children: [
                _Swatch(color: previewColors.bg),
                const SizedBox(width: 4),
                _Swatch(color: previewColors.text),
                const SizedBox(width: 4),
                _Swatch(color: previewColors.accent),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, size: 20, color: appColors.accent),
              ],
            ),
            const SizedBox(height: 8),
            // Label row with optional PRO badge.
            Row(
              children: [
                Expanded(
                  child: Text(
                    previewColors.label,
                    style: TacticalTextStyles.caption(appColors),
                  ),
                ),
                if (previewColors.pro)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: appColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PRO',
                      style: TacticalTextStyles.dim(appColors).copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Primary action button with tactical styling.
///
/// All instances honour [AppConstants.minTouchTarget] (44 px) so they remain
/// easy to press while wearing gloves.
///
/// [isCompact] shrinks horizontal padding for use in toolbars while keeping
/// the same minimum height.
///
/// [isDestructive] switches the background to a warning/red colour.
class TacticalButton extends StatelessWidget {
  const TacticalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isCompact = false,
    this.isDestructive = false,
    required this.colors,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isCompact;
  final bool isDestructive;
  final TacticalColorScheme colors;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDestructive
        ? const Color(0xFFCC0000)
        : colors.accent;

    // Determine foreground colour that contrasts with the accent background.
    // For the white / light theme the accent is red, so white text works.
    // For dark themes the accent is the highlight colour — white also works.
    const Color fgColor = Colors.white;

    return Opacity(
      opacity: _enabled ? 1.0 : 0.30,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _enabled
              ? () {
                  tapMedium();
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: AppConstants.minTouchTarget,
              minWidth: isCompact ? 0 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 24,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize:
                    isCompact ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fgColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: TacticalTextStyles.buttonText(colors).copyWith(
                      color: fgColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

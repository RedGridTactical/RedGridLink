import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/utils/haptics.dart';

/// Standard card container for the tactical UI.
///
/// Provides a themed surface with border, rounded corners, and optional
/// tap handling with haptic feedback.
class TacticalCard extends StatelessWidget {
  const TacticalCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    required this.colors,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets effectivePadding =
        padding ?? const EdgeInsets.all(12);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap != null
            ? () {
                tapLight();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

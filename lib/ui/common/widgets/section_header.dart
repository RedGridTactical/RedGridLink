import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';

/// Section header used in list screens and settings pages.
///
/// Renders an uppercase monospace title with an optional [trailing] widget
/// (e.g. a toggle or info icon) and a divider underneath.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    required this.colors,
  });

  final String title;
  final Widget? trailing;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TacticalTextStyles.label(colors),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Divider(color: colors.border2, height: 1, thickness: 1),
      ],
    );
  }
}

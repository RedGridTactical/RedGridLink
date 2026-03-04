import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Displays a formatted MGRS grid reference with copy-to-clipboard support.
///
/// [isLarge] toggles between the hero-sized display (28 px) and the compact
/// version (16 px) used in cards and list rows.
class MgrsDisplay extends StatelessWidget {
  const MgrsDisplay({
    super.key,
    required this.mgrs,
    this.isLarge = true,
    this.onTap,
    required this.colors,
  });

  final String mgrs;
  final bool isLarge;
  final VoidCallback? onTap;
  final TacticalColorScheme colors;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: mgrs));
    notifySuccess();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'MGRS COPIED',
            style: TacticalTextStyles.caption(colors).copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = isLarge
        ? TacticalTextStyles.mgrsDisplay(colors)
        : TacticalTextStyles.mgrsSmall(colors);

    return GestureDetector(
      onTap: onTap ?? () => _copyToClipboard(context),
      child: Text(mgrs, style: style),
    );
  }
}

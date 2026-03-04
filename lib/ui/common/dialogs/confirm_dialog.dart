import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Standard confirmation dialog styled with tactical theme colours.
///
/// Returns `true` when the user confirms, `false` on cancel, or `null`
/// when dismissed by tapping outside.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.colors,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title.toUpperCase(),
        style: TacticalTextStyles.heading(colors),
      ),
      content: Text(
        message,
        style: TacticalTextStyles.body(colors),
      ),
      actions: [
        // Cancel button.
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppConstants.minTouchTarget),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel.toUpperCase(),
            style: TacticalTextStyles.buttonText(colors).copyWith(
              color: colors.text3,
            ),
          ),
        ),
        // Confirm button.
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppConstants.minTouchTarget),
          ),
          onPressed: () {
            tapMedium();
            Navigator.of(context).pop(true);
          },
          child: Text(
            confirmLabel.toUpperCase(),
            style: TacticalTextStyles.buttonText(colors).copyWith(
              color: isDestructive
                  ? const Color(0xFFCC0000)
                  : colors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience helper that shows a [ConfirmDialog] and returns a non-null
/// boolean (`true` = confirmed, `false` = cancelled or dismissed).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  required TacticalColorScheme colors,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      colors: colors,
    ),
  );
  return result ?? false;
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Dialog with a single text field.
///
/// Returns the entered [String] on confirm, or `null` on cancel / dismiss.
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.initialValue,
    this.hintText,
    this.maxLength = 64,
    required this.colors,
  });

  final String title;
  final String? initialValue;
  final String? hintText;
  final int maxLength;
  final TacticalColorScheme colors;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    tapMedium();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        widget.title.toUpperCase(),
        style: TacticalTextStyles.heading(colors),
      ),
      content: TextField(
        controller: _controller,
        maxLength: widget.maxLength,
        autofocus: true,
        style: TacticalTextStyles.body(colors),
        cursorColor: colors.accent,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TacticalTextStyles.dim(colors),
          filled: true,
          fillColor: colors.card2,
          counterStyle: TacticalTextStyles.dim(colors),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.accent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppConstants.minTouchTarget),
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'CANCEL',
            style: TacticalTextStyles.buttonText(colors).copyWith(
              color: colors.text3,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppConstants.minTouchTarget),
          ),
          onPressed: _submit,
          child: Text(
            'CONFIRM',
            style: TacticalTextStyles.buttonText(colors).copyWith(
              color: colors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience helper that shows a [TextInputDialog] and returns the entered
/// string, or `null` if cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hintText,
  int maxLength = 64,
  required TacticalColorScheme colors,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => TextInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      maxLength: maxLength,
      colors: colors,
    ),
  );
}

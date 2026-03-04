import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Four-digit PIN entry dialog for Field Link sessions.
///
/// Each digit is displayed in its own box. Focus auto-advances as the user
/// types. Returns the 4-digit [String] on completion, or `null` when
/// cancelled / dismissed.
class PinEntryDialog extends StatefulWidget {
  const PinEntryDialog({
    super.key,
    this.title = 'Enter Session PIN',
    required this.colors,
  });

  final String title;
  final TacticalColorScheme colors;

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  static const int _pinLength = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(_pinLength, (_) => TextEditingController());
    _focusNodes = List.generate(_pinLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      selectionTick();
      if (index < _pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All digits entered — submit.
        _submit();
      }
    }
  }

  void _submit() {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length == _pinLength) {
      tapMedium();
      Navigator.of(context).pop(pin);
    }
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
        textAlign: TextAlign.center,
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (i) {
          return Container(
            width: 52,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              autofocus: i == 0,
              style: TacticalTextStyles.value(colors).copyWith(fontSize: 24),
              cursorColor: colors.accent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: colors.card2,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.accent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => _onDigitChanged(i, v),
            ),
          );
        }),
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

/// Convenience helper that shows a [PinEntryDialog] and returns the entered
/// 4-digit PIN string, or `null` if cancelled.
Future<String?> showPinEntryDialog(
  BuildContext context, {
  String? title,
  required TacticalColorScheme colors,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => PinEntryDialog(
      title: title ?? 'Enter Session PIN',
      colors: colors,
    ),
  );
}

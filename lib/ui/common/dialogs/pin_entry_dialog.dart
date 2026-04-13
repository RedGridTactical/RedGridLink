import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';

/// Four-digit PIN entry dialog for Field Link sessions.
///
/// Uses a single hidden TextField to avoid keyboard flicker from multiple
/// focus nodes. The 4 digit boxes are purely visual — all keyboard input
/// goes to the hidden field.
class PinEntryDialog extends StatefulWidget {
  const PinEntryDialog({
    super.key,
    this.title = 'Enter Session PIN',
    required this.colors,
    this.allowEmpty = false,
  });

  final String title;
  final TacticalColorScheme colors;

  /// When true, shows a "SKIP" button that returns an empty string instead
  /// of null. Used when joining via scan where the session may be open.
  final bool allowEmpty;

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  static const int _pinLength = 4;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.length <= _pinLength) {
      setState(() => _currentPin = text);
      if (text.length > 0) selectionTick();
      if (text.length == _pinLength) {
        // Auto-submit after short delay so user sees the last digit fill.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _currentPin.length == _pinLength) {
            _submit();
          }
        });
      }
    } else {
      // Truncate to max length
      _controller.text = text.substring(0, _pinLength);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _pinLength),
      );
    }
  }

  void _submit() {
    if (_currentPin.length == _pinLength) {
      tapMedium();
      Navigator.of(context).pop(_currentPin);
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
      content: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visual digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final hasDigit = i < _currentPin.length;
                final isActive = i == _currentPin.length;
                return Container(
                  width: 52,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colors.card2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? colors.accent : colors.border,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      hasDigit ? _currentPin[i] : '',
                      style: TacticalTextStyles.value(colors)
                          .copyWith(fontSize: 24),
                    ),
                  ),
                );
              }),
            ),

            // Hidden text field that captures keyboard input
            SizedBox(
              height: 1,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: _pinLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
          ],
        ),
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
        if (widget.allowEmpty)
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppConstants.minTouchTarget),
            ),
            onPressed: () {
              tapMedium();
              Navigator.of(context).pop('');
            },
            child: Text(
              'SKIP (OPEN)',
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
  bool allowEmpty = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => PinEntryDialog(
      title: title ?? 'Enter Session PIN',
      colors: colors,
      allowEmpty: allowEmpty,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/models/tactical_message.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';

/// Compact message input bar for sending tactical messages during a session.
///
/// Displays a horizontally scrollable row of pre-canned message buttons.
/// The last button opens a text field for custom messages (160 char limit).
class MessageBar extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const MessageBar({super.key, required this.colors});

  @override
  ConsumerState<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends ConsumerState<MessageBar> {
  bool _showCustomInput = false;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  static const int _maxCustomLength = 160;

  /// Pre-canned message types (all except custom).
  static const _preCanned = [
    TacticalMessageType.help,
    TacticalMessageType.stop,
    TacticalMessageType.rallyOnMe,
    TacticalMessageType.allClear,
    TacticalMessageType.foundSomething,
    TacticalMessageType.headingBack,
    TacticalMessageType.needSupplies,
  ];

  /// Material Icons for each message type.
  static const _icons = <TacticalMessageType, IconData>{
    TacticalMessageType.help: Icons.warning_amber_rounded,
    TacticalMessageType.stop: Icons.pan_tool_rounded,
    TacticalMessageType.rallyOnMe: Icons.location_on_rounded,
    TacticalMessageType.allClear: Icons.check_circle_outline_rounded,
    TacticalMessageType.foundSomething: Icons.search_rounded,
    TacticalMessageType.headingBack: Icons.turn_left_rounded,
    TacticalMessageType.needSupplies: Icons.inventory_2_rounded,
  };

  TacticalColorScheme get colors => widget.colors;

  void _send(TacticalMessageType type, {String? customText}) {
    final service = ref.read(fieldLinkServiceProvider);
    service.sendTacticalMessage(type, customText: customText);
  }

  void _sendCustom() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _send(TacticalMessageType.custom, customText: text);
    _textController.clear();
    setState(() => _showCustomInput = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomInput) {
      return _buildCustomInput();
    }
    return _buildButtonRow();
  }

  Widget _buildButtonRow() {
    return Container(
      height: 48,
      color: colors.card.withValues(alpha: 0.9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ..._preCanned.map(_buildButton),
            const SizedBox(width: 4),
            _buildCustomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(TacticalMessageType type) {
    final isHelp = type == TacticalMessageType.help;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Material(
        color: isHelp ? Colors.red.shade900 : colors.card2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _send(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[type] ?? Icons.message_rounded,
                  size: 16,
                  color: isHelp ? Colors.white : colors.text2,
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isHelp ? Colors.white : colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Material(
        color: colors.card2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _showCustomInput = true);
            // Request focus after frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNode.requestFocus();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 16, color: colors.text2),
                const SizedBox(width: 6),
                Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Container(
      height: 48,
      color: colors.card.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, size: 20, color: colors.text2),
            onPressed: () {
              _textController.clear();
              setState(() => _showCustomInput = false);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLength: _maxCustomLength,
              maxLines: 1,
              style: TextStyle(fontSize: 13, color: colors.text),
              decoration: InputDecoration(
                hintText: 'Type message...',
                hintStyle: TextStyle(fontSize: 13, color: colors.text3),
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: colors.card2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendCustom(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.send_rounded, size: 20, color: colors.accent),
            onPressed: _sendCustom,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

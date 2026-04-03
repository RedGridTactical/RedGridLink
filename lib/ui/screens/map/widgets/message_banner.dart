import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/models/tactical_message.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';

/// Notification banner that slides in from the top when a tactical message
/// is received from a peer.
///
/// Shows sender callsign + message type label. For custom messages, shows
/// the text. Auto-dismisses after 5 seconds; tapping dismisses immediately.
class MessageBanner extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const MessageBanner({super.key, required this.colors});

  @override
  ConsumerState<MessageBanner> createState() => _MessageBannerState();
}

class _MessageBannerState extends ConsumerState<MessageBanner>
    with SingleTickerProviderStateMixin {
  TacticalMessage? _currentMessage;
  Timer? _dismissTimer;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  StreamSubscription<TacticalMessage>? _messageSub;

  TacticalColorScheme get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Subscribe to message stream after first frame so ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToMessages();
    });
  }

  void _subscribeToMessages() {
    final service = ref.read(fieldLinkServiceProvider);
    _messageSub = service.messageService.onMessage.listen(_showMessage);
  }

  void _showMessage(TacticalMessage message) {
    _dismissTimer?.cancel();
    setState(() => _currentMessage = message);
    _slideController.forward(from: 0);
    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _messageSub?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMessage == null) return const SizedBox.shrink();

    final msg = _currentMessage!;
    final isHelp = msg.type == TacticalMessageType.help;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: _dismiss,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isHelp
                  ? Colors.red.shade900.withValues(alpha: 0.95)
                  : colors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHelp ? Colors.red : colors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconForType(msg.type),
                  size: 20,
                  color: isHelp ? Colors.white : colors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${msg.senderCallsign}: ${msg.type.label}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isHelp ? Colors.white : colors.text,
                        ),
                      ),
                      if (msg.type == TacticalMessageType.custom &&
                          msg.customText != null &&
                          msg.customText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            msg.customText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isHelp ? Colors.white70 : colors.text2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(TacticalMessageType type) {
    switch (type) {
      case TacticalMessageType.help:
        return Icons.warning_amber_rounded;
      case TacticalMessageType.stop:
        return Icons.pan_tool_rounded;
      case TacticalMessageType.rallyOnMe:
        return Icons.location_on_rounded;
      case TacticalMessageType.allClear:
        return Icons.check_circle_outline_rounded;
      case TacticalMessageType.foundSomething:
        return Icons.search_rounded;
      case TacticalMessageType.headingBack:
        return Icons.turn_left_rounded;
      case TacticalMessageType.needSupplies:
        return Icons.inventory_2_rounded;
      case TacticalMessageType.custom:
        return Icons.message_rounded;
    }
  }
}

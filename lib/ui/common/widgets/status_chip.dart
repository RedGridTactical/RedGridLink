import 'package:flutter/material.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';

/// Small pill-shaped status indicator.
///
/// Displays a coloured dot next to a label text. When [isPulsing] is `true`
/// the dot animates with a fade-in / fade-out loop to indicate a live state
/// such as "Connected" or "Syncing".
class StatusChip extends StatefulWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.isPulsing = false,
    required this.colors,
  });

  final String label;
  final Color color;
  final bool isPulsing;
  final TacticalColorScheme colors;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isPulsing
                    ? widget.color.withValues(
                        alpha: _opacity.value,
                      )
                    : widget.color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: TacticalTextStyles.caption(widget.colors),
          ),
        ],
      ),
    );
  }
}

/// Helper that wraps [AnimatedBuilder] around a [Listenable].
///
/// Flutter ships [AnimatedBuilder] which accepts any [Listenable] (including
/// [Animation<double>]). We use it directly above but provide this typedef
/// for clarity in case the project grows.

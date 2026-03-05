import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/ghost.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/dialogs/confirm_dialog.dart';
import '../../../common/widgets/mgrs_display.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_card.dart';

/// Ghost (disconnected peer) list widget.
///
/// Each ghost shows: name, last position MGRS, disconnected time ago,
/// opacity indicator, velocity arrow if moving. Long-press to remove.
/// "Clear All Ghosts" option when ghosts exist.
class GhostList extends ConsumerWidget {
  const GhostList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final ghostsAsync = ref.watch(ghostsProvider);

    return ghostsAsync.when(
      data: (ghosts) {
        if (ghosts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Ghosts',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ghosts.length}',
                    style: TacticalTextStyles.caption(colors).copyWith(
                      color: colors.text3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear all button
                  GestureDetector(
                    onTap: () => _clearAllGhosts(context, ref, colors),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: AppConstants.minTouchTarget,
                        minHeight: 32,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_all,
                            size: 16,
                            color: colors.text3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CLEAR',
                            style: TacticalTextStyles.label(colors),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              colors: colors,
            ),
            const SizedBox(height: 6),
            ...ghosts.map((ghost) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _GhostTile(
                    ghost: ghost,
                    colors: colors,
                    onRemove: () => _removeGhost(ref, ghost.peerId),
                  ),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _removeGhost(WidgetRef ref, String peerId) {
    tapMedium();
    ref.read(fieldLinkServiceProvider).removeGhost(peerId);
  }

  Future<void> _clearAllGhosts(
    BuildContext context,
    WidgetRef ref,
    TacticalColorScheme colors,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear All Ghosts',
      message: 'Remove all ghost markers from the map?',
      confirmLabel: 'Clear',
      isDestructive: true,
      colors: colors,
    );

    if (confirmed) {
      tapHeavy();
      ref.read(fieldLinkServiceProvider).removeAllGhosts();
    }
  }
}

/// Individual ghost tile.
class _GhostTile extends StatelessWidget {
  const _GhostTile({
    required this.ghost,
    required this.colors,
    required this.onRemove,
  });

  final Ghost ghost;
  final TacticalColorScheme colors;
  final VoidCallback onRemove;

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }

  String _ghostStateLabel() {
    switch (ghost.ghostState) {
      case GhostState.full:
        return 'Recent';
      case GhostState.faded:
        return 'Fading';
      case GhostState.dim:
        return 'Dim';
      case GhostState.outline:
        return 'Outline';
      case GhostState.removed:
        return 'Removed';
    }
  }

  Color _ghostStateColor() {
    switch (ghost.ghostState) {
      case GhostState.full:
        return const Color(0xFFCCCC00);
      case GhostState.faded:
        return const Color(0xFFCC8800);
      case GhostState.dim:
        return const Color(0xFFCC4400);
      case GhostState.outline:
        return const Color(0xFF880000);
      case GhostState.removed:
        return const Color(0xFF440000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ghost.opacity.clamp(0.3, 1.0),
      child: TacticalCard(
        colors: colors,
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onLongPress: () {
            tapHeavy();
            onRemove();
          },
          child: Row(
            children: [
              // Ghost icon with opacity indicator
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _ghostStateColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _ghostStateColor().withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.person_off,
                  size: 18,
                  color: _ghostStateColor(),
                ),
              ),
              const SizedBox(width: 10),

              // Name + position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ghost.displayName,
                      style: TacticalTextStyles.body(colors).copyWith(
                        color: colors.text2,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    MgrsDisplay(
                      mgrs: ghost.lastPosition.mgrsFormatted.isNotEmpty
                          ? ghost.lastPosition.mgrsFormatted
                          : ghost.lastPosition.mgrsRaw,
                      isLarge: false,
                      colors: colors,
                    ),
                  ],
                ),
              ),

              // State + time + velocity
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Disconnected time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colors.text4,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _timeSince(ghost.disconnectedAt),
                        style: TacticalTextStyles.dim(colors),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Ghost state + decay bar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OpacityBar(
                        opacity: ghost.opacity,
                        color: _ghostStateColor(),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _ghostStateLabel().toUpperCase(),
                        style: TacticalTextStyles.label(colors).copyWith(
                          color: _ghostStateColor(),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  // Velocity arrow
                  if (ghost.velocitySpeed != null &&
                      ghost.velocitySpeed! > 0 &&
                      ghost.velocityBearing != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: (ghost.velocityBearing! * 3.14159 / 180.0),
                          child: const Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: Color(0xFFCC8800),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ghost.velocitySpeed!.toStringAsFixed(1)} m/s',
                          style: TacticalTextStyles.dim(colors).copyWith(
                            color: const Color(0xFFCC8800),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini opacity bar showing ghost decay state.
class _OpacityBar extends StatelessWidget {
  const _OpacityBar({
    required this.opacity,
    required this.color,
    required this.colors,
  });

  final double opacity;
  final Color color;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Background
            Container(
              color: colors.card2,
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

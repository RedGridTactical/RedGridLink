import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/field_link_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/dialogs/confirm_dialog.dart';
import '../../common/widgets/tactical_button.dart';
import 'widgets/ghost_list.dart';
import 'widgets/peer_list.dart';
import 'widgets/session_create_card.dart';
import 'widgets/session_info_card.dart';
import 'widgets/session_join_card.dart';
import 'widgets/sync_status_bar.dart';

/// Main Field Link tab screen.
///
/// When no active session: shows "Create Session" and "Join Session" cards.
/// When session active: shows sync status bar, session info card, peer list,
/// ghost list, and leave session button at the bottom.
class FieldLinkScreen extends ConsumerWidget {
  const FieldLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final isActive = ref.watch(isSessionActiveProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 22,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FIELD LINK',
                    style: TacticalTextStyles.heading(colors),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Proximity coordination with nearby devices',
                style: TacticalTextStyles.caption(colors),
              ),
            ),

            // Sync status bar (only when session active)
            if (isActive) ...[
              const SizedBox(height: 8),
              const SyncStatusBar(),
            ],

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: isActive
                  ? _ActiveSessionView()
                  : _NoSessionView(),
            ),
          ],
        ),
      ),
    );
  }
}

/// View when no active session -- shows Create and Join cards.
class _NoSessionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SessionCreateCard(),
          SizedBox(height: 12),
          SessionJoinCard(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// View when session is active -- shows session info, peers, ghosts,
/// and leave button pinned at the bottom.
class _ActiveSessionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Column(
      children: [
        const Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session info card
                SessionInfoCard(),
                SizedBox(height: 14),

                // Peer list
                PeerList(),
                SizedBox(height: 14),

                // Ghost list
                GhostList(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Leave session button (pinned at bottom)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TacticalButton(
            label: 'Leave Session',
            icon: Icons.exit_to_app,
            isDestructive: true,
            colors: colors,
            onPressed: () => _leaveSession(context, ref, colors),
          ),
        ),
      ],
    );
  }

  Future<void> _leaveSession(
    BuildContext context,
    WidgetRef ref,
    TacticalColorScheme colors,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave Session',
      message:
          'You will disconnect from all peers. '
          'Ghost markers will be preserved for your position.',
      confirmLabel: 'Leave',
      isDestructive: true,
      colors: colors,
    );

    if (confirmed) {
      tapHeavy();
      final service = ref.read(fieldLinkServiceProvider);
      await service.leaveSession();
    }
  }
}

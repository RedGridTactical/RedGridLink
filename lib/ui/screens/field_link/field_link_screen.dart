import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/entitlement.dart';
import '../../../providers/field_link_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/review/review_service.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/dialogs/confirm_dialog.dart';
import '../../common/widgets/paywall_sheet.dart';
import '../../common/widgets/tactical_button.dart';
import '../session/session_history_screen.dart';
import 'widgets/ghost_list.dart';
import 'widgets/peer_list.dart';
import 'widgets/preflight_sheet.dart';
import 'widgets/session_create_card.dart';
import 'widgets/session_info_card.dart';
import 'widgets/session_join_card.dart';
import 'widgets/sync_status_bar.dart';

/// Opens the Field Readiness Preflight bottom sheet.
void _showPreflightSheet(BuildContext context) {
  tapMedium();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const PreflightSheet(),
  );
}

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
    final mode = ref.watch(currentModeProvider);

    // Host-side upsell: a device tried to join past the entitlement cap.
    ref.listen<int>(joinBlockedByCapProvider, (prev, next) {
      if (prev == next) return;
      final entitlement = Entitlement.fromName(ref.read(entitlementProvider));
      if (entitlement.fullFieldLink) return; // already on an 8-device tier
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SESSION FULL — YOUR TIER LINKS ${entitlement.maxDevices} DEVICES',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UPGRADE',
            textColor: Colors.white,
            onPressed: () => showPaywallSheet(
              context,
              featureName: '8-Device Field Link',
            ),
          ),
        ),
      );
    });

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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mode.icon, size: 10, color: colors.accent),
                        const SizedBox(width: 3),
                        Text(
                          mode.label,
                          style: TacticalTextStyles.dim(colors).copyWith(
                            color: colors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                mode.linkSubtitle,
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

/// View when no active session -- shows Create and Join cards,
/// plus a link to the session history screen.
class _NoSessionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SessionCreateCard(),
          const SizedBox(height: 12),
          const SessionJoinCard(),
          const SizedBox(height: 16),
          TacticalButton(
            label: 'Field Readiness',
            icon: Icons.checklist,
            colors: colors,
            onPressed: () => _showPreflightSheet(context),
          ),
          const SizedBox(height: 12),
          TacticalButton(
            label: 'Session History',
            icon: Icons.history,
            colors: colors,
            onPressed: () {
              tapLight();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SessionHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
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

        // Field readiness preflight (pinned, secondary action)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TacticalButton(
            label: 'Field Readiness',
            icon: Icons.checklist,
            colors: colors,
            onPressed: () => _showPreflightSheet(context),
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
      // Capture whether this was a real multi-device session before we
      // disconnect — we only ask for a review after a session that actually
      // linked up with at least one teammate.
      final hadPeers = ref.read(connectedPeerCountProvider) > 0;
      final service = ref.read(fieldLinkServiceProvider);
      await service.leaveSession();
      if (hadPeers) {
        await ref.read(reviewServiceProvider).maybePromptReview();
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/ui/common/role_icon.dart';
import 'package:red_grid_link/ui/common/widgets/signal_bars.dart';

import 'role_selector_dialog.dart';

/// Bottom sheet displaying all peers in the active session with their roles
/// and callsigns.
///
/// The session lead sees a manage button on each peer row that opens
/// [RoleSelectorDialog] or offers a "Promote to Lead" action.
class TeamRosterSheet extends ConsumerWidget {
  const TeamRosterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final peersAsync = ref.watch(connectedPeersProvider);
    final localRole = ref.watch(localRoleProvider);
    final isLead = ref.watch(isLeadProvider);
    final localDeviceId = ref.watch(localDeviceIdProvider);
    final service = ref.watch(fieldLinkServiceProvider);
    final localCallsign = service.roleManager.callsign;
    final qualityMap = ref.watch(connectionQualityProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            'TEAM ROSTER',
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          // Local user row
          _PeerRow(
            icon: iconForRole(localRole),
            name: localCallsign.isNotEmpty
                ? localCallsign
                : 'You',
            roleLabel: localRole.displayName,
            isLocal: true,
            theme: theme,
          ),

          const Divider(),

          // Connected peers
          peersAsync.when(
            data: (peers) {
              if (peers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No peers connected',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: peers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  final label = peer.callsign.isNotEmpty
                      ? peer.callsign
                      : peer.displayName;
                  final roleLabel = peer.role == TeamRole.custom &&
                          peer.customRoleLabel != null &&
                          peer.customRoleLabel!.isNotEmpty
                      ? peer.customRoleLabel!
                      : peer.role.displayName;

                  final quality = qualityMap[peer.id];

                  return _PeerRow(
                    icon: iconForRole(peer.role),
                    name: label,
                    roleLabel: roleLabel,
                    isLocal: false,
                    theme: theme,
                    quality: quality,
                    trailing: isLead
                        ? _ManageButton(
                            peer: peer,
                            service: service,
                            localDeviceId: localDeviceId,
                            theme: theme,
                          )
                        : null,
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A single row in the team roster.
class _PeerRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String roleLabel;
  final bool isLocal;
  final ThemeData theme;
  final ConnectionQuality? quality;
  final Widget? trailing;

  const _PeerRow({
    required this.icon,
    required this.name,
    required this.roleLabel,
    required this.isLocal,
    required this.theme,
    this.quality,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  roleLabel + (isLocal ? ' (You)' : ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (quality != null) ...[
            if (quality!.isWarning)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ),
            SignalBars(
              bars: quality!.bars,
              tier: quality!.tier,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Manage button shown to the lead for each peer row.
class _ManageButton extends StatelessWidget {
  final Peer peer;
  final dynamic service; // FieldLinkService
  final String localDeviceId;
  final ThemeData theme;

  const _ManageButton({
    required this.peer,
    required this.service,
    required this.localDeviceId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
      tooltip: 'Manage',
      onSelected: (value) async {
        if (value == 'role') {
          final result = await showDialog<RoleSelection>(
            context: context,
            builder: (_) => RoleSelectorDialog(
              initialRole: peer.role,
              initialCustomLabel: peer.customRoleLabel,
            ),
          );
          if (result != null) {
            service.roleManager.assignRole(
              peer.id,
              result.role,
              customLabel: result.customLabel,
            );
          }
        } else if (value == 'promote') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('PROMOTE TO LEAD'),
              content: Text(
                'Promote ${peer.displayName} to Lead? '
                'You will be demoted to Scout.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            service.roleManager.promotePeerToLead(peer.id);
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'role',
          child: Text('Change Role'),
        ),
        const PopupMenuItem(
          value: 'promote',
          child: Text('Promote to Lead'),
        ),
      ],
    );
  }
}

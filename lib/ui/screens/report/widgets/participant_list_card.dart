import 'package:flutter/material.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';
import 'package:red_grid_link/ui/common/widgets/tactical_card.dart';

/// Card showing the list of session participants with per-peer stats.
///
/// Displays each peer's display name, device type, last seen timestamp,
/// and number of markers they placed during the session.
class ParticipantListCard extends StatelessWidget {
  const ParticipantListCard({
    super.key,
    required this.aar,
    required this.colors,
  });

  final AarData aar;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.people, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'PARTICIPANTS',
                style: TacticalTextStyles.subheading(colors),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border2),
                ),
                child: Text(
                  '${aar.totalPeers}',
                  style: TacticalTextStyles.caption(colors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (aar.peers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'NO PARTICIPANTS RECORDED',
                  style: TacticalTextStyles.dim(colors),
                ),
              ),
            )
          else
            ...aar.peers.asMap().entries.map((entry) {
              final isLast = entry.key == aar.peers.length - 1;
              return _ParticipantRow(
                peer: entry.value,
                markersPlaced: _markersForPeer(entry.value),
                colors: colors,
                showDivider: !isLast,
              );
            }),
        ],
      ),
    );
  }

  int _markersForPeer(Peer peer) {
    return aar.markers
        .where(
            (m) => m.createdBy == peer.id || m.createdBy == peer.displayName)
        .length;
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.peer,
    required this.markersPlaced,
    required this.colors,
    this.showDivider = true,
  });

  final Peer peer;
  final int markersPlaced;
  final TacticalColorScheme colors;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Status indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Name and device type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.displayName.toUpperCase(),
                      style: TacticalTextStyles.body(colors),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${peer.deviceType.name.toUpperCase()} // '
                      'LAST SEEN ${AarService.formatTacticalTimestamp(peer.lastSeen)}',
                      style: TacticalTextStyles.dim(colors),
                    ),
                  ],
                ),
              ),

              // Markers placed badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border2),
                ),
                child: Column(
                  children: [
                    Text(
                      '$markersPlaced',
                      style: TacticalTextStyles.value(colors).copyWith(fontSize: 14),
                    ),
                    Text(
                      'MKRS',
                      style: TacticalTextStyles.label(colors).copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: colors.border2, height: 1),
      ],
    );
  }
}

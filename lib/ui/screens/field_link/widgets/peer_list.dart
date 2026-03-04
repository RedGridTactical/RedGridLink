import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/peer.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/battery_indicator.dart';
import '../../../common/widgets/bearing_arrow.dart';
import '../../../common/widgets/mgrs_display.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/status_chip.dart';
import '../../../common/widgets/tactical_card.dart';

/// Connected peers list widget.
///
/// Each peer shows: display name, device type icon (Android/iOS), MGRS
/// position, last seen, battery level, sync status chip. Tap opens a
/// detail card with full position, distance from you, and bearing to peer.
class PeerList extends ConsumerWidget {
  const PeerList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final peersAsync = ref.watch(connectedPeersProvider);

    return peersAsync.when(
      data: (peers) {
        final connectedPeers =
            peers.where((p) => p.isConnected).toList();

        if (connectedPeers.isEmpty) {
          return _EmptyPeerState(colors: colors);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Connected Peers',
              trailing: Text(
                '${connectedPeers.length}',
                style: TacticalTextStyles.caption(colors).copyWith(
                  color: colors.accent,
                ),
              ),
              colors: colors,
            ),
            const SizedBox(height: 6),
            ...connectedPeers.map((peer) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PeerTile(
                    peer: peer,
                    colors: colors,
                  ),
                )),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Error loading peers',
          style: TacticalTextStyles.dim(colors),
        ),
      ),
    );
  }
}

/// Empty state when no peers are connected.
class _EmptyPeerState extends StatelessWidget {
  const _EmptyPeerState({required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Connected Peers',
          trailing: Text(
            '0',
            style: TacticalTextStyles.caption(colors).copyWith(
              color: colors.text4,
            ),
          ),
          colors: colors,
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 32,
                color: colors.text4,
              ),
              const SizedBox(height: 8),
              Text(
                'No peers connected',
                style: TacticalTextStyles.dim(colors),
              ),
              const SizedBox(height: 4),
              Text(
                'Waiting for nearby devices...',
                style: TacticalTextStyles.dim(colors).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Individual peer tile.
class _PeerTile extends StatelessWidget {
  const _PeerTile({
    required this.peer,
    required this.colors,
  });

  final Peer peer;
  final TacticalColorScheme colors;

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  IconData _deviceIcon() {
    switch (peer.deviceType) {
      case DeviceType.android:
        return Icons.phone_android;
      case DeviceType.ios:
        return Icons.phone_iphone;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }

  Color _syncColor() {
    switch (peer.syncMode) {
      case SyncMode.active:
        return const Color(0xFF00CC00);
      case SyncMode.expedition:
        return const Color(0xFFCCCC00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(10),
      onTap: () {
        tapLight();
        _showPeerDetail(context);
      },
      child: Row(
        children: [
          // Device type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.card2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border2),
            ),
            child: Icon(
              _deviceIcon(),
              size: 18,
              color: colors.text2,
            ),
          ),
          const SizedBox(width: 10),

          // Name + position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.displayName,
                  style: TacticalTextStyles.body(colors).copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (peer.position != null)
                  MgrsDisplay(
                    mgrs: peer.position!.mgrsFormatted.isNotEmpty
                        ? peer.position!.mgrsFormatted
                        : peer.position!.mgrsRaw,
                    isLarge: false,
                    colors: colors,
                  ),
                if (peer.position == null)
                  Text(
                    'No position',
                    style: TacticalTextStyles.dim(colors),
                  ),
              ],
            ),
          ),

          // Metadata column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Last seen
              Text(
                _timeSince(peer.lastSeen),
                style: TacticalTextStyles.dim(colors),
              ),
              const SizedBox(height: 4),
              // Battery + sync
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (peer.batteryLevel != null)
                    BatteryIndicator(
                      batteryLevel: peer.batteryLevel,
                      isCompact: true,
                      colors: colors,
                    ),
                  const SizedBox(width: 6),
                  StatusChip(
                    label: peer.syncMode.name,
                    color: _syncColor(),
                    colors: colors,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPeerDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PeerDetailSheet(
        peer: peer,
        colors: colors,
      ),
    );
  }
}

/// Bottom sheet with full peer details.
class _PeerDetailSheet extends StatelessWidget {
  const _PeerDetailSheet({
    required this.peer,
    required this.colors,
  });

  final Peer peer;
  final TacticalColorScheme colors;

  String _formatCoord(double val) => val.toStringAsFixed(6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(20),
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
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Row(
            children: [
              Icon(
                peer.deviceType == DeviceType.android
                    ? Icons.phone_android
                    : peer.deviceType == DeviceType.ios
                        ? Icons.phone_iphone
                        : Icons.devices,
                size: 24,
                color: colors.accent,
              ),
              const SizedBox(width: 10),
              Text(
                peer.displayName.toUpperCase(),
                style: TacticalTextStyles.heading(colors),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MGRS position
          if (peer.position != null) ...[
            Text(
              'MGRS POSITION',
              style: TacticalTextStyles.label(colors),
            ),
            const SizedBox(height: 4),
            MgrsDisplay(
              mgrs: peer.position!.mgrsFormatted.isNotEmpty
                  ? peer.position!.mgrsFormatted
                  : peer.position!.mgrsRaw,
              isLarge: true,
              colors: colors,
            ),
            const SizedBox(height: 12),

            // Lat/Lon
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: 'LAT',
                    value: _formatCoord(peer.position!.lat),
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    label: 'LON',
                    value: _formatCoord(peer.position!.lon),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Altitude + Speed
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: 'ALT',
                    value: peer.position!.altitude != null
                        ? '${peer.position!.altitude!.round()}m'
                        : '--',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    label: 'SPEED',
                    value: peer.position!.speed != null
                        ? '${peer.position!.speed!.toStringAsFixed(1)} m/s'
                        : '--',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Heading
            if (peer.position!.heading != null) ...[
              Row(
                children: [
                  _DetailItem(
                    label: 'HEADING',
                    value:
                        '${peer.position!.heading!.round()}\u00B0',
                    colors: colors,
                  ),
                  const SizedBox(width: 12),
                  BearingArrow(
                    bearingDegrees: peer.position!.heading!,
                    size: 24,
                    colors: colors,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],

          // Battery
          if (peer.batteryLevel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'BATTERY: ',
                  style: TacticalTextStyles.label(colors),
                ),
                BatteryIndicator(
                  batteryLevel: peer.batteryLevel,
                  colors: colors,
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Close button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: colors.card,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  tapLight();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: AppConstants.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'CLOSE',
                    style: TacticalTextStyles.buttonText(colors),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Detail item (label + value) for the peer detail sheet.
class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TacticalTextStyles.body(colors).copyWith(
            color: colors.text,
          ),
        ),
      ],
    );
  }
}

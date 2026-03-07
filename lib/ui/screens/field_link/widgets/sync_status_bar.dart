import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/field_link/battery/battery_manager.dart';
import '../../../../services/field_link/field_link_service.dart';
import '../../../../services/field_link/transport/transport_service.dart';
import '../../../common/widgets/status_chip.dart';

/// Compact status bar for the Field Link screen.
///
/// Displays:
/// - Green dot + "X Connected" when peers present
/// - Transport icon (bluetooth / wifi)
/// - Battery mode label
/// - Sync indicator (pulsing when actively syncing)
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final peerCount = ref.watch(connectedPeerCountProvider);
    final status = ref.watch(fieldLinkStatusProvider);
    final batteryMode = ref.watch(batteryModeProvider);

    final service = ref.watch(fieldLinkServiceProvider);
    final transportType = service.activeTransport;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(color: colors.border2),
        ),
      ),
      child: Row(
        children: [
          // Connection status chip
          _ConnectionChip(
            peerCount: peerCount,
            status: status,
            colors: colors,
          ),
          const SizedBox(width: 10),

          // Transport type icon
          _TransportIcon(
            transportType: transportType,
            colors: colors,
          ),
          const SizedBox(width: 10),

          // Battery mode label
          _BatteryModeChip(
            mode: batteryMode,
            colors: colors,
          ),

          const Spacer(),

          // Sync indicator
          if (status == FieldLinkStatus.connected)
            StatusChip(
              label: 'Sync',
              color: colors.accent,
              isPulsing: true,
              colors: colors,
            )
          else if (status == FieldLinkStatus.reconnecting)
            StatusChip(
              label: 'Retry',
              color: const Color(0xFFFF8800),
              isPulsing: true,
              colors: colors,
            ),
        ],
      ),
    );
  }
}

/// Connection count chip with coloured dot.
class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({
    required this.peerCount,
    required this.status,
    required this.colors,
  });

  final int peerCount;
  final FieldLinkStatus status;
  final TacticalColorScheme colors;

  Color _dotColor() {
    switch (status) {
      case FieldLinkStatus.connected:
        return const Color(0xFF00CC00);
      case FieldLinkStatus.discovering:
        return const Color(0xFFCCCC00);
      case FieldLinkStatus.reconnecting:
        return const Color(0xFFFF8800);
      case FieldLinkStatus.error:
        return const Color(0xFFCC0000);
      case FieldLinkStatus.idle:
        return colors.text4;
    }
  }

  String _label() {
    switch (status) {
      case FieldLinkStatus.connected:
        return '$peerCount Connected';
      case FieldLinkStatus.discovering:
        return 'Scanning';
      case FieldLinkStatus.reconnecting:
        return 'Reconnecting';
      case FieldLinkStatus.error:
        return 'Error';
      case FieldLinkStatus.idle:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: _label(),
      color: _dotColor(),
      isPulsing: status == FieldLinkStatus.discovering,
      colors: colors,
    );
  }
}

/// Transport type icon (BLE / WiFi).
class _TransportIcon extends StatelessWidget {
  const _TransportIcon({
    required this.transportType,
    required this.colors,
  });

  final TransportType transportType;
  final TacticalColorScheme colors;

  IconData _icon() {
    switch (transportType) {
      case TransportType.ble:
        return Icons.bluetooth;
      case TransportType.androidP2p:
      case TransportType.iosP2p:
        return Icons.wifi;
    }
  }

  String _tooltip() {
    switch (transportType) {
      case TransportType.ble:
        return 'BLE';
      case TransportType.androidP2p:
        return 'Wi-Fi Direct';
      case TransportType.iosP2p:
        return 'Multipeer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip(),
      child: Icon(
        _icon(),
        size: 18,
        color: colors.text3,
      ),
    );
  }
}

/// Battery mode chip.
class _BatteryModeChip extends StatelessWidget {
  const _BatteryModeChip({
    required this.mode,
    required this.colors,
  });

  final BatteryMode mode;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color iconColor;
    final IconData icon;

    switch (mode) {
      case BatteryMode.ultraExpedition:
        label = 'ULTRA EXP';
        iconColor = const Color(0xFF0088CC);
        icon = Icons.battery_full;
      case BatteryMode.expedition:
        label = 'EXPEDITION';
        iconColor = const Color(0xFF00CC00);
        icon = Icons.battery_saver;
      case BatteryMode.active:
        label = 'ACTIVE';
        iconColor = const Color(0xFFCCCC00);
        icon = Icons.bolt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: TacticalTextStyles.label(colors)),
        ],
      ),
    );
  }
}

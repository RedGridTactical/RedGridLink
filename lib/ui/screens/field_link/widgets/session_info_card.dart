import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/session.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/field_link/transport/transport_service.dart';
import '../../../common/widgets/tactical_card.dart';
import 'qr_display_sheet.dart';

/// Active session information card.
///
/// Displays session name, security mode badge, creation time, peer count,
/// transport type, battery mode with projected time, session PIN (if PIN
/// mode, tappable to copy), QR code button (if QR mode), and share button.
class SessionInfoCard extends ConsumerWidget {
  const SessionInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final sessionAsync = ref.watch(activeSessionProvider);
    final peerCount = ref.watch(connectedPeerCountProvider);
    final batteryMode = ref.watch(batteryModeProvider);
    final batteryProjection = ref.watch(batteryProjectionProvider);
    final service = ref.watch(fieldLinkServiceProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null) return const SizedBox.shrink();
        return _SessionInfoContent(
          session: session,
          peerCount: peerCount,
          transportType: service.activeTransport,
          batteryProjection: batteryProjection,
          batteryLevel: service.batteryMode == batteryMode
              ? null // Will be read separately
              : null,
          colors: colors,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SessionInfoContent extends StatelessWidget {
  const _SessionInfoContent({
    required this.session,
    required this.peerCount,
    required this.transportType,
    required this.batteryProjection,
    this.batteryLevel,
    required this.colors,
  });

  final Session session;
  final int peerCount;
  final TransportType transportType;
  final String batteryProjection;
  final int? batteryLevel;
  final TacticalColorScheme colors;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _transportLabel() {
    switch (transportType) {
      case TransportType.ble:
        return 'BLE';
      case TransportType.androidP2p:
        return 'WiFi Direct';
      case TransportType.iosP2p:
        return 'Multipeer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session name + security badge
          Row(
            children: [
              Expanded(
                child: Text(
                  session.name.toUpperCase(),
                  style: TacticalTextStyles.subheading(colors).copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _SecurityBadge(
                mode: session.securityMode,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info grid
          _InfoRow(
            icon: Icons.access_time,
            label: 'Created',
            value: _formatTime(session.createdAt),
            colors: colors,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.people,
            label: 'Peers',
            value: '$peerCount/${AppConstants.maxDevices} connected',
            colors: colors,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: transportType == TransportType.ble
                ? Icons.bluetooth
                : Icons.wifi,
            label: 'Transport',
            value: _transportLabel(),
            colors: colors,
          ),
          const SizedBox(height: 6),

          // Battery projection
          Row(
            children: [
              Icon(Icons.battery_std, size: 16, color: colors.text3),
              const SizedBox(width: 6),
              Text(
                batteryProjection,
                style: TacticalTextStyles.caption(colors),
              ),
            ],
          ),

          // PIN display (if PIN mode)
          if (session.securityMode == SecurityMode.pin &&
              session.pin != null) ...[
            const SizedBox(height: 12),
            _PinDisplay(pin: session.pin!, colors: colors),
          ],

          // Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              // QR code button (if QR mode)
              if (session.securityMode == SecurityMode.qr)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.qr_code,
                    label: 'Show QR',
                    colors: colors,
                    onTap: () => _showQrSheet(context),
                  ),
                ),

              // Share button
              if (session.securityMode == SecurityMode.qr)
                const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  colors: colors,
                  onTap: () => _shareSession(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrSheet(BuildContext context) {
    tapMedium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QrDisplaySheet(
        session: session,
        colors: colors,
      ),
    );
  }

  void _shareSession(BuildContext context) {
    tapMedium();
    final details = StringBuffer()
      ..writeln('Red Grid Link Session: ${session.name}')
      ..writeln('ID: ${session.id}');
    if (session.securityMode == SecurityMode.pin && session.pin != null) {
      details.writeln('PIN: ${session.pin}');
    }
    details.writeln('Mode: ${session.operationalMode.label}');

    Clipboard.setData(ClipboardData(text: details.toString()));
    notifySuccess();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SESSION DETAILS COPIED',
            style: TacticalTextStyles.caption(colors).copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: colors.accent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Security mode badge (Open / PIN / QR).
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge({
    required this.mode,
    required this.colors,
  });

  final SecurityMode mode;
  final TacticalColorScheme colors;

  IconData _icon() {
    switch (mode) {
      case SecurityMode.open:
        return Icons.lock_open;
      case SecurityMode.pin:
        return Icons.pin;
      case SecurityMode.qr:
        return Icons.qr_code;
    }
  }

  Color _badgeColor() {
    switch (mode) {
      case SecurityMode.open:
        return const Color(0xFFCCCC00);
      case SecurityMode.pin:
        return const Color(0xFF00CC00);
      case SecurityMode.qr:
        return const Color(0xFF00CC00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _badgeColor().withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: _badgeColor()),
          const SizedBox(width: 4),
          Text(
            mode.name.toUpperCase(),
            style: TacticalTextStyles.label(colors).copyWith(
              color: _badgeColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single info row with icon, label, and value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.text3),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TacticalTextStyles.label(colors),
        ),
        Expanded(
          child: Text(
            value,
            style: TacticalTextStyles.caption(colors).copyWith(
              color: colors.text2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Tappable PIN display with copy-to-clipboard.
class _PinDisplay extends StatelessWidget {
  const _PinDisplay({
    required this.pin,
    required this.colors,
  });

  final String pin;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        tapLight();
        await Clipboard.setData(ClipboardData(text: pin));
        notifySuccess();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PIN COPIED',
                style: TacticalTextStyles.caption(colors).copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: colors.accent,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.card2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pin, size: 16, color: colors.accent),
            const SizedBox(width: 8),
            Text(
              'PIN: ',
              style: TacticalTextStyles.label(colors),
            ),
            Text(
              pin.split('').join(' '),
              style: TacticalTextStyles.value(colors).copyWith(
                fontSize: 20,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.copy, size: 14, color: colors.text3),
          ],
        ),
      ),
    );
  }
}

/// Small action button for session card.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.card2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          tapLight();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colors.text2),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TacticalTextStyles.label(colors).copyWith(
                  color: colors.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/peer.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/field_link/transport/transport_service.dart';
import '../../../common/dialogs/pin_entry_dialog.dart';
import '../../../common/dialogs/text_input_dialog.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import 'qr_scan_sheet.dart';

/// Join existing session card.
///
/// Includes:
/// - "Scan for Nearby Sessions" button
/// - List of discovered sessions with signal strength
/// - Tap to join (opens PIN dialog if PIN-secured)
/// - "Scan QR Code" button (opens camera scanner)
/// - Manual session ID entry option
class SessionJoinCard extends ConsumerStatefulWidget {
  const SessionJoinCard({super.key});

  @override
  ConsumerState<SessionJoinCard> createState() => _SessionJoinCardState();
}

class _SessionJoinCardState extends ConsumerState<SessionJoinCard> {
  bool _isScanning = false;
  bool _isJoining = false;
  List<DiscoveredDevice> _discoveredDevices = [];

  void _startScan() async {
    tapMedium();
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    try {
      final service = ref.read(fieldLinkServiceProvider);
      await service.initialize();

      // Listen for discovered devices for a scan window.
      // In production, this listens continuously; here we simulate a timeout.
      final sub = service.statusStream.listen((_) {});

      // Simulate collecting devices for 5 seconds.
      await Future.delayed(const Duration(seconds: 5));
      sub.cancel();
    } catch (e) {
      notifyError();
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _joinSession(DiscoveredDevice device) async {
    final colors = ref.read(currentThemeProvider);

    // If session requires PIN, prompt for it.
    String? pin;
    // We cannot know security mode from discovery alone; try open first,
    // and if it fails, prompt for PIN.

    setState(() => _isJoining = true);
    tapHeavy();

    try {
      final service = ref.read(fieldLinkServiceProvider);
      final success = await service.joinSession(device.id, pin: pin);

      if (!success && mounted) {
        // Likely PIN-protected -- prompt for PIN.
        pin = await showPinEntryDialog(
          context,
          colors: colors,
        );

        if (pin != null) {
          final retrySuccess = await service.joinSession(
            device.id,
            pin: pin,
          );

          if (!retrySuccess && mounted) {
            notifyWarning();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'INCORRECT PIN',
                  style: TacticalTextStyles.caption(colors).copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFCC0000),
              ),
            );
          }
        }
      }
    } catch (e) {
      notifyError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to join: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _joinManually() async {
    final colors = ref.read(currentThemeProvider);

    final sessionId = await showTextInputDialog(
      context,
      title: 'Enter Session ID',
      hintText: 'Paste session ID here',
      colors: colors,
    );

    if (sessionId == null || sessionId.isEmpty) return;

    setState(() => _isJoining = true);
    tapHeavy();

    try {
      final service = ref.read(fieldLinkServiceProvider);
      final success = await service.joinSession(sessionId);

      if (!success && mounted) {
        // Prompt for PIN.
        final pin = await showPinEntryDialog(
          context,
          colors: colors,
        );

        if (pin != null) {
          await service.joinSession(sessionId, pin: pin);
        }
      }
    } catch (e) {
      notifyError();
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _openQrScanner() {
    tapMedium();
    final colors = ref.read(currentThemeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QrScanSheet(colors: colors),
    ).then((qrData) {
      if (qrData != null && qrData is String && qrData.isNotEmpty) {
        _joinFromQr(qrData);
      }
    });
  }

  Future<void> _joinFromQr(String qrData) async {
    setState(() => _isJoining = true);
    tapHeavy();

    try {
      final service = ref.read(fieldLinkServiceProvider);
      await service.joinSession(qrData, qrData: qrData);
    } catch (e) {
      notifyError();
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'JOIN SESSION',
            style: TacticalTextStyles.subheading(colors).copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 14),

          // Scan for nearby sessions
          TacticalButton(
            label: _isScanning ? 'Scanning...' : 'Scan for Nearby Sessions',
            icon: _isScanning ? Icons.radar : Icons.search,
            colors: colors,
            onPressed: _isScanning ? null : _startScan,
          ),
          const SizedBox(height: 12),

          // Discovered sessions list
          if (_discoveredDevices.isNotEmpty) ...[
            Text(
              'NEARBY SESSIONS',
              style: TacticalTextStyles.label(colors),
            ),
            const SizedBox(height: 6),
            ..._discoveredDevices.map((device) => _DiscoveredSessionTile(
                  device: device,
                  colors: colors,
                  isJoining: _isJoining,
                  onTap: () => _joinSession(device),
                )),
            const SizedBox(height: 12),
          ],

          if (_isScanning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scanning for nearby devices...',
                      style: TacticalTextStyles.caption(colors),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (!_isScanning && _discoveredDevices.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No sessions found. Try scanning or use an alternate method.',
                  style: TacticalTextStyles.dim(colors),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Divider
          Divider(color: colors.border2, height: 24, thickness: 1),

          // Alternate join methods
          Text(
            'OTHER METHODS',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Scan QR code
              Expanded(
                child: _JoinMethodButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  colors: colors,
                  onTap: _openQrScanner,
                ),
              ),
              const SizedBox(width: 8),
              // Manual entry
              Expanded(
                child: _JoinMethodButton(
                  icon: Icons.keyboard,
                  label: 'Enter ID',
                  colors: colors,
                  onTap: _joinManually,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tile for a discovered nearby session.
class _DiscoveredSessionTile extends StatelessWidget {
  const _DiscoveredSessionTile({
    required this.device,
    required this.colors,
    required this.isJoining,
    required this.onTap,
  });

  final DiscoveredDevice device;
  final TacticalColorScheme colors;
  final bool isJoining;
  final VoidCallback onTap;

  /// Convert RSSI to a signal quality icon.
  IconData _signalIcon() {
    final rssi = device.rssi ?? -100;
    if (rssi > -50) return Icons.signal_cellular_4_bar;
    if (rssi > -65) return Icons.signal_cellular_alt;
    if (rssi > -80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _signalColor() {
    final rssi = device.rssi ?? -100;
    if (rssi > -50) return const Color(0xFF00CC00);
    if (rssi > -65) return const Color(0xFF88CC00);
    if (rssi > -80) return const Color(0xFFCCCC00);
    return const Color(0xFFCC0000);
  }

  IconData _deviceTypeIcon() {
    switch (device.deviceType) {
      case DeviceType.android:
        return Icons.phone_android;
      case DeviceType.ios:
        return Icons.phone_iphone;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isJoining ? null : () {
          tapMedium();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: colors.card2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border2),
          ),
          child: Row(
            children: [
              // Device type icon
              Icon(
                _deviceTypeIcon(),
                size: 20,
                color: colors.text3,
              ),
              const SizedBox(width: 10),

              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TacticalTextStyles.body(colors).copyWith(
                        color: colors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      device.id.substring(0, 8),
                      style: TacticalTextStyles.dim(colors),
                    ),
                  ],
                ),
              ),

              // Signal strength
              if (device.rssi != null) ...[
                Icon(
                  _signalIcon(),
                  size: 18,
                  color: _signalColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${device.rssi}',
                  style: TacticalTextStyles.dim(colors).copyWith(
                    color: _signalColor(),
                  ),
                ),
              ],

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.text4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact button for alternate join methods.
class _JoinMethodButton extends StatelessWidget {
  const _JoinMethodButton({
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
          tapMedium();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TacticalTextStyles.buttonText(colors).copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

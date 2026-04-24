import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/peer.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/settings_provider.dart';
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

  Future<bool> _checkBluetoothPermission() async {
    try {
      if (Platform.isIOS) {
        var status = await Permission.bluetooth.status;
        if (!status.isGranted) {
          status = await Permission.bluetooth.request();
        }
        if (!status.isGranted && mounted) {
          _showScanError('Bluetooth permission required. Enable in Settings.');
          return false;
        }
      } else {
        // Android: SCAN + CONNECT + ADVERTISE. The joiner also advertises
        // now (v1.5.4) so a third teammate can find them mid-session, and
        // so the creator's slot isn't the single point of failure if its
        // BLE advertising is rate-limited. Without ADVERTISE granted,
        // BleAdvertiserChannel.kt silently fails when we try to start
        // the GATT server from joinSession.
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        final advertiseStatus = await Permission.bluetoothAdvertise.status;
        if (!scanStatus.isGranted ||
            !connectStatus.isGranted ||
            !advertiseStatus.isGranted) {
          final results = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();
          // SCAN and CONNECT are hard requirements. ADVERTISE is soft —
          // without it the joiner can still operate as a central-only
          // client, just won't be discoverable to a third teammate.
          final hardGranted = (results[Permission.bluetoothScan]?.isGranted ?? false) &&
              (results[Permission.bluetoothConnect]?.isGranted ?? false);
          if (!hardGranted && mounted) {
            _showScanError('Bluetooth permission required. Enable in Settings.');
            return false;
          }
        }
      }
      return true;
    } catch (_) {
      return true; // Proceed even if permission check itself fails
    }
  }

  void _showScanError(String message) {
    if (!mounted) return;
    final colors = ref.read(currentThemeProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colors.text),
        ),
        backgroundColor: const Color(0xFFCC0000),
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: colors.accent,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  void _startScan() async {
    tapMedium();

    final hasPermission = await _checkBluetoothPermission();
    if (!hasPermission) return;

    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    StreamSubscription<DiscoveredDevice>? deviceSub;

    try {
      final service = ref.read(fieldLinkServiceProvider);

      // Subscribe before starting so we don't miss early results.
      deviceSub = service.discoveredSessionsStream.listen((device) {
        if (!mounted) return;
        setState(() {
          // Some BLE stacks deliver the service UUID in the first scan
          // callback and the service data (which carries our sessionId)
          // in a later one. If we already have this device WITHOUT a
          // sessionId and the new result DOES carry one, replace the
          // entry in place so a user-tap joins the correct session
          // instead of erroring out with "this host did not broadcast
          // its session id".
          final existingIndex =
              _discoveredDevices.indexWhere((d) => d.id == device.id);
          if (existingIndex == -1) {
            _discoveredDevices.add(device);
          } else {
            final existing = _discoveredDevices[existingIndex];
            final needsUpgrade = (existing.sessionId == null ||
                    existing.sessionId!.isEmpty) &&
                device.sessionId != null &&
                device.sessionId!.isNotEmpty;
            // Also upgrade if the RSSI changed meaningfully so the list
            // reflects current signal strength.
            final rssiChanged = (existing.rssi ?? 0) != (device.rssi ?? 0);
            if (needsUpgrade || rssiChanged) {
              _discoveredDevices[existingIndex] = device;
            }
          }
        });
      });

      await service.startSessionScan();

      // Scan for 10 seconds, then stop automatically.
      await Future.delayed(const Duration(seconds: 10));
    } catch (e) {
      notifyError();
      if (mounted) {
        final msg = _friendlyError(e);
        final colors = ref.read(currentThemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: TextStyle(color: colors.text)),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    } finally {
      await deviceSub?.cancel();
      try {
        final service = ref.read(fieldLinkServiceProvider);
        await service.stopSessionScan();
      } catch (_) {}
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('bluetooth') &&
        (msg.contains('off') || msg.contains('unavailable'))) {
      return 'Bluetooth is off. Enable Bluetooth and try again.';
    }
    if (msg.contains('permission')) {
      return 'Bluetooth permission denied. Enable in Settings.';
    }
    return 'Scan failed. Ensure Bluetooth is on and try again.';
  }

  Future<void> _joinSession(DiscoveredDevice device) async {
    final colors = ref.read(currentThemeProvider);

    // The host's session UUID v4 is broadcast in the BLE service-data
    // advertising field and parsed into [DiscoveredDevice.sessionId] by
    // [BleTransport]. If it's missing, the host is on an old build that
    // didn't include sessionId in its advertisement — the user must use
    // the QR or Manual entry path to enter the full session id.
    //
    // Calling joinSession(device.id) instead would pass the BLE peripheral
    // CoreBluetooth UUID as the sessionId, which mismatches the host's
    // UUID v4 and silently breaks all CRDT sync (the cause of multiple
    // post-v1.5.2 reviewer reports).
    final sessionId = device.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      notifyError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This host did not broadcast its session id. Update both devices, or use Scan QR / Enter Manually.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFFCC0000),
          ),
        );
      }
      return;
    }

    // We cannot know the security mode from BLE advertisement data alone.
    // Always prompt for PIN — the user can leave it empty for open sessions.
    // The host validates via BLE control message (join_request/join_response).
    final pin = await showPinEntryDialog(
      context,
      colors: colors,
      allowEmpty: true,
    );

    // User cancelled the dialog entirely.
    if (pin == null) return;

    setState(() => _isJoining = true);
    tapHeavy();

    try {
      final service = ref.read(fieldLinkServiceProvider);
      await service.joinSession(
        sessionId,
        pin: pin.isNotEmpty ? pin : null,
      );

      // Set callsign from display name so peers see a human-readable label.
      final displayName = ref.read(displayNameProvider);
      if (displayName.isNotEmpty) {
        service.setCallsign(displayName);
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

      final dn = ref.read(displayNameProvider);
      if (dn.isNotEmpty) service.setCallsign(dn);

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
      // Parse the QR payload JSON to extract session ID, PIN, and mode.
      // The QR contains: {id, name, sec, pin, mode}
      final Map<String, dynamic> payload;
      try {
        payload = jsonDecode(qrData) as Map<String, dynamic>;
      } catch (_) {
        // Not valid JSON — treat the raw string as a session ID (fallback).
        final service = ref.read(fieldLinkServiceProvider);
        await service.joinSession(qrData);
        return;
      }

      final sessionId = payload['id'] as String? ?? qrData;
      final pin = payload['pin'] as String?;

      final service = ref.read(fieldLinkServiceProvider);
      final success = await service.joinSession(sessionId, pin: pin);

      final dn = ref.read(displayNameProvider);
      if (dn.isNotEmpty) service.setCallsign(dn);

      if (!success && mounted) {
        notifyWarning();
        final colors = ref.read(currentThemeProvider);
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
                  'No nearby sessions found. Ask the session host to share'
                  ' a QR code or Session ID.',
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

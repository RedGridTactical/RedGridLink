import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/operational_mode.dart';
import '../../../../data/models/session.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/field_link/battery/battery_manager.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Create new session form.
///
/// Includes:
/// - Session name text input
/// - Security mode selector (Open/PIN/QR) as 3 horizontal chips
/// - If PIN: shows generated 4-digit PIN (tappable to regenerate)
/// - If QR: shows QR code with session payload
/// - Operational mode selector
/// - Battery mode toggle (Expedition/Active)
/// - "Create & Start" button
class SessionCreateCard extends ConsumerStatefulWidget {
  const SessionCreateCard({super.key});

  @override
  ConsumerState<SessionCreateCard> createState() => _SessionCreateCardState();
}

class _SessionCreateCardState extends ConsumerState<SessionCreateCard> {
  final _nameController = TextEditingController(text: 'Field Op');
  SecurityMode _securityMode = SecurityMode.pin;
  OperationalMode _operationalMode = OperationalMode.sar;
  BatteryMode _batteryMode = BatteryMode.expedition;
  String _generatedPin = generatePin();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _regeneratePin() {
    tapLight();
    setState(() {
      _generatedPin = generatePin();
    });
  }

  Future<void> _createSession() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      notifyWarning();
      return;
    }

    setState(() => _isCreating = true);

    // Pre-flight check: verify Bluetooth is on before attempting session creation.
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        notifyError();
        if (mounted) {
          _showBluetoothDialog();
        }
        setState(() => _isCreating = false);
        return;
      }
    } catch (e) {
      debugPrint('[FieldLink] BT state check failed: $e');
      // Proceed and let the transport handle the error with better context.
    }

    tapHeavy();

    try {
      final service = ref.read(fieldLinkServiceProvider);

      // Set battery mode before creating session.
      service.setBatteryMode(_batteryMode);

      await service.createSession(
        name: name,
        securityMode: _securityMode,
        pin: _securityMode == SecurityMode.pin ? _generatedPin : null,
        mode: _operationalMode,
      );
    } catch (e) {
      notifyError();
      if (mounted) {
        final message = e.toString();
        if (message.contains('Bluetooth') || message.contains('bluetooth')) {
          _showBluetoothDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create session: $message',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFCC0000),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Show a user-friendly dialog explaining Bluetooth needs to be enabled.
  void _showBluetoothDialog() {
    final colors = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          'Bluetooth Required',
          style: TacticalTextStyles.subheading(colors),
        ),
        content: Text(
          'Field Link uses Bluetooth to discover and communicate with '
          'nearby teammates. Please enable Bluetooth in your device '
          'settings and try again.',
          style: TacticalTextStyles.body(colors),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Attempt to open Bluetooth settings on Android.
              try {
                await FlutterBluePlus.turnOn();
              } catch (_) {
                // turnOn() may not work on iOS or some Android devices.
              }
            },
            child: Text(
              'TURN ON',
              style: TextStyle(color: colors.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: colors.text3),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the QR payload for session info.
  String _qrPayload() {
    return jsonEncode({
      'id': 'pending', // Will be set on create
      'name': _nameController.text.trim(),
      'sec': _securityMode.name,
      'pin': _securityMode == SecurityMode.pin ? _generatedPin : null,
      'mode': _operationalMode.id,
    });
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
            'CREATE SESSION',
            style: TacticalTextStyles.subheading(colors).copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 14),

          // Session name input
          Text(
            'SESSION NAME',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            maxLength: 32,
            style: TacticalTextStyles.body(colors),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              hintText: 'Enter session name',
              hintStyle: TacticalTextStyles.dim(colors),
              counterText: '',
              filled: true,
              fillColor: colors.card2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security mode selector
          Text(
            'SECURITY MODE',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 6),
          _SecurityModeSelector(
            selected: _securityMode,
            colors: colors,
            onChanged: (mode) {
              tapLight();
              setState(() => _securityMode = mode);
            },
          ),
          const SizedBox(height: 12),

          // PIN display (if PIN mode)
          if (_securityMode == SecurityMode.pin) ...[
            _GeneratedPinDisplay(
              pin: _generatedPin,
              colors: colors,
              onRegenerate: _regeneratePin,
            ),
            const SizedBox(height: 12),
          ],

          // QR preview (if QR mode)
          if (_securityMode == SecurityMode.qr) ...[
            _QrPreview(
              data: _qrPayload(),
              colors: colors,
            ),
            const SizedBox(height: 12),
          ],

          // Operational mode selector
          Text(
            'OPERATIONAL MODE',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 6),
          _OperationalModeSelector(
            selected: _operationalMode,
            colors: colors,
            onChanged: (mode) {
              tapLight();
              setState(() => _operationalMode = mode);
            },
          ),
          const SizedBox(height: 16),

          // Battery mode toggle
          Text(
            'BATTERY MODE',
            style: TacticalTextStyles.label(colors),
          ),
          const SizedBox(height: 6),
          _BatteryModeToggle(
            selected: _batteryMode,
            colors: colors,
            onChanged: (mode) {
              tapLight();
              setState(() => _batteryMode = mode);
            },
          ),
          const SizedBox(height: 20),

          // Create button
          TacticalButton(
            label: _isCreating ? 'Creating...' : 'Create & Start',
            icon: Icons.play_arrow,
            colors: colors,
            onPressed: _isCreating ? null : _createSession,
          ),
        ],
      ),
    );
  }
}

/// Horizontal 3-chip security mode selector.
class _SecurityModeSelector extends StatelessWidget {
  const _SecurityModeSelector({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final SecurityMode selected;
  final TacticalColorScheme colors;
  final ValueChanged<SecurityMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.minTouchTarget,
      child: Row(
        children: SecurityMode.values.map((mode) {
          final bool isSelected = mode == selected;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: isSelected ? colors.accent : colors.card,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onChanged(mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minHeight: AppConstants.minTouchTarget,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForMode(mode),
                          size: 14,
                          color: isSelected ? Colors.white : colors.text3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mode.name.toUpperCase(),
                          style: TacticalTextStyles.caption(colors).copyWith(
                            color: isSelected ? Colors.white : colors.text2,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForMode(SecurityMode mode) {
    switch (mode) {
      case SecurityMode.open:
        return Icons.lock_open;
      case SecurityMode.pin:
        return Icons.pin;
      case SecurityMode.qr:
        return Icons.qr_code;
    }
  }
}

/// Generated PIN display with regenerate button.
class _GeneratedPinDisplay extends StatelessWidget {
  const _GeneratedPinDisplay({
    required this.pin,
    required this.colors,
    required this.onRegenerate,
  });

  final String pin;
  final TacticalColorScheme colors;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.pin, size: 18, color: colors.accent),
          const SizedBox(width: 10),
          Text(
            'Session PIN: ',
            style: TacticalTextStyles.label(colors),
          ),
          Text(
            pin.split('').join(' '),
            style: TacticalTextStyles.value(colors).copyWith(
              fontSize: 20,
              letterSpacing: 6,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: AppConstants.minTouchTarget,
            height: AppConstants.minTouchTarget,
            child: IconButton(
              onPressed: onRegenerate,
              icon: Icon(
                Icons.refresh,
                size: 20,
                color: colors.text3,
              ),
              tooltip: 'Regenerate PIN',
            ),
          ),
        ],
      ),
    );
  }
}

/// Small QR code preview for QR security mode.
class _QrPreview extends StatelessWidget {
  const _QrPreview({
    required this.data,
    required this.colors,
  });

  final String data;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 120,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// Horizontal operational mode selector.
class _OperationalModeSelector extends StatelessWidget {
  const _OperationalModeSelector({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final OperationalMode selected;
  final TacticalColorScheme colors;
  final ValueChanged<OperationalMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.minTouchTarget,
      child: Row(
        children: OperationalMode.values.map((mode) {
          final bool isSelected = mode == selected;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? colors.accent : colors.card,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onChanged(mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minHeight: AppConstants.minTouchTarget,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: TacticalTextStyles.caption(colors).copyWith(
                        color: isSelected ? Colors.white : colors.text2,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Battery mode toggle (Expedition / Active).
class _BatteryModeToggle extends StatelessWidget {
  const _BatteryModeToggle({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final BatteryMode selected;
  final TacticalColorScheme colors;
  final ValueChanged<BatteryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.minTouchTarget,
      child: Row(
        children: [
          _BatteryChip(
            label: 'Expedition',
            sublabel: '30s updates',
            icon: Icons.battery_saver,
            isSelected: selected == BatteryMode.expedition,
            colors: colors,
            onTap: () => onChanged(BatteryMode.expedition),
          ),
          const SizedBox(width: 6),
          _BatteryChip(
            label: 'Active',
            sublabel: '5s updates',
            icon: Icons.bolt,
            isSelected: selected == BatteryMode.active,
            colors: colors,
            onTap: () => onChanged(BatteryMode.active),
          ),
        ],
      ),
    );
  }
}

/// Individual battery mode chip.
class _BatteryChip extends StatelessWidget {
  const _BatteryChip({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? colors.accent : colors.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(
              minHeight: AppConstants.minTouchTarget,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : colors.text3,
                ),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TacticalTextStyles.caption(colors).copyWith(
                        color: isSelected ? Colors.white : colors.text2,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TacticalTextStyles.dim(colors).copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : colors.text4,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

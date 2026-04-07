import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/providers/emergency_beacon_provider.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';

/// Floating SOS button that sends an emergency distress signal.
///
/// Only visible during an active Field Link session. On tap, shows a
/// confirmation dialog to prevent accidental activation. When active,
/// pulses red and shows "CANCEL SOS" to allow deactivation.
class SosButton extends ConsumerStatefulWidget {
  const SosButton({super.key});

  @override
  ConsumerState<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSessionActive = ref.watch(isSessionActiveProvider);
    if (!isSessionActive) return const SizedBox.shrink();

    final isBeaconActive = ref.watch(emergencyActiveProvider);

    // Drive the pulse animation based on beacon state.
    if (isBeaconActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isBeaconActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Positioned(
      bottom: 100,
      right: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isBeaconActive ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: isBeaconActive
            ? SizedBox(
                height: 56,
                child: FloatingActionButton.extended(
                  heroTag: 'sos_cancel',
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.close),
                  label: const Text(
                    'CANCEL SOS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => _onCancelSos(ref),
                ),
              )
            : FloatingActionButton(
                heroTag: 'sos_activate',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: () => _onSosTap(context, ref),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
      ),
    );
  }

  void _onSosTap(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Emergency SOS',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Send emergency distress signal to all team members?\n\n'
          'Your GPS coordinates will be broadcast every 30 seconds '
          'until cancelled.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _activateBeacon(ref);
      }
    });
  }

  void _activateBeacon(WidgetRef ref) {
    final position = ref.read(currentPositionProvider);
    if (position == null) return;

    final service = ref.read(fieldLinkServiceProvider);
    service.activateEmergencyBeacon(position.lat, position.lon);
    ref.read(emergencyActiveProvider.notifier).state = true;

    HapticFeedback.heavyImpact();
  }

  void _onCancelSos(WidgetRef ref) {
    final service = ref.read(fieldLinkServiceProvider);
    service.deactivateEmergencyBeacon();
    ref.read(emergencyActiveProvider.notifier).state = false;
  }
}

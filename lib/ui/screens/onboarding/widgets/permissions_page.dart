import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Onboarding page 3: Permission requests.
///
/// Requests location and Bluetooth permissions with explanations.
/// Users can proceed even if permissions are denied (with a warning).
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({
    super.key,
    required this.colors,
  });

  final TacticalColorScheme colors;

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _locationGranted = false;
  bool _bluetoothGranted = false;
  bool _locationChecked = false;
  bool _bluetoothChecked = false;

  TacticalColorScheme get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      final btScanStatus = await Permission.bluetoothScan.status;

      if (mounted) {
        setState(() {
          _locationGranted = locationStatus.isGranted;
          _bluetoothGranted = btScanStatus.isGranted;
          _locationChecked = true;
          _bluetoothChecked = true;
        });
      }
    } catch (_) {
      // Permission handler may not be available on all platforms.
      if (mounted) {
        setState(() {
          _locationChecked = true;
          _bluetoothChecked = true;
        });
      }
    }
  }

  Future<void> _requestLocation() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (mounted) {
        setState(() => _locationGranted = status.isGranted);
      }
      if (status.isGranted) {
        notifySuccess();
      }
    } catch (_) {
      // Graceful fallthrough — user can proceed anyway.
    }
  }

  Future<void> _requestBluetooth() async {
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      final allGranted = statuses.values.every((s) => s.isGranted);
      if (mounted) {
        setState(() => _bluetoothGranted = allGranted);
      }
      if (allGranted) {
        notifySuccess();
      }
    } catch (_) {
      // Graceful fallthrough.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Title
          Center(
            child: Icon(
              Icons.security,
              size: 48,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'PERMISSIONS',
              style: TacticalTextStyles.heading(colors),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Required for core functionality',
              style: TacticalTextStyles.caption(colors),
            ),
          ),
          const SizedBox(height: 24),

          // Location permission
          _PermissionCard(
            icon: Icons.my_location,
            title: 'LOCATION ACCESS',
            description:
                'Required for MGRS grid display, map positioning, '
                'and sharing your location with nearby team members.',
            isGranted: _locationGranted,
            isChecked: _locationChecked,
            colors: colors,
            onRequest: _requestLocation,
          ),

          const SizedBox(height: 12),

          // Bluetooth permission
          _PermissionCard(
            icon: Icons.bluetooth,
            title: 'BLUETOOTH ACCESS',
            description:
                'Required for Field Link proximity sync. Enables '
                'discovery and communication with nearby devices.',
            isGranted: _bluetoothGranted,
            isChecked: _bluetoothChecked,
            colors: colors,
            onRequest: _requestBluetooth,
          ),

          const SizedBox(height: 24),

          // Info note
          TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can change permissions later in your device '
                    'settings. The app will still function in solo mode '
                    'without these permissions.',
                    style: TacticalTextStyles.dim(colors),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isChecked,
    required this.colors,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isChecked;
  final TacticalColorScheme colors;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TacticalTextStyles.subheading(colors)),
              ),
              if (isChecked && isGranted)
                Icon(Icons.check_circle, size: 24, color: colors.accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TacticalTextStyles.caption(colors)),
          if (isChecked && !isGranted) ...[
            const SizedBox(height: 12),
            TacticalButton(
              label: 'Grant',
              icon: Icons.shield,
              colors: colors,
              isCompact: true,
              onPressed: onRequest,
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:io' show Platform;

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

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  bool _locationGranted = false;
  bool _bluetoothGranted = false;
  bool _locationChecked = false;
  bool _bluetoothChecked = false;

  TacticalColorScheme get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when user returns from Settings
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;

      // iOS uses Permission.bluetooth; Android uses granular BT permissions
      PermissionStatus btStatus;
      if (Platform.isIOS) {
        btStatus = await Permission.bluetooth.status;
      } else {
        btStatus = await Permission.bluetoothScan.status;
      }

      if (mounted) {
        setState(() {
          _locationGranted = locationStatus.isGranted;
          _bluetoothGranted = btStatus.isGranted;
          _locationChecked = true;
          _bluetoothChecked = true;
        });
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      // Ensure buttons are shown even if check fails
      if (mounted) {
        setState(() {
          _locationChecked = true;
          _bluetoothChecked = true;
        });
      }
    }
  }

  bool _locationRequesting = false;
  bool _bluetoothRequesting = false;

  Future<void> _requestLocation() async {
    if (_locationRequesting) return;
    setState(() => _locationRequesting = true);

    try {
      final current = await Permission.locationWhenInUse.status;
      debugPrint('Location permission status before request: $current');

      if (current.isPermanentlyDenied) {
        await openAppSettings();
        if (mounted) setState(() => _locationRequesting = false);
        // Re-check after returning from settings
        _recheckAfterDelay();
        return;
      }

      final status = await Permission.locationWhenInUse.request();
      debugPrint('Location permission status after request: $status');

      if (mounted) {
        setState(() {
          _locationGranted = status.isGranted;
          _locationRequesting = false;
        });
      }

      if (status.isGranted) {
        notifySuccess();
      } else if (status.isPermanentlyDenied) {
        if (mounted) _showSettingsSnackbar('Location');
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
      if (mounted) setState(() => _locationRequesting = false);
      await openAppSettings();
    }
  }

  Future<void> _requestBluetooth() async {
    if (_bluetoothRequesting) return;
    setState(() => _bluetoothRequesting = true);

    try {
      if (Platform.isIOS) {
        // iOS: single bluetooth permission
        final current = await Permission.bluetooth.status;
        debugPrint('BT permission status before request (iOS): $current');

        if (current.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) setState(() => _bluetoothRequesting = false);
          _recheckAfterDelay();
          return;
        }

        final status = await Permission.bluetooth.request();
        debugPrint('BT permission status after request (iOS): $status');

        if (mounted) {
          setState(() {
            _bluetoothGranted = status.isGranted;
            _bluetoothRequesting = false;
          });
        }

        if (status.isGranted) {
          notifySuccess();
        } else if (status.isPermanentlyDenied) {
          if (mounted) _showSettingsSnackbar('Bluetooth');
        }
      } else {
        // Android: granular bluetooth permissions
        final current = await Permission.bluetoothScan.status;
        debugPrint('BT permission status before request (Android): $current');

        if (current.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) setState(() => _bluetoothRequesting = false);
          _recheckAfterDelay();
          return;
        }

        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        final allGranted = statuses.values.every((s) => s.isGranted);
        debugPrint('BT permissions after request (Android): $statuses');

        if (mounted) {
          setState(() {
            _bluetoothGranted = allGranted;
            _bluetoothRequesting = false;
          });
        }

        if (allGranted) {
          notifySuccess();
        } else if (statuses.values.any((s) => s.isPermanentlyDenied)) {
          if (mounted) _showSettingsSnackbar('Bluetooth');
        }
      }
    } catch (e) {
      debugPrint('Bluetooth permission error: $e');
      if (mounted) setState(() => _bluetoothRequesting = false);
      await openAppSettings();
    }
  }

  /// Re-check permissions after a short delay (user returning from Settings)
  void _recheckAfterDelay() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _checkPermissions();
    });
  }

  void _showSettingsSnackbar(String permission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$permission was previously denied. Tap to open Settings.',
          style: TextStyle(color: colors.text),
        ),
        backgroundColor: colors.card,
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: colors.accent,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
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
            isRequesting: _locationRequesting,
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
            isRequesting: _bluetoothRequesting,
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
    required this.isRequesting,
    required this.colors,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isChecked;
  final bool isRequesting;
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
            if (isRequesting)
              SizedBox(
                height: 44,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
                ),
              )
            else
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/stats/funnel_stats.dart';

/// In-app diagnostics screen for support requests.
///
/// Surfaces the live internal state of GPS, the active session, and the
/// BLE transport so a user reporting a Field Link issue can copy the
/// snapshot and email it to support. The "Copy to clipboard" action in
/// the app bar dumps every line in plain text suitable for pasting into
/// an email body.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  Timer? _refresh;
  String? _systemLocationStatus;
  Map<String, int> _funnel = const {};

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
    _readSystemLocationStatus();
    FunnelStats.instance.snapshot().then((s) {
      if (mounted) setState(() => _funnel = s);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _readSystemLocationStatus() async {
    try {
      final s = await Permission.locationWhenInUse.status;
      if (mounted) setState(() => _systemLocationStatus = s.toString());
    } catch (_) {
      if (mounted) setState(() => _systemLocationStatus = 'unknown');
    }
  }

  /// One-tap path to fire the iOS / Android location permission prompt
  /// from inside the running app. Without this, a tester whose
  /// `hasCompletedOnboarding` flag is `true` (TestFlight upgrade) has
  /// no in-app way to trigger `Permission.request()` — the app stays
  /// invisible to iOS Settings → Privacy → Location Services until
  /// `request()` is called once. Added in v1.5.4+313.
  Future<void> _grantLocation() async {
    try {
      final current = await Permission.locationWhenInUse.status;

      // If iOS has marked this app as permanently denied (the user has
      // tapped "Don't Allow" then we tried again, or they revoked it
      // post-grant), the OS won't show the prompt again — only the
      // Settings app can flip the toggle. Send them there.
      if (current.isPermanentlyDenied) {
        await openAppSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Open Red Grid Link → Location → While Using App'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final result = await Permission.locationWhenInUse.request();

      if (mounted) {
        setState(() => _systemLocationStatus = result.toString());
      }

      if (result.isGranted || result.isLimited) {
        // Kick the LocationService init provider so the GPS stream
        // actually starts now that we have permission. Same path the
        // onboarding PermissionsPage uses (added in v1.5.4+309).
        ref.invalidate(locationInitProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission granted — GPS starting'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (result.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission denied. Enable in iOS Settings.'),
              action: SnackBarAction(
                label: 'SETTINGS',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission request failed: $e')),
        );
      }
    }
  }

  String _ago(DateTime? t) {
    if (t == null) return 'never';
    final secs = DateTime.now().difference(t).inSeconds;
    if (secs < 1) return 'just now';
    if (secs < 60) return '${secs}s ago';
    if (secs < 3600) return '${(secs / 60).floor()}m ago';
    return '${(secs / 3600).floor()}h ago';
  }

  String _short(String? s) {
    if (s == null) return 'null';
    if (s.length <= 8) return s;
    return '…${s.substring(s.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final locationService = ref.watch(locationServiceProvider);
    final permission = ref.watch(locationPermissionProvider);
    final fieldLink = ref.watch(fieldLinkServiceProvider);
    final session = fieldLink.activeSession;
    final ble = fieldLink.bleTransportOrNull;

    // ── ACTION BUTTONS (v1.5.4+313) ─────────────────────────────
    // If a permission is denied at the system level, give the tester a
    // one-tap path to fire `Permission.X.request()` from inside this
    // screen. Without this, an upgrade install where
    // `hasCompletedOnboarding == true` skips the onboarding
    // PermissionsPage and the user has NO in-app way to grant. iOS
    // also doesn't list the app in Settings → Privacy → Location
    // Services until the app has called `request()` at least once,
    // which creates a permanent dead-end. This single button breaks
    // that loop.
    final showGrantLocationButton =
        _systemLocationStatus == 'PermissionStatus.denied' ||
            _systemLocationStatus == 'PermissionStatus.permanentlyDenied' ||
            _systemLocationStatus == 'PermissionStatus.restricted' ||
            (locationService.lastPosition == null &&
                _systemLocationStatus == null);

    final lines = <_DiagLine>[
      // ── GPS ──────────────────────────────────────────────────
      _DiagLine.section('GPS'),
      _DiagLine.kv('Permission (handler)',
          permission.maybeWhen(
              data: (s) => s.toString(), orElse: () => 'loading')),
      _DiagLine.kv('Permission (system)', _systemLocationStatus ?? 'reading…'),
      _DiagLine.kv('Stream running', '${locationService.isStreamRunning}'),
      _DiagLine.kv('Last position',
          locationService.lastPosition == null
              ? 'null'
              : '${locationService.lastPosition!.lat.toStringAsFixed(5)}, '
                  '${locationService.lastPosition!.lon.toStringAsFixed(5)}'),
      _DiagLine.kv('Last fix at',
          _ago(locationService.lastPosition?.timestamp)),

      // ── Session ──────────────────────────────────────────────
      _DiagLine.section('Active Session'),
      _DiagLine.kv('ID', _short(session?.id)),
      _DiagLine.kv('Name', session?.name ?? '—'),
      _DiagLine.kv('Security', session?.securityMode.toString() ?? '—'),
      _DiagLine.kv('PIN set', '${session?.pin != null}'),

      // ── BLE Transport ────────────────────────────────────────
      _DiagLine.section('BLE Transport'),
      _DiagLine.kv('State', ble?.currentState.toString() ?? 'no BLE transport'),
      _DiagLine.kv('Active session id',
          _short(ble?.activeSessionId)),
      _DiagLine.kv('Central conns (we → peer)',
          '${ble?.diagCentralConnectionCount ?? 0}'),
      _DiagLine.kv('Peripheral subs (peer → us)',
          '${ble?.diagPeripheralCentralCount ?? 0}'),
      _DiagLine.kv('Per-central maxUpdateLen',
          ble?.diagPeripheralCentralMaxUpdateLength.isEmpty ?? true
              ? 'empty'
              : ble!.diagPeripheralCentralMaxUpdateLength.values.join(', ')),
      _DiagLine.kv('Last broadcast',
          _ago(ble?.diagLastBroadcastAt)),
      _DiagLine.kv('Last receive',
          _ago(ble?.diagLastReceivedAt)),
      _DiagLine.kv('Messages received',
          '${ble?.diagMessagesReceived ?? 0}'),
      _DiagLine.kv('Messages emitted',
          '${ble?.diagMessagesEmitted ?? 0}'),
      _DiagLine.kv('Last error', ble?.diagLastError ?? '—'),

      // ── CONVERSION (LOCAL ONLY) ──────────────────────────────
      // Funnel counters recorded on-device only (see FunnelStats) —
      // paywall views, gate hits, purchases. Never transmitted.
      _DiagLine.section('CONVERSION (LOCAL ONLY)'),
      if (_funnel.isEmpty)
        _DiagLine.kv('Counters', 'none recorded')
      else
        ...(_funnel.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => _DiagLine.kv(e.key, '${e.value}')),
    ];

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('FIELD LINK DIAGNOSTICS',
            style: TacticalTextStyles.label(colors)
                .copyWith(letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () async {
              final text = lines.map((l) => l.toLine()).join('\n');
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Diagnostics copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        // +1 for the GRANT button row when shown.
        itemCount: lines.length + (showGrantLocationButton ? 1 : 0),
        itemBuilder: (_, i) {
          // Top-of-list grant action.
          if (showGrantLocationButton && i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.accent, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LOCATION PERMISSION REQUIRED',
                    style: TacticalTextStyles.label(colors).copyWith(
                      color: colors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Without it, the app cannot acquire a GPS fix; '
                    'with no fix, Field Link heartbeats are not broadcast '
                    'and peers will never appear on the map.',
                    style: TacticalTextStyles.body(colors).copyWith(
                      fontSize: 11,
                      color: colors.text.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _grantLocation(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('GRANT LOCATION PERMISSION'),
                  ),
                ],
              ),
            );
          }
          // Adjust index for the action row offset.
          final l = lines[showGrantLocationButton ? i - 1 : i];
          if (l.section != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                l.section!.toUpperCase(),
                style: TacticalTextStyles.label(colors).copyWith(
                  color: colors.accent,
                  letterSpacing: 1.5,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    l.key!,
                    style: TacticalTextStyles.body(colors).copyWith(
                      fontSize: 12,
                      color: colors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l.value!,
                    style: TacticalTextStyles.body(colors).copyWith(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiagLine {
  final String? section;
  final String? key;
  final String? value;
  _DiagLine._({this.section, this.key, this.value});

  factory _DiagLine.section(String s) => _DiagLine._(section: s);
  factory _DiagLine.kv(String k, String v) => _DiagLine._(key: k, value: v);

  String toLine() {
    if (section != null) return '\n## ${section!.toUpperCase()}';
    return '$key: $value';
  }
}

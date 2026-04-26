import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/theme_provider.dart';

/// In-app diagnostics screen used to debug Field Link / GPS issues on
/// release builds (TestFlight). On a release build `kDebugMode` is
/// `false` so all the `if (kDebugMode) print(...)` instrumentation in
/// the BLE / MPC / Location services is silent. This screen surfaces
/// the same internal state via a UI the tester can screenshot and
/// send back.
///
/// Added in v1.5.4+312 to debug the iPad-as-host → iPhone-as-joiner
/// regression that survived through builds 307–311.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  Timer? _refresh;
  String? _systemLocationStatus;

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

      // ── How to read this ─────────────────────────────────────
      _DiagLine.section('How to read this (v1.5.4+312)'),
      _DiagLine.note(
          'The two key signals when iPhone shows 0 connected even '
          'though it joined an iPad host:\n\n'
          '1. iPad — "Last broadcast" should tick under 5s. If it stays '
          '"never", the iPad is not running heartbeats — usually because '
          '"Last fix at" is "never" (no GPS fix → SyncEngine '
          'returns early without broadcasting).\n\n'
          '2. iPad — "Peripheral subs" should be ≥1 if iPhone is '
          'connected. "Per-central maxUpdateLen" should report iOS '
          's negotiated MTU (typically 182). If it says "empty" while '
          'iPhone shows connected, the CCCD subscribe never reached '
          'the iPad.\n\n'
          '3. iPhone — "Last receive" should tick under 5s while iPad '
          'is broadcasting. If it stays "never", iPad → iPhone notify '
          'isn t reaching the central listener.'),
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
        itemCount: lines.length,
        itemBuilder: (_, i) {
          final l = lines[i];
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
          if (l.note != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l.note!,
                style: TacticalTextStyles.body(colors).copyWith(
                  fontSize: 11,
                  color: colors.text.withValues(alpha: 0.65),
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
  final String? note;
  _DiagLine._({this.section, this.key, this.value, this.note});

  factory _DiagLine.section(String s) => _DiagLine._(section: s);
  factory _DiagLine.kv(String k, String v) => _DiagLine._(key: k, value: v);
  factory _DiagLine.note(String n) => _DiagLine._(note: n);

  String toLine() {
    if (section != null) return '\n## ${section!.toUpperCase()}';
    if (note != null) return note!;
    return '$key: $value';
  }
}

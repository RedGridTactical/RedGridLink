import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/field_link_provider.dart';
import '../../../../providers/location_provider.dart';
import '../../../../services/field_link/transport/ble_transport.dart';

class FieldLinkDebugOverlay extends ConsumerStatefulWidget {
  const FieldLinkDebugOverlay({super.key});
  @override
  ConsumerState<FieldLinkDebugOverlay> createState() => _State();
}

class _State extends ConsumerState<FieldLinkDebugOverlay> {
  Timer? _timer;
  String _info = 'loading...';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    try {
      final service = ref.read(fieldLinkServiceProvider);
      final transport = service.activeTransport;
      final status = service.status;
      final connIds = service.connectedPeerCount;
      final session = service.activeSession;
      final pos = ref.read(currentPositionProvider);

      // Transport-level diagnostics
      String bleInfo = '';
      final rawTransport = service.transport;
      if (rawTransport is BleTransport) {
        bleInfo = [
          'BLE CENTRAL: ${rawTransport.diagCentralConnectionCount}',
          'BLE PERIPH: ${rawTransport.diagPeripheralCentralCount}',
          'BLE MSG IN: ${rawTransport.diagMessagesReceived}',
          'BLE MSG OUT: ${rawTransport.diagMessagesEmitted}',
          if (rawTransport.diagLastError != null)
            'BLE ERR: ${rawTransport.diagLastError}',
        ].join('\n');
      }

      // Sync engine diagnostics
      final sync = service.syncEngine;
      final syncInfo = [
        'SYNC IN: ${sync.diagMessagesReceived}',
        'SYNC OK: ${sync.diagMessagesApplied}',
        'SYNC FAIL: ${sync.diagMessagesFailed}',
        'CRDT POS: ${sync.diagRemotePositionCount}',
        if (sync.diagLastError != null)
          'SYNC ERR: ${_truncate(sync.diagLastError!, 60)}',
      ].join('\n');

      setState(() {
        _info = [
          'STATUS: ${status.name}',
          'SESSION: ${session != null ? "${session.name} (${session.securityMode.name})" : "none"}',
          'TRANSPORT: ${transport.name}',
          'PEER COUNT: $connIds',
          'GPS: ${pos != null ? "${pos.lat.toStringAsFixed(4)},${pos.lon.toStringAsFixed(4)}" : "NO FIX"}',
          'SESSION ACTIVE: ${service.isSessionActive}',
          '--- TRANSPORT ---',
          bleInfo,
          '--- SYNC ---',
          syncInfo,
        ].join('\n');
      });
    } catch (e) {
      setState(() => _info = 'ERROR: $e');
    }
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Text(
        _info,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }
}

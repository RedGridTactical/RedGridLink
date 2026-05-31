import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_service.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';
import 'package:red_grid_link/services/location/permission_handler_service.dart';

void main() {
  const svc = PreflightService();

  Session session({SecurityMode mode = SecurityMode.pin}) => Session(
        id: 's1',
        name: 'Test',
        createdAt: DateTime(2026),
        operationalMode: OperationalMode.sar,
        securityMode: mode,
      );

  PreflightInputs inputs({
    LocationPermissionStatus permission = LocationPermissionStatus.granted,
    bool hasGpsFix = true,
    double? accuracy = 5,
    TransportState transport = TransportState.connected,
    int regions = 1,
    Session? sess,
    int peers = 1,
    int maxDevices = 8,
    bool hasPeerContact = true,
    BatteryMode batteryMode = BatteryMode.active,
    int? battery = 80,
  }) =>
      PreflightInputs(
        locationPermission: permission,
        hasGpsFix: hasGpsFix,
        gpsAccuracyMeters: accuracy,
        transportState: transport,
        downloadedRegionCount: regions,
        session: sess,
        connectedPeerCount: peers,
        maxDevices: maxDevices,
        hasPeerContact: hasPeerContact,
        batteryMode: batteryMode,
        batteryPercent: battery,
      );

  PreflightCheck checkFor(PreflightReport r, PreflightCheckId id) =>
      r.checks.firstWhere((c) => c.id == id);

  group('PreflightService.evaluate', () {
    test('produces exactly the eight defined checks', () {
      final r = svc.evaluate(inputs(sess: session()));
      expect(r.checks.length, 8);
      expect(
        r.checks.map((c) => c.id).toSet(),
        PreflightCheckId.values.toSet(),
      );
    });

    test('all-green inputs roll up to ready', () {
      final r = svc.evaluate(inputs(sess: session()));
      expect(r.overall, PreflightStatus.ready);
      expect(r.notReadyCount, 0);
      expect(r.cautionCount, 0);
    });

    test('denied permission is a blocker with an in-app fix', () {
      final r = svc.evaluate(
        inputs(permission: LocationPermissionStatus.denied, sess: session()),
      );
      final c = checkFor(r, PreflightCheckId.gpsPermission);
      expect(c.status, PreflightStatus.notReady);
      expect(c.hasInAppFix, true);
      expect(r.overall, PreflightStatus.notReady);
    });

    test('permanently denied has no in-app fix (settings only)', () {
      final c = checkFor(
        svc.evaluate(inputs(
          permission: LocationPermissionStatus.deniedForever,
          sess: session(),
        )),
        PreflightCheckId.gpsPermission,
      );
      expect(c.status, PreflightStatus.notReady);
      expect(c.hasInAppFix, false);
    });

    test('no GPS fix is a blocker', () {
      final r = svc.evaluate(
        inputs(hasGpsFix: false, accuracy: null, sess: session()),
      );
      expect(
        checkFor(r, PreflightCheckId.gpsFix).status,
        PreflightStatus.notReady,
      );
    });

    test('degraded accuracy is a caution; threshold is ready', () {
      expect(
        checkFor(svc.evaluate(inputs(accuracy: 40, sess: session())),
                PreflightCheckId.gpsFix)
            .status,
        PreflightStatus.caution,
      );
      expect(
        checkFor(
                svc.evaluate(inputs(
                    accuracy: PreflightService.goodAccuracyMeters,
                    sess: session())),
                PreflightCheckId.gpsFix)
            .status,
        PreflightStatus.ready,
      );
    });

    test('idle/error transport blocks Bluetooth; active states are ready', () {
      for (final t in [TransportState.idle, TransportState.error]) {
        expect(
          checkFor(svc.evaluate(inputs(transport: t, sess: session())),
                  PreflightCheckId.bluetooth)
              .status,
          PreflightStatus.notReady,
          reason: '$t should block',
        );
      }
      for (final t in [
        TransportState.discovering,
        TransportState.connecting,
        TransportState.connected,
        TransportState.disconnected,
      ]) {
        expect(
          checkFor(svc.evaluate(inputs(transport: t, sess: session())),
                  PreflightCheckId.bluetooth)
              .status,
          PreflightStatus.ready,
          reason: '$t should be ready',
        );
      }
    });

    test('zero offline regions is a caution with an in-app fix', () {
      final c = checkFor(
        svc.evaluate(inputs(regions: 0, sess: session())),
        PreflightCheckId.offlineMaps,
      );
      expect(c.status, PreflightStatus.caution);
      expect(c.hasInAppFix, true);
    });

    test('open session encryption is a caution; pin/qr are ready', () {
      expect(
        checkFor(svc.evaluate(inputs(sess: session(mode: SecurityMode.open))),
                PreflightCheckId.encryption)
            .status,
        PreflightStatus.caution,
      );
      for (final m in [SecurityMode.pin, SecurityMode.qr]) {
        expect(
          checkFor(svc.evaluate(inputs(sess: session(mode: m))),
                  PreflightCheckId.encryption)
              .status,
          PreflightStatus.ready,
        );
      }
    });

    test('no session leaves roster/peer/encryption as caution (not blockers)', () {
      final r = svc.evaluate(inputs(sess: null, peers: 0, hasPeerContact: false));
      expect(checkFor(r, PreflightCheckId.roster).status,
          PreflightStatus.caution);
      expect(checkFor(r, PreflightCheckId.peerContact).status,
          PreflightStatus.caution);
      expect(checkFor(r, PreflightCheckId.encryption).status,
          PreflightStatus.caution);
      // None of the "no session" cautions should escalate to a hard blocker.
      expect(r.notReadyCount, 0);
    });

    test('active session with zero connected peers is a roster caution', () {
      expect(
        checkFor(svc.evaluate(inputs(sess: session(), peers: 0)),
                PreflightCheckId.roster)
            .status,
        PreflightStatus.caution,
      );
    });

    test('low battery is a caution; unknown battery is ready', () {
      expect(
        checkFor(
                svc.evaluate(inputs(
                    battery: PreflightService.lowBatteryPercent,
                    sess: session())),
                PreflightCheckId.battery)
            .status,
        PreflightStatus.caution,
      );
      expect(
        checkFor(svc.evaluate(inputs(battery: null, sess: session())),
                PreflightCheckId.battery)
            .status,
        PreflightStatus.ready,
      );
    });
  });
}

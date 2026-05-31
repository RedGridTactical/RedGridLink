import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';

void main() {
  PreflightReport sample({String? deviceId, String? callsign}) =>
      PreflightReport(
        deviceId: deviceId,
        callsign: callsign,
        checks: const [
          PreflightCheck(
            id: PreflightCheckId.gpsFix,
            label: 'GPS fix',
            status: PreflightStatus.ready,
            detail: '±4 m',
          ),
          PreflightCheck(
            id: PreflightCheckId.encryption,
            label: 'Encryption',
            status: PreflightStatus.caution,
            detail: 'Open session',
          ),
        ],
      );

  group('PreflightStatus', () {
    test('worst picks the lower-confidence status', () {
      expect(PreflightStatus.ready.worst(PreflightStatus.caution),
          PreflightStatus.caution);
      expect(PreflightStatus.caution.worst(PreflightStatus.notReady),
          PreflightStatus.notReady);
      expect(PreflightStatus.ready.worst(PreflightStatus.ready),
          PreflightStatus.ready);
    });

    test('rollup of empty is ready', () {
      expect(PreflightStatus.rollup(const []), PreflightStatus.ready);
    });

    test('rollup returns the single worst', () {
      expect(
        PreflightStatus.rollup(const [
          PreflightStatus.ready,
          PreflightStatus.caution,
          PreflightStatus.ready,
        ]),
        PreflightStatus.caution,
      );
      expect(
        PreflightStatus.rollup(const [
          PreflightStatus.caution,
          PreflightStatus.notReady,
        ]),
        PreflightStatus.notReady,
      );
    });
  });

  group('report rollups', () {
    test('overall is the worst check; counts are accurate', () {
      final r = sample();
      expect(r.overall, PreflightStatus.caution);
      expect(r.notReadyCount, 0);
      expect(r.cautionCount, 1);
    });
  });

  group('wire round-trip (broadcast)', () {
    test('keeps id + status, rebuilds label, drops detail', () {
      final wire = sample(callsign: 'ALPHA').toWire();
      final restored = PreflightReport.fromWire('peer-1', wire);
      expect(restored.deviceId, 'peer-1');
      expect(restored.callsign, 'ALPHA');
      expect(restored.checks.length, 2);
      expect(restored.checks[0].id, PreflightCheckId.gpsFix);
      expect(restored.checks[0].status, PreflightStatus.ready);
      expect(restored.checks[0].label, 'GPS fix'); // reconstructed default
      expect(restored.checks[0].detail, ''); // not sent over the wire
      expect(restored.overall, PreflightStatus.caution);
    });

    test('omits the callsign key when null', () {
      expect(sample().toWire().containsKey('cs'), false);
    });
  });

  group('JSON round-trip (AAR snapshot)', () {
    test('preserves label, status and detail', () {
      final restored =
          PreflightReport.fromJson(sample(deviceId: 'd1', callsign: 'BRAVO').toJson());
      expect(restored.deviceId, 'd1');
      expect(restored.callsign, 'BRAVO');
      expect(restored.checks[0].detail, '±4 m');
      expect(restored.checks[1].detail, 'Open session');
      expect(restored.checks[1].status, PreflightStatus.caution);
      expect(restored.overall, PreflightStatus.caution);
    });
  });
}

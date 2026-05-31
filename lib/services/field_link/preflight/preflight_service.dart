import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';
import 'package:red_grid_link/services/location/permission_handler_service.dart';

/// Snapshot of everything the readiness check needs, gathered by the provider
/// layer and handed to the pure evaluator below. Keeping the inputs as a plain
/// value object means [PreflightService.evaluate] has zero Flutter/platform
/// dependencies and is fully unit-testable.
class PreflightInputs {
  final LocationPermissionStatus locationPermission;

  /// Whether the GPS stream is running and has produced a fix.
  final bool hasGpsFix;

  /// Horizontal accuracy of the last fix in metres, if any.
  final double? gpsAccuracyMeters;

  /// Live BLE transport state.
  final TransportState transportState;

  /// Number of offline map regions cached on this device.
  final int downloadedRegionCount;

  /// The active session, or null if none has been started yet.
  final Session? session;

  /// Connected peer count in the active session.
  final int connectedPeerCount;

  /// Max devices this entitlement allows (drives the roster check ceiling).
  final int maxDevices;

  /// Whether at least one peer has been successfully reached this session
  /// (e.g. an RSSI sample or sync has been observed).
  final bool hasPeerContact;

  final BatteryMode batteryMode;

  /// Battery percentage 0-100, or null if unknown.
  final int? batteryPercent;

  const PreflightInputs({
    required this.locationPermission,
    required this.hasGpsFix,
    this.gpsAccuracyMeters,
    required this.transportState,
    required this.downloadedRegionCount,
    required this.session,
    required this.connectedPeerCount,
    required this.maxDevices,
    required this.hasPeerContact,
    required this.batteryMode,
    this.batteryPercent,
  });
}

/// Pure evaluator that turns [PreflightInputs] into a [PreflightReport].
///
/// Every threshold lives here so the rules are reviewable in one place and
/// covered by unit tests. No I/O, no platform, no Flutter.
class PreflightService {
  /// GPS fix at or better than this (smaller is better) is "ready".
  static const double goodAccuracyMeters = 15.0;

  /// Battery at or below this is a caution.
  static const int lowBatteryPercent = 20;

  const PreflightService();

  PreflightReport evaluate(PreflightInputs i) {
    return PreflightReport(checks: [
      _gpsPermission(i),
      _gpsFix(i),
      _bluetooth(i),
      _offlineMaps(i),
      _encryption(i),
      _roster(i),
      _peerContact(i),
      _battery(i),
    ]);
  }

  PreflightCheck _gpsPermission(PreflightInputs i) {
    final (status, detail, fix) = switch (i.locationPermission) {
      LocationPermissionStatus.granted => (
          PreflightStatus.ready,
          'Granted',
          false
        ),
      LocationPermissionStatus.denied => (
          PreflightStatus.notReady,
          'Denied — tap to grant',
          true
        ),
      LocationPermissionStatus.deniedForever => (
          PreflightStatus.notReady,
          'Denied — enable in Settings',
          false
        ),
      LocationPermissionStatus.serviceDisabled => (
          PreflightStatus.notReady,
          'Location services off',
          false
        ),
      LocationPermissionStatus.unknown => (
          PreflightStatus.caution,
          'Status unknown',
          false
        ),
    };
    return PreflightCheck(
      id: PreflightCheckId.gpsPermission,
      label: 'Location permission',
      status: status,
      detail: detail,
      hasInAppFix: fix,
    );
  }

  PreflightCheck _gpsFix(PreflightInputs i) {
    if (!i.hasGpsFix) {
      return const PreflightCheck(
        id: PreflightCheckId.gpsFix,
        label: 'GPS fix',
        status: PreflightStatus.notReady,
        detail: 'No fix yet — get clear sky view',
      );
    }
    final acc = i.gpsAccuracyMeters;
    if (acc == null) {
      return const PreflightCheck(
        id: PreflightCheckId.gpsFix,
        label: 'GPS fix',
        status: PreflightStatus.caution,
        detail: 'Fix acquired, accuracy unknown',
      );
    }
    final ready = acc <= goodAccuracyMeters;
    return PreflightCheck(
      id: PreflightCheckId.gpsFix,
      label: 'GPS fix',
      status: ready ? PreflightStatus.ready : PreflightStatus.caution,
      detail: ready
          ? '±${acc.toStringAsFixed(0)} m'
          : '±${acc.toStringAsFixed(0)} m — degraded',
    );
  }

  PreflightCheck _bluetooth(PreflightInputs i) {
    // idle/error means the radio isn't usable for Field Link; any active
    // state (discovering/connecting/connected) means BLE is up.
    final ok = i.transportState != TransportState.idle &&
        i.transportState != TransportState.error;
    return PreflightCheck(
      id: PreflightCheckId.bluetooth,
      label: 'Bluetooth',
      status: ok ? PreflightStatus.ready : PreflightStatus.notReady,
      detail: ok ? 'Radio active' : 'Enable Bluetooth in Settings',
    );
  }

  PreflightCheck _offlineMaps(PreflightInputs i) {
    final n = i.downloadedRegionCount;
    return PreflightCheck(
      id: PreflightCheckId.offlineMaps,
      label: 'Offline maps',
      status: n > 0 ? PreflightStatus.ready : PreflightStatus.caution,
      detail: n > 0
          ? '$n region${n == 1 ? '' : 's'} cached'
          : 'No region cached — download your AO',
      hasInAppFix: n == 0,
    );
  }

  PreflightCheck _encryption(PreflightInputs i) {
    final mode = i.session?.securityMode;
    return switch (mode) {
      SecurityMode.pin || SecurityMode.qr => PreflightCheck(
          id: PreflightCheckId.encryption,
          label: 'Encryption',
          status: PreflightStatus.ready,
          detail: 'AES-256-GCM (${mode == SecurityMode.pin ? 'PIN' : 'QR'})',
        ),
      SecurityMode.open => const PreflightCheck(
          id: PreflightCheckId.encryption,
          label: 'Encryption',
          status: PreflightStatus.caution,
          detail: 'Open session — traffic not encrypted',
        ),
      null => const PreflightCheck(
          id: PreflightCheckId.encryption,
          label: 'Encryption',
          status: PreflightStatus.caution,
          detail: 'No active session',
        ),
    };
  }

  PreflightCheck _roster(PreflightInputs i) {
    if (i.session == null) {
      return const PreflightCheck(
        id: PreflightCheckId.roster,
        label: 'Team roster',
        status: PreflightStatus.caution,
        detail: 'No session — start or join one',
      );
    }
    final connected = i.connectedPeerCount;
    // 0 connected peers in an active session = solo on the map (caution, not a
    // hard blocker — the host may simply be first to arrive).
    return PreflightCheck(
      id: PreflightCheckId.roster,
      label: 'Team roster',
      status: connected > 0 ? PreflightStatus.ready : PreflightStatus.caution,
      detail: connected > 0
          ? '$connected of ${i.maxDevices} connected'
          : 'No teammates connected yet',
    );
  }

  PreflightCheck _peerContact(PreflightInputs i) {
    if (i.session == null) {
      return const PreflightCheck(
        id: PreflightCheckId.peerContact,
        label: 'Peer contact',
        status: PreflightStatus.caution,
        detail: 'No session active',
      );
    }
    return PreflightCheck(
      id: PreflightCheckId.peerContact,
      label: 'Peer contact',
      status: i.hasPeerContact ? PreflightStatus.ready : PreflightStatus.caution,
      detail: i.hasPeerContact
          ? 'Link verified'
          : 'No peer reached yet',
    );
  }

  PreflightCheck _battery(PreflightInputs i) {
    final pct = i.batteryPercent;
    final modeLabel = switch (i.batteryMode) {
      BatteryMode.ultraExpedition => 'Ultra Expedition',
      BatteryMode.expedition => 'Expedition',
      BatteryMode.active => 'Active',
    };
    if (pct == null) {
      return PreflightCheck(
        id: PreflightCheckId.battery,
        label: 'Battery',
        status: PreflightStatus.ready,
        detail: '$modeLabel mode',
      );
    }
    final low = pct <= lowBatteryPercent;
    return PreflightCheck(
      id: PreflightCheckId.battery,
      label: 'Battery',
      status: low ? PreflightStatus.caution : PreflightStatus.ready,
      detail: low ? '$pct% — low, consider Expedition mode' : '$pct% · $modeLabel',
    );
  }
}

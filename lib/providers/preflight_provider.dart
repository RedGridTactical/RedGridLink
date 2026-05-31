import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_report.dart';
import 'package:red_grid_link/services/field_link/preflight/preflight_service.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';
import 'package:red_grid_link/services/location/permission_handler_service.dart';

/// Singleton evaluator (pure, stateless).
final preflightServiceProvider =
    Provider<PreflightService>((ref) => const PreflightService());

/// Resolve the current entitlement enum from the string-backed provider.
final _entitlementEnumProvider = Provider<Entitlement>((ref) {
  final name = ref.watch(entitlementProvider);
  try {
    return Entitlement.values.byName(name);
  } catch (_) {
    return Entitlement.free;
  }
});

/// Whether the current tier unlocks the team-wide readiness board
/// (per-teammate broadcast) and AAR readiness snapshot. Free users get the
/// local-device check only.
final teamPreflightUnlockedProvider = Provider<bool>((ref) {
  return ref.watch(_entitlementEnumProvider).fullFieldLink;
});

/// The local device's live readiness report.
///
/// Recomputes automatically whenever any underlying signal changes — GPS
/// permission, position fix, BLE transport state, downloaded regions, the
/// active session, connected peers, or RSSI contact.
final localPreflightReportProvider = Provider<PreflightReport>((ref) {
  final svc = ref.watch(preflightServiceProvider);
  final fieldLink = ref.watch(fieldLinkServiceProvider);

  // GPS permission (async — fall back to unknown until resolved).
  final permission = ref.watch(locationPermissionProvider).maybeWhen(
        data: (p) => p,
        orElse: () => LocationPermissionStatus.unknown,
      );

  // GPS fix + accuracy from the live position stream.
  final position = ref.watch(currentPositionProvider);
  final hasFix = position != null;
  final accuracy = position?.accuracy;

  // Offline regions (async — treat unresolved as 0, i.e. caution).
  final regionCount = ref.watch(downloadedRegionsProvider).maybeWhen(
        data: (r) => r.length,
        orElse: () => 0,
      );

  // Active session + roster.
  final session = ref.watch(activeSessionProvider).maybeWhen(
        data: (s) => s,
        orElse: () => fieldLink.activeSession,
      );
  final connectedPeers = fieldLink.connectedPeerCount;

  // Peer contact: any RSSI sample means we've actually reached a peer.
  final quality = ref.watch(connectionQualityProvider);
  final hasPeerContact = quality.isNotEmpty;

  final entitlement = ref.watch(_entitlementEnumProvider);

  final inputs = PreflightInputs(
    locationPermission: permission,
    hasGpsFix: hasFix,
    gpsAccuracyMeters: accuracy,
    transportState: fieldLink.transportState,
    downloadedRegionCount: regionCount,
    session: session,
    connectedPeerCount: connectedPeers,
    maxDevices: entitlement.maxDevices,
    hasPeerContact: hasPeerContact,
    batteryMode: fieldLink.batteryMode,
    batteryPercent: fieldLink.batteryLevel,
  );

  return svc.evaluate(inputs);
});

/// Per-teammate readiness reports received over the Field Link control
/// channel, keyed by device id. Populated by [FieldLinkService] when peers
/// broadcast their own preflight status (Pro/Team). Empty for free users and
/// before any teammate has reported.
final teamPreflightReportsProvider =
    StateNotifierProvider<TeamPreflightNotifier, Map<String, PreflightReport>>(
  (ref) => TeamPreflightNotifier(),
);

/// Holds inbound teammate readiness reports. [FieldLinkService] pushes into
/// this via the wiring provider when a `preflight_status` control message
/// arrives; entries are cleared when a session ends.
class TeamPreflightNotifier extends StateNotifier<Map<String, PreflightReport>> {
  TeamPreflightNotifier() : super(const {});

  void upsert(PreflightReport report) {
    final id = report.deviceId;
    if (id == null || id.isEmpty) return;
    state = {...state, id: report};
  }

  void clear() => state = const {};
}

/// In-memory store of the local device's step-off readiness snapshot, keyed by
/// session id. Captured when a session becomes active and read by the AAR
/// compiler at export time. First write per session wins (true step-off
/// readiness, not overwritten by later toggles). Not persisted across app
/// restarts — the snapshot is optional and simply omitted if unavailable.
class PreflightSnapshotStore {
  final Map<String, PreflightReport> _bySession = {};

  void capture(String sessionId, PreflightReport report) {
    _bySession.putIfAbsent(sessionId, () => report);
  }

  PreflightReport? forSession(String sessionId) => _bySession[sessionId];

  void clear(String sessionId) => _bySession.remove(sessionId);
}

/// Singleton [PreflightSnapshotStore].
final preflightSnapshotStoreProvider =
    Provider<PreflightSnapshotStore>((ref) => PreflightSnapshotStore());

/// Convenience: is the BLE radio currently usable? Used by the sheet's
/// Bluetooth fix hint.
final preflightTransportUsableProvider = Provider<bool>((ref) {
  final s = ref.watch(fieldLinkServiceProvider).transportState;
  return s != TransportState.idle && s != TransportState.error;
});

/// Wires the Field Readiness preflight broadcast in both directions:
///
/// - **Inbound:** teammates' `preflight_status` control messages are pushed
///   into [teamPreflightReportsProvider] to drive the team readiness board.
/// - **Outbound:** whenever the local readiness *status vector* changes, it is
///   broadcast to the team — Pro/Team tiers in an active session only. The
///   broadcast is de-duplicated on the status vector so routine GPS-accuracy
///   jitter within a tier doesn't spam the mesh.
///
/// Reports (and the dedup signature) are cleared when the session ends. Watch
/// this provider early (app shell) so the inbound callback is registered
/// before any session starts. Safe to watch when [fieldLinkServiceProvider]
/// is not overridden (e.g. widget tests).
final preflightWiringProvider = Provider<void>((ref) {
  final FieldLinkService service;
  try {
    service = ref.watch(fieldLinkServiceProvider);
  } on UnimplementedError {
    return;
  }

  // Inbound: teammate reports → team readiness board.
  service.onTeammatePreflight =
      ref.read(teamPreflightReportsProvider.notifier).upsert;

  // Outbound: broadcast our own readiness when its status vector changes.
  String? lastSignature;
  ref.listen<PreflightReport>(
    localPreflightReportProvider,
    (_, next) {
      if (!ref.read(teamPreflightUnlockedProvider)) return;
      if (!ref.read(isSessionActiveProvider)) return;
      final sig = next.checks.map((c) => c.status.index).join(',');
      if (sig == lastSignature) return;
      lastSignature = sig;
      service.broadcastPreflight(next);
    },
    fireImmediately: true,
  );

  // On session start: capture the step-off readiness snapshot for the AAR.
  // On session end: clear the board and reset the dedup signature.
  ref.listen<bool>(isSessionActiveProvider, (_, active) {
    if (active) {
      final sessionId = ref.read(activeSessionProvider).valueOrNull?.id;
      if (sessionId != null) {
        ref.read(preflightSnapshotStoreProvider).capture(
              sessionId,
              ref.read(localPreflightReportProvider),
            );
      }
    } else {
      lastSignature = null;
      ref.read(teamPreflightReportsProvider.notifier).clear();
    }
  });

  ref.onDispose(() {
    service.onTeammatePreflight = null;
  });
});

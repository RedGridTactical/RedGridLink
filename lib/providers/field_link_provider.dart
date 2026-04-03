import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/boundary_event.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';
import 'package:red_grid_link/providers/emergency_beacon_provider.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';

// ---------------------------------------------------------------------------
// Core service provider
// ---------------------------------------------------------------------------

/// Provider for the [FieldLinkService] singleton.
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance that holds references to the initialized transport,
/// sync engine, ghost manager, battery manager, and repositories.
final fieldLinkServiceProvider = Provider<FieldLinkService>((ref) {
  throw UnimplementedError(
    'fieldLinkServiceProvider must be overridden in the root ProviderScope.',
  );
});

/// Wires RSSI polling callbacks from [FieldLinkService] to
/// [ConnectionQualityNotifier] so that signal bars update in real time.
///
/// Watch this provider early (e.g., in the app shell) to ensure the
/// callbacks are registered before the first BLE session starts.
/// Safe to watch even when [fieldLinkServiceProvider] is not overridden.
final rssiWiringProvider = Provider<void>((ref) {
  final FieldLinkService service;
  try {
    service = ref.watch(fieldLinkServiceProvider);
  } on UnimplementedError {
    // Service not overridden (e.g., in widget tests). Nothing to wire.
    return;
  }
  final notifier = ref.watch(connectionQualityProvider.notifier);

  service.onRssiReading = notifier.updateRssi;
  service.onRssiClear = notifier.clear;

  ref.onDispose(() {
    service.onRssiReading = null;
    service.onRssiClear = null;
  });
});

/// Wires remote emergency state changes from [FieldLinkService] to
/// [emergencyActiveProvider] so the alert overlay reacts to remote SOS.
///
/// Watch this provider early (e.g., in the app shell) alongside
/// [rssiWiringProvider]. Safe to watch when the service is not overridden.
final emergencyWiringProvider = Provider<void>((ref) {
  final FieldLinkService service;
  try {
    service = ref.watch(fieldLinkServiceProvider);
  } on UnimplementedError {
    return;
  }

  service.onEmergencyStateChanged = (active) {
    ref.read(emergencyActiveProvider.notifier).state = active;
  };

  ref.onDispose(() {
    service.onEmergencyStateChanged = null;
  });
});

// ---------------------------------------------------------------------------
// Session state
// ---------------------------------------------------------------------------

/// Stream of the currently active [Session], or null when no session
/// is active.
///
/// Updates reactively whenever a session is created, joined, or left.
final activeSessionProvider = StreamProvider<Session?>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.sessionStream;
});

// ---------------------------------------------------------------------------
// Peer state
// ---------------------------------------------------------------------------

/// Stream of connected peers in the active session.
///
/// Derived from the sync engine's CRDT state; emits a new list whenever
/// any peer's position or connection status changes.
final connectedPeersProvider = StreamProvider<List<Peer>>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.peersStream;
});

/// The number of currently connected peers.
///
/// Derived from [connectedPeersProvider] (a [StreamProvider]) so that the
/// count updates reactively when peers connect or disconnect. A synchronous
/// read of `service.connectedPeerCount` would only capture the initial
/// value and never update.
final connectedPeerCountProvider = Provider<int>((ref) {
  final peersAsync = ref.watch(connectedPeersProvider);
  return peersAsync.valueOrNull?.length ?? 0;
});

// ---------------------------------------------------------------------------
// Ghost state
// ---------------------------------------------------------------------------

/// Stream of ghost markers for disconnected peers.
///
/// Ghosts decay through opacity states over time and can be manually
/// dismissed or automatically removed when the peer reconnects.
final ghostsProvider = StreamProvider<List<Ghost>>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.ghostsStream;
});

// ---------------------------------------------------------------------------
// Battery state
// ---------------------------------------------------------------------------

/// Current battery mode (expedition or active).
///
/// Switching modes adjusts the sync heartbeat interval.
final batteryModeProvider = StateProvider<BatteryMode>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.batteryMode;
});

/// Human-readable battery projection string (e.g., "8hr 12min remaining").
final batteryProjectionProvider = Provider<String>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.batteryProjection;
});

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/// Current Field Link connection status.
///
/// Derived from [fieldLinkStatusStreamProvider] so that it re-evaluates
/// reactively whenever the service emits a new status. A plain read of
/// `service.status` would only capture the value at first evaluation
/// because the service reference itself never changes.
final fieldLinkStatusProvider = Provider<FieldLinkStatus>((ref) {
  final statusAsync = ref.watch(fieldLinkStatusStreamProvider);
  return statusAsync.valueOrNull ?? FieldLinkStatus.idle;
});

/// Stream of Field Link status changes for reactive UI updates.
final fieldLinkStatusStreamProvider = StreamProvider<FieldLinkStatus>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.statusStream;
});

// ---------------------------------------------------------------------------
// Synced markers
// ---------------------------------------------------------------------------

/// Stream of synced markers from the CRDT state.
///
/// Emits the latest list of live (non-tombstoned) markers whenever
/// the sync engine's CRDT state changes.
final syncedMarkersProvider = StreamProvider<List<model.Marker>>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.markersStream;
});

// ---------------------------------------------------------------------------
// Synced annotations
// ---------------------------------------------------------------------------

/// Stream of synced annotations from the CRDT state.
///
/// Emits the latest list of live (non-tombstoned) annotations whenever
/// the sync engine's CRDT state changes.
final syncedAnnotationsProvider = StreamProvider<List<Annotation>>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.annotationsStream;
});

// ---------------------------------------------------------------------------
// Role state
// ---------------------------------------------------------------------------

/// The local device's current team role in the active session.
///
/// Defaults to [TeamRole.scout] when no service is available.
final localRoleProvider = Provider<TeamRole>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.roleManager.localRole;
});

/// Whether the local device is the session lead.
final isLeadProvider = Provider<bool>((ref) {
  return ref.watch(localRoleProvider).isLead;
});

// ---------------------------------------------------------------------------
// Local device ID
// ---------------------------------------------------------------------------

/// The local device ID for this Field Link instance.
final localDeviceIdProvider = Provider<String>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.localDeviceId;
});

// ---------------------------------------------------------------------------
// Boundary state
// ---------------------------------------------------------------------------

/// The currently active boundary annotation, or null.
///
/// Derived from [syncedAnnotationsProvider] by filtering for boundary
/// type annotations. Only one boundary per session is expected.
final activeBoundaryProvider = Provider<Annotation?>((ref) {
  final annotations = ref.watch(syncedAnnotationsProvider).value ?? [];
  return annotations
      .where((a) => a.type == AnnotationType.boundary)
      .firstOrNull;
});

/// Stream of boundary crossing events (exits).
///
/// Emits a [BoundaryEvent] whenever the local user or a peer crosses
/// outside the active boundary. Used by the map screen to show alerts.
final boundaryEventStreamProvider = StreamProvider<BoundaryEvent>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.boundaryEventStream;
});

// ---------------------------------------------------------------------------
// Convenience
// ---------------------------------------------------------------------------

/// Whether a Field Link session is currently active.
///
/// Derived from [activeSessionProvider] (a [StreamProvider]) so that the
/// value updates reactively when a session is created or left. Without
/// this, the provider would read `service.isSessionActive` once and never
/// re-evaluate because the service reference itself is a constant override.
final isSessionActiveProvider = Provider<bool>((ref) {
  final sessionAsync = ref.watch(activeSessionProvider);
  return sessionAsync.valueOrNull != null;
});

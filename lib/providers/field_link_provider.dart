import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/session.dart';
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
/// Synchronous read derived from the transport layer.
final connectedPeerCountProvider = Provider<int>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.connectedPeerCount;
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
/// One of: idle, discovering, connected, or error.
final fieldLinkStatusProvider = Provider<FieldLinkStatus>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.status;
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
// Local device ID
// ---------------------------------------------------------------------------

/// The local device ID for this Field Link instance.
final localDeviceIdProvider = Provider<String>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.localDeviceId;
});

// ---------------------------------------------------------------------------
// Convenience
// ---------------------------------------------------------------------------

/// Whether a Field Link session is currently active.
final isSessionActiveProvider = Provider<bool>((ref) {
  final service = ref.watch(fieldLinkServiceProvider);
  return service.isSessionActive;
});

// Demo data provider for screenshots and marketing demos.
//
// When demoMode is active, these providers inject a fake team session
// centered on the Washington Monument (same anchor used by
// currentPositionProvider in location_provider.dart) so every screen
// has realistic-looking Field Link data even with no BLE hardware and
// no live session. Used by:
//
//   - App Store / Play Store screenshot generation via fastlane snapshot
//   - Reviewer walkthrough demos
//   - In-office marketing captures
//
// Fake population:
//   - 3 connected peers (ALPHA / BRAVO / CHARLIE) with live positions
//   - 1 ghost (DELTA, disconnected 8 minutes ago, faded state)
//   - 5 synced markers (rally point, hazard, objective, waypoint, cache)
//   - 1 boundary annotation (polygon around the AO)
//
// All coordinates are offsets from the Washington Monument reference so
// peer chips land at believable ranges (200-500 m) without overlapping.
//
// This provider is read by the overlay logic in field_link_provider.dart
// — the stream providers there check demoModeProvider first and return
// the synchronous demo data instead of subscribing to the real service
// streams when demo mode is active.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/marker.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/position.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/core/utils/mgrs.dart';

// ---------------------------------------------------------------------------
// Reference point: Washington Monument
// ---------------------------------------------------------------------------

/// Washington Monument — same anchor used by currentPositionProvider's
/// demo mode. All fake peers/markers/ghosts are offset from this point.
const double _refLat = 38.8895;
const double _refLon = -77.0353;

/// Converts a meter offset at Washington DC latitude to (dLat, dLon)
/// degree deltas. Accurate enough for visual layout at 200-500 m scale.
({double lat, double lon}) _offset(double metersNorth, double metersEast) {
  const metersPerDegLat = 111132.0;
  const metersPerDegLon = 111320.0 * 0.776; // cos(38.89°)
  return (
    lat: _refLat + metersNorth / metersPerDegLat,
    lon: _refLon + metersEast / metersPerDegLon,
  );
}

Position _position(double metersNorth, double metersEast, {double? heading,
    double? speed}) {
  final o = _offset(metersNorth, metersEast);
  final raw = toMGRS(o.lat, o.lon);
  return Position(
    lat: o.lat,
    lon: o.lon,
    altitude: 18.0,
    speed: speed ?? 1.4,
    heading: heading ?? 90.0,
    accuracy: 4.0,
    mgrsRaw: raw,
    mgrsFormatted: formatMGRS(raw),
    timestamp: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Fake session
// ---------------------------------------------------------------------------

/// A mock active session so isSessionActiveProvider returns true in demo
/// mode and session-gated UI elements render.
final demoSessionProvider = Provider<Session>((ref) {
  return Session(
    id: 'demo-session-0001',
    name: 'DEMO PATROL',
    securityMode: SecurityMode.pin,
    pin: '0426',
    sessionKey: 'demo-key',
    createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
    operationalMode: OperationalMode.sar,
    peers: const ['demo-local', 'demo-alpha', 'demo-bravo', 'demo-charlie'],
    isActive: true,
  );
});

// ---------------------------------------------------------------------------
// Fake peers (3 connected)
// ---------------------------------------------------------------------------

/// ALPHA, BRAVO, CHARLIE — three connected peers at believable SAR ranges.
final demoPeersProvider = Provider<List<Peer>>((ref) {
  return [
    Peer(
      id: 'demo-alpha',
      displayName: 'ALPHA',
      deviceType: DeviceType.ios,
      position: _position(312.0, -97.0, heading: 341.0, speed: 1.6),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 2)),
      isConnected: true,
      batteryLevel: 82,
      syncMode: SyncMode.active,
      role: TeamRole.scout,
      callsign: 'ALPHA',
    ),
    Peer(
      id: 'demo-bravo',
      displayName: 'BRAVO',
      deviceType: DeviceType.android,
      position: _position(-48.0, -215.0, heading: 278.0, speed: 0.0),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 4)),
      isConnected: true,
      batteryLevel: 71,
      syncMode: SyncMode.active,
      role: TeamRole.medic,
      callsign: 'BRAVO',
    ),
    Peer(
      id: 'demo-charlie',
      displayName: 'CHARLIE',
      deviceType: DeviceType.ios,
      position: _position(-405.0, -265.0, heading: 63.0, speed: 2.1),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 3)),
      isConnected: true,
      batteryLevel: 64,
      syncMode: SyncMode.active,
      role: TeamRole.comms,
      callsign: 'CHARLIE',
    ),
  ];
});

// ---------------------------------------------------------------------------
// Fake ghost (1 disconnected, faded state)
// ---------------------------------------------------------------------------

/// DELTA — disconnected 8 minutes ago, shows faded ghost marker.
final demoGhostsProvider = Provider<List<Ghost>>((ref) {
  final disconnectedAt = DateTime.now().subtract(const Duration(minutes: 8));
  return [
    Ghost(
      peerId: 'demo-delta',
      displayName: 'DELTA',
      lastPosition: _position(518.0, -392.0, heading: 180.0, speed: 0.0),
      disconnectedAt: disconnectedAt,
      ghostState: GhostState.faded,
    ),
  ];
});

// ---------------------------------------------------------------------------
// Fake synced markers (5 varied icons)
// ---------------------------------------------------------------------------

final demoMarkersProvider = Provider<List<Marker>>((ref) {
  final now = DateTime.now();
  Marker mk({
    required String id,
    required String label,
    required double north,
    required double east,
    required MarkerIcon icon,
    required String by,
  }) {
    final o = _offset(north, east);
    final raw = toMGRS(o.lat, o.lon);
    return Marker(
      id: id,
      lat: o.lat,
      lon: o.lon,
      mgrs: raw,
      label: label,
      icon: icon,
      createdBy: by,
      createdAt: now.subtract(const Duration(minutes: 15)),
      origin: MarkerOrigin.manual,
    );
  }

  return [
    mk(
      id: 'demo-m1',
      label: 'RALLY POINT',
      north: 80.0,
      east: 40.0,
      icon: MarkerIcon.rallyPoint,
      by: 'demo-local',
    ),
    mk(
      id: 'demo-m2',
      label: 'HAZARD',
      north: 240.0,
      east: 180.0,
      icon: MarkerIcon.hazard,
      by: 'demo-alpha',
    ),
    mk(
      id: 'demo-m3',
      label: 'OBJECTIVE',
      north: -180.0,
      east: 260.0,
      icon: MarkerIcon.objective,
      by: 'demo-local',
    ),
    mk(
      id: 'demo-m4',
      label: 'WAYPOINT',
      north: 140.0,
      east: -280.0,
      icon: MarkerIcon.waypoint,
      by: 'demo-bravo',
    ),
    mk(
      id: 'demo-m5',
      label: 'CACHE',
      north: -320.0,
      east: -160.0,
      icon: MarkerIcon.cache,
      by: 'demo-charlie',
    ),
  ];
});

// ---------------------------------------------------------------------------
// Fake boundary annotation (polygon)
// ---------------------------------------------------------------------------

final demoAnnotationsProvider = Provider<List<Annotation>>((ref) {
  final points = <AnnotationPoint>[
    _offsetPoint(600.0, -600.0),
    _offsetPoint(600.0, 600.0),
    _offsetPoint(-600.0, 600.0),
    _offsetPoint(-600.0, -600.0),
  ];
  return [
    Annotation(
      id: 'demo-b1',
      type: AnnotationType.boundary,
      points: points,
      color: 0xFFCC3333,
      strokeWidth: 2.5,
      label: 'AO BOUNDARY',
      createdBy: 'demo-local',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
});

AnnotationPoint _offsetPoint(double metersNorth, double metersEast) {
  final o = _offset(metersNorth, metersEast);
  return AnnotationPoint(lat: o.lat, lon: o.lon);
}

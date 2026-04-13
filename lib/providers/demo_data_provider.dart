// Demo data provider for screenshots and marketing demos.
//
// When demoMode is active, these providers inject a fake team session
// in a remote wilderness area so every screen has realistic-looking
// Field Link data even with no BLE hardware and no live session.
//
// Used by:
//   - App Store / Play Store screenshot generation
//   - Reviewer walkthrough demos
//   - In-office marketing captures
//
// Fake population:
//   - 4 connected peers (VIPER / NOMAD / FALCON / REAPER) with live positions
//   - 1 ghost (SPECTER, disconnected 12 minutes ago, faded state)
//   - 5 synced markers (rally point, hazard, objective, waypoint, cache)
//   - 1 boundary annotation (polygon around the AO)
//
// All coordinates are offsets from a remote Appalachian Trail reference
// point so peer chips land at believable ranges (200-600 m).

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
// Reference point: Remote wilderness (Appalachian Trail, Shenandoah NP)
// ---------------------------------------------------------------------------

/// Shenandoah National Park, Virginia — remote backcountry trail junction.
/// No city features visible on map at this zoom level.
const double _refLat = 38.5225;
const double _refLon = -78.4352;

/// Converts a meter offset to (dLat, dLon) degree deltas.
({double lat, double lon}) _offset(double metersNorth, double metersEast) {
  const metersPerDegLat = 111132.0;
  const metersPerDegLon = 111320.0 * 0.783; // cos(38.52°)
  return (
    lat: _refLat + metersNorth / metersPerDegLat,
    lon: _refLon + metersEast / metersPerDegLon,
  );
}

Position _position(double metersNorth, double metersEast, {double? heading,
    double? speed, double? altitude}) {
  final o = _offset(metersNorth, metersEast);
  final raw = toMGRS(o.lat, o.lon);
  return Position(
    lat: o.lat,
    lon: o.lon,
    altitude: altitude ?? 945.0,
    speed: speed ?? 1.4,
    heading: heading ?? 90.0,
    accuracy: 3.5,
    mgrsRaw: raw,
    mgrsFormatted: formatMGRS(raw),
    timestamp: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Fake session
// ---------------------------------------------------------------------------

final demoSessionProvider = Provider<Session>((ref) {
  return Session(
    id: 'demo-session-0001',
    name: 'RIDGE SWEEP',
    securityMode: SecurityMode.pin,
    pin: '7492',
    sessionKey: 'demo-key',
    createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
    operationalMode: OperationalMode.sar,
    peers: const [
      'demo-local',
      'demo-viper',
      'demo-nomad',
      'demo-falcon',
      'demo-reaper',
    ],
    isActive: true,
  );
});

// ---------------------------------------------------------------------------
// Fake peers (4 connected)
// ---------------------------------------------------------------------------

final demoPeersProvider = Provider<List<Peer>>((ref) {
  return [
    Peer(
      id: 'demo-viper',
      displayName: 'VIPER',
      deviceType: DeviceType.ios,
      position: _position(340.0, -120.0,
          heading: 22.0, speed: 1.8, altitude: 962.0),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 2)),
      isConnected: true,
      batteryLevel: 87,
      syncMode: SyncMode.active,
      role: TeamRole.scout,
      callsign: 'VIPER',
    ),
    Peer(
      id: 'demo-nomad',
      displayName: 'NOMAD',
      deviceType: DeviceType.ios,
      position: _position(-85.0, -280.0,
          heading: 315.0, speed: 0.0, altitude: 938.0),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 4)),
      isConnected: true,
      batteryLevel: 72,
      syncMode: SyncMode.active,
      role: TeamRole.medic,
      callsign: 'NOMAD',
    ),
    Peer(
      id: 'demo-falcon',
      displayName: 'FALCON',
      deviceType: DeviceType.ios,
      position: _position(-420.0, 190.0,
          heading: 68.0, speed: 2.3, altitude: 918.0),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 3)),
      isConnected: true,
      batteryLevel: 64,
      syncMode: SyncMode.active,
      role: TeamRole.comms,
      callsign: 'FALCON',
    ),
    Peer(
      id: 'demo-reaper',
      displayName: 'REAPER',
      deviceType: DeviceType.ios,
      position: _position(180.0, 350.0,
          heading: 145.0, speed: 1.2, altitude: 955.0),
      lastSeen: DateTime.now().subtract(const Duration(seconds: 5)),
      isConnected: true,
      batteryLevel: 91,
      syncMode: SyncMode.active,
      role: TeamRole.scout,
      callsign: 'REAPER',
    ),
  ];
});

// ---------------------------------------------------------------------------
// Fake ghost (1 disconnected, faded state)
// ---------------------------------------------------------------------------

final demoGhostsProvider = Provider<List<Ghost>>((ref) {
  final disconnectedAt = DateTime.now().subtract(const Duration(minutes: 12));
  return [
    Ghost(
      peerId: 'demo-specter',
      displayName: 'SPECTER',
      lastPosition: _position(560.0, -420.0,
          heading: 180.0, speed: 0.0, altitude: 970.0),
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
      north: 95.0,
      east: 55.0,
      icon: MarkerIcon.rallyPoint,
      by: 'demo-local',
    ),
    mk(
      id: 'demo-m2',
      label: 'CLIFF EDGE',
      north: 280.0,
      east: 200.0,
      icon: MarkerIcon.hazard,
      by: 'demo-viper',
    ),
    mk(
      id: 'demo-m3',
      label: 'LAST KNOWN POS',
      north: -200.0,
      east: 300.0,
      icon: MarkerIcon.objective,
      by: 'demo-local',
    ),
    mk(
      id: 'demo-m4',
      label: 'TRAIL JUNCTION',
      north: 160.0,
      east: -310.0,
      icon: MarkerIcon.waypoint,
      by: 'demo-nomad',
    ),
    mk(
      id: 'demo-m5',
      label: 'SUPPLY CACHE',
      north: -360.0,
      east: -180.0,
      icon: MarkerIcon.cache,
      by: 'demo-falcon',
    ),
  ];
});

// ---------------------------------------------------------------------------
// Fake boundary annotation (polygon)
// ---------------------------------------------------------------------------

final demoAnnotationsProvider = Provider<List<Annotation>>((ref) {
  final points = <AnnotationPoint>[
    _offsetPoint(650.0, -650.0),
    _offsetPoint(650.0, 650.0),
    _offsetPoint(-650.0, 650.0),
    _offsetPoint(-650.0, -650.0),
  ];
  return [
    Annotation(
      id: 'demo-b1',
      type: AnnotationType.boundary,
      points: points,
      color: 0xFFCC3333,
      strokeWidth: 2.5,
      label: 'SEARCH SECTOR ALPHA',
      createdBy: 'demo-local',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
});

AnnotationPoint _offsetPoint(double metersNorth, double metersEast) {
  final o = _offset(metersNorth, metersEast);
  return AnnotationPoint(lat: o.lat, lon: o.lon);
}

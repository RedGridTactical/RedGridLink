import 'package:flutter/material.dart';

/// Operational modes — one engine, four presentation layers.
///
/// Each mode provides context-appropriate terminology for markers, base
/// locations, rally points, and tool descriptions so the UI adapts to
/// the user's activity without changing any underlying functionality.
enum OperationalMode {
  sar(
    id: 'sar',
    label: 'SAR',
    description: 'Search and Rescue',
    rallyPointLabel: 'Rally Point',
    baseLabel: 'Command Post',
    markerLabel: 'Find',
    icon: Icons.search,
    toolsSubtitle: 'Search and rescue navigation tools',
    gridSubtitle: 'Search area navigation',
    linkSubtitle: 'Search team coordination',
    mapSubtitle: 'Search area map',
    waypointAction: 'Mark Find',
    quickActions: ['Sector Assign', 'Mark Clue', 'Search Pattern'],
  ),
  backcountry(
    id: 'backcountry',
    label: 'BACKCOUNTRY',
    description: 'Backcountry Navigation',
    rallyPointLabel: 'Camp',
    baseLabel: 'Trailhead',
    markerLabel: 'Waypoint',
    icon: Icons.terrain,
    toolsSubtitle: 'Backcountry navigation calculators',
    gridSubtitle: 'Trail navigation',
    linkSubtitle: 'Group coordination',
    mapSubtitle: 'Trail and terrain map',
    waypointAction: 'Mark Waypoint',
    quickActions: ['Mark Camp', 'Set Waypoint', 'Trail Nav'],
  ),
  hunting(
    id: 'hunting',
    label: 'HUNTING',
    description: 'Hunting Party',
    rallyPointLabel: 'Rally',
    baseLabel: 'Truck',
    markerLabel: 'Stand',
    icon: Icons.track_changes,
    toolsSubtitle: 'Hunting party field tools',
    gridSubtitle: 'Stand navigation',
    linkSubtitle: 'Hunting party coordination',
    mapSubtitle: 'Hunting area map',
    waypointAction: 'Mark Stand',
    quickActions: ['Mark Stand', 'Game Sighting', 'Property Line'],
  ),
  training(
    id: 'training',
    label: 'TRAINING',
    description: 'Training Exercise',
    rallyPointLabel: 'Objective',
    baseLabel: 'Start Point',
    markerLabel: 'Checkpoint',
    icon: Icons.flag,
    toolsSubtitle: 'Training exercise navigation tools',
    gridSubtitle: 'Exercise navigation',
    linkSubtitle: 'Exercise team coordination',
    mapSubtitle: 'Exercise area map',
    waypointAction: 'Mark Checkpoint',
    quickActions: ['Set Objective', 'Rally Point', 'Phase Line'],
  );

  final String id;
  final String label;
  final String description;
  final String rallyPointLabel;
  final String baseLabel;
  final String markerLabel;

  /// Icon representing this operational mode.
  final IconData icon;

  /// Mode-specific subtitle for the Tools screen.
  final String toolsSubtitle;

  /// Mode-specific subtitle for the Grid screen.
  final String gridSubtitle;

  /// Mode-specific subtitle for the Field Link screen.
  final String linkSubtitle;

  /// Mode-specific subtitle for the Map screen.
  final String mapSubtitle;

  /// Mode-specific label for the waypoint action button.
  final String waypointAction;

  /// Mode-specific quick action labels for context menus.
  final List<String> quickActions;

  const OperationalMode({
    required this.id,
    required this.label,
    required this.description,
    required this.rallyPointLabel,
    required this.baseLabel,
    required this.markerLabel,
    required this.icon,
    required this.toolsSubtitle,
    required this.gridSubtitle,
    required this.linkSubtitle,
    required this.mapSubtitle,
    required this.waypointAction,
    required this.quickActions,
  });

  /// Resolve an [OperationalMode] from its string [id].
  ///
  /// Returns [OperationalMode.sar] if the id is unrecognized.
  static OperationalMode fromId(String id) {
    return OperationalMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => OperationalMode.sar,
    );
  }
}

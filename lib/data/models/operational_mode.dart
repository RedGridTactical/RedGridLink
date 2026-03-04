/// Operational modes — one engine, four presentation layers
enum OperationalMode {
  sar(
    id: 'sar',
    label: 'SAR',
    description: 'Search and Rescue',
    rallyPointLabel: 'Rally Point',
    baseLabel: 'Command Post',
    markerLabel: 'Find',
  ),
  backcountry(
    id: 'backcountry',
    label: 'BACKCOUNTRY',
    description: 'Backcountry Navigation',
    rallyPointLabel: 'Camp',
    baseLabel: 'Trailhead',
    markerLabel: 'Waypoint',
  ),
  hunting(
    id: 'hunting',
    label: 'HUNTING',
    description: 'Hunting Party',
    rallyPointLabel: 'Rally',
    baseLabel: 'Truck',
    markerLabel: 'Stand',
  ),
  training(
    id: 'training',
    label: 'TRAINING',
    description: 'Training Exercise',
    rallyPointLabel: 'Objective',
    baseLabel: 'Start Point',
    markerLabel: 'Checkpoint',
  );

  final String id;
  final String label;
  final String description;
  final String rallyPointLabel;
  final String baseLabel;
  final String markerLabel;

  const OperationalMode({
    required this.id,
    required this.label,
    required this.description,
    required this.rallyPointLabel,
    required this.baseLabel,
    required this.markerLabel,
  });
}

/// Team role assigned to a peer in a Field Link session
enum TeamRole {
  lead,
  scout,
  medic,
  comms,
  custom;

  static TeamRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lead':
        return TeamRole.lead;
      case 'medic':
        return TeamRole.medic;
      case 'comms':
        return TeamRole.comms;
      case 'custom':
        return TeamRole.custom;
      case 'scout':
      default:
        return TeamRole.scout;
    }
  }

  String toShortString() => name;

  String get displayName {
    switch (this) {
      case TeamRole.lead:
        return 'Lead';
      case TeamRole.scout:
        return 'Scout';
      case TeamRole.medic:
        return 'Medic';
      case TeamRole.comms:
        return 'Comms';
      case TeamRole.custom:
        return 'Custom';
    }
  }

  bool get isLead => this == TeamRole.lead;
}

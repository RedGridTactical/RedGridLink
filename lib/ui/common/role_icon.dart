import 'package:flutter/material.dart';
import 'package:red_grid_link/data/models/team_role.dart';

/// Maps a [TeamRole] to a Material icon for display in rosters and markers.
IconData iconForRole(TeamRole role) {
  switch (role) {
    case TeamRole.lead:
      return Icons.star;
    case TeamRole.scout:
      return Icons.explore;
    case TeamRole.medic:
      return Icons.medical_services;
    case TeamRole.comms:
      return Icons.cell_tower;
    case TeamRole.custom:
      return Icons.person;
  }
}

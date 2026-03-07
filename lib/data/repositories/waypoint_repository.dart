import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/waypoint.dart';

/// Repository for saved waypoints using SharedPreferences.
///
/// Waypoints are personal navigation aids — lightweight and local-only.
/// Stored as a JSON array under a single key.
class WaypointRepository {
  final SharedPreferences _prefs;

  static const _key = 'saved_waypoints';

  WaypointRepository(this._prefs);

  /// Load all saved waypoints, sorted by creation date (newest first).
  List<Waypoint> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final waypoints = list
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList();
      waypoints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return waypoints;
    } catch (_) {
      return [];
    }
  }

  /// Save a new waypoint.
  Future<void> add(Waypoint waypoint) async {
    final list = getAll();
    list.insert(0, waypoint);
    await _persist(list);
  }

  /// Remove a waypoint by ID.
  Future<void> remove(String id) async {
    final list = getAll();
    list.removeWhere((w) => w.id == id);
    await _persist(list);
  }

  /// Rename a waypoint.
  Future<void> rename(String id, String newName) async {
    final list = getAll();
    final index = list.indexWhere((w) => w.id == id);
    if (index >= 0) {
      list[index] = list[index].copyWith(name: newName);
      await _persist(list);
    }
  }

  Future<void> _persist(List<Waypoint> list) async {
    final json = jsonEncode(list.map((w) => w.toJson()).toList());
    await _prefs.setString(_key, json);
  }
}

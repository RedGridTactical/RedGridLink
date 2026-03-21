import 'dart:convert';

import 'package:red_grid_link/data/models/aar_data.dart';

/// Result of a session import attempt.
class ImportResult {
  /// The parsed session data (non-null on success).
  final AarData? data;

  /// Human-readable error message (non-null on failure).
  final String? error;

  const ImportResult.success(this.data) : error = null;
  const ImportResult.failure(this.error) : data = null;

  bool get isSuccess => data != null;
}

/// Imports session data from the portable JSON format produced by
/// [SessionExporter].
///
/// Validates the version tag, required fields, and coordinate ranges
/// before returning a fully hydrated [AarData].
class SessionImporter {
  static const _supportedVersions = ['1.3'];

  /// Parse and validate a JSON string into [AarData].
  ///
  /// Returns [ImportResult.success] with the deserialized data or
  /// [ImportResult.failure] with a descriptive error message.
  static ImportResult importFromJson(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;

      // --- Version check ---
      final version = map['version'] as String?;
      if (version == null || !_supportedVersions.contains(version)) {
        return ImportResult.failure(
          'Unsupported version: $version. '
          'Supported: ${_supportedVersions.join(", ")}',
        );
      }

      // --- Session payload ---
      final session = map['session'] as Map<String, dynamic>?;
      if (session == null) {
        return const ImportResult.failure('Missing session data');
      }

      // Deserialize through AarData.fromJson which already handles all
      // sub-model parsing (peers, markers, annotations, trackPoints,
      // boundary, boundaryEvents).
      final aarData = AarData.fromJson(session);

      // --- Coordinate validation ---
      for (final tp in aarData.trackPoints) {
        if (tp.lat < -90 || tp.lat > 90 || tp.lon < -180 || tp.lon > 180) {
          return const ImportResult.failure(
            'Invalid coordinates in track points',
          );
        }
      }
      for (final m in aarData.markers) {
        if (m.lat < -90 || m.lat > 90 || m.lon < -180 || m.lon > 180) {
          return const ImportResult.failure('Invalid coordinates in markers');
        }
      }

      return ImportResult.success(aarData);
    } on FormatException {
      return const ImportResult.failure('Invalid JSON format');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }
}

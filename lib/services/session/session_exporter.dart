import 'dart:convert';

import 'package:red_grid_link/data/models/aar_data.dart';

/// Exports session data to a portable JSON format.
///
/// The export envelope wraps the [AarData.toJson] payload with a version
/// tag and timestamp so the [SessionImporter] can validate compatibility
/// on the receiving end.
class SessionExporter {
  static const _version = '1.3';

  /// Serialize a session's [AarData] to a pretty-printed JSON string.
  static String exportToJson(AarData data) {
    final map = <String, dynamic>{
      'version': _version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'session': data.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Generate a sanitized filename for the export.
  ///
  /// Format: `redgridlink_session_{name}_{YYYY-MM-DD}.json`
  static String generateFilename(String sessionName) {
    final date = DateTime.now().toIso8601String().split('T').first;
    final safeName = sessionName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return 'redgridlink_session_${safeName}_$date.json';
  }
}

/// Geospatial unit conversion and formatting utilities.
///
/// Pure math — no external dependencies, no network, no storage.

// ---------------------------------------------------------------------------
// Unit conversions
// ---------------------------------------------------------------------------

/// Convert meters to feet.
double metersToFeet(double m) => m * 3.28084;

/// Convert feet to meters.
double feetToMeters(double ft) => ft / 3.28084;

/// Convert meters to statute miles.
double metersToMiles(double m) => m / 1609.344;

/// Convert statute miles to meters.
double milesToMeters(double mi) => mi * 1609.344;

/// Convert kilometers per hour to miles per hour.
double kphToMph(double kph) => kph * 0.621371;

/// Convert miles per hour to kilometers per hour.
double mphToKph(double mph) => mph / 0.621371;

// ---------------------------------------------------------------------------
// Coordinate formatting
// ---------------------------------------------------------------------------

/// Format a decimal-degree value to degrees, minutes, seconds with
/// hemisphere prefix.
///
/// [deg] Decimal degrees (positive or negative).
/// [isLat] If true, uses N/S; if false, uses E/W.
/// Returns formatted string, e.g. `N 38° 53' 12.4"`.
String formatCoordinate(double deg, bool isLat) {
  final String hemisphere;
  if (isLat) {
    hemisphere = deg >= 0 ? 'N' : 'S';
  } else {
    hemisphere = deg >= 0 ? 'E' : 'W';
  }

  final double absDeg = deg.abs();
  final int degrees = absDeg.floor();
  final double minFull = (absDeg - degrees) * 60;
  final int minutes = minFull.floor();
  final double seconds = (minFull - minutes) * 60;

  return "$hemisphere $degrees\u00B0 $minutes' ${seconds.toStringAsFixed(1)}\"";
}

/// Parse a DMS (degrees, minutes, seconds) string to decimal degrees.
///
/// Accepts various formats:
///   - `N 38° 53' 51.7"`
///   - `38 53 51.7`
///   - `38° 53' 51.7" N`
///   - `S 33° 52' 7.7"`
///
/// A leading or trailing S or W makes the result negative.
/// Returns null if the string cannot be parsed.
double? parseDMS(String dms) {
  if (dms.trim().isEmpty) return null;

  // Detect hemisphere
  final upper = dms.toUpperCase().trim();
  final bool isNegative = upper.startsWith('S') ||
      upper.startsWith('W') ||
      upper.endsWith('S') ||
      upper.endsWith('W');

  // Strip hemisphere letters and symbols, leaving only numbers and separators
  final cleaned = dms
      .replaceAll(RegExp(r'[NSEW]', caseSensitive: false), '')
      .replaceAll(RegExp('[°\u00B0\u2032\u2033\'"]'), ' ')
      .trim();

  final parts =
      cleaned.split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .toList();

  if (parts.isEmpty || parts.length > 3) return null;

  final d = double.tryParse(parts[0]);
  if (d == null) return null;

  final m = parts.length > 1 ? double.tryParse(parts[1]) : 0.0;
  final s = parts.length > 2 ? double.tryParse(parts[2]) : 0.0;
  if (m == null || s == null) return null;

  double result = d.abs() + m / 60 + s / 3600;
  if (isNegative || d < 0) result = -result.abs();

  return result;
}

// ---------------------------------------------------------------------------
// Compass direction
// ---------------------------------------------------------------------------

/// Convert a bearing (0-360) to an 8-point compass direction string.
///
/// Returns one of: "N", "NE", "E", "SE", "S", "SW", "W", "NW".
String compassDirection(double bearing) {
  // Normalize to 0-360
  final double normalized = ((bearing % 360) + 360) % 360;

  const List<String> directions = [
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW',
  ];

  // Each sector is 45 degrees; offset by half a sector (22.5) so that
  // 0 degrees maps to "N" for the range 337.5 - 22.5.
  final int index = ((normalized + 22.5) / 45).floor() % 8;
  return directions[index];
}

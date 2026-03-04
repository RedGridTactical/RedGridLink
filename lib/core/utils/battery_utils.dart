/// Battery projection and formatting utilities.
///
/// Provides remaining-time estimation based on current level and drain rate,
/// plus mode-specific drain rate constants.

// ---------------------------------------------------------------------------
// Drain rate constants (percent per hour, approximate)
// ---------------------------------------------------------------------------

/// Return the estimated battery drain rate (% per hour) for a given
/// operational mode string.
///
/// Modes:
/// - "expedition" / "low_power": ~0.5% per hour (GPS off, minimal BLE)
/// - "active" / "standard": ~2% per hour (GPS + BLE beacon)
/// - "high_accuracy": ~4% per hour (continuous GPS + frequent BLE)
///
/// Defaults to the "active" rate if the mode is unrecognized.
int drainRateForMode(String mode) {
  switch (mode.toLowerCase()) {
    case 'expedition':
    case 'low_power':
      // GPS off, minimal BLE — roughly 0.5%/hr.
      // Stored as int tenths to avoid floating-point; callers expecting
      // whole-percent should treat 1 as the floor.
      return 1; // ~0.5-1%/hr, rounded up for safety
    case 'active':
    case 'standard':
      return 2; // ~2%/hr
    case 'high_accuracy':
      return 4; // ~4%/hr
    default:
      return 2;
  }
}

// ---------------------------------------------------------------------------
// Estimation
// ---------------------------------------------------------------------------

/// Estimate remaining battery time based on current level and drain rate.
///
/// [currentLevel] Battery percentage (0-100).
/// [drainRatePerHour] Percent drained per hour (must be > 0).
/// Returns estimated remaining Duration, or null if inputs are invalid.
Duration? estimateRemainingTime(int currentLevel, int drainRatePerHour) {
  if (currentLevel <= 0 || drainRatePerHour <= 0) return null;
  if (currentLevel > 100) return null;

  final double hours = currentLevel / drainRatePerHour;
  final int totalMinutes = (hours * 60).round();
  return Duration(minutes: totalMinutes);
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

/// Format a battery remaining Duration to a human-readable string.
///
/// Returns "8hr 12min remaining", "45min remaining", or "Unknown".
String formatBatteryTime(Duration? remaining) {
  if (remaining == null) return 'Unknown';

  final int totalMinutes = remaining.inMinutes;
  if (totalMinutes <= 0) return 'Depleted';

  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;

  if (hours == 0) return '${minutes}min remaining';
  if (minutes == 0) return '${hours}hr remaining';
  return '${hours}hr ${minutes}min remaining';
}

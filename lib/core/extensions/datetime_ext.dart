/// DateTime extensions for tactical time formatting.
///
/// Provides UTC ISO 8601, relative time strings, military DTG format,
/// and staleness checks.

extension DateTimeExtensions on DateTime {
  /// Always returns UTC ISO 8601 string regardless of source timezone.
  ///
  /// Example: "2026-03-02T14:30:00.000Z"
  String toIso8601Utc() {
    return toUtc().toIso8601String();
  }

  /// Returns a human-readable relative time string.
  ///
  /// Examples: "just now", "2m ago", "1hr ago", "3d ago", "2w ago"
  String toRelativeString() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.isNegative) return 'in the future';
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}yr ago';
  }

  /// Returns military Date-Time Group (DTG) format.
  ///
  /// Example: "02MAR26 1430Z"
  String toTacticalFormat() {
    final utc = toUtc();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final day = utc.day.toString().padLeft(2, '0');
    final month = months[utc.month - 1];
    final year = (utc.year % 100).toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    return '$day$month$year ${hour}${minute}Z';
  }

  /// Returns true if this DateTime is older than [threshold] from now.
  ///
  /// Useful for marking stale position data or expired sessions.
  bool isStale(Duration threshold) {
    return DateTime.now().difference(this) > threshold;
  }
}

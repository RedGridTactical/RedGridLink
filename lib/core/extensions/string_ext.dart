/// String extensions for validation and formatting.
///
/// Provides truncation, title casing, PIN validation, and MGRS pattern checks.

extension StringExtensions on String {
  /// Truncate this string to [maxLength] characters, appending ellipsis if
  /// the string exceeds the limit.
  ///
  /// Returns the original string if it fits within [maxLength].
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    if (maxLength <= 3) return substring(0, maxLength);
    return '${substring(0, maxLength - 3)}...';
  }

  /// Convert this string to title case (capitalize the first letter of
  /// each word).
  ///
  /// Example: "hello world" -> "Hello World"
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Check if this string is a valid 4-digit PIN.
  ///
  /// Returns true if the string is exactly 4 decimal digits.
  bool isValidPin() {
    return RegExp(r'^\d{4}$').hasMatch(this);
  }

  /// Check if this string matches a basic MGRS coordinate pattern.
  ///
  /// Validates the general structure: 1-2 digit zone number, zone letter,
  /// 2-letter grid square identifier, and even-length numeric easting/northing
  /// (2-10 digits).
  ///
  /// This is a structural check only -- it does not verify that the
  /// coordinate resolves to a real location.
  bool isValidMGRS() {
    // Pattern: 1-2 digit zone, band letter (C-X excluding I/O),
    // 2 grid square letters (A-Z excluding I/O), even-count digits (2-10)
    return RegExp(
      r'^(\d{1,2})([C-HJ-NP-X])([A-HJ-NP-Z]{2})(\d{2}|\d{4}|\d{6}|\d{8}|\d{10})$',
      caseSensitive: false,
    ).hasMatch(replaceAll(RegExp(r'\s+'), '').toUpperCase());
  }
}

/// UUID v4 generation wrapper.
///
/// Provides a singleton [Uuid] instance and a simple top-level function
/// for generating unique identifiers throughout the app.

import 'package:uuid/uuid.dart';

/// Singleton UUID generator instance.
const Uuid _uuid = Uuid();

/// Generate a new random UUID v4 string.
///
/// Example: "550e8400-e29b-41d4-a716-446655440000"
String generateV4() {
  return _uuid.v4();
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_exceptions.dart';

/// Centralised error handler for Red Grid Link.
///
/// In debug builds every error is printed to the console with its stack trace.
/// In release builds errors are forwarded to Sentry for crash reporting
/// (configured in `main.dart` with privacy-safe location stripping).
class ErrorHandler {
  ErrorHandler._(); // prevent instantiation

  /// Handle an error: log it (debug) and forward to Sentry (release).
  static void handleError(Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('=== Red Grid Link Error ===');
      debugPrint('Type : ${error.runtimeType}');
      debugPrint('Detail: $error');
      if (stack != null) {
        debugPrint('Stack :\n$stack');
      }
      debugPrint('=========================');
    }

    // Forward to Sentry in release builds.
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stack);
    }
  }

  /// Return a short, user-facing message suitable for a snackbar or dialog.
  static String getUserMessage(Object error) {
    if (error is MgrsException) {
      return 'Grid reference error: ${error.message}';
    }
    if (error is LocationException) {
      return 'Location error: ${error.message}';
    }
    if (error is MapException) {
      return 'Map error: ${error.message}';
    }
    if (error is TransportException) {
      return 'Connection error: ${error.message}';
    }
    if (error is SyncException) {
      return 'Sync error: ${error.message}';
    }
    if (error is SecurityException) {
      return 'Security error: ${error.message}';
    }
    if (error is StorageException) {
      return 'Storage error: ${error.message}';
    }
    if (error is EntitlementException) {
      return 'Feature not available: ${error.message}';
    }
    if (error is FieldLinkException) {
      return 'Field-link error: ${error.message}';
    }
    if (error is AppException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Operation timed out. Check your connection and try again.';
    }
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Tiny structured logger that replaces ad-hoc `print()` calls in production
/// code paths. Release builds drop debug-level output entirely so transport
/// traces, GPS first-fix lines, and other operational chatter never appear in
/// device logs that bystanders or attached debuggers can capture.
///
/// Audit 2026-05-03 P1 fix: previously `print(...)` calls in
/// FieldLinkService, BleTransport, IosP2pTransport, LocationService and
/// SyncEngine all printed in release mode, including locations and BLE peer
/// IDs. Replacing them with this logger gives a single chokepoint we can
/// later route to a redacted in-app diagnostics buffer.
///
/// Usage:
///   RedLog.d('FieldLink', 'Creator auto-connecting to ${device.id}');
///   RedLog.w('BleTransport', 'peripheral broadcast failed', e);
///   RedLog.e('SyncEngine', 'decode failed', e, st);
///
/// Caller policy:
///   - Never log raw GPS coordinates or peer locations — log only counts,
///     accuracy class, or rounded values.
///   - Never log encryption keys, PINs, QR session secrets, or auth tokens.
///   - Prefer a tag that matches the originating subsystem so downstream
///     diagnostics filtering is straightforward.

import 'package:flutter/foundation.dart';

/// Structured logger. All methods are no-ops in release mode unless the
/// caller has explicitly opted into release-mode emission.
class RedLog {
  RedLog._();

  /// Debug-level: high-volume operational tracing. Drop in release.
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Info-level: notable lifecycle events (session create, transport up).
  /// Visible in debug builds; suppressed in release.
  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag][i] $message');
    }
  }

  /// Warning-level: recoverable error or unexpected state. Visible in
  /// debug; suppressed in release. Optional [error] is included when
  /// supplied so the message is self-contained at the call site.
  static void w(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('[$tag][w] $message — $error');
      } else {
        debugPrint('[$tag][w] $message');
      }
    }
  }

  /// Error-level: caught exceptions and unrecoverable conditions. Visible
  /// in debug; suppressed in release. The optional [stackTrace] is
  /// included when supplied to make the call site fully self-contained.
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      final buf = StringBuffer('[$tag][e] $message');
      if (error != null) buf.write(' — $error');
      if (stackTrace != null) buf.write('\n$stackTrace');
      debugPrint(buf.toString());
    }
  }
}

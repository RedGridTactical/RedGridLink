// Driver script for screenshots_test.dart.
//
// Uses integration_test's `writeResponseData` hook to persist PNG bytes
// captured by `binding.takeScreenshot(name)` into ./screenshots/<device>/
// on the host filesystem.
//
// The device subfolder is passed via the DEVICE_TARGET env var so
// iPhone and iPad runs land in separate folders.
//
// Usage (invoked by tools/capture_screenshots.sh):
//   flutter drive \
//     --driver=integration_test/test_driver/screenshot_driver.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d <simulator>

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Device folder comes from DEVICE_TARGET. Defaults to 'unknown'.
  final device = Platform.environment['DEVICE_TARGET'] ?? 'unknown';
  final outDir = Directory('screenshots/$device');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [dynamic args]) async {
      final file = File('${outDir.path}/$name.png');
      file.writeAsBytesSync(bytes);
      // Echo to driver stdout so it's visible in the capture log.
      stdout.writeln('✓ captured ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}

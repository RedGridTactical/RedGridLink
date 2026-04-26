#!/usr/bin/env bash
# Red Grid Link — Android emulator screenshot capture.
#
# Runs the integration_test/screenshots_test.dart on the RedGridDev emulator
# and saves 8 raw PNGs to screenshots/raw_android/phone/.
#
# Usage:
#   tools/screenshots/capture-android.sh
#
# Prerequisites:
#   - RedGridDev AVD booted (emulator-5554)
#   - APK already installed (run once: adb install -r build/.../app-debug.apk)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

export PATH="$HOME/flutter/bin:/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"

ADB="/opt/homebrew/share/android-commandlinetools/platform-tools/adb"
DEVICE="emulator-5554"
OUT_DIR="screenshots/raw_android/phone"

# ── Preflight ──────────────────────────────────────────────────────────────

echo "Checking emulator state…"
if ! "$ADB" -s "$DEVICE" get-state 2>/dev/null | grep -q "^device$"; then
  echo "ERROR: $DEVICE not connected or not ready."
  echo "Boot the RedGridDev AVD first:"
  echo "  /opt/homebrew/share/android-commandlinetools/emulator/emulator -avd RedGridDev &"
  exit 1
fi
echo "  ✓ $DEVICE ready"

# ── Clean output ───────────────────────────────────────────────────────────

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# ── Capture ────────────────────────────────────────────────────────────────

echo
echo "Running flutter drive on $DEVICE…"
echo "  Output → $OUT_DIR"
echo

DEVICE_TARGET="raw_android/phone" flutter drive \
  --driver=integration_test/test_driver/screenshot_driver.dart \
  --target=integration_test/screenshots_test.dart \
  -d "$DEVICE" \
  --no-pub

# ── Report ─────────────────────────────────────────────────────────────────

echo
echo "Raw Android phone screenshots:"
ls -lh "$OUT_DIR" 2>/dev/null || echo "  (empty — check flutter drive output above)"

echo
echo "Next step: node tools/screenshots/render-android.js"

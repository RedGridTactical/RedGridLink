#!/usr/bin/env bash
# Red Grid Link — App Store screenshot capture.
#
# Boots iPhone 17 Pro Max + iPad Pro 13" M5 simulators, runs the
# integration screenshot test on each, and lands raw PNGs in
# screenshots/<device>/.
#
# Usage:
#   tools/screenshots/capture.sh            # both devices
#   tools/screenshots/capture.sh iphone     # iphone only
#   tools/screenshots/capture.sh ipad       # ipad only

set -euo pipefail

# ---- paths ----
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

export PATH="$HOME/flutter/bin:$PATH"
export LANG="en_US.UTF-8"

# ---- simulators (newest available per 2026-04-11) ----
IPHONE_UDID="$(xcrun simctl list devices 'iPhone 17 Pro Max' | grep -oE '[0-9A-F-]{36}' | head -1)"
IPAD_UDID="$(xcrun simctl list devices 'iPad Pro 13-inch (M5)' | grep -oE '[0-9A-F-]{36}' | head -1)"

if [[ -z "$IPHONE_UDID" ]]; then
  echo "ERROR: iPhone 17 Pro Max simulator not found. Open Xcode and create one first."
  exit 1
fi
if [[ -z "$IPAD_UDID" ]]; then
  echo "ERROR: iPad Pro 13-inch (M5) simulator not found."
  exit 1
fi

run_capture() {
  local device_name="$1"
  local udid="$2"
  local folder="$3"

  echo
  echo "===================================================================="
  echo "  Capturing $device_name (UDID: $udid)"
  echo "===================================================================="

  # Boot simulator if needed
  xcrun simctl boot "$udid" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$udid"

  # Wait for simulator to finish booting
  xcrun simctl bootstatus "$udid" -b

  # Clean old captures for this device
  rm -rf "screenshots/$folder"
  mkdir -p "screenshots/$folder"

  # Run the drive test
  DEVICE_TARGET="$folder" flutter drive \
    --driver=integration_test/test_driver/screenshot_driver.dart \
    --target=integration_test/screenshots_test.dart \
    -d "$udid" \
    --no-pub

  echo
  echo "  Captures for $device_name:"
  ls -la "screenshots/$folder" || true
}

MODE="${1:-both}"

case "$MODE" in
  iphone)
    run_capture "iPhone 17 Pro Max" "$IPHONE_UDID" "iphone_17_pro_max"
    ;;
  ipad)
    run_capture "iPad Pro 13-inch M5" "$IPAD_UDID" "ipad_pro_13_m5"
    ;;
  both)
    run_capture "iPhone 17 Pro Max" "$IPHONE_UDID" "iphone_17_pro_max"
    run_capture "iPad Pro 13-inch M5" "$IPAD_UDID" "ipad_pro_13_m5"
    ;;
  *)
    echo "Usage: $0 [iphone|ipad|both]"
    exit 1
    ;;
esac

echo
echo "✓ Capture complete. Raw PNGs in screenshots/"
echo "  Next: run tools/screenshots/frame.py to add bezels + captions"

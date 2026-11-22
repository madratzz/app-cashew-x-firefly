#!/usr/bin/env bash
# Runs the attachment round trip on macOS or a booted iOS simulator against the
# emulated Firefly server (hosted macOS runners have no Docker).
# Usage: attachments-smoke.sh <macos|ios>
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root/budget"
test_file=integration_test/final/attachments_device_test.dart
if [[ "$1" == macos ]]; then
  device=macos
  flutter build macos --debug -t "$test_file"
else
  device="$(xcrun simctl list devices available -j |
    jq -r '[.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | test("^iPhone"))][0].udid')"
  xcrun simctl boot "$device"
  xcrun simctl bootstatus "$device" -b
  flutter build ios --simulator --debug -t "$test_file"
fi
log="${RUNNER_TEMP:-/tmp}/attachments-smoke.log"
if ! flutter test "$test_file" -d "$device" > "$log" 2>&1; then
  grep -v "Localization key" "$log" | tail -150
  exit 1
fi
grep -E "All tests passed|tests? passed" "$log" | tail -3

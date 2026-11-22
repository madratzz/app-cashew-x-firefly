#!/usr/bin/env bash
# Runs the TokenStore smoke test on macOS or a booted iOS simulator.
# Usage: keychain-smoke.sh <macos|ios>
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cp "$root/scripts/ci/integration_test/token_store_smoke_test.dart" "$root/budget/integration_test/"
cd "$root/budget"
if [[ "$1" == macos ]]; then
  device=macos
else
  device="$(xcrun simctl list devices available -j |
    jq -r '[.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | test("^iPhone"))][0].udid')"
  xcrun simctl boot "$device"
  xcrun simctl bootstatus "$device" -b
fi
log="${RUNNER_TEMP:-/tmp}/keychain-smoke.log"
if ! flutter test integration_test/token_store_smoke_test.dart -d "$device" --verbose > "$log" 2>&1; then
  grep -v "Localization key" "$log" | tail -150
  exit 1
fi
grep -E "All tests passed|tests? passed" "$log" | tail -3

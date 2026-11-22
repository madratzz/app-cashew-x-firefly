#!/usr/bin/env bash
# Launches the built macOS app and fails if it exits within 10 seconds.
# Usage: macos-smoke.sh <debug|release>
set -euo pipefail
if [[ "$1" == release ]]; then Mode=Release; else Mode=Debug; fi
app="$(ls -d budget/build/macos/Build/Products/$Mode/*.app | head -n1)"
codesign -d --entitlements - "$app" 2>/dev/null || true
exe="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
"$exe" &
pid=$!
sleep 10
if ! kill -0 "$pid" 2>/dev/null; then
  wait "$pid" || echo "app exited with status $?"
  log show --last 1m --predicate 'process == "amfid" OR eventMessage CONTAINS "AMFI"' | tail -20 || true
  exit 1
fi
kill "$pid"
echo "app stayed up for 10 s"

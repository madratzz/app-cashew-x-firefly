#!/usr/bin/env bash
# Launches the built Linux bundle under Xvfb and fails if it exits within 10 s.
# Usage: linux-smoke.sh <debug|release>
set -euo pipefail
bundle="budget/build/linux/x64/$1/bundle"
exe="$bundle/$(sed -nE 's/^set\(BINARY_NAME "([^"]+)"\)/\1/p' budget/linux/CMakeLists.txt)"
test -x "$exe"
log="${RUNNER_TEMP:-/tmp}/linux-smoke.log"
xvfb-run --auto-servernum --server-args='-screen 0 1280x800x24' "$exe" >"$log" 2>&1 &
pid=$!
sleep 10
if ! kill -0 "$pid" 2>/dev/null; then
  wait "$pid" || echo "app exited with status $?"
  tail -50 "$log"
  exit 1
fi
kill "$pid"
wait "$pid" 2>/dev/null || true
echo "app stayed up for 10 s"

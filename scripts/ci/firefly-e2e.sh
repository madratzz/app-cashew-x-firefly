#!/usr/bin/env bash
# Starts the disposable Docker Firefly III and runs every live suite against
# it: the Phase 1, 2 and 3 host suites, then the attachment round trip on a
# device. The minted token is masked in the log; the stack is always destroyed.
# Usage: firefly-e2e.sh <host|linux|android>
#   host     the three live host suites, the A1-A7 probe, then the
#            attachment test on Linux desktop under Xvfb
#   android  only the attachment test on a booted Android emulator, which
#            reaches the server through `adb reverse`
set -euo pipefail
target="${1:-host}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
trap '"$root/docker/firefly/down.sh" >/dev/null 2>&1 || true' EXIT
exports="$("$root/docker/firefly/up.sh")"
token="$(sed -n 's/^export FIREFLY_E2E_TOKEN=//p' <<<"$exports")"
echo "::add-mask::$token"
eval "$exports"
test -n "${FIREFLY_E2E_URL:-}" && test -n "${FIREFLY_E2E_TOKEN:-}"
cd "$root/budget"
defines=(--dart-define=FIREFLY_ALLOW_HTTP=true
  "--dart-define=FIREFLY_E2E_URL=$FIREFLY_E2E_URL"
  "--dart-define=FIREFLY_E2E_TOKEN=$FIREFLY_E2E_TOKEN")
attachments=integration_test/final/attachments_device_test.dart

if [[ "$target" == host ]]; then
  # One live suite at a time; each deletes what it created.
  for suite in test/firefly/e2e/live_e2e_test.dart \
    test/firefly/e2e/phase2/live_phase2_e2e_test.dart \
    test/firefly/e2e/phase3/live_phase3_e2e_test.dart; do
    echo "::group::$suite"
    flutter test --dart-define=FIREFLY_ALLOW_HTTP=true --reporter expanded "$suite"
    echo "::endgroup::"
  done
  # The probe writes and removes its own fixtures, so it runs after the
  # suites that need an empty server.
  echo "::group::A1-A7 probe"
  FIREFLY_BASE_URL=$FIREFLY_E2E_URL FIREFLY_API_TOKEN=$FIREFLY_E2E_TOKEN \
    python3 -I tool/firefly_probe/probe.py --disposable --container cashew-firefly-e2e-app-1
  echo "::endgroup::"
  echo "::group::$attachments (linux)"
  xvfb-run --auto-servernum --server-args='-screen 0 1280x800x24' \
    flutter test "${defines[@]}" --reporter expanded "$attachments" -d linux
  echo "::endgroup::"
else
  port="${FIREFLY_E2E_URL##*:}"
  adb reverse "tcp:$port" "tcp:$port"
  flutter test "${defines[@]}" --reporter expanded "$attachments" \
    -d "$(adb devices | awk 'NR == 2 { print $1 }')"
fi

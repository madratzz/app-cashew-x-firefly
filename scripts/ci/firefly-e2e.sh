#!/usr/bin/env bash
# Starts the disposable Docker Firefly III from WP-19 and runs the live E2E
# suite against it. The minted token is masked in the log; the stack is always
# destroyed.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
trap '"$root/docker/firefly/down.sh" >/dev/null 2>&1 || true' EXIT
exports="$("$root/docker/firefly/up.sh")"
token="$(sed -n 's/^export FIREFLY_E2E_TOKEN=//p' <<<"$exports")"
echo "::add-mask::$token"
eval "$exports"
test -n "${FIREFLY_E2E_URL:-}" && test -n "${FIREFLY_E2E_TOKEN:-}"
cd "$root/budget"
flutter test --dart-define=FIREFLY_ALLOW_HTTP=true --reporter expanded test/firefly/e2e/live_e2e_test.dart

#!/bin/sh
# Starts a disposable Firefly III 6.6.2, creates a throwaway user and mints a
# personal access token (assumption A7). Prints the export lines for the E2E
# suite on stdout. Nothing is written to disk; `down.sh` destroys everything.
set -eu
cd "$(dirname "$0")"
rand() { head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c "$1"; }
export FIREFLY_E2E_PORT="${FIREFLY_E2E_PORT:-8089}"
export FIREFLY_E2E_DB_PASSWORD="$(rand 24)"
export FIREFLY_E2E_APP_KEY="$(rand 32)"
docker compose -p cashew-firefly-e2e up -d --wait >&2
compose() { docker compose -p cashew-firefly-e2e "$@"; }
# 6.6.2 has several firefly-iii:verify* commands; the bare name is ambiguous.
until compose exec -T app php artisan firefly-iii:verify-database-connection >/dev/null 2>&1; do sleep 3; done
email="e2e-$(rand 8)@example.invalid"
password="$(rand 24)"
# The image has no tinker, so a small script creates the owner and the token.
# It must be world-readable inside the container.
chmod 644 mint.php
compose cp mint.php app:/tmp/cashew-mint.php >&2
token="$(compose exec -T app php /tmp/cashew-mint.php "$email" "$password" | tail -n 1)"
# docker cp leaves the file owned by the host user, so remove it as root.
compose exec -T -u root app rm -f /tmp/cashew-mint.php >&2
# Creates the new user's default user group and repairs related rows.
compose exec -T app php artisan firefly-iii:correct-database >&2
[ -n "$token" ] || { echo "token creation failed (A7)" >&2; exit 1; }
echo "export FIREFLY_E2E_URL=http://127.0.0.1:$FIREFLY_E2E_PORT"
echo "export FIREFLY_E2E_TOKEN=$token"

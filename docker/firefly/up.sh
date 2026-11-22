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
until docker compose -p cashew-firefly-e2e exec -T app php artisan firefly-iii:verify >/dev/null 2>&1; do sleep 3; done
email="e2e-$(rand 8)@example.invalid"
password="$(rand 24)"
token="$(docker compose -p cashew-firefly-e2e exec -T app php artisan tinker --execute "
\$u = FireflyIII\\User::create(['email' => '$email', 'password' => bcrypt('$password'), 'blocked' => false]);
\$u->roles()->attach(FireflyIII\\Models\\Role::where('name','owner')->first());
app(FireflyIII\\Repositories\\User\\UserRepositoryInterface::class)->createDefaultGroups(\$u);
if (!Laravel\\Passport\\Client::where('personal_access_client', true)->exists()) {
  Artisan::call('passport:client', ['--personal' => true, '--name' => 'e2e', '--no-interaction' => true]);
}
echo \$u->createToken('e2e')->accessToken;
" | tail -n 1)"
[ -n "$token" ] || { echo "token creation failed (A7)" >&2; exit 1; }
echo "export FIREFLY_E2E_URL=http://127.0.0.1:$FIREFLY_E2E_PORT"
echo "export FIREFLY_E2E_TOKEN=$token"

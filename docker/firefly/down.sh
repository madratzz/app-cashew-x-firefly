#!/bin/sh
# Destroys the disposable instance and its in-memory database.
set -eu
cd "$(dirname "$0")"
FIREFLY_E2E_DB_PASSWORD=x FIREFLY_E2E_APP_KEY=x docker compose -p cashew-firefly-e2e down -v --remove-orphans

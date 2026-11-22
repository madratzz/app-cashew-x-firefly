#!/usr/bin/env bash
# Installs the Flutter version pinned in budget/.fvmrc and puts it on PATH.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
version="$(jq -er '.flutter' "$root/budget/.fvmrc")"
dest="${RUNNER_TEMP:-/tmp}/flutter"
git clone --depth 1 --branch "$version" https://github.com/flutter/flutter.git "$dest"
echo "$dest/bin" >> "$GITHUB_PATH"
"$dest/bin/flutter" --version

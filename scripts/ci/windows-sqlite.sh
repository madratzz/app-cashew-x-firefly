#!/usr/bin/env bash
# Host-side `flutter test` opens sqlite3.dll via dart:ffi; Windows runners lack it.
set -euo pipefail
dir="$RUNNER_TEMP/sqlite"
mkdir -p "$dir"
curl -fsSL -o "$dir/sqlite.zip" https://www.sqlite.org/2024/sqlite-dll-win-x64-3460100.zip
7z x -y -o"$dir" "$dir/sqlite.zip" >/dev/null
cygpath -w "$dir" >> "$GITHUB_PATH"

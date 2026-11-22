#!/usr/bin/env bash
# Collects one target's build output into dist/. Usage: package.sh <target> <debug|release>
set -euo pipefail
target="$1"; mode="$2"
root="$(cd "$(dirname "$0")/../.." && pwd)"
build="$root/budget/build"
dist="$root/dist"
mkdir -p "$dist"
name="cashew-$target-$mode"
if [[ "$mode" == release ]]; then Mode=Release; else Mode=Debug; fi
case "$target" in
  android)
    cp "$build/app/outputs/flutter-apk/app-$mode.apk" "$dist/$name.apk"
    if [[ "$mode" == release ]]; then
      cp "$build/app/outputs/bundle/release/app-release.aab" "$dist/$name.aab"
    fi ;;
  ios)
    staging="$(mktemp -d)"; mkdir "$staging/Payload"
    cp -R "$build/ios/iphoneos/Runner.app" "$staging/Payload/"
    (cd "$staging" && zip -qry "$dist/$name-unsigned.ipa" Payload) ;;
  macos)
    app="$(ls -d "$build/macos/Build/Products/$Mode"/*.app | head -n1)"
    ditto -c -k --keepParent "$app" "$dist/$name.zip" ;;
  linux)
    tar -czf "$dist/$name.tar.gz" -C "$build/linux/x64/$mode" bundle ;;
  windows)
    (cd "$build/windows/x64/runner/$Mode" && 7z a -tzip "$dist/$name.zip" . >/dev/null) ;;
  *) echo "unknown target $target" >&2; exit 1 ;;
esac
ls -l "$dist"

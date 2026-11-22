#!/usr/bin/env bash
# keychain-access-groups needs a real Team ID and provisioning profile. An
# ad-hoc signed app that carries it is killed by AMFI at launch, so drop it
# from the working copy unless APPLE_TEAM_ID is configured.
set -euo pipefail
if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
  echo "APPLE_TEAM_ID set; keeping keychain-access-groups"
  exit 0
fi
echo "::warning::APPLE_TEAM_ID not set; building ad-hoc without keychain-access-groups"
for file in budget/macos/Runner/DebugProfile.entitlements budget/macos/Runner/Release.entitlements; do
  /usr/libexec/PlistBuddy -c 'Delete :keychain-access-groups' "$file" 2>/dev/null || true
done

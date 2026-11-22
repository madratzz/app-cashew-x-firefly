#!/usr/bin/env bash
# Writes budget/android/key.properties for release builds.
# Uses ANDROID_KEYSTORE_BASE64 and friends when set; otherwise a throwaway
# key so unsigned-by-us CI builds still assemble.
set -euo pipefail
android="$(cd "$(dirname "$0")/../../budget/android" && pwd)"
store="$RUNNER_TEMP/release.jks"
if [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$store"
  alias="$ANDROID_KEY_ALIAS"; storepass="$ANDROID_KEYSTORE_PASSWORD"; keypass="$ANDROID_KEY_PASSWORD"
else
  echo "::warning::ANDROID_KEYSTORE_BASE64 not set; signing with a throwaway CI key"
  alias=ci; storepass=cipassword; keypass=cipassword
  keytool -genkeypair -noprompt -keystore "$store" -alias "$alias" -keyalg RSA -keysize 2048 \
    -validity 365 -storepass "$storepass" -keypass "$keypass" -dname "CN=CI"
fi
cat > "$android/key.properties" <<PROPS
storeFile=$store
storePassword=$storepass
keyAlias=$alias
keyPassword=$keypass
PROPS

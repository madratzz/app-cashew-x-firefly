# Builds and releases

## Workflows

- `.github/workflows/build.yml` runs on every pull request and on manual dispatch. It builds Android (Ubuntu), iOS (`macos-15`, `--no-codesign`), macOS (`macos-15`), Linux (Ubuntu with GTK, libsecret, ninja, clang, cmake) and Windows (`windows-2022`; Flutter 3.19 only knows Visual Studio up to 2022), and runs `flutter test` on the macOS, Linux and Windows jobs. Pull requests build in debug mode; a manual dispatch can choose `release`.
- `.github/workflows/release.yml` runs on tags `v*`. It calls `build.yml` in release mode and attaches one artifact set per target to a new GitHub release:
  - `cashew-android-release.apk` and `cashew-android-release.aab`
  - `cashew-ios-release-unsigned.ipa` (unsigned `Payload/Runner.app`)
  - `cashew-macos-release.zip` (ad-hoc signed `.app`)
  - `cashew-linux-release.tar.gz` (the `bundle/` directory)
  - `cashew-windows-release.zip`

Flutter comes from `budget/.fvmrc` via `scripts/ci/install-flutter.sh`, so CI always matches the pinned version.

Manual run: `gh workflow run build.yml --ref <branch> -f mode=release`.

Cutting a release: `git tag v1.2.3 && git push origin v1.2.3`.

## Secrets

No signing material is in the repository. Configure these as GitHub Actions repository secrets; all are optional.

| Secret | Use |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the upload keystore (`base64 -i upload.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `APPLE_TEAM_ID` | Apple Team ID. When set, the macOS build keeps `keychain-access-groups`; when absent, CI removes it before the ad-hoc signed build |

When `ANDROID_KEYSTORE_BASE64` is absent, `scripts/ci/android-signing.sh` generates a throwaway key so release builds still assemble; such APKs cannot update a store install. iOS and macOS builds are unsigned (ad-hoc for macOS); Apple signing and notarisation are not wired yet. Windows builds are unsigned.

## Smoke checks

- The macOS job launches the built `.app` for 10 s and fails if it exits. An ad-hoc signed app that still carries `keychain-access-groups` is killed by AMFI at launch, so `scripts/ci/macos-entitlements.sh` removes that key from the working copy unless `APPLE_TEAM_ID` is set. The committed entitlements are unchanged.
- The Linux job launches the built bundle under `xvfb-run` for 10 s and fails if it exits.
- The iOS and macOS build jobs stand in for the owner-pending local Xcode builds (`flutter build macos --debug`, `flutter build ios --debug --no-codesign`).
- The `keychain-macos` and `keychain-ios` jobs run `scripts/ci/integration_test/token_store_smoke_test.dart` (copied into `budget/integration_test/` at CI time only) on macOS and on an iOS simulator. The test writes, reads and deletes the Firefly token through `TokenStore`.

## Live E2E (deferred)

The Docker Firefly III E2E job is deferred to WP-49 (orchestrator decision; `docker/firefly/up.sh` is being fixed in WP-39). `scripts/ci/firefly-e2e.sh` is ready for it: it starts the stack, masks the minted token, runs `test/firefly/e2e/live_e2e_test.dart` with `FIREFLY_ALLOW_HTTP=true` and always runs `down.sh`.

## Action pinning

Every action is pinned to a commit SHA with its version in a comment. Update a pin by resolving the new tag (`gh api repos/<owner>/<action>/commits/<tag> -q .sha`).

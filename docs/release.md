# Builds and releases

## Workflows

- `.github/workflows/build.yml` runs on every pull request and on manual dispatch. It builds Android (Ubuntu), iOS (`macos-15`, `--no-codesign`), macOS (`macos-15`), Linux (Ubuntu with GTK, libsecret, ninja, clang, cmake) and Windows (`windows-latest`), and runs `flutter test` on the macOS, Linux and Windows jobs. Pull requests build in debug mode; a manual dispatch can choose `release`.
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

When `ANDROID_KEYSTORE_BASE64` is absent, `scripts/ci/android-signing.sh` generates a throwaway key so release builds still assemble; such APKs cannot update a store install. iOS and macOS builds are unsigned (ad-hoc for macOS); Apple signing and notarisation are not wired yet. Windows builds are unsigned.

## Not yet covered

- The Docker Firefly E2E job waits for WP-19 (`docker/firefly/`) to merge.

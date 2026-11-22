# Orchestrator follow-ups

Cross-package seams and owner checks. WP-49 closed every item; the only owner action left is optional signing (bottom).

## WP-19 (Phase 1 integration)

- [x] main.dart: replace FlutterTimezone.getLocalTimezone() with localTimezoneName() from package:budget/platform/timezone.dart (WP-P1); keep the tz.getLocation fallback to America/New_York. Done: `main.dart` calls `localTimezoneName()`.
- [x] Wallet deletes in Firefly mode: route the remaining legacy delete paths to FireflyWalletQueries.deleteWalletLocally(walletPk) (WP-10). The primary-wallet "0" delete/merge stays disabled in Firefly mode. Done: `FinanceDatabase.deleteWallet` routes to `deleteWalletLocally` in Firefly mode and ignores wallet "0"; this covers the delete and merge paths in `editWalletsPage.dart`. Test: `test/firefly/e2e/seams_test.dart`.
- [x] Localize the display name of the reserved local category "firefly-uncategorized" (persisted as "Uncategorized"). Done: `fireflyUncategorizedName()` uses `firefly-category-uncategorized` (`assets/translations/firefly/en/integration.json`), with "Uncategorized" when no locale is loaded. The row is renamed when the language changes; it never syncs.
- [x] Re-enable budget/integration_test in gate G3 once this package creates it. Done: `budget/integration_test/` exists, so CI G3 now analyses it.
- [x] Verify WP-03 API-NOTES assumptions A1-A7 live against a disposable Firefly III 6.6.2 and remove the fallbacks that turn out unnecessary. Done: results in `API-NOTES.md` (WP-39 live run); the `docker-e2e` CI job reruns `tool/firefly_probe/probe.py --container` on every pull request, including A7 through `up.sh`. A6 is unsupported by the server (HTTP 500), so its fallback stays by design; A3 and A4 keep their cheap safeguards.
- [x] conflicts_page.dart:129: subtitle shows raw enum names; show localized labels. Done: `fireflyEntityLabel` and `fireflyResolutionLabel`.

## Owner checks, now run in CI (WP-49)

- [x] Live E2E against Docker: `.github/workflows/e2e.yml` job `docker-e2e` runs `scripts/ci/firefly-e2e.sh host` on Ubuntu: `docker/firefly/up.sh`, the live Phase 1, 2 and 3 suites, the A1-A7 probe, then `down.sh`.
- [x] Attachments on a device: `integration_test/final/attachments_device_test.dart` writes a binary file on the device, attaches it as the add-transaction page does, syncs, downloads it from the server and through a second device, and compares bytes. It runs on Linux desktop (Xvfb) and an Android emulator against the Docker server, and on macOS and an iOS simulator against the emulated server (hosted macOS runners have no Docker). The native file dialog itself is not driven; the test feeds the same file stream the picker returns.
- [x] Linux smoke launch with Xvfb: `build.yml` linux job (`scripts/ci/linux-smoke.sh`).
- [x] macOS and iOS builds: `build.yml` macos and ios jobs on `macos-15`, plus the macOS launch smoke test and the keychain jobs. Local `xcode-select` is no longer needed.
- [x] Windows: `build.yml` windows job builds and runs `flutter test`.
- [x] WP-38 integration: `FireflyConfig.metaRoaming`, engine calls, scheduler key, default preference and the connection page toggle. Tests: `test/firefly/engine/engine_test.dart` (meta roaming off, on, failing).

## Optional, owner only

- [ ] Signing secrets, if store-installable builds are wanted: `APPLE_TEAM_ID`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (see `docs/release.md`). Without them CI produces unsigned or throwaway-signed builds.

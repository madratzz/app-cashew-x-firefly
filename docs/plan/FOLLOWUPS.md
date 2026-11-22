# Orchestrator follow-ups for WP-19 (Phase 1 integration)

Cross-package seams that wave-1 packages could not close because the other side merges in parallel.

- [x] main.dart: replace FlutterTimezone.getLocalTimezone() with localTimezoneName() from package:budget/platform/timezone.dart (WP-P1); keep the tz.getLocation fallback to America/New_York. Done: `main.dart` calls `localTimezoneName()`.
- [x] Wallet deletes in Firefly mode: route the remaining legacy delete paths to FireflyWalletQueries.deleteWalletLocally(walletPk) (WP-10). The primary-wallet "0" delete/merge stays disabled in Firefly mode. Done: `FinanceDatabase.deleteWallet` routes to `deleteWalletLocally` in Firefly mode and ignores wallet "0"; this covers the delete and merge paths in `editWalletsPage.dart`. Test: `test/firefly/e2e/seams_test.dart`.
- [x] Localize the display name of the reserved local category "firefly-uncategorized" (persisted as "Uncategorized"). Done: `fireflyUncategorizedName()` uses `firefly-category-uncategorized` (`assets/translations/firefly/en/integration.json`), with "Uncategorized" when no locale is loaded. The row is renamed when the language changes; it never syncs.
- [x] Re-enable budget/integration_test in gate G3 once this package creates it. Done: `budget/integration_test/` exists, so CI G3 now analyses it.
- [ ] Verify WP-03 API-NOTES assumptions A1-A7 live against the disposable dockerised Firefly 6.6.2 (orion-nexus has Docker) and remove the fallbacks that turn out unnecessary. **Pending:** no Docker access (see `docs/firefly/testing.md`). The fallbacks stay until the live probe runs.
- [x] conflicts_page.dart:129: subtitle shows raw enum names; show localized labels. Done: `fireflyEntityLabel` and `fireflyResolutionLabel`.

## Pending owner-run checks (for WP-49 final integration)
Owner chose to merge without these; run them once the machines allow it.
- orion-nexus: `sudo usermod -aG docker madratzz` (re-login), then live E2E: `eval "$(docker/firefly/up.sh)"; cd budget; fvm flutter test --dart-define=FIREFLY_ALLOW_HTTP=true test/firefly/e2e/live_e2e_test.dart`, and verify WP-03 API-NOTES A1-A7.
- orion-nexus: `sudo pacman -S xorg-server-xvfb`, then the WP-P1 Linux smoke launch with xvfb-run.
- This Mac: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch && softwareupdate --install-rosetta --agree-to-license`, then `fvm flutter build macos --debug` and `fvm flutter build ios --debug --no-codesign`.
- Windows: verified only through WP-P2 CI (windows-latest).

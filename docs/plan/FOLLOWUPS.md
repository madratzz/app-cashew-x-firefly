# Orchestrator follow-ups for WP-19 (Phase 1 integration)

Cross-package seams that wave-1 packages could not close because the other side merges in parallel.

- main.dart: replace FlutterTimezone.getLocalTimezone() with localTimezoneName() from package:budget/platform/timezone.dart (WP-P1); keep the tz.getLocation fallback to America/New_York.
- Wallet deletes in Firefly mode: route the remaining legacy delete paths to FireflyWalletQueries.deleteWalletLocally(walletPk) (WP-10). The primary-wallet "0" delete/merge stays disabled in Firefly mode.
- Localize the display name of the reserved local category "firefly-uncategorized" (persisted as "Uncategorized").
- Re-enable budget/integration_test in gate G3 once this package creates it.
- Verify WP-03 API-NOTES assumptions A1-A7 live against the disposable dockerised Firefly 6.6.2 (orion-nexus has Docker) and remove the fallbacks that turn out unnecessary.

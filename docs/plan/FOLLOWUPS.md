# Orchestrator follow-ups for WP-19 (Phase 1 integration)

Cross-package seams that wave-1 packages could not close because the other side merges in parallel.

- main.dart: replace FlutterTimezone.getLocalTimezone() with localTimezoneName() from package:budget/platform/timezone.dart (WP-P1); keep the tz.getLocation fallback to America/New_York.
- Wallet deletes in Firefly mode: route the remaining legacy delete paths to FireflyWalletQueries.deleteWalletLocally(walletPk) (WP-10). The primary-wallet "0" delete/merge stays disabled in Firefly mode.
- Wire WP-04's local-write echo suppression hook into WP-02's watcher if WP-02 merged before it existed.
- Localize the display name of the reserved local category "firefly-uncategorized" (persisted as "Uncategorized").
- Re-enable budget/integration_test in gate G3 once this package creates it.

# Testing Firefly sync

Run every command from `budget/` with the pinned Flutter (`fvm flutter`).

## Suites

| Suite | Path | Needs | Runs in `flutter test` |
|---|---|---|---|
| Unit and widget tests | `test/firefly/**`, `test/platform/**` | Nothing | Yes |
| Phase 1 E2E, emulated server | `test/firefly/e2e/fake_server_e2e_test.dart` | Nothing | Yes |
| Phase 1 E2E, live server | `test/firefly/e2e/live_e2e_test.dart` (tag `live`) | `FIREFLY_E2E_URL`, `FIREFLY_E2E_TOKEN` | Yes, skipped when unset |
| Seam tests (mode-off legacy delete, wallet delete routing, labels) | `test/firefly/e2e/seams_test.dart` | Nothing | Yes |
| On-device E2E | `integration_test/firefly_phase1_test.dart` | A device or desktop target | No: `fvm flutter test integration_test -d <device>` |

The emulated and live runs share one scenario file, `test/firefly/e2e/support/phase1_suite.dart`. It drives the real `SyncEngine`, the default syncer registry and `HttpFireflyTransport` over HTTP. The tests run in order against one server and one device:

1. Initial import of the seeded data set: 3 asset accounts in 2 currencies, 20 categories and 500 transaction groups, including transfers and one split. Every local wallet total must equal the server `current_balance`.
2. A second sync with no changes sends no write request.
3. Local create, edit and delete of an account, a category, a withdrawal, a deposit and a transfer reach the server.
4. The same changes made on the server reach the device.
5. An edit on both sides: the server version wins and the conflicts table holds the local version.
6. Ten local edits made while the server is unreachable: one cycle after reconnecting pushes all ten exactly once, and the next cycle sends nothing.

"Server unreachable" is simulated in the app's transport (`SwitchableTransport.offline`), which throws `FireflyNetworkError` like a stopped server would. The suite seeds the data itself through the API, and it refuses to run against a server that already has transactions.

The emulator (`test/firefly/e2e/support/firefly_emulator.dart`) models only what Phase 1 uses: journal ids, date windows, `updated_at_after:` search, the computed `current_balance`, whole-second `updated_at` stamps and cascading deletes. It is reached through an HTTPS placeholder host that a test HTTP client routes to a loopback port, so it needs no build define.

## Live run against a disposable Firefly III 6.6.2

Never point the suite at a server with real data. `docker/firefly/` starts a throwaway instance whose database lives in `tmpfs`. Every secret (database password, app key, user and token) is generated at start-up and only printed to your terminal.

```sh
eval "$(../docker/firefly/up.sh)"     # needs Docker; prints FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN
fvm flutter test --dart-define=FIREFLY_ALLOW_HTTP=true test/firefly/e2e/live_e2e_test.dart
../docker/firefly/down.sh            # destroys the instance and its data
```

`FIREFLY_ALLOW_HTTP=true` lets the debug test build reach `http://127.0.0.1`. To run on another host, forward the port over SSH (`ssh -L 8089:127.0.0.1:8089 <host>`) so the URL stays loopback.

The A1–A7 probe from WP-03 can run against the same instance:

```sh
FIREFLY_BASE_URL=$FIREFLY_E2E_URL FIREFLY_API_TOKEN=$FIREFLY_E2E_TOKEN \
  python3 tool/firefly_probe/probe.py --disposable --container cashew-firefly-e2e-app-1
```

## Status

| Item | Status |
|---|---|
| Emulated Phase 1 E2E (acceptance 2–6) | Passing |
| Live Phase 1 E2E against Docker | **Pending.** No Docker on the development Mac. The Linux host that has Docker refused this user access to the socket (`permission denied ... /var/run/docker.sock`). Needs a user in the `docker` group or a CI job (WP-P2) |
| A1–A7 live verification | **Pending**, same blocker. The fallbacks in `API-NOTES.md` stay in place until the probe runs |
| `up.sh` token minting (A7) | Written, not yet run. If minting fails, create a token in the web UI of the disposable instance and export it by hand |
| Legacy flow with mode off (acceptance 7) | Covered by the existing hook tests and `seams_test.dart` at the database and settings level. A full UI run (onboarding, add transaction, backup export) on a device is still manual |

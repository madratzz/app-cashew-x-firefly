# Testing Firefly sync

Run every command from `budget/` with the pinned Flutter (`fvm flutter`).

## Suites

| Suite | Path | Needs | Runs in `flutter test` |
|---|---|---|---|
| Unit and widget tests | `test/firefly/**`, `test/platform/**` | Nothing | Yes |
| Phase 1 E2E, emulated server | `test/firefly/e2e/fake_server_e2e_test.dart` | Nothing | Yes |
| Phase 1 E2E, live server | `test/firefly/e2e/live_e2e_test.dart` (tag `live`) | `FIREFLY_E2E_URL`, `FIREFLY_E2E_TOKEN` | Yes, skipped when unset |
| Seam tests (mode-off legacy delete, wallet delete routing, labels) | `test/firefly/e2e/seams_test.dart` | Nothing | Yes |
| Phase 2 E2E, emulated server | `test/firefly/e2e/phase2/fake_server_phase2_e2e_test.dart` | Nothing | Yes |
| Phase 2 E2E, live server | `test/firefly/e2e/phase2/live_phase2_e2e_test.dart` (tag `live`) | `FIREFLY_E2E_URL`, `FIREFLY_E2E_TOKEN`, a fresh instance | Yes, skipped when unset |
| Phase 3 E2E, emulated server | `test/firefly/e2e/phase3/fake_server_phase3_e2e_test.dart` | Nothing | Yes |
| Phase 3 E2E, live server | `test/firefly/e2e/phase3/live_phase3_e2e_test.dart` (tag `live`) | `FIREFLY_E2E_URL`, `FIREFLY_E2E_TOKEN` | Yes, skipped when unset |
| Phase 3 seams (in-place saves, tag links on delete, conflict reapply, payee direction, phone width) | `test/firefly/e2e/phase3/*_test.dart` | Nothing | Yes |
| On-device E2E | `integration_test/firefly_phase1_test.dart`, `integration_test/phase2/firefly_phase2_test.dart`, `integration_test/phase3/firefly_phase3_test.dart` | A device or desktop target | No: `fvm flutter test integration_test -d <device>` |
| Attachment round trip on a device | `integration_test/final/attachments_device_test.dart` | A device or desktop target; live when `FIREFLY_E2E_URL` and `FIREFLY_E2E_TOKEN` are passed with `--dart-define` | No: CI `e2e.yml` runs it on Linux, Android, macOS and iOS |

The emulated and live runs share one scenario file, `test/firefly/e2e/support/phase1_suite.dart`. It drives the real `SyncEngine`, the default syncer registry and `HttpFireflyTransport` over HTTP. The tests run in order against one server and one device:

1. Initial import of the seeded data set: 3 asset accounts in 2 currencies, 20 categories and 500 transaction groups, including transfers and one split. Every local wallet total must equal the server `current_balance`.
2. A second sync with no changes sends no write request.
3. Local create, edit and delete of an account, a category, a withdrawal, a deposit and a transfer reach the server.
4. The same changes made on the server reach the device.
5. An edit on both sides: the server version wins and the conflicts table holds the local version.
6. Ten local edits made while the server is unreachable: one cycle after reconnecting pushes all ten exactly once, and the next cycle sends nothing.

"Server unreachable" is simulated in the app's transport (`SwitchableTransport.offline`), which throws `FireflyNetworkError` like a stopped server would. The suite seeds the data itself through the API, and it refuses to run against a server that already has transactions.

The emulator (`test/firefly/e2e/support/firefly_emulator.dart`) models only what Phase 1 uses: journal ids, date windows, `updated_at_after:` search, the computed `current_balance`, whole-second `updated_at` stamps and cascading deletes. It is reached through an HTTPS placeholder host that a test HTTP client routes to a loopback port, so it needs no build define.

## Phase 2 scenarios

`test/firefly/e2e/phase2/support/phase2_suite.dart` runs in order against one empty server, with every Phase 2 syncer and contributor in the default registry:

1. A contributor version change (a Phase 1 install stored version `0` for every contributor) makes the next cycle a full transaction pull, exactly once. The cycle after it is incremental again.
2. A budget with a limit and an assigned withdrawal created on the device reaches the server, and the same made on the server reaches the device.
3. Money added to a piggy bank on the device and on the server shows on the other side, with the history events.
4. A bill linked to a transaction on either side shows on the other.
5. A triggered recurrence imports its transaction once, with no local duplicate on the next cycle.
6. A repetition moment edited on the device reaches the server in one PUT, and the next cycle sends nothing.

The emulator (`phase2/support/phase2_emulator.dart`) extends the Phase 1 one with piggy bank account amounts and events, the auto-budget limit, weekly recurrence occurrences with `POST /recurrences/{id}/trigger`, and the 6.6.2 validation rules listed below.

## Phase 3 scenarios

`test/firefly/e2e/phase3/support/phase3_suite.dart` runs in order against one server with two devices:

1. One withdrawal with a payee, two tags, a foreign amount, a budget, a bill and an attachment, set through `FireflyTransactionDraft` as the add-transaction page does. It is checked on the server and on the second device, and a further cycle on either device writes nothing.
2. A three-split group created on the device reaches the server. The second device retitles it and removes a split, and the first device sees both changes.
3. A payment from an asset account to a loan. Firefly stores it as a withdrawal; both devices show the local transfer pair.
4. Deleting the rich transaction removes it on the server and on the second device, with no orphaned tag links.

Objects carry a per-run suffix, so this suite does not need an empty server.

The emulator (`phase3/support/phase3_emulator.dart`) adds the liability read shape, the md5 hash and size that an attachment upload stamps, and journal pagination (below).

## Firefly 6.6.2 behaviour found on the live server

- `GET /transactions` pages by journal. `total` and `per_page` count splits, and a split group can continue on the next page with its remaining splits. The transaction pull holds back each page's last group, merges it with its continuation, and keeps it in the resume checkpoint. The Phase 3 emulator pages by journal, two per page.
- A budget POSTed with an auto-budget amount gets the current period's limit from the server, and the server also accepts a second limit for the same period. The limit syncer adopts that unmapped limit instead of creating another one.
- `POST /piggy-banks` requires `start_date`.
- `PUT /recurrences/{id}` requires `transactions` in every request ("Need at least one transaction."), even for a title-only edit, so the app always sends them. Repetition moments from 0 to 10 are accepted on PUT; an earlier note that they were rejected was wrong.
- `GET /attachments/{id}/download` with `Accept: application/octet-stream` alone answers 406 (`BadHttpHeaderException`), so the app sends `application/octet-stream, */*`. Found by the device attachment test in CI (WP-49); the Phase 3 suite only compared filenames.
- `POST /attachments/{id}/upload` sniffs the content against a MIME allow-list. A rejected file still answers the upload, logs "Mime type ... is not allowed for API file upload", and stays not uploaded; a later download answers 500 ("200000: File has not been uploaded (yet)."). The device test uploads a PDF.
- `POST /recurrences/{id}/trigger?date=` creates a group only when the date is a listed occurrence, and only once per occurrence. The app triggers the server's next occurrence.

## Live run against a disposable Firefly III 6.6.2

Never point the suite at a server with real data. `docker/firefly/` starts a throwaway instance whose database lives in `tmpfs`. Every secret (database password, app key, user and token) is generated at start-up and only printed to your terminal.

```sh
eval "$(../docker/firefly/up.sh)"     # needs Docker; prints FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN
fvm flutter test --dart-define=FIREFLY_ALLOW_HTTP=true test/firefly/e2e/live_e2e_test.dart
../docker/firefly/down.sh            # destroys the instance and its data
```

`FIREFLY_ALLOW_HTTP=true` lets the debug test build reach `http://127.0.0.1`. To run on another host, forward the port over SSH (`ssh -L 8089:127.0.0.1:8089 <host>`) so the URL stays loopback.

A live run records the ids on the server before it starts (`E2eServerSnapshot` in `e2e_harness.dart`) and deletes only what it created, so the three suites can run one after another on one persistent instance. The Phase 1 and Phase 2 suites still refuse a server that already has transactions. Set `FIREFLY_E2E_KEEP=1` to leave the created objects in place for inspection. Run one live suite at a time: they share the server.

The A1–A7 probe from WP-03 can run against the same instance:

```sh
FIREFLY_BASE_URL=$FIREFLY_E2E_URL FIREFLY_API_TOKEN=$FIREFLY_E2E_TOKEN \
  python3 tool/firefly_probe/probe.py --disposable --container cashew-firefly-e2e-app-1
```

## In CI

`.github/workflows/e2e.yml` (see `docs/release.md`) runs the live Phase 1, 2 and 3 suites, the A1-A7 probe and the device attachment test against a disposable Docker Firefly III on every pull request. Locally, `scripts/ci/firefly-e2e.sh host` does the same on a Linux machine with Docker and Xvfb.

## Status

| Item | Status |
|---|---|
| Emulated Phase 1, 2 and 3 E2E | Passing |
| Live Phase 1, 2 and 3 E2E | Passing in CI (`docker-e2e`) against a disposable Firefly III 6.6.2 |
| A1-A7 live verification | Recorded in `API-NOTES.md` and rerun in CI. A6 is unsupported by the server (HTTP 500), so its fallback stays |
| `up.sh` token minting (A7) | Runs end to end in CI |
| Attachments on a device | `attachments_device_test.dart` in CI on Linux and Android (live) and macOS and iOS (emulated) |
| Legacy flow with mode off (acceptance 7) | Covered by the existing hook tests and `seams_test.dart` at the database and settings level, and by the launch smoke tests on macOS and Linux |

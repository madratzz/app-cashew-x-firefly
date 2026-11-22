# Firefly III 6.6.2 API notes

WP-03 had no live instance. WP-39 ran the probe against a disposable Firefly III 6.6.2 on 2026-11-22; the result column records what it found. The three live E2E suites pass against the same instance.

| ID | Live check | Fallback while unverified | Live result (6.6.2) |
|---|---|---|---|
| A1 | Search for a recently edited transaction that has an older transaction date. Confirm that a future cutoff excludes it. | Use the transaction date-window listing and full reconcile. | Supported: an edited transaction with an older date is found by `updated_at_after:`. |
| A2 | Request 100 records and check the server's pagination metadata. | Use the returned `per_page` and `total_pages`. | Accepted: `per_page` is 100. `total` and `per_page` count journals, not groups, and a split group can continue on the next page; the transaction pull merges it. |
| A3 | Patch a category, account and transaction group. Re-read each and compare omitted fields. | Send full objects built from the last pulled copy when a resource does not preserve omitted fields. | Omitted fields are retained for categories, accounts and transaction groups. Other resources unverified. |
| A4 | Create a transaction with a matching rule and compare the POST response with a GET for the same group. | Re-read pushed transaction groups. | The rule effect is already in the POST response for the probe fixture. The re-read stays. |
| A5 | Corrected from [v6.6.2 source](https://github.com/firefly-iii/firefly-iii/blob/v6.6.2/app/Api/V1/Requests/Models/PiggyBank/StoreRequest.php), live run still pending. Create with `accounts[].account_id` and `transaction_currency_code`. If rejected, retry with a top-level `account_id` as well. | The app sends all three fields. | Verified: `accounts[].account_id` with `transaction_currency_code` is accepted without a top-level `account_id`. 6.6.2 also requires `start_date`, which the app and the probe send. |
| A6 | Try creating a reconciliation split with only the asset account specified. | Push an unpaired correction as a withdrawal or deposit titled “Balance correction”. | Not supported: a reconciliation split with only the asset account gets HTTP 500, so the app keeps pushing an unpaired correction as a withdrawal or deposit titled “Balance correction”. |
| A7 | Mint a temporary personal access token inside the Docker container, verify it against the API and revoke it. | Supply a token to E2E through the environment. | `docker/firefly/mint.php` mints a token on 6.6.2 (no `tinker`; Passport 13 has no `personal_access_client` column). `up.sh` uses it and then runs `firefly-iii:correct-database`. The probe's container check was not run. |

Run from `budget/` with Python 3 after exporting `FIREFLY_BASE_URL` and `FIREFLY_API_TOKEN` in the environment for a disposable Firefly III 6.6.2 instance. The probe creates and removes financial records and rules. Omit `--container` to run A1–A6 and leave A7 unverified.

```sh
python3 tool/firefly_probe/probe.py --disposable --container <disposable-container>
```

The probe prints check results and HTTP status codes. It keeps response bodies, credentials, URLs and the temporary token out of stdout. A passing A3 result covers the sampled resources.

The app transport retries transient failures up to five attempts for replayable requests. An attachment upload consumes a single-subscription stream once. After an upload fails, the caller can reopen the file for a later sync. A download can retry until it returns its byte stream. If the stream fails after that, its consumer receives a typed error and can restart the download.

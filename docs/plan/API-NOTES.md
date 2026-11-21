# Firefly III 6.6.2 API notes

WP-03 had no disposable live Firefly III 6.6.2 instance. A1–A7 remain unverified. The table records the fallback from the plan for each assumption.

| ID | Live check | Fallback while unverified |
|---|---|---|
| A1 | Search for a recently edited transaction that has an older transaction date. Confirm that a future cutoff excludes it. | Use the transaction date-window listing and full reconcile. |
| A2 | Request 100 records and check the server's pagination metadata. | Use the returned `per_page` and `total_pages`. |
| A3 | Patch a category, account and transaction group. Re-read each and compare omitted fields. | Send full objects built from the last pulled copy when a resource does not preserve omitted fields. |
| A4 | Create a transaction with a matching rule and compare the POST response with a GET for the same group. | Re-read pushed transaction groups. |
| A5 | Create a piggy bank with `accounts[]` alone. If rejected, try with both `accounts[]` and `account_id`. | Send both fields. |
| A6 | Try creating a reconciliation split with only the asset account specified. | Push an unpaired correction as a withdrawal or deposit titled “Balance correction”. |
| A7 | Mint a temporary personal access token inside the Docker container, verify it against the API and revoke it. | Supply a token to E2E through the environment. |

Run from `budget/` with Python 3 after exporting `FIREFLY_BASE_URL` and `FIREFLY_API_TOKEN` in the environment for a disposable Firefly III 6.6.2 instance. The probe creates and removes financial records and rules. Omit `--container` to run A1–A6 and leave A7 unverified.

```sh
python3 tool/firefly_probe/probe.py --disposable --container <disposable-container>
```

The probe prints check results and HTTP status codes. It keeps response bodies, credentials, URLs and the temporary token out of stdout. A passing A3 result covers the sampled resources.

The app transport retries transient failures up to five attempts for replayable requests. An attachment upload consumes a single-subscription stream once. After an upload fails, the caller can reopen the file for a later sync. A download can retry until it returns its byte stream. If the stream fails after that, its consumer receives a typed error and can restart the download.

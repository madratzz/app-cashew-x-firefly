# Cashew × Firefly III — execution plan

Status: ready for orchestration · Written 2026-11-22 · Base branch `firefly-sync` · Source brief: `docs/plan/BRIEF.md`

This plan turns the brief into work packages that run in parallel git worktrees. Sections 1–7 are shared context every worker reads. Section 8 holds the packages. Section 9 is the definition of done every package must meet. Sections 10–12 cover merging, API coverage and open decisions.

## 0. Orchestration rules

**Model routing**

| Worker label in this plan | Model | Effort |
|---|---|---|
| Codex | `gpt-6.2-sol` | medium |
| Claude | `opus` | low |

Codex takes heavy implementation (schema, sync logic, API clients, tests). Claude takes UI and integration packages.

**Branches and worktrees**

- Every package works on its own branch `feature-<x>` cut from the tip of `firefly-sync`, in its own worktree, for example `git worktree add ../app-cashew-x-firefly.wt/<branch> -b <branch> firefly-sync`.
- Commit `docs/plan/` to `firefly-sync` before creating worktrees, so every worker can read this plan.
- A package may only edit the files listed under "Files owned". Anything else is a change request back to the orchestrator.
- Packages in the same wave have disjoint file sets. A wave starts when its dependencies are merged into `firefly-sync`.

**What each worker is given**

Sections 1–7 and 9 of this plan, its own package section, and `docs/plan/CONTRACTS.md` once WP-01 has written it. After WP-01 merges, `CONTRACTS.md` and the merged code are the source of truth for names and signatures; this plan gives intent.

**Prerequisite that is not met on the planning machine**

`flutter` and `dart` are not on `PATH` on the machine where this plan was written, so nothing here was compiled or analysed. Workers need a Flutter SDK before any acceptance check can run. WP-00 pins the version.

**Hard rules for every package**

- The app stays GPL-3.0. Do not change `LICENSE`. New dependencies must be GPL-compatible.
- No secrets in any file: no tokens, no real server hostnames, no personal data in fixtures. See section 7.
- With Firefly mode off, the app behaves exactly as upstream Cashew does today.
- Do not vendor the Firefly OpenAPI YAML into the repo (it is AGPL). Hand-write the DTOs.

## 1. Facts verified while planning

### 1.1 Repository

| Fact | Where |
|---|---|
| Flutter app lives in `budget/`; platform folders present are `android/`, `ios/`, `web/` only | `budget/` |
| `pubspec.lock` is tracked even though `.gitignore` lists it; it locks `intl 0.18.1`, Dart `>=3.3.0`, Flutter `>=3.19.0`, `drift 2.18.0` | `budget/pubspec.lock` |
| Drift schema version is 46; tables: `Wallets`, `Transactions`, `Categories`, `CategoryBudgetLimits`, `AssociatedTitles`, `Budgets`, `AppSettings`, `ScannerTemplates`, `DeleteLogs`, `Objectives` | `budget/lib/database/tables.dart` (7,667 lines; also holds every query) |
| Migrations up to 32 are hand-written; from 33 on they use generated `migrationSteps` plus a schema dump per version | `tables.dart`, `schema_versions.dart`, `budget/drift_schemas/`, README "Migrate Database" |
| All primary keys are text UUIDs. Wallet `"0"` is the default wallet and category `"0"` is the balance-correction pseudo-category; both are column defaults and are referenced by literal throughout the code (the literal `"0"` appears on about 180 lines) | `tables.dart`, `initializeDefaultDatabase.dart`, `addWalletPage.dart` |
| Every synced table has a nullable `dateTimeModified`; every delete path writes a `DeleteLogs` row (`entryPk`, `type`, `dateTimeModified`) | `tables.dart` (`createDeleteLog`, `createDeleteLogs`) |
| `createOrUpdate*` methods stamp `dateTimeModified = now` and run side effects (shared budgets, balance-correction ordering). `createOrUpdateTransaction` has no way to pass a custom modified time | `tables.dart:3427` |
| A transfer is two balance-correction transactions in category `"0"`, linked by `pairedTransactionFk` | `addWalletPage.dart:985-1200` |
| Budgets with `addedTransactionsOnly = true` take their members from `Transactions.sharedReferenceBudgetPk` | `tables.dart` |
| Drive sync entry points: `syncData`, `createSyncBackup`, `cancelAndPreventSyncOperation`; called from `runAllCloudFunctions` and the `watchAllForAutoSync` listener | `struct/syncClient.dart`, `widgets/navigationFramework.dart:305,467`, `widgets/accountAndBackup.dart`, `widgets/pullDownToRefreshSync.dart`, `widgets/navigationSidebar.dart` |
| Settings are one JSON map (`appStateSettings`) in shared preferences, and it is copied into the `AppSettings` table and into backups | `struct/settings.dart`, `struct/defaultPreferences.dart` |
| `main()` calls `Firebase.initializeApp` unconditionally and `firebase_options.dart` throws on macOS, Windows and Linux | `main.dart`, `firebase_options.dart` |
| `getPlatform()` only knows iOS, Android and web; it returns `null` on desktop (about 225 call sites) | `functions.dart:1336` |
| The database file is created in the user's Documents directory | `database/platform/native.dart` |
| Translations come from a Google Sheet through `generate-translations.py` into `assets/translations/generated/*.json`, loaded by a custom asset loader | `struct/languageMap.dart:105` |
| `analysis_options.yaml` includes `flutter_lints`, which is not a dependency; `flutter_test` is not declared; the only test is the unmodified counter template and would fail | `budget/analysis_options.yaml`, `budget/test/widget_test.dart` |
| The only CI workflow is a Firebase Hosting preview that runs `npm ci` at the repo root | `.github/workflows/firebase-hosting-pull-request.yml` |
| App ids: Android `com.budget.tracker_app`, iOS `com.budget.tracker-app` (upstream's ids) | `android/app/build.gradle`, `ios/Runner.xcodeproj` |

### 1.2 Firefly III API v6.6.2

Source: `dist/firefly-iii-v6.6.2-v1.yaml` from `github.com/firefly-iii/api-docs` (the exact server version in the brief). `api-docs.firefly-iii.org` rejects non-browser clients, so the spec file was read instead.

| Topic | Verified shape |
|---|---|
| Base path and auth | `<base>/api/v1/...`; `Authorization: Bearer <token>`; responses are `application/vnd.api+json`; request bodies are `application/json`; optional `X-Trace-Id` UUID header on every call |
| Envelope | `{ data: { type, id, attributes, links } }` or `data: [...]` with `meta.pagination { total, count, per_page, current_page, total_pages }` |
| Pagination | `limit` and `page` query parameters; default 50 per page |
| About | `GET /v1/about` returns `data.version`, `api_version`, `php_version`, `os`, `driver`; `GET /v1/about/user` returns the user |
| Accounts | `GET/POST /v1/accounts`, `GET/PUT/DELETE /v1/accounts/{id}`; list filter `type` (`asset`, `expense`, `revenue`, `liability`, `cash`, ...); store requires `name`, `type`; fields include `account_role` (`defaultAsset`, `sharedAsset`, `savingAsset`, `ccAsset`, `cashWalletAsset`), `currency_code`, `opening_balance`, `virtual_balance`, `active`, `order`, `include_net_worth`, `iban`, `bic`, `account_number`, `notes`, `liability_type` (`loan`, `debt`, `mortgage`), `liability_direction` (`credit`, `debit`), `interest`, `interest_period`; read-only `current_balance`, `updated_at` |
| Categories | Flat: `name`, `notes`. No hierarchy, no income flag, no colour |
| Transactions | A transaction is a group (`id`, `group_title`, `created_at`, `updated_at`) holding `transactions[]` splits. Split store requires `type`, `date`, `amount`, `description`. `type` is one of `withdrawal`, `deposit`, `transfer`, `reconciliation`, `opening balance`. Amounts are positive decimal strings. Other split fields: `source_id/name`, `destination_id/name`, `currency_code`, `foreign_amount`, `foreign_currency_code`, `category_id/name`, `budget_id`, `bill_id` (read also returns `subscription_id`), `piggy_bank_id` (store only), `tags[]`, `notes`, `reconciled`, `internal_reference`, `external_id`, `external_url`, `order`. Read adds `transaction_journal_id`, `has_attachments`, `primary_currency_*` and `pc_*` amounts |
| Transaction writes | `POST /v1/transactions` takes `error_if_duplicate_hash`, `apply_rules`, `fire_webhooks`, `group_title`, `transactions[]`. `PUT /v1/transactions/{id}` has no required fields; each split carries `transaction_journal_id`. `DELETE /v1/transactions/{id}` removes the group; `DELETE /v1/transaction-journals/{id}` removes one split |
| Transaction reads | `GET /v1/transactions` filters only by `start`, `end` (transaction date, `YYYY-MM-DD`, inclusive) and `type`. There is no "changed since" parameter and no tombstone feed. `GET /v1/search/transactions?query=` exists |
| Budgets | `name`, `active`, `notes`, `auto_budget_type` (`reset`, `rollover`, `none`), `auto_budget_period` (`daily`, `weekly`, `monthly`, `quarterly`, `half-year`, `yearly`), `auto_budget_amount`, `auto_budget_currency_code` |
| Budget limits | `GET/POST /v1/budgets/{id}/limits`, `GET/PUT/DELETE /v1/budgets/{id}/limits/{limitId}`; store requires `amount`, `start`, `end`; `GET /v1/budget-limits` requires `start` and `end`. `/v1/available-budgets` is read-only |
| Piggy banks | `name`, `accounts[] { id, current_amount }`, `target_amount`, `current_amount`, `start_date`, `target_date`, `order`, `notes`, `object_group_*`; events are read-only at `GET /v1/piggy-banks/{id}/events`. The spec lists `account_id` as required but only defines `accounts[]` |
| Bills | `name`, `amount_min`, `amount_max`, `date`, `end_date`, `extension_date`, `repeat_freq` (`weekly`, `monthly`, `quarterly`, `half-year`, `yearly`), `skip`, `active`; read-only `paid_dates`, `pay_dates`, `next_expected_match` |
| Recurrences | `type` (`withdrawal`, `transfer`, `deposit`), `title`, `first_date`, `repeat_until`, `nr_of_repetitions`, `apply_rules`, `active`, `repetitions[] { type: daily, weekly, ndom, monthly, yearly; moment; skip; weekend }`, `transactions[]`; `POST /v1/recurrences/{id}/trigger?date=` creates the transaction dated today |
| Tags | `tag`, `date`, `description`; the path parameter of `/v1/tags/{tag}` accepts the tag id or the tag text |
| Attachments | `POST /v1/attachments` with `filename`, `attachable_type` (`Account`, `Budget`, `Bill`, `TransactionJournal`, `PiggyBank`, `Tag`), `attachable_id`; then `POST /v1/attachments/{id}/upload` with the raw file as the body (204); `GET /v1/attachments/{id}/download` |
| Currencies | `code`, `name`, `symbol`, `decimal_places`, `enabled`, `primary`; `POST /v1/currencies/{code}/enable`, `/disable`, `/primary`; `GET /v1/currencies/primary`; `/v1/exchange-rates` has full CRUD |
| Rules | `/v1/rule-groups` and `/v1/rules` CRUD; a rule has `title`, `rule_group_id`, `trigger` (`store-journal`, `update-journal`, `manual-activation`), `active`, `strict`, `stop_processing`, `triggers[] { type, value, prohibited }`, `actions[] { type, value }`; `GET /v1/rules/{id}/test` and `POST /v1/rules/{id}/trigger` take `start`, `end`, `accounts[]`; trigger answers 204 and runs asynchronously. Same pair exists on rule groups |
| Preferences | `GET/POST /v1/preferences`, `GET/PUT /v1/preferences/{name}` with a free-form `data` value |
| Errors | 401 unauthenticated, 404 not found, 422 validation `{ message, errors{field: [..]} }`, 400, 500 |

### 1.3 Assumptions the spec does not settle

These need a live Firefly 6.6.2 instance. WP-03 probes them and records the answers in `docs/plan/API-NOTES.md`. Each has a fallback so parallel work is not blocked.

| Id | Assumption | Fallback if false |
|---|---|---|
| A1 | The search query operator `updated_at_after:YYYY-MM-DD` returns transactions edited since a date | Use only the date-window listing plus a daily full reconcile |
| A2 | `limit` above 50 is honoured (target 100) | Read `meta.pagination.per_page` and page accordingly |
| A3 | `PUT` leaves omitted fields untouched for every resource | Send the full object built from the last pulled copy |
| A4 | With `apply_rules: true` the POST response may predate rule effects | Already handled: pushed ids are re-read at the end of the cycle |
| A5 | Piggy bank create works with `accounts[]` and without `account_id` | Send both |
| A6 | A `reconciliation` split can be created through the API with only the asset account given | Push unpaired balance corrections as a plain withdrawal or deposit titled "Balance correction" |
| A7 | A personal access token can be minted non-interactively in the Docker image for E2E | E2E runs only when a token is supplied through the environment |

## 2. Architecture

### 2.1 Shape

Firefly mode is an opt-in mode. The local Drift database stays the store the whole UI reads and writes. A sync engine moves changes between Drift and the Firefly server. Nothing in the existing query layer learns about HTTP.

- All new Dart code lives in `budget/lib/firefly/` and `budget/lib/platform/`. Tests live in `budget/test/firefly/`, `budget/test/platform/` and `budget/integration_test/`.
- The engine is pure Dart on top of `package:http`, Drift and `flutter_secure_storage`. It uses no platform channel of its own, which is what makes behaviour identical on all five targets.
- Firefly mode is unavailable on web (browser CORS and no safe token storage). The web build keeps working as it does today.

### 2.2 How parallel packages avoid editing the same files

Four techniques, all set up before the fan-out:

1. **One schema migration for all phases.** WP-00 adds every table and column any phase needs in a single 46 → 47 migration. After that, `tables.dart`, `tables.g.dart`, `schema_versions.dart` and `drift_schemas/` are frozen. A later schema need is a change request handled by one dedicated package that runs alone between waves.
2. **New queries in new files.** Firefly queries are Dart extensions on `FinanceDatabase` in `lib/firefly/db/<area>_queries.dart`. Extensions need no code generation and never touch `tables.dart`.
3. **Stub files and frozen registries.** WP-01 creates every syncer, transaction contributor, UI section, chip and hub entry as a no-op stub file and lists them all in registries that are then frozen. A feature package replaces the body of the stub files it owns. No package ever adds a line to a shared registry.
4. **Hook points inserted once.** WP-02 puts the few calls into legacy files (settings page, add-transaction page, navigation framework, Drive sync) that render slots or consult mode and capability flags. Later packages fill slots; they do not reopen those legacy files. Each remaining legacy file that needs feature-specific changes has exactly one owning package.

### 2.3 Directory layout (created by WP-01, owners in section 8)

```
budget/lib/firefly/
  firefly.dart                      mode facade (enabled / available), init
  config/                           settings keys, URL normalisation, token store, log redaction
  api/
    transport.dart                  FireflyTransport interface, exceptions, page type, amount and date codecs
    http_transport.dart             real transport
    firefly_api.dart                facade exposing one client per resource
    models/<resource>.dart          hand-written DTOs
    resources/<resource>_api.dart   one client per resource
  db/
    id_map_repository.dart, sync_meta_repository.dart, conflict_repository.dart, resource_cache_repository.dart
    <area>_queries.dart             extensions on FinanceDatabase
  sync/
    contracts.dart                  EntitySyncer, TransactionContributor, SyncContext, SyncReport
    registry.dart                   ordered syncers and contributors (frozen)
    collection_sync.dart            reusable pull/push algorithm for mapped collections
    conflict_policy.dart, dirty_tracker.dart, hashing.dart
    engine.dart, scheduler.dart     orchestration
    entities/<entity>_syncer.dart
    contributors/<aspect>_contributor.dart
  ui/
    slots.dart                      slot registries (frozen)
    draft.dart                      FireflyTransactionDraft (all Firefly-only fields of a transaction being edited)
    settings/, transaction/, entry/, wallet/, hub/   slot implementations
    pages/<feature>/                feature pages
budget/lib/platform/capabilities.dart    PlatformCapabilities
budget/assets/translations/firefly/en/<package>.json   one strings file per package
budget/test/support/                fake transport, in-process fake Firefly server, in-memory database, fixture builders
```

### 2.4 Contracts named in this plan

| Name | Purpose |
|---|---|
| `FireflyMode.enabled` | True when the setting is on, a token exists, and the platform is not web. Every hook checks this first |
| `PlatformCapabilities` | Booleans such as `supportsGoogleSignIn`, `supportsFirebase`, `supportsLocalNotifications`, `supportsBiometrics`, `supportsHomeWidget`, `supportsInAppPurchase`, `supportsCamera`. `googleDriveAvailable` is `supportsGoogleSignIn && !FireflyMode.enabled` |
| `FireflyTransport` | `get`, `getPage`, `post`, `put`, `delete`, `upload`, `download`; throws typed exceptions for 401, 404, 422, rate limit, server and network errors |
| `TokenStore` | `read`, `write`, `delete` for the personal access token |
| `IdMapRepository`, `SyncMetaRepository`, `ConflictRepository`, `ResourceCacheRepository` | Access to the four sync tables |
| `EntitySyncer` | One per entity: `type`, `dependsOn`, `pull`, `push`, `pushDeletes` |
| `CollectionSync` | Generic algorithm used by most syncers: list all pages, upsert, detect remote deletes, push dirty rows |
| `TransactionContributor` | Lets a later package add one aspect (payee, tags, budget, ...) to transaction mapping in both directions without editing the transaction syncer. Each has a `version`; a changed version triggers a full transaction re-pull |
| `FireflyTransactionDraft` | Holds payee, tags, foreign amount and currency, split rows, bill, piggy bank, budget and attachments while the add-transaction page is open; `load(transactionPk)` and `persist(transactionPk)` |
| Slots | `FireflyTransactionExtras`, `FireflyTransactionEntryExtras`, `FireflyWalletExtras`, `FireflyHubSection`, `FireflySettingsEntry`, `FireflySyncStatus` |

## 3. Schema version 47 (WP-00)

One migration step `from46To47`, following the README procedure. Additive only.

**New columns**

| Table | Column | Type | Use |
|---|---|---|---|
| `Transactions` | `payeeFk` | text, nullable, references `Payees` | Expense or revenue account |
| `Transactions` | `foreignAmount` | real, nullable | Amount in the foreign currency |
| `Transactions` | `foreignCurrency` | text, nullable | Lower-case code, same convention as `Wallets.currency` |
| `Transactions` | `splitGroupFk` | text, nullable, references `TransactionGroups` | Set when the Firefly group has more than one split |
| `Transactions` | `splitOrder` | integer, nullable | Position inside the group |
| `Transactions` | `fireflyType` | int enum, nullable | `withdrawal`, `deposit`, `transfer`, `reconciliation`, `openingBalance` |
| `Transactions` | `billFk` | text, nullable | Local key of the linked bill |
| `Transactions` | `reconciled` | bool, default false | |
| `Wallets` | `accountKind` | int enum, default `asset` | `asset`, `liability`, `cash` |
| `Wallets` | `archived` | bool, default false | Firefly `active = false` |

**New tables**

| Table | Columns | Use |
|---|---|---|
| `FireflyIdMap` | See section 5.1 | Local key ↔ remote id, sync state |
| `FireflySyncMeta` | `key` (pk), `value` | Cursors, server version, user id, server URL hash, contributor versions |
| `FireflyConflicts` | `conflictPk`, `entityType`, `localPk`, `remoteId`, `localJson`, `remoteJson`, `resolution`, `dateCreated`, `acknowledged` | Local versions that lost to the server |
| `FireflyResourceCache` | `resourcePk`, `entityType`, `json`, `dateTimeModified` | JSON store for entities the UI never joins in SQL: bills, recurrences, rules, rule groups, currencies, piggy bank state and events, available budgets, object groups, transaction links |
| `Payees` | `payeePk`, `name`, `kind` (expense or revenue), `active`, `notes`, `iban`, `dateCreated`, `dateTimeModified` | Expense and revenue accounts |
| `Tags` | `tagPk`, `name`, `description`, `date`, `dateCreated`, `dateTimeModified` | |
| `TransactionTags` | `transactionFk`, `tagFk` (composite pk) | |
| `TransactionGroups` | `groupPk`, `title`, `dateTimeModified` | Split groups |
| `Attachments` | `attachmentPk`, `attachableType`, `attachableFk`, `filename`, `title`, `mime`, `size`, `localPath`, `hash`, `uploadState`, `dateCreated`, `dateTimeModified` | |
| `AccountDetails` | `walletFk` (pk), `accountRole`, `liabilityType`, `liabilityDirection`, `interest`, `interestPeriod`, `iban`, `bic`, `accountNumber`, `notes`, `includeNetWorth`, `virtualBalance`, `serverBalance`, `serverBalanceDate`, `dateTimeModified` | Firefly-only account fields and the server balance used for the parity check |
| `BudgetLimits` | `budgetLimitPk`, `budgetFk`, `start`, `end`, `amount`, `currency`, `notes`, `dateTimeModified` | Firefly budget limits per period |

`DeleteLogType` is not extended. Deletes of rows in the new tables are recorded by setting the `FireflyIdMap` row to `pendingDelete`.

## 4. Entity mapping

| Firefly resource | Cashew side | Field mapping (Firefly ↔ Cashew) | Local-only, never pushed | Notes | Package |
|---|---|---|---|---|---|
| Asset account (`type=asset`) | `Wallets`, `AccountDetails` | `name` ↔ `name`; `currency_code` ↔ `currency` (case converted); `currency_decimal_places` → `decimals`; `order` ↔ `order`; `active` ↔ `!archived`; `created_at` → `dateCreated`; `current_balance` → `AccountDetails.serverBalance` | `colour`, `iconName`, `currencyFormat`, `homePageWidgetDisplay` | Create sends `type: asset`, `account_role: defaultAsset`. The server's first default asset account is mapped onto local wallet `"0"` so legacy defaults keep working | WP-10 |
| Liability account (`type=liability`) | `Wallets` with `accountKind = liability`, `AccountDetails` | As asset plus `liability_type`, `liability_direction`, `interest`, `interest_period` | Same as asset | Shown in a separate liabilities section. Cashew loan objectives are not mapped | WP-33a |
| Expense and revenue accounts | `Payees` | `name` ↔ `name`; `type` ↔ `kind`; `active`, `notes`, `iban` | — | Withdrawal destination or deposit source ↔ `Transactions.payeeFk` | WP-30a |
| Category | `Categories` (main) | `name` ↔ `name` | `colour`, `iconName`, `emojiIconName`, `order`, `income`, `methodAdded` | New remote categories get an icon from the existing name heuristic. Subcategory: a Firefly category named `Parent / Child` whose parent exists becomes a Cashew subcategory, and a Cashew subcategory is pushed under that name. Separator is a setting (decision D1). Category `"0"` is never pushed | WP-11 |
| Transaction group with one withdrawal split | `Transactions` | `description` ↔ `name` (falls back to the category name when empty); `amount` ↔ `-abs(amount)`, `income = false`; `source_id` ↔ `walletFk`; `date` ↔ `dateCreated`; `notes` ↔ `note`; `category_id` ↔ `categoryFk` and `subCategoryFk`; `reconciled` ↔ `reconciled` | `budgetFksExclude`, `methodAdded`, `upcomingTransactionNotification`, `originalDateDue`, `createdAnotherFutureTransaction`, `skipPaid`, all `shared*` columns | Text longer than Cashew's limits (name 250, note 500) is truncated on pull and that field is marked lossy so it is not pushed back unless edited | WP-12 |
| Deposit split | `Transactions` | As withdrawal with `amount` ↔ `+abs(amount)`, `income = true`, `destination_id` ↔ `walletFk` | Same | | WP-12 |
| Transfer split | Two `Transactions` rows in category `"0"` linked by `pairedTransactionFk` | Out row: `source_id` ↔ `walletFk`, `-amount`. In row: `destination_id` ↔ `walletFk`, `+foreign_amount` if currencies differ, else `+amount` | Same | Both rows map to the same remote split with different `remoteRole` | WP-12 |
| `opening balance`, `reconciliation` splits | `Transactions` row in category `"0"` with `fireflyType` set | Amount and wallet as above | Same | Read-only in the UI. Local unpaired balance corrections are pushed per assumption A6 | WP-12 |
| Group with several splits | One `Transactions` row per split, shared `splitGroupFk`; `group_title` ↔ `TransactionGroups.title` | Per split as above; `order` ↔ `splitOrder` | Same | Imported and editable row by row from Phase 1. Creating and restructuring splits arrives in Phase 3 | WP-12, WP-32 |
| Budget | `Budgets` with `addedTransactionsOnly = true` | `name` ↔ `name`; `active` ↔ `!archived`; `auto_budget_amount` ↔ `amount`; `auto_budget_period` ↔ `reoccurrence` and `periodLength` (`quarterly` = 3 months, `half-year` = 6 months) | `colour`, `pinned`, `order`, `income`, filters, wallet and category lists, all `shared*` columns | Split `budget_id` ↔ `Transactions.sharedReferenceBudgetPk` through a contributor. Budgets without an auto-budget use a monthly period | WP-20a |
| Budget limit | `BudgetLimits` | `start`, `end`, `amount`, `currency_code`, `notes` | — | The limit covering the current period supplies `Budgets.amount`; older limits feed the past-periods page. `CategoryBudgetLimits` stays local-only | WP-20a |
| Available budget | `FireflyResourceCache` | Read-only | — | Displayed, not editable | WP-20a |
| Piggy bank | `Objectives` (`type = goal`) plus cached state | `name` ↔ `name`; `target_amount` ↔ `amount`; `target_date` ↔ `endDate`; `start_date` ↔ `dateCreated`; first `accounts[].id` ↔ `walletFk`; `current_amount` → cached state | `colour`, `iconName`, `emojiIconName`, `income`, `pinned`, `order`, `archived` | In Firefly mode progress shows the server's `current_amount`. "Add or remove money" sends a `PUT` with the new amount. Events are pulled for history, and an event that names a journal sets `Transactions.objectiveFk` | WP-21a |
| Bill | `FireflyResourceCache`; link via `Transactions.billFk` | All bill fields in JSON | — | Shown on the subscriptions page in Firefly mode. Read `subscription_id ?? bill_id`; write `bill_id` | WP-22a |
| Recurrence | `FireflyResourceCache` | All recurrence fields in JSON | — | The server creates the transactions. In Firefly mode Cashew does not auto-create the next occurrence; upcoming entries are derived from `repetitions[].occurrences` | WP-22a |
| Tag | `Tags`, `TransactionTags` | `tag` ↔ `name`; `description`; `date`; split `tags[]` ↔ junction rows | — | | WP-31a |
| Currency | `FireflyResourceCache`; `Transactions.foreignAmount`, `foreignCurrency` | `code` ↔ Cashew lower-case code; `foreign_amount`, `foreign_currency_code` on splits | — | A wallet's currency is enabled on the server before its account is created | WP-03 (API), WP-34a |
| Exchange rate | Existing `cachedCurrencyExchange` setting | `rate` per pair and date | — | Optional source for Cashew's rates in Firefly mode | WP-34a |
| Attachment | `Attachments` plus a file in the app support directory | `filename`, `title`, `mime`, `size`, `hash`; `attachable_id` = journal id | `localPath`, `uploadState` | Replaces the Drive upload in Firefly mode | WP-35a |
| Rule, rule group | `FireflyResourceCache` | Whole object as JSON | — | Edited online; cached for offline viewing | WP-40a |
| Object group, transaction link, link type | `FireflyResourceCache` | Whole object as JSON | — | | WP-41 |
| Preference `cashew.*` | Local-only attributes of wallets, categories, budgets, objectives | JSON blob keyed by remote id | — | Optional roaming of colours, icons and ordering between Cashew devices | WP-38 |

**Cashew features with no Firefly counterpart, in Firefly mode**

| Feature | Behaviour | Decision |
|---|---|---|
| Google Drive backup and device sync | Disabled and hidden. Local file export and import stay | Brief |
| Shared budgets (Firebase), Gmail scanning | Hidden together with the Google account section | D4 |
| Associated titles, scanner templates, per-category budget limits | Stay local-only | — |
| Unpaid upcoming, subscription and repetitive transactions | Stay local-only until marked paid, then pushed | D2 |
| Lent and borrowed transaction types, loan objectives | Creation hidden. Existing rows are not pushed | D3 |

## 5. Sync algorithm

### 5.1 The id mapping table `FireflyIdMap`

| Column | Type | Meaning |
|---|---|---|
| `entityType` | int enum | `walletAccount`, `liabilityAccount`, `payeeAccount`, `category`, `transaction`, `transactionGroup`, `budget`, `budgetLimit`, `piggyBank`, `bill`, `recurrence`, `tag`, `attachment`, `currency`, `rule`, `ruleGroup`, `objectGroup`, `transactionLink` |
| `localPk` | text | Primary key of the local row |
| `remoteId` | text | Firefly id. For a transaction this is the group id |
| `remoteSubId` | text, default `''` | `transaction_journal_id` for transactions |
| `remoteRole` | int, default 0 | 0 single, 1 transfer source side, 2 transfer destination side |
| `remoteUpdatedAt` | datetime, nullable | Server `updated_at` of the version last applied or pushed |
| `localVersionAt` | datetime, nullable | The local row's `dateTimeModified` at the last successful sync |
| `syncedHash` | text, nullable | SHA-256 of the canonical synced fields at the last successful sync |
| `lossyFields` | text, nullable | Fields truncated on pull; not pushed unless edited locally |
| `state` | int enum | `synced`, `creating`, `pendingDelete`, `conflict`, `error`, `localOnly` |
| `attempts`, `lastError`, `lastAttemptAt` | | Shown in the sync issues list |

Primary key `(entityType, localPk)`. Unique index `(entityType, remoteId, remoteSubId, remoteRole)`.

### 5.2 Detecting local changes without touching the write paths

- **Created:** a local row with no map row.
- **Updated:** `dateTimeModified` is null or later than `localVersionAt`, and the canonical hash differs from `syncedHash`. The hash check stops no-op pushes when a row was only re-saved.
- **Deleted:** a `DeleteLogs` row newer than the `deleteLogCursor` in `FireflySyncMeta` whose `(type, entryPk)` has a map row. That map row becomes `pendingDelete`. Delete logs without a map row are ignored.

Both timestamps compared are local clock values, so device clock skew against the server does not matter.

Pull writes never go through `createOrUpdate*`. They use Drift batches with insert-or-replace in `lib/firefly/db/`, set the row's `dateTimeModified` to the server `updated_at`, and store the same value in `localVersionAt`, all in one database transaction. A pulled row is therefore never seen as dirty. Pull writers must apply the invariants `createOrUpdate*` would have applied: trimmed names, sign and `income` flag agreement, length limits.

### 5.3 One sync cycle

Only one cycle runs at a time. Triggers: app start and resume, pull-to-refresh, the manual button, a 5-second debounce after any local write, and a 15-minute foreground timer. There is no background isolate in the first version.

1. **Preflight.** Mode on, token present. `GET /v1/about`. On the first connect also `GET /v1/about/user`; the user id and a hash of the base URL are stored, and a later mismatch stops sync and asks for a reset.
2. **Collect local deletes** from `DeleteLogs` (5.2).
3. **Pull**, in dependency order: currencies → asset accounts → liability accounts → expense and revenue accounts → categories → tags → budgets → budget limits → bills → piggy banks → recurrences → transactions → attachments → links → rules. Conflicts are resolved here (5.5).
4. **Push creates and updates** in the same order. Requests are sequential.
5. **Push deletes** in reverse order. A 404 counts as success.
6. **Re-read** every transaction pushed in this cycle (`GET /v1/transactions/{id}`) to pick up server-side rule effects.
7. **Balance parity check.** For each asset wallet compare the local total with the server's `current_balance`. A mismatch is reported in the sync status; it does not change data.
8. **Record** cursors and a summary; refresh the status widget.

### 5.4 Pulling

**Small collections** (everything except transactions): fetch every page on every cycle.

- Unmapped remote object: if an unmapped local row has the same natural key (name, plus type for accounts), link the two; otherwise insert a local row and a map row.
- Mapped and `updated_at` later than `remoteUpdatedAt`: apply the server-owned fields; leave local-only fields alone.
- Mapped but missing from a complete listing: deleted on the server. Delete the local row and its map row in one transaction.

**Pagination.** Request `limit` from the `fireflyPageSize` setting (default 100) and loop on `meta.pagination.current_page < total_pages`, trusting the returned `per_page`. A listing is complete only if every page arrived and `total` did not change between pages. Delete detection is skipped for an incomplete listing.

**Transactions**

| Mode | When | Requests | Delete detection |
|---|---|---|---|
| Initial import | First sync, after a reset, or when a contributor version changed | `GET /v1/transactions?type=all`, all pages. The page cursor is stored so an interrupted import resumes | Not needed |
| Incremental | Every other cycle | `GET /v1/search/transactions?query=updated_at_after:<cursor − 1 day>` (A1) for edits anywhere in history, plus `GET /v1/transactions?type=all&start=<today − N>&end=<today + 366>` for the window (`N` = `fireflyTransactionWindowDays`, default 90) | A mapped row dated inside the window but absent from the complete window listing is checked with `GET /v1/transactions/{id}`: 404 deletes it locally, 200 applies the returned version |
| Full reconcile | Every 7 days and on the manual "full resync" action | Full listing, all pages | Any mapped transaction missing from the complete listing is deleted locally |

Every upsert is keyed by remote id, so repeating a page is harmless.

### 5.5 Conflict rule

Record level. The server wins.

| Local | Remote | Result |
|---|---|---|
| Clean | Changed | Apply remote |
| Dirty | Unchanged | Push local |
| Dirty | Changed | Apply remote. Save the local version to `FireflyConflicts`. If both sides hash the same, mark synced with no conflict |
| Pending delete | Unchanged | Delete on the server |
| Pending delete | Changed | Restore the local row from the server, drop the pending delete, log a conflict |
| Dirty or clean | Deleted | Delete locally. If it was dirty, save the local version to `FireflyConflicts` |
| No map row | — | Create on the server |
| — | No map row | Insert locally |

The conflicts page lets the user re-apply a saved local version, which marks the row dirty again. Firefly has no ETag or conditional write, so a change made on the server between step 3 and step 4 of the same cycle can be overwritten; this window is accepted.

### 5.6 Pushing

- **Create:** before the POST, write a map row in state `creating`. For transactions send `internal_reference = cashew:<localPk>`. If the app dies after the server stored the object, the next pull finds an unmapped remote transaction carrying that reference and links it instead of inserting a duplicate. Other entities are linked by natural key, and a 422 "already exists" on create triggers the same lookup.
- **Update:** send only the fields Cashew owns for that entity (A3), so server-only fields such as SEPA data survive. Every split in a transaction update carries its `transaction_journal_id`.
- **Flags:** `apply_rules` and `fire_webhooks` follow the settings `fireflyApplyRules` and `fireflyFireWebhooks`, both default true.
- **Amounts:** formatted from the double with the currency's decimal places into a plain decimal string, always positive for splits. Never use `double.toString()`.
- **Dates:** sent as ISO 8601 with the device offset; received instants converted to local time.
- **After success:** the response body supplies ids and `updated_at`; the map row gets the new `remoteUpdatedAt`, `localVersionAt` and `syncedHash`.

| Response | Handling |
|---|---|
| 401 | Stop the cycle, flag an auth error, ask for a new token. Keep all local data |
| 404 on update | Treat as deleted on the server (5.5) |
| 422 | Map row to `error` with the server message; not retried until the row changes; listed under sync issues |
| 429, 5xx, timeout, network | Exponential backoff with jitter, up to 5 attempts, then abort the cycle and resume on the next trigger. Request timeout 30 seconds |

### 5.7 First connection

| Mode | Behaviour | Package |
|---|---|---|
| Replace local with server (default) | Export a local database backup file, clear the finance tables, keep settings, run the initial import | WP-05 |
| Upload local data to an empty server | Allowed only when the server has no transactions; every local row is created remotely | WP-37 |
| Merge two non-empty data sets | Not supported | — |

Switching Firefly mode off keeps the local data and the map tables. Signing out deletes the token only.

## 6. Settings keys (added to `defaultPreferences.dart` by WP-00)

| Key | Default | Meaning |
|---|---|---|
| `fireflyMode` | `false` | Master switch |
| `fireflyBaseUrl` | `""` | Server URL without `/api` |
| `fireflySyncOnChange` | `true` | Debounced sync after local writes |
| `fireflyApplyRules` | `true` | Sent on transaction writes |
| `fireflyFireWebhooks` | `true` | Sent on transaction writes |
| `fireflyTransactionWindowDays` | `90` | Incremental window |
| `fireflyPageSize` | `100` | Requested page size |
| `fireflySubcategorySeparator` | `" / "` | Decision D1 |

None of these is secret. The token is never a settings key.

## 7. Secret handling

| Rule | Detail |
|---|---|
| Where the token lives | Only in `flutter_secure_storage` under the key `firefly.pat`: Keychain on iOS and macOS, Keystore-backed storage on Android, libsecret on Linux, the Windows credential store on Windows |
| Where it must never be | `appStateSettings`, shared preferences, any Drift table, backups and exports, logs, crash output, test fixtures, git |
| No secure store available | On Linux without a secret service the token is held in memory for the session only and the user is asked again on next launch. It is never written to a plain file |
| Transport | `https://` is required. Plain HTTP is accepted only for `localhost` and `127.0.0.1` in debug builds started with `--dart-define=FIREFLY_ALLOW_HTTP=true`, which is how tests reach a local server. Certificate validation is never disabled |
| Logging | The transport never logs headers or request bodies. A redactor masks `Authorization` and `Bearer` patterns before text reaches the existing `captureLogs` buffer |
| UI | The token field is obscured, is never pre-filled from storage, and the stored token is never displayed |
| Tests and E2E | Read `FIREFLY_E2E_URL` and `FIREFLY_E2E_TOKEN` from the environment and skip when unset. Fixtures use the literal `REDACTED` |
| Repository hygiene | `.gitignore` gains `.env`, `.env.*`, `*.pat` and `docker/firefly/.env`. CI runs `gitleaks` on every pull request |
| CI and release | Signing keys and any tokens come from GitHub Actions secrets only. Unsigned builds are produced when a secret is absent |
| Platform setup | macOS needs the `com.apple.security.network.client` entitlement and keychain access; Android excludes secure storage from auto-backup; Linux builds need `libsecret-1-dev` |

## 8. Work packages

### 8.1 Overview

| Id | Title | Branch | Worker | Depends on | Wave |
|---|---|---|---|---|---|
| WP-00 | Toolchain and schema v47 | `feature-firefly-schema` | Codex | — | 0a |
| WP-01 | Contracts, core repositories, stubs, test harness | `feature-firefly-foundation` | Codex | WP-00 | 0b |
| WP-02 | Legacy hook points and mode gating | `feature-firefly-hooks` | Claude | WP-01 | 1 |
| WP-03 | HTTP transport, about, currencies API, live probe | `feature-firefly-transport` | Codex | WP-01 | 1 |
| WP-04 | Sync engine orchestration | `feature-firefly-sync-engine` | Codex | WP-01 | 1 |
| WP-05 | Connection settings, first-connect flow, sync status UI | `feature-firefly-connection-ui` | Claude | WP-01 | 1 |
| WP-10 | Asset accounts ↔ wallets | `feature-firefly-accounts` | Codex | WP-01 | 1 |
| WP-11 | Categories | `feature-firefly-categories` | Codex | WP-01 | 1 |
| WP-12 | Transactions and transfers | `feature-firefly-transactions` | Codex | WP-01 | 1 |
| WP-P1 | Desktop platforms and plugin guards | `feature-platform-desktop` | Claude | WP-01 | 1 |
| WP-19 | Phase 1 integration and E2E harness | `feature-firefly-phase1-integration` | Claude | WP-02 to WP-05, WP-10 to WP-12 | 1 gate |
| WP-P2 | CI builds and release for five targets | `feature-platform-ci` | Claude | WP-P1 | 1 gate |
| WP-20a | Budgets and limits: data | `feature-firefly-budgets-data` | Codex | WP-19 | 2 |
| WP-21a | Piggy banks ↔ objectives: data | `feature-firefly-piggy-banks-data` | Codex | WP-19 | 2 |
| WP-22a | Bills and recurrences: data | `feature-firefly-bills-data` | Codex | WP-19 | 2 |
| WP-20b | Budgets UI | `feature-firefly-budgets-ui` | Claude | WP-20a | 2 |
| WP-21b | Piggy banks UI | `feature-firefly-piggy-banks-ui` | Claude | WP-21a | 2 |
| WP-22b | Bills and recurrences UI | `feature-firefly-bills-ui` | Claude | WP-22a | 2 |
| WP-29 | Phase 2 integration | `feature-firefly-phase2-integration` | Claude | All WP-2x | 2 gate |
| WP-30a | Payees: data | `feature-firefly-payees-data` | Codex | WP-19 | 3 |
| WP-31a | Tags: data | `feature-firefly-tags-data` | Codex | WP-19 | 3 |
| WP-32a | Split transactions: data | `feature-firefly-splits-data` | Codex | WP-19 | 3 |
| WP-33a | Liabilities and account details: data | `feature-firefly-liabilities-data` | Codex | WP-19 | 3 |
| WP-34a | Currencies, foreign amounts, exchange rates: data | `feature-firefly-currencies-data` | Codex | WP-19 | 3 |
| WP-35a | Attachments: data | `feature-firefly-attachments-data` | Codex | WP-19 | 3 |
| WP-30b to WP-35b | UI for each of the six features above | `feature-firefly-<feature>-ui` | Claude | The matching `a` package | 3 |
| WP-36 | Filters and search by payee, tag, bill | `feature-firefly-filters` | Claude | WP-30a, WP-31a, WP-22a | 3 |
| WP-37 | Upload existing local data to an empty server | `feature-firefly-local-upload` | Codex | WP-30a to WP-35a, WP-29 | 3 |
| WP-38 | Roaming of Cashew-only attributes through preferences (optional) | `feature-firefly-meta-roaming` | Codex | WP-19 | 3 |
| WP-39 | Phase 3 integration | `feature-firefly-phase3-integration` | Claude | All WP-3x | 3 gate |
| WP-40a | Rules and rule groups: data | `feature-firefly-rules-data` | Codex | WP-19 | 4 |
| WP-40b | Rules UI with test and trigger | `feature-firefly-rules-ui` | Claude | WP-40a | 4 |
| WP-41 | Object groups and transaction links | `feature-firefly-links-groups` | Codex | WP-39 | 4 |
| WP-49 | Final integration, docs, release hardening | `feature-firefly-final-integration` | Claude | Everything | 4 gate |

The "Depends on WP-19" entries in waves 2 to 4 are a quality gate, not a code dependency. Technically those data packages need only WP-01 and the transaction DTO from WP-12, so the orchestrator may start waves 2, 3 and 4 data packages together once WP-12 is merged if capacity allows. Phase 2, 3 and 4 data packages are mutually independent.

```
0a  WP-00
0b  WP-01
1   WP-02  WP-03  WP-04  WP-05  WP-10  WP-11  WP-12  WP-P1      (8 parallel)
    WP-19 (after 02-05, 10-12)        WP-P2 (after P1)
2   WP-20a WP-21a WP-22a   →   WP-20b WP-21b WP-22b   →   WP-29
3   WP-30a … WP-35a, WP-38   →   WP-30b … WP-35b, WP-36, WP-37   →   WP-39
4   WP-40a   →   WP-40b, WP-41   →   WP-49
```

Paths below are relative to `budget/` unless they start with `.github/`, `docs/` or `docker/`. "DoD" means section 9.

### 8.2 Wave 0

#### WP-00 — Toolchain and schema v47

- **Branch:** `feature-firefly-schema` · **Worker:** Codex · **Depends on:** nothing
- **Files owned:** `pubspec.yaml`, `pubspec.lock`, `.fvmrc`, `analysis_options.yaml`, `lib/firefly/analysis_options.yaml`, `lib/platform/analysis_options.yaml`, `test/analysis_options.yaml`, `lib/database/tables.dart` (table classes, enums, database annotation, migration only), `lib/database/tables.g.dart`, `lib/database/schema_versions.dart`, `drift_schemas/drift_schema_v47.json`, `lib/struct/defaultPreferences.dart`, `test/widget_test.dart` (delete), `test/database/**`, `.gitignore`, `.gitleaks.toml`, `.github/workflows/ci.yml`, `docs/plan/analyze-baseline.txt`
- **Scope:**
  - Add a gitleaks baseline for findings already in upstream code (for example the Firebase client keys in `lib/firebase_options.dart`), so gate G6 reports new findings only.
  - Find the newest Flutter version that resolves the committed lock file (`intl 0.18.1` points at 3.19.x) and pin it in `.fvmrc` and CI.
  - Add dependencies: `http`, `flutter_secure_storage`, `crypto`, `uuid` and `async` as direct dependencies; `flutter_test`, `integration_test`, `mocktail`, `flutter_lints` as dev dependencies.
  - Implement section 3 exactly, following the README migration procedure: bump to 47, run the generator, dump the schema, generate steps, add `from46To47` with the same try/catch style as recent steps.
  - Add the settings keys from section 6.
  - Record the analyzer baseline, then make the new directories strict through nested analysis options.
  - `ci.yml`: on pull requests run pub get, analyze, test and gitleaks.
- **Acceptance:**
  1. DoD.
  2. A migration test opens a database created from `drift_schema_v46.json`, migrates to 47, and passes Drift schema verification; a fresh install also yields schema 47.
  3. A test inserts and reads one row in each new table and each new column.
  4. `flutter test` passes with the template test removed.
  5. `docs/plan/analyze-baseline.txt` holds the issue count and the pinned Flutter version.
  6. With no other change, the app builds for Android (`flutter build apk --debug`).

#### WP-01 — Contracts, core repositories, stubs, test harness

- **Branch:** `feature-firefly-foundation` · **Worker:** Codex · **Depends on:** WP-00
- **Files owned:** everything under `lib/firefly/` (creates the whole tree of section 2.3), `lib/platform/capabilities.dart`, `lib/struct/languageMap.dart`, `assets/translations/firefly/en/core.json`, `pubspec.yaml` (asset entry only), `test/support/**`, `test/firefly/core/**`, `docs/plan/CONTRACTS.md`
- **Scope:**
  - Contracts of section 2.4 with real implementations of: the four repositories, `TokenStore`, config and URL normalisation, log redaction, amount and date codecs, hashing, `conflict_policy` (the table in 5.5 as a pure function), `dirty_tracker` (5.2), and `collection_sync` (5.4 small collections plus 5.6).
  - No-op stubs for: `http_transport.dart`, `engine.dart`, `scheduler.dart`, every syncer, contributor, resource client, DTO file, UI slot implementation and hub entry named in section 8. Registries list all of them in the order of 5.3 and are then frozen.
  - Where one package calls another package's resource client or query file (for example WP-10 calling the currencies client that WP-03 implements, or WP-30a and WP-33a calling the accounts client from WP-10), the stub declares that method signature so both sides compile against it.
  - `PlatformCapabilities` with conservative values (true only where the app runs today).
  - Extend the translation asset loader to merge every JSON file under `assets/translations/firefly/en/` over the generated translations, for all locales.
  - Test harness: fake `FireflyTransport`, an in-process fake Firefly HTTP server with pagination and the JSON:API envelope, an in-memory database factory, fixture builders.
  - `CONTRACTS.md`: every public name, its signature, the stub file each later package fills, and one worked example of a syncer built on `collection_sync`.
- **Acceptance:**
  1. DoD.
  2. Unit tests cover every row of the conflict table, the three dirty cases of 5.2, the pagination loop including the incomplete-listing case, natural-key linking, the `creating` crash-recovery path, and the amount codec for 0, 2 and 3 decimal places.
  3. A token written through `TokenStore` appears in none of: shared preferences, the database file, the log buffer (test with a fake secure storage backend).
  4. The redactor masks a bearer token in a sample log line.
  5. With every stub in place the app builds and behaves as before; a test proves a string from `core.json` resolves through the loader.
  6. Line coverage of `lib/firefly/sync/` and `lib/firefly/db/` is at least 85%.

### 8.3 Wave 1 — Phase 1 core sync, and platforms

#### WP-02 — Legacy hook points and mode gating

- **Branch:** `feature-firefly-hooks` · **Worker:** Claude · **Depends on:** WP-01
- **Files owned:** `lib/main.dart`, `lib/struct/syncClient.dart`, `lib/struct/shareBudget.dart`, `lib/struct/uploadAttachment.dart`, `lib/widgets/accountAndBackup.dart`, `lib/widgets/navigationFramework.dart`, `lib/widgets/navigationSidebar.dart`, `lib/widgets/pullDownToRefreshSync.dart`, `lib/widgets/transactionEntry/**`, `lib/pages/accountsPage.dart`, `lib/pages/settingsPage.dart`, `lib/pages/addTransactionPage.dart`, `lib/pages/addWalletPage.dart`, `assets/translations/firefly/en/hooks.json`, `test/firefly/hooks/**`
- **Scope:** minimal, one-line-style insertions only.
  - `main.dart`: guard Firebase initialisation with `PlatformCapabilities.supportsFirebase`; initialise the Firefly facade after settings load.
  - Drive: early return from `createSyncBackup`, `_syncData`, `createBackupInBackground`, silent sign-in, the sign-in fly-in and the backup reminder when `googleDriveAvailable` is false. `cancelAndPreventSyncOperation` also cancels a running Firefly cycle. Hide the Google account, backup, shared-budget and Gmail-scanning entries in settings and sidebar in Firefly mode.
  - `runAllCloudFunctions`, pull-to-refresh, the sidebar sync button and the change listener call the engine when Firefly mode is on.
  - Slots: `FireflySettingsEntry` and `FireflyHubSection` in the settings page; `FireflySyncStatus` where the last-synced label is shown; `FireflyTransactionExtras` plus draft `load` and `persist` calls in the add-transaction page; `FireflyTransactionEntryExtras` in the transaction row; `FireflyWalletExtras` in the add-wallet page.
  - Add-transaction page: hide the lent and borrowed types in Firefly mode; make rows with `fireflyType` of reconciliation or opening balance read-only.
  - `uploadAttachment.dart`: in Firefly mode route to the attachments slot instead of Drive; use `supportsCamera`.
- **Acceptance:**
  1. DoD.
  2. Widget tests: with Firefly mode off the settings page shows exactly one new entry and no Firefly network call is made; with it on, the Google sections are absent and the slots render.
  3. A test proves `createSyncBackup` and `syncData` return false without touching Google APIs in Firefly mode.
  4. The diff of each legacy file is insertions and guard conditions only; no reformatting.

#### WP-03 — HTTP transport, about, currencies API, live probe

- **Branch:** `feature-firefly-transport` · **Worker:** Codex · **Depends on:** WP-01
- **Files owned:** `lib/firefly/api/http_transport.dart`, `lib/firefly/api/models/{about,currency}.dart`, `lib/firefly/api/resources/{about,currencies}_api.dart`, `test/firefly/transport/**`, `tool/firefly_probe/**`, `docs/plan/API-NOTES.md`
- **Scope:** real transport per sections 5.6 and 7 (bearer header, `X-Trace-Id`, envelope decoding, typed errors, backoff, timeout, HTTPS rule, upload and download streams, at most 4 concurrent GETs); about and currencies clients including enable; a probe script that runs against a disposable Firefly 6.6.2 and answers assumptions A1 to A7.
- **Acceptance:**
  1. DoD.
  2. Tests against the fake server cover each row of the error table in 5.6, the backoff attempt count, HTTPS enforcement with the debug localhost exception, and that no header value reaches the log buffer.
  3. `API-NOTES.md` states the result for each of A1 to A7, or records that no live server was available; the probe reads its URL and token from the environment only.

#### WP-04 — Sync engine orchestration

- **Branch:** `feature-firefly-sync-engine` · **Worker:** Codex · **Depends on:** WP-01
- **Files owned:** `lib/firefly/sync/engine.dart`, `lib/firefly/sync/scheduler.dart`, `lib/firefly/db/delete_log_queries.dart`, `test/firefly/engine/**`
- **Scope:** the cycle of 5.3: single-flight lock, cancellation, preflight and identity check, delete-log collection, ordered pull, push, reverse-order deletes, re-read step, balance parity check, cursors, progress reporting through the existing global loading keys, the triggers, the weekly full reconcile, the contributor-version check.
- **Acceptance:**
  1. DoD.
  2. Tests with fake syncers prove: order of calls; a second trigger during a cycle does not start a second cycle; cancellation stops between entities; a 401 aborts and leaves data intact; an error in one syncer is reported and later independent syncers still run; changed server identity blocks sync.
  3. A test proves a delete log with a map row becomes `pendingDelete` and one without is ignored.

#### WP-05 — Connection settings, first-connect flow, sync status UI

- **Branch:** `feature-firefly-connection-ui` · **Worker:** Claude · **Depends on:** WP-01
- **Files owned:** `lib/firefly/ui/settings/**`, `lib/firefly/ui/pages/connection/**`, `lib/firefly/db/reset_queries.dart`, `lib/pages/onBoardingPage.dart`, `assets/translations/firefly/en/connection.json`, `test/firefly/connection_ui/**`
- **Scope:** settings page for URL and token with a connection test that shows the server version and user; mode switch; the first-connect flow of 5.7 (replace local with server, with the automatic backup export and a confirmation); sync status widget (last sync, progress, parity result); sync issues list; conflicts list with re-apply; sign out; full resync; advanced settings of section 6; an optional "connect to Firefly III" step in onboarding.
- **Acceptance:**
  1. DoD.
  2. Widget tests: invalid URL and non-HTTPS URL are rejected with a message; a failed connection test does not save the token; the token field is obscured and empty on reopen; sign out removes the token and keeps data.
  3. A test proves the replace flow writes a backup file before any table is cleared and leaves settings intact.
  4. Layout checked at phone width and at a desktop width of 1280.

#### WP-10 — Asset accounts ↔ wallets

- **Branch:** `feature-firefly-accounts` · **Worker:** Codex · **Depends on:** WP-01
- **Files owned:** `lib/firefly/api/models/account.dart`, `lib/firefly/api/resources/accounts_api.dart`, `lib/firefly/sync/entities/wallet_account_syncer.dart`, `lib/firefly/db/wallet_queries.dart`, `test/firefly/accounts/**`
- **Scope:** the complete account DTO and client for all account types (later packages reuse them); the asset syncer per section 4, including mapping the primary account onto wallet `"0"`, enabling the currency before create, filling `AccountDetails`, and keeping `selectedWalletPk` valid after deletes.
- **Acceptance:**
  1. DoD.
  2. Round-trip tests on the fake server: pull creates wallets with the right currency and decimals; local create, rename, reorder and delete reach the server; a remote delete removes the wallet and its transactions locally; local-only fields survive a pull.
  3. A test proves the primary account lands on wallet `"0"` and a second device linking the same server does the same.

#### WP-11 — Categories

- **Branch:** `feature-firefly-categories` · **Worker:** Codex · **Depends on:** WP-01
- **Files owned:** `lib/firefly/api/models/category.dart`, `lib/firefly/api/resources/categories_api.dart`, `lib/firefly/sync/entities/category_syncer.dart`, `lib/firefly/db/category_queries.dart`, `test/firefly/categories/**`
- **Scope:** category syncer per section 4, including the subcategory naming convention, icon heuristic for new remote categories, and exclusion of category `"0"`.
- **Acceptance:**
  1. DoD.
  2. Round-trip tests: create, rename, delete in both directions; `Food / Groceries` on the server becomes a subcategory of `Food` and back; a renamed parent renames its pushed children; category `"0"` never produces a request.
  3. Colour, icon, order and the income flag survive a pull.

#### WP-12 — Transactions and transfers

- **Branch:** `feature-firefly-transactions` · **Worker:** Codex · **Depends on:** WP-01
- **Files owned:** `lib/firefly/api/models/transaction.dart`, `lib/firefly/api/resources/{transactions,search}_api.dart`, `lib/firefly/sync/entities/transaction_syncer.dart`, `lib/firefly/db/transaction_queries.dart`, `test/firefly/transactions/**`
- **Scope:** the complete transaction DTO (every split field of section 1.2); the syncer for all five split types and for multi-split groups per section 4; the three pull modes of 5.4; push per 5.6 including `internal_reference`, journal ids on update, lossy fields; calling every registered contributor in both directions; unpaid upcoming rows kept `localOnly` until paid.
- **Acceptance:**
  1. DoD.
  2. Mapping tests for withdrawal, deposit, same-currency transfer, cross-currency transfer, opening balance, reconciliation, and a three-split group, in both directions.
  3. Pull tests for initial import with resume after interruption, incremental with and without the search operator, window delete detection with the 404 confirmation, and full reconcile.
  4. Push tests: create, edit, delete; deleting one side of a transfer deletes the remote transfer; a 422 marks the row `error`; crash between POST and map write does not duplicate.
  5. A 600-character server note is truncated locally and is not pushed back when another field is edited.
  6. Amount tests for JPY (0 decimals), USD (2) and KWD (3) with no floating-point artefacts in the request body.

#### WP-P1 — Desktop platforms and plugin guards

- **Branch:** `feature-platform-desktop` · **Worker:** Claude · **Depends on:** WP-01
- **Files owned:** `macos/**`, `linux/**`, `windows/**`, `.metadata`, `pubspec.yaml` and `pubspec.lock` (sole owner from wave 1 on), `lib/platform/**`, `lib/functions.dart`, `lib/colors.dart`, `lib/firebase_options.dart`, `lib/database/platform/native.dart`, `lib/struct/{firebaseAuthGlobal,initializeNotifications,notificationsGlobal,initializeBiometrics,quickActions}.dart`, `lib/widgets/{notificationsSettings,ratingPopup,importDB,importCSV,exportDB,exportCSV}.dart`, `lib/widgets/util/{checkWidgetLaunch,saveFile,appLinks}.dart`, `lib/pages/{premiumPage,notificationsPage,autoTransactionsPageEmail}.dart`, `android/**` and `ios/**` (only for secure storage and backup exclusion), `test/platform/**`, `docs/platforms.md`
- **Scope:**
  - Generate the missing folders with `flutter create --platforms=macos,linux,windows .` and keep existing platform folders untouched.
  - Set real values in `PlatformCapabilities` and guard every plugin call that has no implementation on a target:

    | Plugin | Desktop situation at the locked version | Action |
    |---|---|---|
    | `google_sign_in`, Drive, Gmail | No Linux or Windows; macOS needs its own client configuration | Capability false on all three desktops; entries hidden |
    | `firebase_core`, `firebase_auth`, `cloud_firestore` | Options throw on desktop; no Linux support | Capability false on desktop; shared budgets hidden |
    | `flutter_local_notifications` 17.x | macOS and Linux yes, Windows no | Add macOS and Linux initialisation; guard Windows or upgrade |
    | `local_auth` | macOS and Windows yes, Linux no | Guard Linux |
    | `flutter_secure_storage` | All five | Add entitlements and Linux build dependency |
    | `file_picker` (git fork), `image_picker` | Pickers work; no camera | Guard camera; add macOS file-access entitlement; verify the fork builds on all three |
    | `home_widget`, `quick_actions`, `notification_listener_service`, `flutter_displaymode`, `app_settings` | Mobile only | Guard |
    | `in_app_purchase`, `in_app_review` | No Linux or Windows | Guard; desktop premium behaviour per decision D7 |
    | `flutter_timezone` 1.x | No Linux or Windows | Fallback to the system zone name or upgrade |
    | `flutter_charset_detector` | Unverified on desktop | Fallback to UTF-8 decoding |

  - Store the database in the application support directory on desktop.
  - macOS entitlements for network client, keychain and user-selected files; sensible minimum window size on desktop.
- **Acceptance:**
  1. DoD.
  2. `flutter build macos`, `flutter build linux` and `flutter build windows` succeed in debug and release; Android and iOS still build.
  3. On each desktop OS the app starts on a fresh profile, passes onboarding, adds a transaction, and exports then imports a backup, with no `MissingPluginException` or unsupported-platform error in the log.
  4. The WP-01 token store test passes on macOS, Linux and Windows.
  5. `docs/platforms.md` lists per platform which features are available and the build prerequisites.

#### WP-19 — Phase 1 integration and E2E harness

- **Branch:** `feature-firefly-phase1-integration` · **Worker:** Claude · **Depends on:** WP-02, WP-03, WP-04, WP-05, WP-10, WP-11, WP-12
- **Files owned:** `docker/firefly/**`, `integration_test/**`, `test/firefly/e2e/**`, `docs/firefly/testing.md`, and during this package only: seam fixes in any `lib/firefly/**` file and non-schema fixes in `lib/database/tables.dart`
- **Scope:** Docker Compose for Firefly III 6.6.2 with a throwaway database; scripted user and token creation (A7); an E2E suite driven by environment variables; a fake-server integration suite that needs no Docker; fix whatever the first real end-to-end run exposes; apply the A1 to A7 results from `API-NOTES.md`.
- **Acceptance:**
  1. DoD.
  2. E2E against Docker: connect; initial import of a seeded data set (3 asset accounts in 2 currencies, 20 categories, 500 transactions including transfers and one split); every local wallet total equals the server `current_balance`.
  3. E2E two-way: create, edit and delete an account, a category, a withdrawal, a deposit and a transfer locally and see them on the server; do the same on the server and see them locally after sync.
  4. E2E conflict: edit the same transaction on both sides; the server version wins and the conflicts table holds the local one.
  5. E2E offline: 10 local edits with the server stopped, then start the server; one cycle pushes all 10 exactly once.
  6. A second sync with no changes sends no write request.
  7. With Firefly mode off, the full legacy flow (onboarding, add transaction, backup export) still passes.

#### WP-P2 — CI builds and release for five targets

- **Branch:** `feature-platform-ci` · **Worker:** Claude · **Depends on:** WP-P1
- **Files owned:** `.github/workflows/**` except `ci.yml`, `scripts/ci/**`, `docs/release.md`
- **Scope:**
  - `build.yml` on pull requests: build matrix for Android (Ubuntu), iOS (macOS, `--no-codesign`), macOS, Linux (Ubuntu with GTK, libsecret, ninja, clang, cmake) and Windows; `flutter test` on Ubuntu, macOS and Windows runners so the sync suite runs on all three desktop operating systems.
  - `release.yml` on tags `v*`: release builds and one artifact per target attached to the GitHub release: APK and AAB, unsigned iOS archive, macOS app zip, Linux tar.gz, Windows zip. Signing is applied only when the matching secret exists.
  - A Linux job that starts the Docker Firefly from WP-19 and runs the E2E suite, once WP-19 is merged.
  - Remove or disable the inherited Firebase Hosting workflow.
- **Acceptance:**
  1. DoD.
  2. A pull request run shows five green build jobs and three green test jobs.
  3. Pushing a test tag on a fork produces a release with five platform artifacts, each of which starts on its platform.
  4. No workflow echoes a secret; workflows pin the Flutter version from `.fvmrc`; all third-party actions are pinned to a commit.

### 8.4 Wave 2 — Phase 2: budgets, piggy banks, bills and recurrences

#### WP-20a — Budgets and limits: data

- **Branch:** `feature-firefly-budgets-data` · **Worker:** Codex · **Depends on:** WP-19
- **Files owned:** `lib/firefly/api/models/{budget,budget_limit,available_budget}.dart`, `lib/firefly/api/resources/budgets_api.dart`, `lib/firefly/sync/entities/{budget,budget_limit}_syncer.dart`, `lib/firefly/sync/contributors/budget_contributor.dart`, `lib/firefly/db/budget_queries.dart`, `test/firefly/budgets/**`
- **Scope:** section 4 rows for budget, budget limit and available budget; period mapping; the contributor linking split `budget_id` and `sharedReferenceBudgetPk`.
- **Acceptance:** DoD; round-trip tests for budget create, rename, archive, delete; limit create, edit, delete for current and past periods; auto-budget period mapping for all six Firefly periods; a withdrawal assigned to a budget on either side shows on the other; local-only budget fields survive a pull; `CategoryBudgetLimits` produces no request.

#### WP-20b — Budgets UI

- **Branch:** `feature-firefly-budgets-ui` · **Worker:** Claude · **Depends on:** WP-20a
- **Files owned:** `lib/pages/{addBudgetPage,budgetPage,budgetsListPage,editBudgetPage,pastBudgetsPage,editBudgetLimitsPage}.dart`, `lib/widgets/{budgetContainer,categoryLimits}.dart`, `lib/firefly/ui/transaction/budget_section.dart`, `lib/firefly/ui/pages/budgets/**`, `assets/translations/firefly/en/budgets.json`, `test/firefly/budgets_ui/**`
- **Scope:** in Firefly mode a new budget is an envelope (added-transactions-only, fixed); options Firefly cannot represent are hidden; limit editing per period; available-budget display; a budget picker in the add-transaction slot for withdrawals.
- **Acceptance:** DoD; widget tests for the restricted budget form, the per-period limit editor and the budget picker; with Firefly mode off all budget pages are unchanged (golden or widget comparison).

#### WP-21a — Piggy banks ↔ objectives: data

- **Branch:** `feature-firefly-piggy-banks-data` · **Worker:** Codex · **Depends on:** WP-19
- **Files owned:** `lib/firefly/api/models/piggy_bank.dart`, `lib/firefly/api/resources/piggy_banks_api.dart`, `lib/firefly/sync/entities/piggy_bank_syncer.dart`, `lib/firefly/sync/contributors/piggy_bank_contributor.dart`, `lib/firefly/db/objective_queries.dart`, `test/firefly/piggy_banks/**`
- **Scope:** section 4 piggy bank row; cached current amount and events; add and remove money through `PUT`; loan-type objectives excluded.
- **Acceptance:** DoD; round-trip tests for create, edit, delete; adding money locally changes `current_amount` on the server and yields an event on the next pull; a server event naming a journal sets `objectiveFk`; loan objectives produce no request.

#### WP-21b — Piggy banks UI

- **Branch:** `feature-firefly-piggy-banks-ui` · **Worker:** Claude · **Depends on:** WP-21a
- **Files owned:** `lib/pages/{addObjectivePage,objectivePage,objectivesListPage,editObjectivesPage}.dart`, `lib/firefly/ui/transaction/piggy_section.dart`, `lib/firefly/ui/pages/piggy_banks/**`, `assets/translations/firefly/en/piggy_banks.json`, `test/firefly/piggy_banks_ui/**`
- **Scope:** in Firefly mode goal progress comes from the server amount; add and remove money action; event history; account selection; loan objective creation hidden.
- **Acceptance:** DoD; widget tests for progress display, the add-money flow and the hidden loan option; legacy mode unchanged.

#### WP-22a — Bills and recurrences: data

- **Branch:** `feature-firefly-bills-data` · **Worker:** Codex · **Depends on:** WP-19
- **Files owned:** `lib/firefly/api/models/{bill,recurrence}.dart`, `lib/firefly/api/resources/{bills,recurrences}_api.dart`, `lib/firefly/sync/entities/{bill,recurrence}_syncer.dart`, `lib/firefly/sync/contributors/bill_contributor.dart`, `lib/firefly/db/bill_recurrence_queries.dart`, `test/firefly/bills/**`
- **Scope:** bills and recurrences in the resource cache with offline create, edit and delete; the bill link contributor; next-occurrence computation from server data; the recurrence trigger call.
- **Acceptance:** DoD; round-trip tests for bill and recurrence create, edit, delete; all five bill frequencies and all five repetition types parse and serialise; linking a transaction to a bill on either side shows on the other; trigger returns the created transaction and it is imported.

#### WP-22b — Bills and recurrences UI

- **Branch:** `feature-firefly-bills-ui` · **Worker:** Claude · **Depends on:** WP-22a
- **Files owned:** `lib/pages/{subscriptionsPage,upcomingOverdueTransactionsPage}.dart`, `lib/struct/upcomingTransactionsFunctions.dart`, `lib/firefly/ui/transaction/bill_section.dart`, `lib/firefly/ui/hub/{bills,recurrences}_entry.dart`, `lib/firefly/ui/pages/bills/**`, `assets/translations/firefly/en/bills.json`, `test/firefly/bills_ui/**`
- **Scope:** in Firefly mode the subscriptions page lists bills with paid and expected dates; a recurrences page with editor and "create now"; upcoming list fed by recurrence occurrences; Cashew's own auto-creation of the next occurrence switched off for server recurrences; bill picker in the add-transaction slot.
- **Acceptance:** DoD; widget tests for the bill list, bill editor, recurrence editor and the trigger action; a test proves no local auto-created duplicate appears for a server recurrence; legacy mode unchanged.

#### WP-29 — Phase 2 integration

- **Branch:** `feature-firefly-phase2-integration` · **Worker:** Claude · **Depends on:** all WP-2x
- **Files owned:** `integration_test/phase2/**`, `test/firefly/e2e/phase2/**`, and during this package only: seam fixes in `lib/firefly/**` and non-schema fixes in `lib/database/tables.dart`
- **Acceptance:** DoD; E2E against Docker for budgets with limits, piggy banks with money added on both sides, bills linked to transactions and a triggered recurrence; the contributor-version change caused a full transaction re-pull exactly once; all Phase 1 E2E tests still pass.

### 8.5 Wave 3 — Phase 3: payees, tags, splits, liabilities, currencies, attachments

Each feature has a data package (worker: Codex, depends on WP-19) and a UI package (worker: Claude, depends on its own data package). All six data packages run in parallel, then all six UI packages.

| Id | Branch | Files owned | Scope | Feature-specific acceptance (in addition to DoD) |
|---|---|---|---|---|
| WP-30a Payees data | `feature-firefly-payees-data` | `lib/firefly/sync/entities/payee_account_syncer.dart`, `lib/firefly/sync/contributors/payee_contributor.dart`, `lib/firefly/db/payee_queries.dart`, `test/firefly/payees/**` | Expense and revenue accounts ↔ `Payees` using the WP-10 client; contributor for withdrawal destination and deposit source | Round trips for payee create, rename, delete; a withdrawal's payee set on either side shows on the other; a transaction without a payee sends no destination name |
| WP-30b Payees UI | `feature-firefly-payees-ui` | `lib/firefly/ui/transaction/payee_section.dart`, `lib/firefly/ui/entry/payee_chip.dart`, `lib/firefly/ui/hub/payees_entry.dart`, `lib/firefly/ui/pages/payees/**`, `assets/translations/firefly/en/payees.json`, `test/firefly/payees_ui/**` | Payee picker with search and create-inline; payee chip on rows; payees list, edit, delete; per-payee transaction list | Widget tests for picker, chip and list page |
| WP-31a Tags data | `feature-firefly-tags-data` | `lib/firefly/api/models/tag.dart`, `lib/firefly/api/resources/tags_api.dart`, `lib/firefly/sync/entities/tag_syncer.dart`, `lib/firefly/sync/contributors/tags_contributor.dart`, `lib/firefly/db/tag_queries.dart`, `test/firefly/tags/**` | Tags and the junction table; contributor for split `tags[]` | Round trips for tag create, rename, delete; adding and removing tags on a transaction on either side; non-ASCII tag names addressed by id |
| WP-31b Tags UI | `feature-firefly-tags-ui` | `lib/firefly/ui/transaction/tags_section.dart`, `lib/firefly/ui/entry/tags_chip.dart`, `lib/firefly/ui/hub/tags_entry.dart`, `lib/firefly/ui/pages/tags/**`, `assets/translations/firefly/en/tags.json`, `test/firefly/tags_ui/**` | Tag chips input; tag chips on rows; tags management page | Widget tests for input, chips and management page |
| WP-32a Splits data | `feature-firefly-splits-data` | `lib/firefly/sync/contributors/split_group_contributor.dart`, `lib/firefly/db/split_queries.dart`, `test/firefly/splits/**` | Create a group from several local rows; add a split to and remove a split from an existing group (`DELETE /v1/transaction-journals/{id}`); group title; convert single ↔ split | Round trips for create 3-split group, add split, remove split, change group title, delete whole group; sums verified against the server |
| WP-32b Splits UI | `feature-firefly-splits-ui` | `lib/firefly/ui/transaction/split_section.dart`, `lib/firefly/ui/entry/split_chip.dart`, `lib/firefly/ui/pages/splits/**`, `assets/translations/firefly/en/splits.json`, `test/firefly/splits_ui/**` | Split editor in the add-transaction slot (rows with amount, category, description; running total); grouped display in lists | Widget tests for the editor including total validation and for grouped rows |
| WP-33a Liabilities data | `feature-firefly-liabilities-data` | `lib/firefly/sync/entities/liability_account_syncer.dart`, `lib/firefly/db/liability_queries.dart`, `test/firefly/liabilities/**` | Liability accounts ↔ wallets with `accountKind = liability`; all `AccountDetails` fields for asset and liability accounts in both directions | Round trips for loan, debt, mortgage in both directions; payments to a liability appear as transfers; net-worth flag respected |
| WP-33b Liabilities UI | `feature-firefly-liabilities-ui` | `lib/pages/{walletDetailsPage,editWalletsPage}.dart`, `lib/widgets/walletEntry.dart`, `lib/firefly/ui/wallet/**`, `lib/firefly/ui/hub/liabilities_entry.dart`, `lib/firefly/ui/pages/liabilities/**`, `assets/translations/firefly/en/liabilities.json`, `test/firefly/liabilities_ui/**` | Account details section (role, IBAN, notes, net-worth flag); liabilities list and editor; archived accounts shown separately | Widget tests for the details section and liabilities pages; legacy wallet pages unchanged with Firefly mode off |
| WP-34a Currencies data | `feature-firefly-currencies-data` | `lib/firefly/api/models/exchange_rate.dart`, `lib/firefly/api/resources/exchange_rates_api.dart`, `lib/firefly/sync/entities/currency_syncer.dart`, `lib/firefly/sync/contributors/foreign_currency_contributor.dart`, `lib/firefly/db/currency_queries.dart`, `test/firefly/currencies/**` | Currency list cache with enable, disable and primary; contributor for `foreign_amount` and `foreign_currency_code`; optional exchange rates from the server | Round trips for a withdrawal with a foreign amount in both directions; currencies missing from Cashew's static list are registered as custom currencies; primary currency read correctly |
| WP-34b Currencies UI | `feature-firefly-currencies-ui` | `lib/pages/exchangeRatesPage.dart`, `lib/struct/currencyFunctions.dart`, `lib/widgets/currencyPicker.dart`, `lib/firefly/ui/transaction/foreign_amount_section.dart`, `lib/firefly/ui/entry/foreign_amount_chip.dart`, `lib/firefly/ui/hub/currencies_entry.dart`, `lib/firefly/ui/pages/currencies/**`, `assets/translations/firefly/en/currencies.json`, `test/firefly/currencies_ui/**` | Foreign amount and currency input; foreign amount on rows; server currencies page; switch to use server exchange rates | Widget tests for the input, chip and currencies page |
| WP-35a Attachments data | `feature-firefly-attachments-data` | `lib/firefly/api/models/attachment.dart`, `lib/firefly/api/resources/attachments_api.dart`, `lib/firefly/sync/entities/attachment_syncer.dart`, `lib/firefly/sync/contributors/attachments_contributor.dart`, `lib/firefly/db/attachment_queries.dart`, `test/firefly/attachments/**` | Metadata sync; two-step upload; lazy download into the app support directory; offline queue; size limit and hash check | Round trips for upload, rename, delete; a queued offline upload is sent once; a download matches the server hash; no file is written outside the app support directory |
| WP-35b Attachments UI | `feature-firefly-attachments-ui` | `lib/firefly/ui/transaction/attachments_section.dart`, `lib/firefly/ui/entry/attachment_chip.dart`, `lib/firefly/ui/pages/attachments/**`, `assets/translations/firefly/en/attachments.json`, `test/firefly/attachments_ui/**` | Attach from file picker, gallery, or camera where supported; list, open, delete; indicator on rows | Widget tests for the section; manual check on one mobile and one desktop target |

Further wave 3 packages:

#### WP-36 — Filters and search by payee, tag, bill

- **Branch:** `feature-firefly-filters` · **Worker:** Claude · **Depends on:** WP-30a, WP-31a, WP-22a
- **Files owned:** `lib/pages/{transactionFilters,transactionsSearchPage}.dart`, `lib/firefly/db/filter_queries.dart`, `assets/translations/firefly/en/filters.json`, `test/firefly/filters/**`
- **Acceptance:** DoD; filter tests for payee, tag (any and all), bill, reconciled, has-attachment; filters hidden with Firefly mode off.

#### WP-37 — Upload existing local data to an empty server

- **Branch:** `feature-firefly-local-upload` · **Worker:** Codex · **Depends on:** WP-30a to WP-35a, WP-29
- **Files owned:** `lib/firefly/sync/bootstrap_upload.dart`, `lib/firefly/ui/pages/connection/upload_flow.dart`, `assets/translations/firefly/en/upload.json`, `test/firefly/upload/**`
- **Acceptance:** DoD; refuses when the server has any transaction; E2E uploads a generated local data set (existing `generatePreviewData`) and the parity check passes for every wallet; an interrupted upload resumes without duplicates; lent, borrowed and unpaid rows are reported as skipped.

#### WP-38 — Roaming of Cashew-only attributes through preferences (optional)

- **Branch:** `feature-firefly-meta-roaming` · **Worker:** Codex · **Depends on:** WP-19
- **Files owned:** `lib/firefly/api/models/preference.dart`, `lib/firefly/api/resources/preferences_api.dart`, `lib/firefly/sync/meta_roaming.dart`, `test/firefly/meta_roaming/**`
- **Acceptance:** DoD; colours, icons and ordering set on one database appear on a second database linked to the same fake server; last-writer-wins per attribute; switched off by default behind a setting.

#### WP-39 — Phase 3 integration

- **Branch:** `feature-firefly-phase3-integration` · **Worker:** Claude · **Depends on:** all WP-3x
- **Files owned:** `integration_test/phase3/**`, `test/firefly/e2e/phase3/**`, and during this package only: seam fixes in `lib/firefly/**` and non-schema fixes in `lib/database/tables.dart`
- **Acceptance:** DoD; E2E against Docker creating one transaction that has a payee, two tags, a foreign amount, a budget, a bill and an attachment, verified on the server and on a second local database; a split group round trip; a liability payment; all earlier E2E suites pass; the add-transaction page is usable at phone width with every section present.

### 8.6 Wave 4 — Phase 4: rules, remaining parity, release

#### WP-40a — Rules and rule groups: data

- **Branch:** `feature-firefly-rules-data` · **Worker:** Codex · **Depends on:** WP-19
- **Files owned:** `lib/firefly/api/models/{rule,rule_group}.dart`, `lib/firefly/api/resources/rules_api.dart`, `lib/firefly/sync/entities/rule_syncer.dart`, `lib/firefly/db/rule_queries.dart`, `test/firefly/rules/**`
- **Scope:** CRUD for rules and rule groups with cache; trigger and action keyword lists taken from the 6.6.2 spec; `test` and `trigger` calls for rules and groups with date range and account filters.
- **Acceptance:** DoD; round trips for rule and group create, edit, reorder, delete; every trigger and action keyword in the spec parses; `test` returns matching transactions; `trigger` handles the 204 and schedules a transaction pull.

#### WP-40b — Rules UI with test and trigger

- **Branch:** `feature-firefly-rules-ui` · **Worker:** Claude · **Depends on:** WP-40a
- **Files owned:** `lib/firefly/ui/hub/rules_entry.dart`, `lib/firefly/ui/pages/rules/**`, `assets/translations/firefly/en/rules.json`, `test/firefly/rules_ui/**`
- **Scope:** rule groups and rules list; rule editor (triggers, actions, strict, stop processing, active); "test" showing matches; "run now" on a rule or a group with date range and accounts, followed by a sync; clear offline state (viewing works offline, editing and running need a connection).
- **Acceptance:** DoD; widget tests for list, editor validation, test result view and run flow; offline state shows a disabled run button with an explanation.

#### WP-41 — Object groups and transaction links

- **Branch:** `feature-firefly-links-groups` · **Worker:** Codex · **Depends on:** WP-39
- **Files owned:** `lib/firefly/api/models/{object_group,transaction_link}.dart`, `lib/firefly/api/resources/{object_groups,transaction_links}_api.dart`, `lib/firefly/sync/entities/{object_group,transaction_link}_syncer.dart`, `lib/firefly/ui/hub/links_entry.dart`, `lib/firefly/ui/pages/links/**`, `assets/translations/firefly/en/links.json`, `test/firefly/links/**`
- **Acceptance:** DoD; piggy banks and bills display their object group; a link between two transactions can be created, viewed and removed and round-trips.

#### WP-49 — Final integration, docs, release hardening

- **Branch:** `feature-firefly-final-integration` · **Worker:** Claude · **Depends on:** everything
- **Files owned:** `README.md`, `docs/firefly/**`, `integration_test/final/**`, and during this package only: fixes anywhere
- **Acceptance:** DoD; the complete E2E suite passes on Linux against Docker, and the fake-server suite passes on macOS and Windows runners; a manual pass on all five targets of connect, initial import, one edit in each direction, and offline edit then reconnect; initial import of 10,000 transactions completes and the app stays responsive; README documents Firefly mode, supported server version, token creation and the feature tables of section 4; a tagged release produces five artifacts.

## 9. Definition of done for every package

Run from `budget/` with the pinned Flutter version.

| Gate | Command | Pass condition |
|---|---|---|
| G1 | `flutter pub get --enforce-lockfile` | Succeeds. Only WP-00 and WP-P1 may change `pubspec.yaml` or the lock file |
| G2 | `flutter analyze --no-fatal-infos --no-fatal-warnings` | Exit code 0 and total issue count not above `docs/plan/analyze-baseline.txt` |
| G3 | `flutter analyze --fatal-infos --fatal-warnings lib/firefly lib/platform test integration_test` | No issue of any severity |
| G4 | `flutter test` | All tests pass, including the tests the package adds |
| G5 | `git diff --name-only firefly-sync...HEAD` | Every path is in the package's "Files owned" |
| G6 | `gitleaks detect --no-banner --redact` | No finding beyond the upstream baseline in `.gitleaks.toml`. No real hostname, token or personal data in fixtures |
| G7 | Review | With Firefly mode off there is no behaviour change and no request to a Firefly server |
| G8 | Review | Every new user-visible string is in the package's own translations file; none is hard-coded |

A package report states the command output for G1 to G6 and names any acceptance item that was not met.

## 10. Merge protocol

1. Merge order inside a wave is free because file sets are disjoint. Rebase each branch on `firefly-sync` immediately before merging and rerun G1 to G4.
2. A package that finds it needs a file it does not own stops and reports. The orchestrator either assigns the change to the owner or queues it for the wave's integration package.
3. Frozen after WP-01: `lib/firefly/sync/registry.dart`, `lib/firefly/ui/slots.dart`, `lib/firefly/api/firefly_api.dart`, `lib/firefly/sync/contracts.dart`. Frozen after WP-00: the four schema files. Changes go through a dedicated package run alone between waves; a schema change means version 48 with its own migration test.
4. Integration packages (WP-19, WP-29, WP-39, WP-49) run alone on the files they may fix, after every other package of the wave is merged.
5. Upstream Cashew changes are merged into `firefly-sync` only between waves.

## 11. Firefly III API coverage

| API area | Covered by | Status |
|---|---|---|
| about, user | WP-03 | Planned |
| accounts (asset, liability, expense, revenue, cash) | WP-10, WP-30a, WP-33a | Planned |
| categories | WP-11 | Planned |
| transactions, transaction journals, search | WP-12, WP-32a, WP-36 | Planned |
| budgets, budget limits, available budgets | WP-20a | Planned (available budgets read-only, as in the API) |
| piggy banks, piggy bank events | WP-21a | Planned |
| bills, recurrences | WP-22a | Planned |
| tags | WP-31a | Planned |
| currencies, exchange rates | WP-03, WP-34a | Planned |
| attachments | WP-35a | Planned for transactions; other attachable types display-only |
| rules, rule groups | WP-40a, WP-40b | Planned |
| object groups, transaction links, link types | WP-41 | Planned |
| preferences | WP-38 | Optional |
| summary, insight, chart | — | Not used; Cashew computes its own reports from local data |
| autocomplete | — | Not used; pickers read the local cache |
| webhooks, users, user groups, configuration, cron, data export, data destroy, data purge, batch | — | Out of scope pending decision D6 |

## 12. Risks and open decisions

### 12.1 Decisions taken by default that the owner should confirm

| Id | Decision | Default in this plan | Alternative |
|---|---|---|---|
| D1 | Subcategories on a flat server | A category named `Parent / Child` | Keep subcategories local-only and push the parent |
| D2 | Unpaid upcoming transactions | Local-only until paid | Push as future-dated with a marker tag |
| D3 | Lent, borrowed, loan objectives | Hidden in Firefly mode; existing rows not pushed | Map loan objectives to liability accounts |
| D4 | Other Google features in Firefly mode | Gmail scanning and shared budgets hidden along with Drive | Keep them where the platform supports Google sign-in |
| D5 | Self-signed certificates and plain HTTP on a LAN | Not supported; valid HTTPS only | A per-server trusted-certificate setting |
| D6 | Meaning of "full" support | Everything a personal-finance user does; server administration endpoints excluded (section 11) | Add admin screens |
| D7 | Premium on desktop, where in-app purchase is absent | Same treatment the web build gets today | Unlock everything in this fork |
| D8 | App ids and name | Unchanged upstream ids; CI artifacts only, no store publishing | New ids and name for the fork before any public release |
| D9 | Web target | Firefly mode not offered on web | A proxy-based web mode later |

### 12.2 Risks

| Risk | Effect | Mitigation |
|---|---|---|
| Flutter is pinned to an old release by `intl 0.18.1` and the lock file | Current Xcode or Windows toolchains may not build it | WP-00 pins; WP-P1 owns the upgrade if the toolchain forces one, as its first step, because it alone owns `pubspec` after wave 0 |
| `tables.dart` is 7,667 lines and holds every query | Any second editor causes large conflicts | One schema package, frozen afterwards, queries in extension files |
| Legacy code assumes wallet `"0"` and category `"0"` exist | Crashes after "replace local with server" | Primary account mapped to `"0"`; category `"0"` kept local; covered by WP-10 and WP-19 tests |
| No server change feed or tombstones | Missed edits or deletes of old transactions | Search by `updated_at`, window listing with confirmation, weekly full reconcile, balance parity check |
| No conditional writes on the server | A server edit made during a cycle can be overwritten | Pull immediately before push in the same cycle; local version kept in the conflicts table when detected |
| Server rules change a transaction after the app pushed it | Local copy differs from the server | Re-read step at the end of each cycle |
| Text length limits in Cashew are below Firefly's | Silent truncation pushed back | `lossyFields` on the map row |
| Double-precision amounts in Cashew, decimal strings in Firefly | Rounding drift | Fixed-decimal formatting; parity check after every cycle |
| Recurrences generate transactions on the server while Cashew also auto-creates | Duplicates | Local auto-creation disabled for server recurrences in WP-22b |
| macOS keychain access in unsigned CI builds | Token store failures in CI | Fake secure storage in automated tests; real keychain checked manually and in signed builds |
| Stub-and-registry design depends on WP-01 getting names right | Rework across many packages | `CONTRACTS.md` reviewed before wave 1 starts; contract changes only through the protocol in section 10 |

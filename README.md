# Cashew × Firefly III

A fork of [Cashew](https://github.com/jameskokoska/Cashew), the budget and expense tracker by James Kokoska, that syncs with a self-hosted [Firefly III](https://www.firefly-iii.org/) server. Your data lives in Cashew's local database on the device and in your own Firefly III; nothing goes to Google or Firebase.

- **Firefly mode** is opt-in. With it off, the app behaves like upstream Cashew without the Google account features (Google sign-in, Drive backup and Firebase were removed in this fork).
- **Supported server:** Firefly III **6.6.2** (API v1). Other 6.x versions may work but are not tested.
- **Platforms:** Android, iOS, macOS, Linux and Windows. The web build still runs, but Firefly mode is unavailable there (browser CORS and no safe place to keep the token).

## Connect to Firefly III

1. In Firefly III open **Options → Profile → OAuth**, and under **Personal access tokens** choose **Create new token**. Give it a name such as `Cashew on my phone` and copy the token. Firefly shows it only once.
2. In Cashew open the **Firefly III connection** page from Settings (or pick **Connect to Firefly III** during onboarding).
3. Enter the server URL, for example `https://firefly.example.com`. Leave out `/api`; the app adds it. HTTPS is required.
4. Paste the personal access token and tap **Test connection**, then **Connect**.
5. Turn on **Firefly III mode**. On the first connection you choose whether to upload what is already on the device or replace it with the server's data. Replacing writes a backup of the local database first.

The token is stored only in the platform's secure store (Keychain on iOS and macOS, Keystore-backed storage on Android, libsecret on Linux, the Windows credential store). It is never written to settings, backups, exports or logs. On Linux without a secret service the token is kept for the session only and you are asked again on the next launch.

Sync runs on launch, every 15 minutes while the app is in the foreground, shortly after local changes, and from pull-to-refresh. Edits made on both sides keep the server version; the local version is kept on the connection page under **Conflicts**, where it can be re-applied. **Sync colours, icons and order across devices** (off by default) stores Cashew-only display settings as Firefly III preferences so other Cashew devices pick them up.

## What syncs

| Firefly resource | Cashew side | Field mapping (Firefly ↔ Cashew) | Local-only, never pushed | Notes |
|---|---|---|---|---|
| Asset account (`type=asset`) | `Wallets`, `AccountDetails` | `name` ↔ `name`; `currency_code` ↔ `currency` (case converted); `currency_decimal_places` → `decimals`; `order` ↔ `order`; `active` ↔ `!archived`; `created_at` → `dateCreated`; `current_balance` → `AccountDetails.serverBalance` | `colour`, `iconName`, `currencyFormat`, `homePageWidgetDisplay` | Create sends `type: asset`, `account_role: defaultAsset`. The server's first default asset account is mapped onto local wallet `"0"` so legacy defaults keep working |
| Liability account (`type=liability`) | `Wallets` with `accountKind = liability`, `AccountDetails` | As asset plus `liability_type`, `liability_direction`, `interest`, `interest_period` | Same as asset | Shown in a separate liabilities section. Cashew loan objectives are not mapped |
| Expense and revenue accounts | `Payees` | `name` ↔ `name`; `type` ↔ `kind`; `active`, `notes`, `iban` | — | Withdrawal destination or deposit source ↔ `Transactions.payeeFk` |
| Category | `Categories` (main) | `name` ↔ `name` | `colour`, `iconName`, `emojiIconName`, `order`, `income`, `methodAdded` | New remote categories get an icon from the existing name heuristic. Subcategory: a Firefly category named `Parent / Child` whose parent exists becomes a Cashew subcategory, and a Cashew subcategory is pushed under that name. Separator is a setting (decision D1). Category `"0"` is never pushed |
| Transaction group with one withdrawal split | `Transactions` | `description` ↔ `name` (falls back to the category name when empty); `amount` ↔ `-abs(amount)`, `income = false`; `source_id` ↔ `walletFk`; `date` ↔ `dateCreated`; `notes` ↔ `note`; `category_id` ↔ `categoryFk` and `subCategoryFk`; `reconciled` ↔ `reconciled` | `budgetFksExclude`, `methodAdded`, `upcomingTransactionNotification`, `originalDateDue`, `createdAnotherFutureTransaction`, `skipPaid`, all `shared*` columns | Text longer than Cashew's limits (name 250, note 500) is truncated on pull and that field is marked lossy so it is not pushed back unless edited |
| Deposit split | `Transactions` | As withdrawal with `amount` ↔ `+abs(amount)`, `income = true`, `destination_id` ↔ `walletFk` | Same | |
| Transfer split | Two `Transactions` rows in category `"0"` linked by `pairedTransactionFk` | Out row: `source_id` ↔ `walletFk`, `-amount`. In row: `destination_id` ↔ `walletFk`, `+foreign_amount` if currencies differ, else `+amount` | Same | Both rows map to the same remote split with different `remoteRole` |
| `opening balance`, `reconciliation` splits | `Transactions` row in category `"0"` with `fireflyType` set | Amount and wallet as above | Same | Read-only in the UI. Local unpaired balance corrections are pushed per assumption A6 |
| Group with several splits | One `Transactions` row per split, shared `splitGroupFk`; `group_title` ↔ `TransactionGroups.title` | Per split as above; `order` ↔ `splitOrder` | Same | Imported and editable row by row from Phase 1. Creating and restructuring splits arrives in Phase 3 |
| Budget | `Budgets` with `addedTransactionsOnly = true` | `name` ↔ `name`; `active` ↔ `!archived`; `auto_budget_amount` ↔ `amount`; `auto_budget_period` ↔ `reoccurrence` and `periodLength` (`quarterly` = 3 months, `half-year` = 6 months) | `colour`, `pinned`, `order`, `income`, filters, wallet and category lists, all `shared*` columns | Split `budget_id` ↔ `Transactions.sharedReferenceBudgetPk` through a contributor. Budgets without an auto-budget use a monthly period |
| Budget limit | `BudgetLimits` | `start`, `end`, `amount`, `currency_code`, `notes` | — | The limit covering the current period supplies `Budgets.amount`; older limits feed the past-periods page. `CategoryBudgetLimits` stays local-only |
| Available budget | `FireflyResourceCache` | Read-only | — | Displayed, not editable |
| Piggy bank | `Objectives` (`type = goal`) plus cached state | `name` ↔ `name`; `target_amount` ↔ `amount`; `target_date` ↔ `endDate`; `start_date` ↔ `dateCreated`; first `accounts[].id` ↔ `walletFk`; `current_amount` → cached state | `colour`, `iconName`, `emojiIconName`, `income`, `pinned`, `order`, `archived` | In Firefly mode progress shows the server's `current_amount`. "Add or remove money" sends a `PUT` with the new amount. Events are pulled for history, and an event that names a journal sets `Transactions.objectiveFk` |
| Bill | `FireflyResourceCache`; link via `Transactions.billFk` | All bill fields in JSON | — | Shown on the subscriptions page in Firefly mode. Read `subscription_id ?? bill_id`; write `bill_id` |
| Recurrence | `FireflyResourceCache` | All recurrence fields in JSON | — | The server creates the transactions. In Firefly mode Cashew does not auto-create the next occurrence; upcoming entries are derived from `repetitions[].occurrences` |
| Tag | `Tags`, `TransactionTags` | `tag` ↔ `name`; `description`; `date`; split `tags[]` ↔ junction rows | — | |
| Currency | `FireflyResourceCache`; `Transactions.foreignAmount`, `foreignCurrency` | `code` ↔ Cashew lower-case code; `foreign_amount`, `foreign_currency_code` on splits | — | A wallet's currency is enabled on the server before its account is created |
| Exchange rate | Existing `cachedCurrencyExchange` setting | `rate` per pair and date | — | Optional source for Cashew's rates in Firefly mode |
| Attachment | `Attachments` plus a file in the app support directory | `filename`, `title`, `mime`, `size`, `hash`; `attachable_id` = journal id | `localPath`, `uploadState` | Replaces the Drive upload in Firefly mode |
| Rule, rule group | `FireflyResourceCache` | Whole object as JSON | — | Edited online; cached for offline viewing |
| Object group, transaction link, link type | `FireflyResourceCache` | Whole object as JSON | — | |
| Preference `cashew.*` | Local-only attributes of wallets, categories, budgets, objectives | JSON blob keyed by remote id | — | Optional roaming of colours, icons and ordering between Cashew devices |

### Cashew features with no Firefly counterpart

| Feature | Behaviour | Decision |
|---|---|---|
| Google Drive backup and device sync | Disabled and hidden. Local file export and import stay | Brief |
| Shared budgets (Firebase), Gmail scanning | Hidden together with the Google account section | D4 |
| Associated titles, scanner templates, per-category budget limits | Stay local-only | — |
| Unpaid upcoming, subscription and repetitive transactions | Stay local-only until marked paid, then pushed | D2 |
| Lent and borrowed transaction types, loan objectives | Creation hidden. Existing rows are not pushed | D3 |

## Downloads

Tagged releases on the [Releases page](https://github.com/madratzz/app-cashew-x-firefly/releases) carry five builds: an Android APK and AAB, an unsigned iOS IPA, an ad-hoc signed macOS app, a Linux bundle and a Windows zip. See [docs/release.md](docs/release.md) for what each contains and how signing works.

## Building from source

The app is in `budget/`. Flutter is pinned in `budget/.fvmrc` (3.19.6); use [FVM](https://fvm.app/).

```sh
cd budget
fvm flutter pub get --enforce-lockfile
fvm flutter run            # pick a device or desktop target
fvm flutter test           # unit, widget and emulated end-to-end tests
```

Linux builds need `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev libsqlite3-dev`.

Testing, including the live end-to-end suites against a disposable Firefly III in Docker, is described in [docs/firefly/testing.md](docs/firefly/testing.md). CI and releases are described in [docs/release.md](docs/release.md). The original Cashew README, with its developer notes, is kept at [docs/upstream-cashew-README.md](docs/upstream-cashew-README.md).

## Licence and credit

Cashew is © James Kokoska and contributors and is licensed under the [GNU General Public License v3.0](LICENSE). This fork keeps that licence; all changes are GPL-3.0 too. It is not affiliated with or endorsed by the Cashew or Firefly III projects. Firefly III is © James Cole and contributors.

# Firefly foundation contracts

Paths in this document are relative to `budget/` unless specified. The code and this document define the shared interfaces for work after WP-01. Keep the constructors and factory references used by the registries stable. Each package implements the files it owns in [PLAN.md](PLAN.md#8-work-packages).

## Mode, configuration and credentials

| File | Public interface |
|---|---|
| `lib/firefly/firefly.dart` | `FireflyMode.init(Map<String, Object?> Function() settings, {TokenStore? tokenStore}) → Future<void>`, `refreshToken() → Future<void>`, and static getters `available: bool`, `enabled: bool`, `config: FireflyConfig`, `tokens: TokenStore` |
| `lib/firefly/config/config.dart` | `FireflyConfig({bool mode = false, String baseUrl = '', bool syncOnChange = true, bool applyRules = true, bool fireWebhooks = true, int transactionWindowDays = 90, int pageSize = 100, String subcategorySeparator = ' / '})` and `FireflyConfig.fromSettings(Map<String, Object?>)`. Properties have the same names and types as the constructor arguments. Each has a corresponding static setting key, such as `FireflyConfig.baseUrlKey`. `normalizeFireflyUrl(String) → Uri` throws `FormatException` on invalid input |
| `lib/firefly/config/token_store.dart` | `TokenStore({FlutterSecureStorage? storage, bool? linux})`, `read() → Future<String?>`, `write(String token) → Future<void>`, `delete() → Future<void>`, `sessionOnly: bool`, `TokenStore.key = 'firefly.pat'` |
| `lib/firefly/config/log_redaction.dart` | `redactFireflyLog(String message, {String? token}) → String`, `logFirefly(String message, {String? token}) → void` |
| `lib/platform/capabilities.dart` | `PlatformCapabilities.supportsGoogleSignIn`, `supportsFirebase`, `supportsLocalNotifications`, `supportsBiometrics`, `supportsHomeWidget`, `supportsInAppPurchase`, `supportsCamera`, and `googleDriveAvailable`, all static `bool` getters. WP-P1 fills desktop support |

Pass `() => appStateSettings` to `FireflyMode.init` after settings load. Startup skips secure storage when mode is off. Call `refreshToken` after a credential changes or an existing credential should be used when enabling mode. `enabled` requires native platform support, the mode setting and a token. The facade reads settings on demand and retains only a token-presence flag.

URLs keep a reverse proxy path and drop trailing slashes and an optional API suffix. The transport owns the `/api/v1` prefix. Plain HTTP requires a debug build, `FIREFLY_ALLOW_HTTP=true` and one of the two documented loopback hosts. Reject credentials, query strings and fragments in the base URL. On Linux, a missing plugin or libsecret error switches the instance to session memory. Read `sessionOnly` to tell the user their token will need to be entered again.

Use `logFirefly` for Firefly diagnostics that enter the existing print capture. Supply the actual token to the redactor if an error could echo it as plain text. WP-03 must redact validation messages and field-level validation details before exposing them to clients, since sync issues can be persisted. Request headers and bodies belong outside diagnostic messages.

## Transport and DTOs

`JsonObject` is `Map<String, Object?>`. `FireflyQuery` is `Map<String, String>`. A transport path such as `/accounts` is relative to the API prefix. The transport returns the decoded `data` object on single-resource requests and unwraps list data and pagination into `FireflyPage<T>`. A single resource object retains its JSON:API `type`, `id`, `attributes` and `links`. About responses use the API's own data shape.

| `FireflyTransport` method | Return type |
|---|---|
| `get(String path, {FireflyQuery query = const {}})` | `Future<JsonObject>` |
| `getPage(String path, {FireflyQuery query = const {}})` | `Future<FireflyPage<JsonObject>>` |
| `post(String path, JsonObject body, {FireflyQuery query = const {}})` | `Future<JsonObject>` |
| `put(String path, JsonObject body, {FireflyQuery query = const {}})` | `Future<JsonObject>` |
| `delete(String path, {FireflyQuery query = const {}})` | `Future<void>` |
| `upload(String path, Stream<List<int>> bytes, {int? length})` | `Future<void>` |
| `download(String path)` | `Future<Stream<List<int>>>` |

`FireflyPage<T>({required List<T> items, required int total, required int currentPage, required int perPage, required int totalPages})` exposes those fields and `map<R>(R Function(T)) → FireflyPage<R>`.

`FireflyException` exposes `description: String`. Its variants are `FireflyUnauthorized()`, `FireflyNotFound()`, `FireflyValidation(String message, {Map<String, List<String>> errors = const {}})`, `FireflyRateLimited({Duration? retryAfter})`, `FireflyServerError(int statusCode)`, `FireflyUnexpectedResponse(int statusCode)`, `FireflyNetworkError()`, `FireflyTimeout()`, `FireflyInvalidPayload()`, and `FireflyTransportUnavailable()`. Constructor payloads are readable fields. The validation exception's string representation uses a generic description, since details are available separately.

`formatFireflyAmount(double amount, int decimalPlaces) → String` formats a non-negative decimal rounded to the requested precision. `parseFireflyAmount(String) → double` accepts finite values. `formatFireflyDateTime(DateTime) → String` uses the device offset for the given instant. `parseFireflyDateTime(String) → DateTime` converts the received instant to local time. `formatFireflyDate(DateTime) → String` uses the input calendar date.

WP-03 fills `api/http_transport.dart`. Its stub is `HttpFireflyTransport({required Uri baseUrl, required Future<String?> Function() readToken, http.Client? client})`, implements `FireflyTransport` and exposes `close() → void`. Each method currently completes with `FireflyTransportUnavailable`. The constructor arguments are readable fields.

### Resource clients

`FireflyApi(FireflyTransport transport)` exposes `transport` and the clients below. Every client takes `FireflyTransport` as its sole constructor argument and exposes it as `transport`. The typed CRUD clients inherit `FireflyResourceApi<T extends FireflyResource>` with these signatures.

| Method | Return type |
|---|---|
| `list({int page = 1, int limit = 100, FireflyQuery query = const {}})` | `Future<FireflyPage<T>>` |
| `get(String id)` | `Future<T>` |
| `create(JsonObject body)` | `Future<T>` |
| `update(String id, JsonObject body)` | `Future<T>` |
| `delete(String id)` | `Future<void>` |

The DTOs extending `FireflyResource` all take `({required String id, JsonObject attributes = const {}})` and inherit those fields plus `name: String?` and `updatedAt: DateTime?`. Implement decoding in the package that owns the DTO. The `Firefly` prefix is part of each DTO class name.

| Package | Facade property and client | Files under `api/` and DTOs |
|---|---|---|
| WP-03 | `about: AboutApi` | `resources/about_api.dart`, `models/about.dart` with `FireflyAbout`, `FireflyUser` |
| WP-03 | `currencies: CurrenciesApi` | `resources/currencies_api.dart`, `models/currency.dart` with `FireflyCurrency` |
| WP-10 | `accounts: AccountsApi` | `resources/accounts_api.dart`, `models/account.dart` with `FireflyAccount`. WP-30a and WP-33a share this client |
| WP-11 | `categories: CategoriesApi` | `resources/categories_api.dart`, `models/category.dart` with `FireflyCategory` |
| WP-12 | `transactions: TransactionsApi`, `search: SearchApi` | `resources/transactions_api.dart`, `resources/search_api.dart`, `models/transaction.dart` with `FireflyTransaction`, `FireflyTransactionSplit` |
| WP-20a | `budgets: BudgetsApi` | `resources/budgets_api.dart`, `models/{budget,budget_limit,available_budget}.dart` with `FireflyBudget`, `FireflyBudgetLimit`, `FireflyAvailableBudget` |
| WP-21a | `piggyBanks: PiggyBanksApi` | `resources/piggy_banks_api.dart`, `models/piggy_bank.dart` with `FireflyPiggyBank` |
| WP-22a | `bills: BillsApi`, `recurrences: RecurrencesApi` | `resources/{bills,recurrences}_api.dart`, `models/{bill,recurrence}.dart` with `FireflyBill`, `FireflyRecurrence` |
| WP-31a | `tags: TagsApi` | `resources/tags_api.dart`, `models/tag.dart` with `FireflyTag` |
| WP-34a | `exchangeRates: ExchangeRatesApi` | `resources/exchange_rates_api.dart`, `models/exchange_rate.dart` with `FireflyExchangeRate` |
| WP-35a | `attachments: AttachmentsApi` | `resources/attachments_api.dart`, `models/attachment.dart` with `FireflyAttachment` |
| WP-38 | `preferences: PreferencesApi` | `resources/preferences_api.dart`, `models/preference.dart` with `FireflyPreference` |
| WP-40a | `rules: RulesApi` | `resources/rules_api.dart`, `models/{rule,rule_group}.dart` with `FireflyRule`, `FireflyRuleGroup` |
| WP-41 | `objectGroups: ObjectGroupsApi`, `transactionLinks: TransactionLinksApi` | `resources/{object_groups,transaction_links}_api.dart`, `models/{object_group,transaction_link}.dart` with `FireflyObjectGroup`, `FireflyTransactionLink` |

Additional client methods return futures with the indicated value type.

| Client | Methods |
|---|---|
| `AboutApi` | `get() → FireflyAbout`, `getUser() → FireflyUser` |
| `AccountsApi` | CRUD `list` also accepts `String? type`, such as `asset`, `expense`, `revenue` or `liability` |
| `TransactionsApi` | CRUD `list` also accepts `String type = 'all'`, `DateTime? start`, `DateTime? end`. `deleteJournal(String journalId) → void` |
| `SearchApi` | `transactions(String search, {int page = 1, int limit = 100}) → FireflyPage<FireflyTransaction>` |
| `CurrenciesApi` | `primary() → FireflyCurrency`, `enable(String code)`, `disable(String code)` and `setPrimary(String code) → void` |
| `BudgetsApi` | `listLimits(String budgetId, {int page = 1, int limit = 100}) → FireflyPage<FireflyBudgetLimit>`, `getLimit(String budgetId, String limitId) → FireflyBudgetLimit`, `createLimit(String budgetId, JsonObject body) → FireflyBudgetLimit`, `updateLimit(String budgetId, String limitId, JsonObject body) → FireflyBudgetLimit`, `deleteLimit(String budgetId, String limitId) → void`, `listAvailable({int page = 1, int limit = 100, DateTime? start, DateTime? end}) → FireflyPage<FireflyAvailableBudget>` |
| `PiggyBanksApi` | `listEvents(String id, {int page = 1, int limit = 100}) → FireflyPage<JsonObject>` |
| `RecurrencesApi` | `trigger(String id, {DateTime? date}) → FireflyTransaction?` |
| `AttachmentsApi` | `upload(String id, Stream<List<int>> bytes, {int? length}) → void`, `download(String id) → Stream<List<int>>` |
| `RulesApi` | `listGroups({int page = 1, int limit = 100}) → FireflyPage<FireflyRuleGroup>`, `getGroup(String id) → FireflyRuleGroup`, `createGroup(JsonObject body) → FireflyRuleGroup`, `updateGroup(String id, JsonObject body) → FireflyRuleGroup`, `deleteGroup(String id) → void`. `test` and `testGroup` return `FireflyPage<FireflyTransaction>`. `trigger` and `triggerGroup` return `void`. All four take `(String id, {DateTime? start, DateTime? end, List<String> accounts = const []})` |
| `TransactionLinksApi` | `listTypes({int page = 1, int limit = 100}) → FireflyPage<JsonObject>` |

- `FireflyAbout({required String version, String? apiVersion})` and `FireflyUser({required String id, String? displayName})` expose the named fields.
- `FireflyAccount` exposes `type: String?`, `currencyCode: String?`, `currencyDecimalPlaces: int?`, `active: bool?`. `FireflyCurrency` exposes `code: String?`, `decimalPlaces: int?`, `enabled: bool?`, `primary: bool?`.
- `FireflyTransaction` exposes `groupTitle: String?` and `splits: List<FireflyTransactionSplit>`. `FireflyTransactionSplit(JsonObject fields)` exposes `fields`, `journalId`, `type`, `sourceId`, `destinationId` and `internalReference`. The last five are nullable strings.

## Drift repositories and query ownership

All four repositories take `FinanceDatabase db` in a const constructor and expose it as `db`. They participate in any existing Drift transaction on that database. IDs and enum values use the schema v47 definitions in `lib/database/tables.dart`. In the table below, `Type` is `FireflyEntityType`, and return types are wrapped in `Future` unless a stream or a static helper is shown.

| Repository | Interface |
|---|---|
| `IdMapRepository` in `id_map_repository.dart` | `byLocal(Type type, String localPk) → FireflyIdMapping?`, `byRemote(Type type, String remoteId, {String subId = '', int role = 0}) → FireflyIdMapping?`, `forRemoteGroup(Type type, String remoteId) → List<FireflyIdMapping>`, `list(Type type, {FireflySyncState? state}) → List<FireflyIdMapping>`, `put(FireflyIdMapping mapping) → void`, `markPendingDelete(Type type, String localPk) → bool`, `remove(Type type, String localPk) → void`. Static `creatingId(String localPk) → String`, `isProvisional(FireflyIdMapping) → bool` |
| `SyncMetaRepository` in `sync_meta_repository.dart` | `read(String key) → String?`, `write(String key, String value) → void`, `readDate(String key) → DateTime?`, `writeDate(String key, DateTime value) → void`, `remove(String key) → void`. Static keys `deleteLogCursor`, `serverVersion`, `serverUserId`, `serverUrlHash`, `transactionPage`, `transactionCursor`, `lastFullReconcile`, `lastSync`, and `contributorVersion(String id) → String` |
| `ConflictRepository` in `conflict_repository.dart` | `record({required Type type, required String localPk, required String remoteId, required JsonObject local, JsonObject? remote, required String resolution, DateTime? createdAt}) → FireflyConflict`, `read(String pk) → FireflyConflict?`, `list({bool unacknowledgedOnly = false}) → List<FireflyConflict>`, `watch({bool unacknowledgedOnly = false}) → Stream<List<FireflyConflict>>`, `acknowledge(String pk) → void` |
| `ResourceCacheRepository` in `resource_cache_repository.dart` | `read(Type type, String id) → FireflyCachedResource?`, `list(Type type) → List<FireflyCachedResource>`, `watch(Type type) → Stream<List<FireflyCachedResource>>`, `write(Type type, String id, JsonObject data, {DateTime? modifiedAt}) → void`, `remove(Type type, String id) → void`. Static `resourcePk(Type type, String id) → String`, `decode(FireflyCachedResource row) → JsonObject` |

Each query stub below is an extension on `FinanceDatabase` under `lib/firefly/db/`. The shown methods return futures. Check the specific UI package's data dependencies before extending an interface.

| Owner | File and extension | Shared methods |
|---|---|---|
| WP-04 | `delete_log_queries.dart`, `FireflyDeleteLogQueries` | `fireflyDeleteLogs({DateTime? after}) → List<DeleteLog>` |
| WP-05 | `reset_queries.dart`, `FireflyResetQueries` | `clearFireflyFinanceData() → void` |
| WP-10 | `wallet_queries.dart`, `FireflyWalletQueries` | `fireflyWallet(String pk) → TransactionWallet?`, `fireflyAccountDetails(String walletPk) → AccountDetail?`, `deleteWalletLocally(String walletPk) → void` (atomically removes the wallet and its transactions/details, queues one wallet delete, and repairs the selection) |
| WP-11 | `category_queries.dart`, `FireflyCategoryQueries` | `fireflyCategory(String pk) → TransactionCategory?`, `ensureUncategorizedCategory() → String` |
| WP-12 | `transaction_queries.dart`, `FireflyTransactionQueries` | `fireflyTransaction(String pk) → Transaction?` |
| WP-20a | `budget_queries.dart`, `FireflyBudgetQueries` | `fireflyBudget(String pk) → Budget?` |
| WP-21a | `objective_queries.dart`, `FireflyObjectiveQueries` | `fireflyObjective(String pk) → Objective?` |
| WP-22a | `bill_recurrence_queries.dart`, `FireflyBillRecurrenceQueries` | `fireflyBill(String pk)`, `fireflyRecurrence(String pk) → FireflyCachedResource?` |
| WP-30a | `payee_queries.dart`, `FireflyPayeeQueries` | `fireflyPayee(String pk) → Payee?`, `fireflyPayees({String? search}) → List<Payee>` |
| WP-31a | `tag_queries.dart`, `FireflyTagQueries` | `fireflyTransactionTags(String transactionPk) → List<Tag>`, `fireflyTags({String? search}) → List<Tag>` |
| WP-32a | `split_queries.dart`, `FireflySplitQueries` | `fireflyGroupSplits(String groupPk) → List<Transaction>`, `fireflyGroupTitle(String groupPk) → String?`, `persistFireflyGroupDraft(String transactionPk, List<Transaction> splits, String? title) → void` |
| WP-33a | `liability_queries.dart`, `FireflyLiabilityQueries` | `fireflyLiabilities() → List<TransactionWallet>` |
| WP-34a | `currency_queries.dart`, `FireflyCurrencyQueries` | `fireflyCurrency(String code) → FireflyCachedResource?` |
| WP-35a | `attachment_queries.dart`, `FireflyAttachmentQueries` | `fireflyTransactionAttachments(String transactionPk) → List<Attachment>`, `persistFireflyAttachmentDraft(String transactionPk, List<Attachment> attachments) → void` |
| WP-36 | `filter_queries.dart`, `FireflyFilterQueries` | `fireflyFilteredTransactionPks({String? payeePk, List<String> tagPks = const [], bool matchAllTags = false, String? billPk, bool? reconciled, bool? hasAttachment}) → List<String>` |
| WP-40a | `rule_queries.dart`, `FireflyRuleQueries` | `fireflyRules({bool groups = false}) → List<FireflyCachedResource>` |

The local-only `firefly-uncategorized` category has the name “Uncategorized” and no Firefly ID mapping. Category pulls use it for transactions detached by a remote category deletion. WP-12 uses `ensureUncategorizedCategory()` when a remote transaction has no category and sends a null `category_id` for transactions using this local category.

## Sync interfaces

`SyncContext({required FinanceDatabase db, required FireflyApi api, required FireflyConfig config, SyncPullMode pullMode = SyncPullMode.incremental, DateTime Function()? now, bool Function()? isCancelled})` exposes those fields, resolved clock and cancellation functions, and repositories `idMap`, `meta`, `conflicts`, `cache`. `pushedTransactionIds` is a mutable `Set<String>` scoped to the cycle. `SyncPullMode` values are `incremental`, `initial`, `full`.

- `EntitySyncer()` exposes `type: FireflyEntityType`, `dependsOn: Set<FireflyEntityType>` and `pull`, `push`, `pushDeletes`, `rereadPushed`, each `(SyncContext) → Future<void>`. WP-12 implements `rereadPushed` for transaction IDs recorded in the context. WP-04 calls that hook in the reread phase.
- `TransactionContributor()` exposes stable `id: String`, `version: int`, `pull(SyncContext, FireflyTransaction group, FireflyTransactionSplit split, String transactionPk) → Future<void>` and `push(SyncContext, Transaction transaction, JsonObject split) → Future<void>`. The transaction syncer invokes pull inside its Drift transaction and passes a mutable outgoing split map to push. Increment `version` when a contributor must see already-imported transactions again. Versions are stored using `SyncMetaRepository.contributorVersion(id)`.
- `SyncReport({DateTime? startedAt, DateTime? finishedAt, bool cancelled = false, List<SyncIssue> issues = const [], Map<String, double> balanceMismatches = const {}})` exposes those fields and `succeeded: bool`. Mismatches are keyed by local wallet PK. `SyncIssue(String message, {FireflyEntityType? entityType, SyncPhase? phase})` and `SyncProgress(SyncPhase phase, {FireflyEntityType? entityType})` expose their arguments. `SyncPhase` values are `preflight`, `pull`, `push`, `delete`, `reread`, `parity`, `complete`.
- WP-04 fills `sync/engine.dart` and `sync/scheduler.dart`. `SyncEngine(SyncContext context, {List<EntitySyncer> syncers = entitySyncers, List<TransactionContributor> contributors = transactionContributors})` exposes those fields, `isRunning: bool`, `progress: Stream<SyncProgress>`, `run({bool fullResync = false}) → Future<SyncReport>`, `cancel() → void`, and `dispose() → Future<void>`. `SyncScheduler(SyncEngine engine)` exposes `engine`, `start()`, `resume()`, `pause()`, `localWrite()` and `dispose()`, all returning `void`, plus `syncNow({bool fullResync = false}) → Future<SyncReport>`. WP-02 owns attaching scheduler startup and invocation to the legacy app. WP-05 uses these interfaces for sync status and full resync.
- WP-37 fills `sync/bootstrap_upload.dart` with `FireflyBootstrapUpload(SyncContext context)`, `context`, `canUpload() → Future<bool>` and `run() → Future<SyncReport>`. WP-38 fills `sync/meta_roaming.dart` with `FireflyMetaRoaming(SyncContext context)`, `context`, `pull()` and `push() → Future<void>`.

### Registry order and stub owners

The frozen const `entitySyncers` list in `sync/registry.dart` is traversed in the order shown for pulls and pushes, and reversed for deletes. Each class has an unnamed const constructor and lives under `lib/firefly/sync/entities/`.

| Order | Enum member | Class and file | Owner |
|---|---|---|---|
| 1 | `currency` | `CurrencySyncer`, `currency_syncer.dart` | WP-34a |
| 2 | `walletAccount` | `WalletAccountSyncer`, `wallet_account_syncer.dart` | WP-10 |
| 3 | `liabilityAccount` | `LiabilityAccountSyncer`, `liability_account_syncer.dart` | WP-33a |
| 4 | `payeeAccount` | `PayeeAccountSyncer`, `payee_account_syncer.dart` | WP-30a |
| 5 | `category` | `CategorySyncer`, `category_syncer.dart` | WP-11 |
| 6 | `tag` | `TagSyncer`, `tag_syncer.dart` | WP-31a |
| 7 | `budget` | `BudgetSyncer`, `budget_syncer.dart` | WP-20a |
| 8 | `budgetLimit` | `BudgetLimitSyncer`, `budget_limit_syncer.dart` | WP-20a |
| 9 | `bill` | `BillSyncer`, `bill_syncer.dart` | WP-22a |
| 10 | `piggyBank` | `PiggyBankSyncer`, `piggy_bank_syncer.dart` | WP-21a |
| 11 | `recurrence` | `RecurrenceSyncer`, `recurrence_syncer.dart` | WP-22a |
| 12 | `transaction` | `TransactionSyncer`, `transaction_syncer.dart` | WP-12 |
| 13 | `attachment` | `AttachmentSyncer`, `attachment_syncer.dart` | WP-35a |
| 14 | `objectGroup` | `ObjectGroupSyncer`, `object_group_syncer.dart` | WP-41 |
| 15 | `transactionLink` | `TransactionLinkSyncer`, `transaction_link_syncer.dart` | WP-41 |
| 16 | `rule` | `RuleSyncer`, `rule_syncer.dart` | WP-40a implements rule groups within this syncer |

The const `transactionContributors` list uses the following order and stable IDs. Each takes no constructor arguments and lives under `lib/firefly/sync/contributors/`.

| ID | Class | File | Owner |
|---|---|---|---|
| `payee` | `PayeeContributor` | `payee_contributor.dart` | WP-30a |
| `tags` | `TagsContributor` | `tags_contributor.dart` | WP-31a |
| `budget` | `BudgetContributor` | `budget_contributor.dart` | WP-20a |
| `bill` | `BillContributor` | `bill_contributor.dart` | WP-22a |
| `piggyBank` | `PiggyBankContributor` | `piggy_bank_contributor.dart` | WP-21a |
| `splitGroup` | `SplitGroupContributor` | `split_group_contributor.dart` | WP-32a |
| `foreignCurrency` | `ForeignCurrencyContributor` | `foreign_currency_contributor.dart` | WP-34a |
| `attachments` | `AttachmentsContributor` | `attachments_contributor.dart` | WP-35a |

### Collection sync and policies

`canonicalJson(JsonObject fields) → String` recursively sorts object keys while preserving array order. `syncedFieldsHash(JsonObject fields) → String` hashes the result with SHA-256. `fireflyTextHash(String) → String` hashes a plain string, for example the normalized server URL.

`resolveConflict({required LocalSyncVersion local, required RemoteSyncVersion remote, bool sameHash = false}) → ConflictDecision` implements [the plan's conflict table](PLAN.md#55-conflict-rule). `LocalSyncVersion` values are `missing`, `clean`, `dirty`, `pendingDelete`. `RemoteSyncVersion` values are `missing`, `unchanged`, `changed`, `deleted`. Decisions are `none`, `createRemote`, `insertLocal`, `applyRemote`, `applyRemoteWithConflict`, `markSynced`, `pushLocal`, `deleteRemote`, `deleteLocal`, `deleteLocalWithConflict`.

`detectLocalChange({required FireflyIdMapping? mapping, required DateTime? modifiedAt, required String hash}) → LocalChange` returns `clean`, `created`, `updated` or `deleted`. `DirtyTracker(IdMapRepository idMap)` exposes `idMap` and `collectDeletes(Iterable<DeleteLog> logs, {DateTime? after}) → Future<int>`. The engine should wrap log collection and cursor advancement in one outer transaction. New Firefly-only tables mark pending deletes directly through `IdMapRepository`.

`LocalCollectionRow({required String pk, required JsonObject fields, DateTime? modifiedAt, JsonObject? snapshot})` and `RemoteCollectionRow<T>({required String id, required T value, required JsonObject fields, DateTime? updatedAt, JsonObject? snapshot})` expose the given fields and `hash: String`. Use the same key names and normalized representations for synced fields in both directions. Supply a `snapshot` when conflict recovery requires more information than the hashed fields.

`CollectionAdapter<T>()` describes a one-to-one local and remote collection. Methods below return futures.

| Method | Value type |
|---|---|
| `page(int page, int limit)` | `FireflyPage<RemoteCollectionRow<T>>` |
| `listLocal()` and `readLocal(String pk)` | `List<LocalCollectionRow>` and `LocalCollectionRow?` |
| `findNaturalKey(RemoteCollectionRow<T> remote)`, `recoverLocalPk(RemoteCollectionRow<T> remote)` | `String?` local PK. Reference-based recovery is checked first, then the natural key |
| `applyRemote(RemoteCollectionRow<T> remote, {String? localPk})` | `LocalCollectionRow` actually written |
| `removeLocal(String pk)` and `removeRemote(String id)` | `void` |
| `createRemote(LocalCollectionRow local)` | `RemoteCollectionRow<T>` |
| `updateRemote(FireflyIdMapping mapping, LocalCollectionRow local)` | `RemoteCollectionRow<T>` |
| `findDuplicate(LocalCollectionRow local, FireflyValidation error)` | `RemoteCollectionRow<T>?`. Check whether the validation error is a duplicate before looking up an existing resource |

The adapter exposes `type: FireflyEntityType` and `compareHashWhenTimestampsEqual: bool` (default false). Enable the latter when a resource can change its synced fields while keeping the same stored timestamp. A canonical hash mismatch then counts as a remote change. `CollectionSync<T>({required CollectionAdapter<T> adapter, required IdMapRepository idMap, required ConflictRepository conflicts, required int pageSize, DateTime Function()? now, String Function(String) redactError = redactFireflyLog})` exposes these fields with a resolved clock, plus `pull() → Future<CollectionPullResult>`, `push() → Future<void>`, `pushDeletes() → Future<void>`. `CollectionPullResult({required bool complete, required int seen})` exposes both fields.

### Worked example using a category adapter

A category syncer builds one `CollectionSync` per cycle and shares it across the three phases. This wrapper takes a category adapter factory. WP-11 can bind its Drift category queries and the categories client in that factory. A runnable implementation of the adapter contract and its round trips also lives in [collection_sync_test.dart](../../budget/test/firefly/core/collection_sync_test.dart).

```dart
class ExampleCategorySyncer extends EntitySyncer {
  ExampleCategorySyncer(this.buildAdapter);

  final CollectionAdapter<FireflyCategory> Function(SyncContext) buildAdapter;
  final _cycles = Expando<CollectionSync<FireflyCategory>>();

  @override
  FireflyEntityType get type => FireflyEntityType.category;

  CollectionSync<FireflyCategory> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: buildAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    await _cycle(context).pull();
  }

  @override
  Future<void> push(SyncContext context) => _cycle(context).push();

  @override
  Future<void> pushDeletes(SyncContext context) =>
      _cycle(context).pushDeletes();
}
```

1. Map `api.categories.list(page: page, limit: limit)` with `FireflyPage.map`. A remote category's synced fields can be `{'name': normalizedName}`. The local snapshot can carry the full editable record for conflict replay. For subcategories, derive the remote name using the configured separator before hashing either side.
2. Skip category `"0"` in local enumeration. Find a natural-key match by normalized name among eligible local rows. For an incoming category, preserve the linked row's colour, icon and income flag, and stamp the actual stored version. The collection writes the resulting mapping in the same Drift transaction. It uses schema v47's second precision for version comparison.
3. Call the API's create, update and delete methods with the appropriate ID or writable name. If a create operation is interrupted, the map keeps a unique provisional ID. A complete pull can link the previously created remote category by name. While the listing is incomplete, the helper suppresses retries of provisional creates and skips missing-remote detection.
4. Report `CollectionPullResult.complete` where the engine needs to show an incomplete listing. Authorization and transient failures propagate. A rejected payload stays on the issues list, and the helper retries when the local version and its synced fields change. An update 404 goes through remote-delete conflict handling. A delete 404 clears the mapping.

Transactions use their own group and window logic from the plan. They can reuse the hashing, policy, dirty tracker and repositories.

## UI contracts and stub ownership

WP-02 inserts the widgets exported by `ui/slots.dart`. All take an optional `Key? key`.

| Widget | Additional constructor args | Registry |
|---|---|---|
| `FireflySettingsEntry` | None | Calls `fireflyConnectionEntry(BuildContext) → Widget` when mode is available, including before setup |
| `FireflySyncStatus` | None | Calls `fireflySyncStatus(BuildContext) → Widget` when mode is enabled |
| `FireflyTransactionExtras` | `required FireflyTransactionDraft draft` | `fireflyTransactionSections: List<Widget Function(BuildContext, FireflyTransactionDraft)>` |
| `FireflyTransactionEntryExtras` | `required Transaction transaction` | `fireflyTransactionChips: List<Widget Function(BuildContext, Transaction)>` |
| `FireflyWalletExtras` | `required String? walletPk` | `fireflyWalletSections: List<Widget Function(BuildContext, String?)>` |
| `FireflyHubSection` | None | `fireflyHubEntries: List<Widget Function(BuildContext)>` |

`FireflyTransactionDraft(FinanceDatabase db)` exposes `db`, nullable strings `payeePk`, `foreignCurrency`, `splitTitle`, `billPk`, `piggyBankPk`, `budgetPk`, nullable `double foreignAmount`, `Set<String> tagPks`, `List<Transaction> splits` and `List<Attachment> attachments`. `load(String transactionPk)` and `persist(String transactionPk)` return `Future<void>`. After saving the legacy transaction, persist edited draft fields and tag changes. Splits and attachment writes are delegated to the owning query extensions.

These files live under `lib/firefly/ui/`. Functions take `BuildContext` followed by their registry's argument, if applicable, and return `Widget`. The registry lists in `slots.dart` define rendering order.

| Owner | Slot factories | Page stubs and exported widgets |
|---|---|---|
| WP-05 | `settings/connection_entry.dart` → `fireflyConnectionEntry`, `settings/sync_status.dart` → `fireflySyncStatus` | `pages/connection/{connection_page,conflicts_page,sync_issues_page}.dart` → `FireflyConnectionPage`, `FireflyConflictsPage`, `FireflySyncIssuesPage` |
| WP-20b | `transaction/budget_section.dart` → `fireflyBudgetSection` | `pages/budgets/budget_limits_page.dart` → `FireflyBudgetLimitsPage` |
| WP-21b | `transaction/piggy_section.dart` → `fireflyPiggySection` | `pages/piggy_banks/piggy_bank_events_page.dart` → `FireflyPiggyBankEventsPage` |
| WP-22b | `transaction/bill_section.dart` → `fireflyBillSection`, `hub/{bills,recurrences}_entry.dart` → `fireflyBillsEntry`, `fireflyRecurrencesEntry` | `pages/bills/{bills_page,recurrences_page}.dart` → `FireflyBillsPage`, `FireflyRecurrencesPage` |
| WP-30b | `transaction/payee_section.dart` → `fireflyPayeeSection`, `entry/payee_chip.dart` → `fireflyPayeeChip`, `hub/payees_entry.dart` → `fireflyPayeesEntry` | `pages/payees/payees_page.dart` → `FireflyPayeesPage` |
| WP-31b | `transaction/tags_section.dart` → `fireflyTagsSection`, `entry/tags_chip.dart` → `fireflyTagsChip`, `hub/tags_entry.dart` → `fireflyTagsEntry` | `pages/tags/tags_page.dart` → `FireflyTagsPage` |
| WP-32b | `transaction/split_section.dart` → `fireflySplitSection`, `entry/split_chip.dart` → `fireflySplitChip` | `pages/splits/splits_page.dart` → `FireflySplitsPage` |
| WP-33b | `wallet/account_details_section.dart` → `fireflyAccountDetailsSection`, `hub/liabilities_entry.dart` → `fireflyLiabilitiesEntry` | `pages/liabilities/liabilities_page.dart` → `FireflyLiabilitiesPage` |
| WP-34b | `transaction/foreign_amount_section.dart` → `fireflyForeignAmountSection`, `entry/foreign_amount_chip.dart` → `fireflyForeignAmountChip`, `hub/currencies_entry.dart` → `fireflyCurrenciesEntry` | `pages/currencies/currencies_page.dart` → `FireflyCurrenciesPage` |
| WP-35b | `transaction/attachments_section.dart` → `fireflyAttachmentsSection`, `entry/attachment_chip.dart` → `fireflyAttachmentChip` | `pages/attachments/attachments_page.dart` → `FireflyAttachmentsPage` |
| WP-37 | — | `pages/connection/upload_flow.dart` → `FireflyUploadFlow` |
| WP-40b | `hub/rules_entry.dart` → `fireflyRulesEntry` | `pages/rules/rules_page.dart` → `FireflyRulesPage` |
| WP-41 | `hub/links_entry.dart` → `fireflyLinksEntry` | `pages/links/links_page.dart` → `FireflyLinksPage` |

The page widgets' stub constructors accept `{Key? key}`. Add package-specific optional arguments as needed. The localization loader merges assets under `assets/translations/firefly/en/` in path order over each generated locale. Put each new key in its owning package's JSON file. Core owns `firefly-title`.

## Test support

- `test/support/test_database.dart` exports `inMemoryFinanceDatabase() → FinanceDatabase` with foreign keys enabled. Close it with `addTearDown(db.close)`.
- `test/support/fixtures.dart` exports `fixtureTime: DateTime`, `fireflyResource(String type, String id, JsonObject attributes) → JsonObject` and `fixtureMapping({FireflyEntityType type, String localPk, String remoteId, String subId, int role, DateTime? localVersionAt, DateTime? remoteUpdatedAt, String? syncedHash, FireflySyncState state}) → FireflyIdMapping`. Defaults produce an ordinary synced category with local key `local` and remote ID `1`.
- `FakeFireflyRequest` is a named record with `method: String`, `path: String`, `query: FireflyQuery`, `body: JsonObject?`. `FakeFireflyTransport({int maxPageSize = 50})` implements the transport, exposes `maxPageSize`, records `requests: List<FakeFireflyRequest>`, calls a configurable `onRequest: void Function(FakeFireflyRequest)?` before serving requests and offers `seed(String path, String id, JsonObject attributes)` and `removeSeed(String path, String id)`.
- `FakeFireflyServer.start({FakeFireflyTransport? transport, Future<bool> Function(HttpRequest)? intercept}) → Future<FakeFireflyServer>` binds an ephemeral loopback port. It exposes `baseUrl: Uri`, `transport`, `intercept` and `close() → Future<void>`. An interceptor can respond directly and return true. The default handler serves JSON:API pages, resource objects and raw attachment bytes. Start and close one per test and pass the debug HTTP define when the test uses the real transport.

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/budget_limit.dart';
import 'package:budget/firefly/api/resources/budgets_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class BudgetLimitSyncer extends EntitySyncer {
  const BudgetLimitSyncer();

  static final _cycles = Expando<CollectionSync<FireflyBudgetLimit>>();

  @override
  FireflyEntityType get type => FireflyEntityType.budgetLimit;

  @override
  Set<FireflyEntityType> get dependsOn => const {FireflyEntityType.budget};

  CollectionSync<FireflyBudgetLimit> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _BudgetLimitAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    await _cycle(context).pull();
    await context.db.projectFireflyBudgetAmounts(context.now());
  }

  @override
  Future<void> push(SyncContext context) async {
    await _cycle(context).push();
    await context.db.projectFireflyBudgetAmounts(context.now());
  }

  @override
  Future<void> pushDeletes(SyncContext context) =>
      _cycle(context).pushDeletes();
}

class _BudgetLimitAdapter extends CollectionAdapter<FireflyBudgetLimit> {
  _BudgetLimitAdapter(this.context);

  final SyncContext context;
  final _decimalPlaces = <String, int>{};

  FinanceDatabase get _db => context.db;
  BudgetsApi get _api => context.api.budgets;

  @override
  FireflyEntityType get type => FireflyEntityType.budgetLimit;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  bool _available(FireflyIdMapping parent) =>
      !IdMapRepository.isProvisional(parent) &&
      parent.state != FireflySyncState.pendingDelete &&
      parent.state != FireflySyncState.localOnly;

  Future<FireflyIdMapping?> _parent(String pk) async {
    final mapping = await context.idMap.byLocal(FireflyEntityType.budget, pk);
    return mapping != null && _available(mapping) ? mapping : null;
  }

  JsonObject _fields(String budgetPk, DateTime start, DateTime end,
          double amount, String currency, String? notes) =>
      {
        'budget_fk': budgetPk,
        'start': formatFireflyDate(start),
        'end': formatFireflyDate(end),
        'amount': amount,
        'currency_code': currency.toUpperCase(),
        'notes': (notes?.isEmpty ?? true) ? null : notes,
      };

  LocalCollectionRow _local(BudgetLimit limit) => LocalCollectionRow(
        pk: limit.budgetLimitPk,
        modifiedAt: limit.dateTimeModified,
        snapshot: limit.toJson(),
        fields: _fields(limit.budgetFk, limit.start, limit.end, limit.amount,
            limit.currency, limit.notes),
      );

  RemoteCollectionRow<FireflyBudgetLimit> _remote(
      FireflyIdMapping budget, FireflyBudgetLimit limit) {
    final code = limit.currencyCode.toUpperCase();
    if (limit.decimalPlaces case final int places) {
      _decimalPlaces[code] = places;
    }
    return RemoteCollectionRow(
      // The parent id must survive local deletion to address the nested route.
      id: '${Uri.encodeComponent(budget.remoteId)}/${Uri.encodeComponent(limit.id)}',
      updatedAt: limit.updatedAt,
      value: limit,
      fields: _fields(budget.localPk, limit.start, limit.end, limit.amount,
          code, limit.notes),
    );
  }

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyBudgetLimit>>> page(
      int page, int limit) async {
    // Each budget has an independent page sequence. Surface their combined
    // snapshot as one page so CollectionSync only reconciles complete lists.
    final rows = <RemoteCollectionRow<FireflyBudgetLimit>>[];
    var complete = true;
    for (final budget in await context.idMap.list(FireflyEntityType.budget)) {
      if (!_available(budget)) continue;
      if (context.isCancelled()) {
        complete = false;
        break;
      }
      final listing = await readBudgetPages(
          (page) => _api.listLimits(budget.remoteId, page: page, limit: limit));
      rows.addAll(listing.items.map((item) => _remote(budget, item)));
      complete = complete && listing.complete;
    }
    return FireflyPage(
      items: rows,
      total: rows.length + (complete ? 0 : 1),
      currentPage: 1,
      perPage: rows.isEmpty ? 1 : rows.length,
      totalPages: 1,
    );
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async {
    final rows = <LocalCollectionRow>[];
    for (final budget in await context.idMap.list(FireflyEntityType.budget)) {
      if (_available(budget)) {
        rows.addAll(
            (await _db.fireflyBudgetLimits(budget.localPk)).map(_local));
      }
    }
    return rows;
  }

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final limit = await _db.fireflyBudgetLimit(pk);
    return limit == null ? null : _local(limit);
  }

  bool _samePeriod(JsonObject a, JsonObject b) =>
      a['budget_fk'] == b['budget_fk'] &&
      a['start'] == b['start'] &&
      a['end'] == b['end'] &&
      a['currency_code'] == b['currency_code'];

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyBudgetLimit> remote) async {
    final pk = remote.fields['budget_fk'] as String;
    for (final limit in await _db.fireflyBudgetLimits(pk)) {
      if (!_samePeriod(remote.fields, _local(limit).fields)) continue;
      final mapping = await context.idMap.byLocal(type, limit.budgetLimitPk);
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        return limit.budgetLimitPk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
      RemoteCollectionRow<FireflyBudgetLimit> remote,
      {String? localPk}) async {
    final limit = remote.value;
    final pk = localPk ?? const Uuid().v4();
    await _db.into(_db.budgetLimits).insertOnConflictUpdate(
          BudgetLimitsCompanion.insert(
            budgetLimitPk: Value(pk),
            budgetFk: remote.fields['budget_fk'] as String,
            start: limit.start,
            end: limit.end,
            amount: limit.amount,
            currency: limit.currencyCode.toLowerCase(),
            notes: Value(limit.notes),
            dateTimeModified: Value(limit.updatedAt),
          ),
        );
    return _local((await _db.fireflyBudgetLimit(pk))!);
  }

  @override
  Future<void> removeLocal(String pk) => _db.removePulledFireflyBudgetLimit(pk);

  Future<JsonObject> _body(LocalCollectionRow local) async {
    final body = Map<String, Object?>.of(local.fields)..remove('budget_fk');
    final code = body['currency_code'] as String;
    final decimals = _decimalPlaces[code] ??=
        (await context.api.currencies.get(code)).decimalPlaces ?? 2;
    body['amount'] = formatFireflyAmount(body['amount'] as double, decimals);
    body['fire_webhooks'] = context.config.fireWebhooks;
    return body;
  }

  Future<FireflyIdMapping> _requireParent(LocalCollectionRow local) async {
    final parent = await _parent(local.fields['budget_fk'] as String);
    if (parent == null) {
      throw const FireflyInvalidPayload();
    }
    return parent;
  }

  @override
  Future<RemoteCollectionRow<FireflyBudgetLimit>> createRemote(
      LocalCollectionRow local) async {
    final parent = await _requireParent(local);
    final created = _remote(
        parent, await _api.createLimit(parent.remoteId, await _body(local)));
    // Firefly creates the current period's limit for a new auto budget, in
    // its primary currency when the budget has none, and accepts a second
    // limit for the same period. Remove that unmapped duplicate.
    final listing = await readBudgetPages((page) => _api.listLimits(
        parent.remoteId,
        page: page,
        limit: context.config.pageSize));
    for (final item in listing.items) {
      final remote = _remote(parent, item);
      final fields = remote.fields;
      if (remote.id == created.id ||
          fields['start'] != local.fields['start'] ||
          fields['end'] != local.fields['end'] ||
          await context.idMap.byRemote(type, remote.id) != null) {
        continue;
      }
      try {
        await _api.deleteLimit(parent.remoteId, item.id);
      } on FireflyNotFound {
        // Already gone.
      }
    }
    return created;
  }

  @override
  Future<RemoteCollectionRow<FireflyBudgetLimit>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local) async {
    final parent = await _requireParent(local);
    final (budgetId, limitId) = _remoteKeys(mapping.remoteId);
    if (parent.remoteId != budgetId) {
      throw const FireflyInvalidPayload();
    }
    return _remote(
        parent, await _api.updateLimit(budgetId, limitId, await _body(local)));
  }

  @override
  Future<void> removeRemote(String id) async {
    final (budgetId, limitId) = _remoteKeys(id);
    final parent =
        await context.idMap.byRemote(FireflyEntityType.budget, budgetId);
    if (parent == null || !_available(parent)) return;
    await _api.deleteLimit(budgetId, limitId);
  }

  (String, String) _remoteKeys(String id) {
    final parts = id.split('/');
    return (Uri.decodeComponent(parts.first), Uri.decodeComponent(parts.last));
  }

  @override
  Future<RemoteCollectionRow<FireflyBudgetLimit>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final message = error.message.toLowerCase();
    if (!message.contains('already') && !message.contains('duplicate')) {
      return null;
    }
    final parent = await _parent(local.fields['budget_fk'] as String);
    if (parent == null) return null;
    final listing = await readBudgetPages((page) => _api.listLimits(
        parent.remoteId,
        page: page,
        limit: context.config.pageSize));
    for (final item in listing.items) {
      final remote = _remote(parent, item);
      if (_samePeriod(remote.fields, local.fields)) return remote;
    }
    return null;
  }
}

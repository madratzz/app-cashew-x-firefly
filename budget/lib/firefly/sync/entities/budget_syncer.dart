import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/budget.dart';
import 'package:budget/firefly/api/resources/budgets_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class BudgetSyncer extends EntitySyncer {
  const BudgetSyncer();

  static final _cycles = Expando<CollectionSync<FireflyBudget>>();

  @override
  FireflyEntityType get type => FireflyEntityType.budget;

  @override
  Set<FireflyEntityType> get dependsOn => const {FireflyEntityType.currency};

  CollectionSync<FireflyBudget> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _BudgetAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    await _cycle(context).pull();
    if (context.isCancelled()) return;
    final available = await readBudgetPages((page) => context.api.budgets
        .listAvailable(page: page, limit: context.config.pageSize));
    if (context.isCancelled()) return;
    await context.db.cacheFireflyAvailableBudgets(available.items,
        complete: available.complete);
  }

  @override
  Future<void> push(SyncContext context) => _cycle(context).push();

  @override
  Future<void> pushDeletes(SyncContext context) =>
      _cycle(context).pushDeletes();
}

enum _Period {
  daily(BudgetReoccurence.daily, 1),
  weekly(BudgetReoccurence.weekly, 1),
  monthly(BudgetReoccurence.monthly, 1),
  quarterly(BudgetReoccurence.monthly, 3),
  halfYear(BudgetReoccurence.monthly, 6),
  yearly(BudgetReoccurence.yearly, 1);

  const _Period(this.reoccurrence, this.length);

  final BudgetReoccurence reoccurrence;
  final int length;
  String get wireValue => this == halfYear ? 'half_year' : name;

  static _Period fromRemote(
          FireflyBudget budget) =>
      budget.autoBudgetType == 'none'
          ? monthly
          : values
                  .where((value) =>
                      value.wireValue ==
                      budget.autoBudgetPeriod?.replaceAll('-', '_'))
                  .firstOrNull ??
              monthly;

  static _Period? fromLocal(Budget budget) => values
      .where((value) =>
          value.reoccurrence == budget.reoccurrence &&
          value.length == budget.periodLength)
      .firstOrNull;

  ({DateTime start, DateTime end}) bounds(DateTime now) {
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final startMonth = ((month - 1) ~/ length) * length + 1;
    return switch (this) {
      daily => (
          start: DateTime(year, month, day),
          end: DateTime(year, month, day)
        ),
      weekly => (
          start: DateTime(year, month, day - now.weekday + DateTime.monday),
          end: DateTime(year, month, day - now.weekday + DateTime.sunday),
        ),
      monthly || quarterly || halfYear => (
          start: DateTime(year, startMonth),
          end: DateTime(year, startMonth + length, 0),
        ),
      yearly => (start: DateTime(year), end: DateTime(year + 1, 1, 0)),
    };
  }
}

class _BudgetAdapter extends CollectionAdapter<FireflyBudget> {
  const _BudgetAdapter(this.context);

  final SyncContext context;

  FinanceDatabase get _db => context.db;
  BudgetsApi get _api => context.api.budgets;

  @override
  FireflyEntityType get type => FireflyEntityType.budget;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  String _name(String value) {
    final trimmed = value.trim();
    return trimmed.length > NAME_LIMIT
        ? trimmed.substring(0, NAME_LIMIT)
        : trimmed;
  }

  RemoteCollectionRow<FireflyBudget> _remote(FireflyBudget budget) {
    final type = budget.autoBudgetType;
    return RemoteCollectionRow(
      id: budget.id,
      value: budget,
      updatedAt: budget.updatedAt,
      snapshot: budget.attributes,
      fields: {
        'name': _name(budget.name!),
        'active': budget.active,
        'auto_budget_type': type,
        if (type != 'none') ...{
          'auto_budget_period': _Period.fromRemote(budget).wireValue,
          'auto_budget_amount': budget.autoBudgetAmount,
          'auto_budget_currency_code': budget.currencyCode?.toUpperCase(),
        },
      },
    );
  }

  Future<LocalCollectionRow> _local(Budget budget) async {
    final state = await _db.fireflyBudgetState(budget.budgetPk);
    final previous = state?.remote;
    final baseline = previous?.autoBudgetAmount ?? 0;
    final projected = state?.projectedAmount;
    final amount = projected != null && budget.amount == projected
        ? baseline
        : budget.amount.abs();
    final period = _Period.fromLocal(budget);
    final unchangedManual = previous?.autoBudgetType == 'none' &&
        amount == baseline &&
        period == _Period.fromRemote(previous!);
    final autoType = period == null ||
            unchangedManual ||
            (amount == 0 &&
                (previous == null || previous.autoBudgetType == 'none'))
        ? 'none'
        : previous != null && previous.autoBudgetType != 'none'
            ? previous.autoBudgetType
            : 'reset';
    return LocalCollectionRow(
      pk: budget.budgetPk,
      modifiedAt: budget.dateTimeModified,
      snapshot: budget.toJson(),
      fields: {
        'name': _name(budget.name),
        'active': !budget.archived,
        'auto_budget_type': autoType,
        if (autoType != 'none') ...{
          'auto_budget_period': period!.wireValue,
          'auto_budget_amount': amount,
          'auto_budget_currency_code': previous?.currencyCode?.toUpperCase(),
        },
      },
    );
  }

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyBudget>>> page(
          int page, int limit) async =>
      (await _api.list(page: page, limit: limit)).map(_remote);

  Future<List<Budget>> _envelopes() => (_db.select(_db.budgets)
        ..where((row) => row.addedTransactionsOnly.equals(true)))
      .get();

  @override
  Future<List<LocalCollectionRow>> listLocal() async =>
      Future.wait((await _envelopes()).map(_local));

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final budget = await _db.fireflyBudget(pk);
    return budget == null ? null : _local(budget);
  }

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyBudget> remote) async {
    final name = remote.fields['name'];
    for (final budget in await _envelopes()) {
      if (_name(budget.name) != name) continue;
      final mapping = await context.idMap.byLocal(type, budget.budgetPk);
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        return budget.budgetPk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
      RemoteCollectionRow<FireflyBudget> remote,
      {String? localPk}) async {
    final existing = localPk == null ? null : await _db.fireflyBudget(localPk);
    final budget = remote.value;
    final period = _Period.fromRemote(budget);
    final bounds = period.bounds(context.now());
    final keepBounds =
        existing != null && _Period.fromLocal(existing) == period;
    final pk = localPk ?? const Uuid().v4();
    final order = _db.budgets.order.max();
    final last = existing == null
        ? await (_db.selectOnly(_db.budgets)..addColumns([order])).getSingle()
        : null;
    final row = (existing ??
            Budget(
              budgetPk: pk,
              name: '',
              amount: 0,
              startDate: bounds.start,
              endDate: bounds.end,
              income: false,
              archived: false,
              addedTransactionsOnly: true,
              periodLength: period.length,
              dateCreated: budget.createdAt ?? context.now(),
              pinned: false,
              order: (last?.read(order) ?? -1) + 1,
              walletFk: '0',
              isAbsoluteSpendingLimit: false,
            ))
        .copyWith(
      name: _name(budget.name!),
      amount: budget.autoBudgetAmount,
      archived: !budget.active,
      addedTransactionsOnly: true,
      reoccurrence: Value(period.reoccurrence),
      periodLength: period.length,
      startDate: keepBounds ? existing.startDate : bounds.start,
      endDate: keepBounds ? existing.endDate : bounds.end,
      dateTimeModified: Value(budget.updatedAt),
    );
    await _db.into(_db.budgets).insertOnConflictUpdate(row.toCompanion(false));
    await _db.cacheFireflyBudgetState(pk, budget);
    return _local((await _db.fireflyBudget(pk))!);
  }

  @override
  Future<void> removeLocal(String pk) => _db.removePulledFireflyBudget(pk);

  Future<JsonObject> _body(LocalCollectionRow local) async {
    final body = Map<String, Object?>.of(local.fields);
    final amount = body['auto_budget_amount'] as double?;
    if (amount != null) {
      final state = await _db.fireflyBudgetState(local.pk);
      final code = body['auto_budget_currency_code'] as String?;
      if (code == null) body.remove('auto_budget_currency_code');
      final decimals = state?.remote.decimalPlaces ??
          (code == null
                  ? await context.api.currencies.primary()
                  : await context.api.currencies.get(code))
              .decimalPlaces ??
          2;
      body['auto_budget_amount'] = formatFireflyAmount(amount, decimals);
    }
    body['fire_webhooks'] = context.config.fireWebhooks;
    return body;
  }

  @override
  Future<RemoteCollectionRow<FireflyBudget>> createRemote(
          LocalCollectionRow local) async =>
      _acceptPush(local, await _api.create(await _body(local)));

  @override
  Future<RemoteCollectionRow<FireflyBudget>> updateRemote(
          FireflyIdMapping mapping, LocalCollectionRow local) async =>
      _acceptPush(
          local, await _api.update(mapping.remoteId, await _body(local)));

  Future<RemoteCollectionRow<FireflyBudget>> _acceptPush(
      LocalCollectionRow local, FireflyBudget budget) async {
    await _db.transaction(() async {
      final current = await _db.fireflyBudget(local.pk);
      if (current == null) return;
      final state = await _db.fireflyBudgetState(local.pk);
      final previousProjection = state?.projectedAmount;
      // Carry forward a displayed limit only when the submitted amount came
      // from auto-budget state. A direct edit becomes the new underlying amount.
      final submitted = Budget.fromJson(local.snapshot!);
      final keepProjection = submitted.amount == previousProjection;
      if (!keepProjection &&
          current.dateTimeModified == local.modifiedAt &&
          current.amount == submitted.amount &&
          current.amount != budget.autoBudgetAmount) {
        await (_db.update(_db.budgets)
              ..where((row) => row.budgetPk.equals(local.pk)))
            .write(BudgetsCompanion(amount: Value(budget.autoBudgetAmount)));
      }
      await _db.cacheFireflyBudgetState(local.pk, budget,
          projectedAmount: keepProjection ? previousProjection : null);
    });
    return _remote(budget);
  }

  @override
  Future<void> removeRemote(String id) => _api.delete(id);

  @override
  Future<RemoteCollectionRow<FireflyBudget>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final messages =
        [error.message, ...?error.errors['name']].join(' ').toLowerCase();
    if (!messages.contains('already') && !messages.contains('duplicate')) {
      return null;
    }
    final found = await readBudgetPages(
        (page) => _api.list(page: page, limit: context.config.pageSize));
    for (final budget in found.items) {
      if (_name(budget.name!) == local.fields['name']) return _remote(budget);
    }
    return null;
  }
}

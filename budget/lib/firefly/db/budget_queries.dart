import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/available_budget.dart';
import 'package:budget/firefly/api/models/budget.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:drift/drift.dart';

const _budgetType = FireflyEntityType.budget;
const _limitType = FireflyEntityType.budgetLimit;
// Schema 47 has no separate available-budget entity type.
const _availablePrefix = 'available:';
const _autoPrefix = 'auto:';

extension FireflyBudgetQueries on FinanceDatabase {
  Future<Budget?> fireflyBudget(String pk) =>
      (select(budgets)..where((row) => row.budgetPk.equals(pk)))
          .getSingleOrNull();

  Future<List<BudgetLimit>> fireflyBudgetLimits(String budgetPk) =>
      _limits(budgetPk).get();

  Stream<List<BudgetLimit>> watchFireflyBudgetLimits(String budgetPk) =>
      _limits(budgetPk).watch();

  SimpleSelectStatement<$BudgetLimitsTable, BudgetLimit> _limits(
          String budgetPk) =>
      select(budgetLimits)
        ..where((row) => row.budgetFk.equals(budgetPk))
        ..orderBy([
          (row) => OrderingTerm.desc(row.start),
          (row) => OrderingTerm.asc(row.end),
          (row) => OrderingTerm.asc(row.budgetLimitPk),
        ]);

  Future<BudgetLimit?> fireflyBudgetLimit(String pk) =>
      (select(budgetLimits)..where((row) => row.budgetLimitPk.equals(pk)))
          .getSingleOrNull();

  /// Records a local edit with a version distinguishable at Drift's precision.
  Future<BudgetLimit> fireflySaveBudgetLimit(BudgetLimitsCompanion limit) =>
      transaction(() async {
        final previous = limit.budgetLimitPk.present
            ? await fireflyBudgetLimit(limit.budgetLimitPk.value)
            : null;
        final now = DateTime.now();
        final next =
            previous?.dateTimeModified?.add(const Duration(seconds: 1));
        final patch = limit.copyWith(
            dateTimeModified: Value(
          next != null && next.isAfter(now) ? next : now,
        ));
        if (previous == null) return into(budgetLimits).insertReturning(patch);
        await (update(budgetLimits)
              ..where(
                  (row) => row.budgetLimitPk.equals(previous.budgetLimitPk)))
            .write(patch);
        return (await fireflyBudgetLimit(previous.budgetLimitPk))!;
      });

  Future<void> fireflyDeleteBudgetLimit(String limitPk) =>
      transaction(() async {
        await IdMapRepository(this).markPendingDelete(_limitType, limitPk);
        await removePulledFireflyBudgetLimit(limitPk);
      });

  /// Delete a Firefly envelope. Firefly cascades the remote limit deletions.
  Future<void> fireflyDeleteBudget(String budgetPk) => transaction(() async {
        await IdMapRepository(this).markPendingDelete(_budgetType, budgetPk);
        await removePulledFireflyBudget(budgetPk);
      });

  Future<void> removePulledFireflyBudgetLimit(String limitPk) =>
      (delete(budgetLimits)..where((row) => row.budgetLimitPk.equals(limitPk)))
          .go();

  Future<void> removePulledFireflyBudget(String budgetPk) =>
      transaction(() async {
        final idMap = IdMapRepository(this);
        for (final limit in await fireflyBudgetLimits(budgetPk)) {
          await idMap.remove(_limitType, limit.budgetLimitPk);
        }
        await (delete(budgetLimits)
              ..where((row) => row.budgetFk.equals(budgetPk)))
            .go();
        await (delete(categoryBudgetLimits)
              ..where((row) => row.budgetFk.equals(budgetPk)))
            .go();
        await (update(transactions)
              ..where((row) => row.sharedReferenceBudgetPk.equals(budgetPk)))
            .write(const TransactionsCompanion(
                sharedReferenceBudgetPk: Value(null)));
        final excluded = await (select(transactions)
              ..where((row) => row.budgetFksExclude.isNotNull()))
            .get();
        for (final row in excluded) {
          final keys = row.budgetFksExclude!;
          if (!keys.contains(budgetPk)) continue;
          await (update(transactions)
                ..where((item) => item.transactionPk.equals(row.transactionPk)))
              .write(TransactionsCompanion(
            budgetFksExclude:
                Value(keys.where((key) => key != budgetPk).toList()),
          ));
        }
        await (delete(budgets)..where((row) => row.budgetPk.equals(budgetPk)))
            .go();
        await ResourceCacheRepository(this)
            .remove(_budgetType, '$_autoPrefix$budgetPk');
      });

  Stream<List<FireflyAvailableBudget>> watchFireflyAvailableBudgets() =>
      ResourceCacheRepository(this).watch(_budgetType).map((rows) => [
            for (final row in rows)
              if (row.resourcePk
                  .startsWith('${_budgetType.name}:$_availablePrefix'))
                FireflyAvailableBudget(
                  id: row.resourcePk.substring(
                      '${_budgetType.name}:$_availablePrefix'.length),
                  attributes: ResourceCacheRepository.decode(row),
                ),
          ]);

  Future<void> cacheFireflyAvailableBudgets(List<FireflyAvailableBudget> items,
          {required bool complete}) =>
      transaction(() async {
        final cache = ResourceCacheRepository(this);
        final ids = <String>{};
        for (final item in items) {
          final key = '$_availablePrefix${item.id}';
          ids.add(ResourceCacheRepository.resourcePk(_budgetType, key));
          await cache.write(_budgetType, key, item.attributes,
              modifiedAt: item.updatedAt);
        }
        if (!complete) return;
        final prefix = '${_budgetType.name}:';
        for (final row in await cache.list(_budgetType)) {
          if (row.resourcePk.startsWith('$prefix$_availablePrefix') &&
              !ids.contains(row.resourcePk)) {
            await cache.remove(
                _budgetType, row.resourcePk.substring(prefix.length));
          }
        }
      });

  Future<({FireflyBudget remote, double? projectedAmount})?> fireflyBudgetState(
      String budgetPk) async {
    final row = await ResourceCacheRepository(this)
        .read(_budgetType, '$_autoPrefix$budgetPk');
    if (row == null) return null;
    final data = ResourceCacheRepository.decode(row);
    return (
      remote: FireflyBudget.fromJson(data),
      projectedAmount: (data['projected_amount'] as num?)?.toDouble(),
    );
  }

  Future<void> cacheFireflyBudgetState(String budgetPk, FireflyBudget remote,
          {double? projectedAmount}) =>
      ResourceCacheRepository(this).write(
          _budgetType,
          '$_autoPrefix$budgetPk',
          {
            'id': remote.id,
            'attributes': remote.attributes,
            'projected_amount': projectedAmount,
          },
          modifiedAt: remote.updatedAt);

  /// Apply the current period's amount without making the budget dirty.
  Future<void> projectFireflyBudgetAmounts(DateTime now) =>
      transaction(() async {
        final today = DateTime(now.year, now.month, now.day);
        final mappings = await IdMapRepository(this).list(_budgetType);
        for (final mapping in mappings) {
          if (mapping.state != FireflySyncState.synced) continue;
          final budget = await fireflyBudget(mapping.localPk);
          final state = await fireflyBudgetState(mapping.localPk);
          if (budget == null || state == null) continue;
          final autoAmount = state.remote.autoBudgetAmount;
          if (budget.amount != (state.projectedAmount ?? autoAmount)) continue;

          final limits = (await fireflyBudgetLimits(budget.budgetPk)).where(
              (limit) =>
                  !limit.start.isAfter(today) && !limit.end.isBefore(today));
          final currency = state.remote.currencyCode?.toLowerCase();
          final current =
              limits.where((limit) => limit.currency == currency).firstOrNull ??
                  limits.firstOrNull;
          final projected = current?.amount;
          if (budget.amount != (projected ?? autoAmount)) {
            await (update(budgets)
                  ..where((row) => row.budgetPk.equals(budget.budgetPk)))
                .write(
                    BudgetsCompanion(amount: Value(projected ?? autoAmount)));
          }
          if (projected != state.projectedAmount) {
            await cacheFireflyBudgetState(budget.budgetPk, state.remote,
                projectedAmount: projected);
          }
        }
      });
}

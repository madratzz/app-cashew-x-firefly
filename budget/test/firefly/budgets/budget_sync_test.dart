import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../e2e/support/e2e_harness.dart';

const _budget = FireflyEntityType.budget;
const _limit = FireflyEntityType.budgetLimit;

void main() {
  late E2eDevice device;
  late E2eTarget target;
  late E2eClock clock;
  late FinanceDatabase db;
  late String accountId;

  setUp(() async {
    clock = E2eClock(live: false);
    target = await E2eTarget.fake(clock.now);
    addTearDown(target.close);
    device = E2eDevice(target, clock);
    addTearDown(device.close);
    db = device.db;
    accountId = (await device.admin.accounts.create({
      'name': 'Checking',
      'type': 'asset',
      'currency_code': 'USD',
    }))
        .id;
  });

  Future<List<E2eWrite>> sync() async {
    await clock.tick();
    final result = await device.sync();
    expect(result.report.succeeded, isTrue,
        reason: result.report.issues.map((e) => e.message).join(', '));
    return result.writes;
  }

  Future<Budget> localBudget({
    String name = 'Groceries',
    double amount = 80,
    BudgetReoccurence period = BudgetReoccurence.monthly,
    int length = 1,
  }) =>
      db.into(db.budgets).insertReturning(BudgetsCompanion.insert(
            name: name,
            startDate: clock.now(),
            endDate: clock.now(),
            amount: amount,
            reoccurrence: Value(period),
            periodLength: length,
            dateTimeModified: Value(clock.now()),
            addedTransactionsOnly: const Value(true),
            pinned: const Value(true),
            colour: const Value('#FF00FF'),
            income: const Value(true),
            order: 14,
            sharedKey: const Value('example-key'),
            walletFks: const Value(['0']),
            categoryFks: const Value(['0']),
            memberTransactionFilters: const Value(['example-member']),
          ));

  Future<Budget> remoteBudget(String name, {String? period}) async {
    final remote = await device.admin.budgets.create({
      'name': name,
      'active': true,
      if (period != null) ...{
        'auto_budget_type': 'rollover',
        'auto_budget_period': period,
        'auto_budget_amount': '100.00',
        'auto_budget_currency_code': 'USD',
      },
    });
    await sync();
    return (await db
        .fireflyBudget((await device.localPk(_budget, remote.id))!))!;
  }

  test('budget create, rename, archive and delete sync in both directions',
      () async {
    await sync();
    final local = await localBudget(name: '  Groceries  ');
    expect(await sync(), [(method: 'POST', path: '/budgets')]);
    final id = (await device.remoteId(_budget, local.budgetPk))!;
    final api = device.admin.budgets;
    final created = await api.get(id);
    expect(created.name, 'Groceries');
    expect(created.autoBudgetAmount, 80);
    expect(created.autoBudgetType, 'reset');
    expect(await sync(), isEmpty);

    await clock.tick();
    await (db.update(db.budgets)
          ..where((b) => b.budgetPk.equals(local.budgetPk)))
        .write(BudgetsCompanion(
      name: const Value('Food'),
      archived: const Value(true),
      dateTimeModified: Value(clock.now()),
    ));
    expect(await sync(), [(method: 'PUT', path: '/budgets/$id')]);
    expect((await api.get(id)).name, 'Food');
    expect((await api.get(id)).active, isFalse);

    await api
        .update(id, {'name': 'Fresh food', 'active': true, 'notes': 'Online'});
    expect(await sync(), isEmpty);
    final pulled = (await db.fireflyBudget(local.budgetPk))!;
    expect(pulled.name, 'Fresh food');
    expect(pulled.archived, isFalse);
    expect(pulled.pinned, local.pinned);
    expect(pulled.colour, local.colour);
    expect(pulled.income, local.income);
    expect(pulled.order, local.order);
    expect(pulled.sharedKey, local.sharedKey);
    expect(pulled.walletFks, local.walletFks);
    expect(pulled.categoryFks, local.categoryFks);
    expect(pulled.memberTransactionFilters, local.memberTransactionFilters);

    await device.admin.budgets.delete(id);
    expect(await sync(), isEmpty);
    expect(await db.fireflyBudget(local.budgetPk), isNull);
    expect(await device.remoteId(_budget, local.budgetPk), isNull);

    final imported = await remoteBudget('Remote only');
    expect(imported.addedTransactionsOnly, isTrue);
    expect(imported.reoccurrence, BudgetReoccurence.monthly);
    final importedId = (await device.remoteId(_budget, imported.budgetPk))!;
    await db.fireflyDeleteBudget(imported.budgetPk);
    expect(await sync(), [(method: 'DELETE', path: '/budgets/$importedId')]);
    await expectLater(api.get(importedId), throwsA(isA<FireflyNotFound>()));
  });

  test('all six auto-budget periods map on read and write', () async {
    const periods = [
      ('daily', 'daily', BudgetReoccurence.daily, 1),
      ('weekly', 'weekly', BudgetReoccurence.weekly, 1),
      ('monthly', 'monthly', BudgetReoccurence.monthly, 1),
      ('quarterly', 'quarterly', BudgetReoccurence.monthly, 3),
      ('half-year', 'half_year', BudgetReoccurence.monthly, 6),
      ('yearly', 'yearly', BudgetReoccurence.yearly, 1),
    ];
    for (final (remote, wire, period, length) in periods) {
      final imported = await remoteBudget('Remote $remote', period: remote);
      expect(imported.reoccurrence, period);
      expect(imported.periodLength, length);
      expect(imported.amount, 100);
      final created = await localBudget(
          name: 'Local $remote', period: period, length: length);
      await sync();
      final id = (await device.remoteId(_budget, created.budgetPk))!;
      expect((await device.admin.budgets.get(id)).autoBudgetPeriod, wire);
    }
    expect(await sync(), isEmpty);
  });

  test('current and historical limits round-trip and do not dirty auto budgets',
      () async {
    final budget = await remoteBudget('Household', period: 'monthly');
    final id = (await device.remoteId(_budget, budget.budgetPk))!;
    final now = clock.now();
    final currentStart = DateTime(now.year, now.month);
    final currentEnd = DateTime(now.year, now.month + 1, 0);
    final pastStart = DateTime(now.year, now.month - 1);
    final pastEnd = DateTime(now.year, now.month, 0);
    final api = device.admin.budgets;
    final current = await api.createLimit(id, {
      'start': '${formatFireflyDate(currentStart)}T00:00:00+14:00',
      'end': '${formatFireflyDate(currentEnd)}T23:59:59-11:00',
      'amount': '75.25',
      'currency_code': 'USD',
      'notes': 'Current',
    });
    final past = await db.fireflySaveBudgetLimit(BudgetLimitsCompanion.insert(
      budgetFk: budget.budgetPk,
      start: pastStart,
      end: pastEnd,
      amount: 45.5,
      currency: 'eur',
      notes: const Value('Past'),
    ));

    expect(await sync(), [(method: 'POST', path: '/budgets/$id/limits')]);
    final limits = await db.fireflyBudgetLimits(budget.budgetPk);
    expect(limits, hasLength(2));
    final imported = limits.first;
    expect(imported.start, currentStart);
    expect(imported.end, currentEnd);
    expect(imported.amount, 75.25);
    expect(imported.currency, 'usd');
    expect(imported.notes, 'Current');
    expect((await db.fireflyBudget(budget.budgetPk))!.amount, 75.25);
    expect((await api.get(id)).autoBudgetAmount, 100);
    final remotePast = (await api.listLimits(id))
        .items
        .singleWhere((row) => row.id != current.id);
    expect(remotePast.amount, 45.5);
    expect(remotePast.currencyCode, 'EUR');

    await db.fireflySaveBudgetLimit(BudgetLimitsCompanion(
      budgetLimitPk: Value(imported.budgetLimitPk),
      amount: const Value(90),
      notes: const Value(null),
    ));
    await api.updateLimit(
        id, remotePast.id, {'amount': '55.75', 'notes': 'Updated'});
    expect(await sync(),
        [(method: 'PUT', path: '/budgets/$id/limits/${current.id}')]);
    expect((await api.getLimit(id, current.id)).amount, 90);
    expect((await api.getLimit(id, current.id)).notes, isNull);
    expect((await db.fireflyBudgetLimit(past.budgetLimitPk))!.amount, 55.75);
    expect((await db.fireflyBudget(budget.budgetPk))!.amount, 90);
    expect((await api.get(id)).autoBudgetAmount, 100);
    expect(await sync(), isEmpty);

    await api.deleteLimit(id, current.id);
    await db.fireflyDeleteBudgetLimit(past.budgetLimitPk);
    expect(await sync(),
        [(method: 'DELETE', path: '/budgets/$id/limits/${remotePast.id}')]);
    expect(await db.fireflyBudgetLimits(budget.budgetPk), isEmpty);
    expect((await db.fireflyBudget(budget.budgetPk))!.amount, 100);
    expect((await api.listLimits(id)).items, isEmpty);
  });

  test('deleting a budget queues only its parent and cleans up child limits',
      () async {
    final budget = await remoteBudget('Envelope');
    final id = (await device.remoteId(_budget, budget.budgetPk))!;
    await device.admin.budgets.createLimit(id, {
      'start': '2023-01-01',
      'end': '2023-01-31',
      'amount': '50.00',
      'currency_code': 'USD',
    });
    await sync();
    expect(await db.fireflyBudgetLimits(budget.budgetPk), hasLength(1));
    await db.fireflyDeleteBudget(budget.budgetPk);
    expect(await db.fireflyBudget(budget.budgetPk), isNull);
    expect(await db.fireflyBudgetLimits(budget.budgetPk), isEmpty);
    expect(await device.context.idMap.list(_limit), isEmpty);
    expect(
      (await device.context.idMap
              .list(_budget, state: FireflySyncState.pendingDelete))
          .map((row) => row.localPk),
      [budget.budgetPk],
    );
    expect(await sync(), [(method: 'DELETE', path: '/budgets/$id')]);
  });

  test('category budget limits stay local and available budgets are read-only',
      () async {
    final budget = await remoteBudget('Local category limit');
    final category = await device.addCategory('Food');
    await sync();
    target.emulator!.seed('/available-budgets', '7', {
      'start': '2023-01-01',
      'end': '2023-01-31',
      'amount': '99.00',
      'currency_code': 'USD',
    });
    final categoryLimit = await db
        .into(db.categoryBudgetLimits)
        .insertReturning(CategoryBudgetLimitsCompanion.insert(
          categoryFk: category,
          budgetFk: budget.budgetPk,
          amount: 23,
        ));
    expect(await sync(), isEmpty);
    final available = (await db.watchFireflyAvailableBudgets().first).single;
    expect(available.id, '7');
    expect(available.amount, 99);
    expect(available.currencyCode, 'USD');
    expect(await db.select(db.categoryBudgetLimits).get(), [categoryLimit]);
    target.emulator!.removeSeed('/available-budgets', '7');
    expect(await sync(), isEmpty);
    expect(await db.watchFireflyAvailableBudgets().first, isEmpty);
  });

  test(
      'withdrawal assignments survive local and remote edits and can be cleared',
      () async {
    final groceries = await remoteBudget('Groceries');
    final travel = await remoteBudget('Travel');
    final groceriesId = (await device.remoteId(_budget, groceries.budgetPk))!;
    final travelId = (await device.remoteId(_budget, travel.budgetPk))!;
    final journal = await device.admin.transactions.create({
      'transactions': [
        {
          'type': 'withdrawal',
          'date': formatFireflyDateTime(clock.now()),
          'amount': '10.00',
          'description': 'Supplies',
          'source_id': accountId,
          'destination_name': 'Shop',
          'budget_id': groceriesId,
        },
      ],
    });
    await sync();
    final split = journal.splits.single;
    final pk = (await device.localPk(FireflyEntityType.transaction, journal.id,
        subId: split.journalId!))!;
    expect((await db.fireflyTransaction(pk))!.sharedReferenceBudgetPk,
        groceries.budgetPk);

    await clock.tick();
    await (db.update(db.transactions)
          ..where((row) => row.transactionPk.equals(pk)))
        .write(TransactionsCompanion(
      sharedReferenceBudgetPk: Value(travel.budgetPk),
      dateTimeModified: Value(clock.now()),
    ));
    expect(
        await sync(), [(method: 'PUT', path: '/transactions/${journal.id}')]);
    expect(
        (await device.admin.transactions.get(journal.id))
            .splits
            .single
            .budgetId,
        travelId);
    expect((await db.fireflyTransaction(pk))!.sharedReferenceBudgetPk,
        travel.budgetPk);
    expect(await sync(), isEmpty);

    await clock.tick();
    await device.admin.transactions.update(journal.id, {
      'transactions': [
        {'transaction_journal_id': split.journalId, 'budget_id': groceriesId},
      ],
    });
    expect(await sync(), isEmpty);
    expect((await db.fireflyTransaction(pk))!.sharedReferenceBudgetPk,
        groceries.budgetPk);

    await clock.tick();
    await (db.update(db.transactions)
          ..where((row) => row.transactionPk.equals(pk)))
        .write(TransactionsCompanion(
      sharedReferenceBudgetPk: const Value(null),
      dateTimeModified: Value(clock.now()),
    ));
    expect(
        await sync(), [(method: 'PUT', path: '/transactions/${journal.id}')]);
    expect(
        (await device.admin.transactions.get(journal.id))
            .splits
            .single
            .budgetId,
        isNull);

    await clock.tick();
    await device.admin.transactions.update(journal.id, {
      'transactions': [
        {'transaction_journal_id': split.journalId, 'budget_id': travelId},
      ],
    });
    await sync();
    expect((await db.fireflyTransaction(pk))!.sharedReferenceBudgetPk,
        travel.budgetPk);
    await clock.tick();
    await device.admin.transactions.update(journal.id, {
      'transactions': [
        {'transaction_journal_id': split.journalId, 'budget_id': null},
      ],
    });
    expect(await sync(), isEmpty);
    expect((await db.fireflyTransaction(pk))!.sharedReferenceBudgetPk, isNull);
  });
}

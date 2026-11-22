import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../phase2/support/phase2_emulator.dart';
import '../support/e2e_harness.dart';

/// Firefly creates a new auto budget's current limit in its primary currency
/// when the budget has none. The local limit must replace it, not sit next
/// to it.
void main() {
  test('a local limit adopts the auto limit made in another currency',
      () async {
    final clock = E2eClock(live: false);
    final target = await Phase2Emulator.target(clock.now);
    addTearDown(target.close);
    target.emulator!.seed('/currencies', 'primary', {
      'code': 'EUR',
      'name': 'EUR',
      'symbol': 'EUR',
      'decimal_places': 2,
      'enabled': true,
      'primary': true,
    });
    final device = E2eDevice(target, clock);
    addTearDown(device.close);

    await device.db.into(device.db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Cash', order: 0));
    final now = clock.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1, 0);
    final budget = await device.db
        .into(device.db.budgets)
        .insertReturning(BudgetsCompanion.insert(
          name: 'Groceries',
          startDate: start,
          endDate: end,
          amount: 200,
          reoccurrence: const Value(BudgetReoccurence.monthly),
          periodLength: 1,
          order: 0,
          addedTransactionsOnly: const Value(true),
          dateTimeModified: Value(now),
        ));
    await device.db.fireflySaveBudgetLimit(BudgetLimitsCompanion.insert(
      budgetFk: budget.budgetPk,
      start: start,
      end: end,
      amount: 150,
      currency: 'usd',
    ));
    final cycle = await device.sync();
    expect(cycle.report.succeeded, isTrue);

    final id =
        (await device.remoteId(FireflyEntityType.budget, budget.budgetPk))!;
    final limits = (await device.admin.budgets.listLimits(id)).items;
    expect(limits.map((limit) => (limit.amount, limit.currencyCode)),
        [(150.0, 'USD')]);
  });
}

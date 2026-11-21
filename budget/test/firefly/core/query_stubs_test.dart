import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/db/delete_log_queries.dart';
import 'package:budget/firefly/db/filter_queries.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/db/reset_queries.dart';
import 'package:budget/firefly/db/rule_queries.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  test('feature query stubs return empty results and leave local data intact',
      () async {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final wallet = await db.into(db.wallets).insertReturning(
          WalletsCompanion.insert(name: 'Example', order: 0),
        );

    expect(await db.fireflyWallet(wallet.walletPk), wallet);
    for (final result in await Future.wait<Object?>([
      db.fireflyAccountDetails(wallet.walletPk),
      db.fireflyCategory('sample'),
      db.fireflyBudget('sample'),
      db.fireflyTransaction('sample'),
      db.fireflyObjective('sample'),
      db.fireflyBill('sample'),
      db.fireflyRecurrence('sample'),
      db.fireflyPayee('sample'),
      db.fireflyCurrency('USD'),
    ])) {
      expect(result, isNull);
    }

    for (final result in await Future.wait<List<Object?>>([
      db.fireflyDeleteLogs(),
      db.fireflyFilteredTransactionPks(),
      db.fireflyLiabilities(),
      db.fireflyRules(),
      db.fireflyPayees(),
      db.fireflyTags(),
      db.fireflyTransactionTags('sample'),
    ])) {
      expect(result, isEmpty);
    }

    await db.clearFireflyFinanceData();
    expect(await db.select(db.wallets).get(), isEmpty);
  });
}

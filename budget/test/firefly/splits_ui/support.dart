import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

Future<FinanceDatabase> seededDatabase() async {
  final db = inMemoryFinanceDatabase();
  await db.into(db.wallets).insert(WalletsCompanion.insert(
      walletPk: const Value('0'), name: 'Default', order: 0));
  for (final (pk, name, order) in [('0', 'Balance', 0), ('food', 'Food', 1)]) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: Value(pk), name: name, order: order));
  }
  return db;
}

Future<(Transaction, Transaction)> seedGroup(FinanceDatabase db) async {
  final group = await db
      .into(db.transactionGroups)
      .insertReturning(const TransactionGroupsCompanion(title: Value('Shop')));
  Future<Transaction> row(String name, double amount, int order) =>
      db.into(db.transactions).insertReturning(TransactionsCompanion.insert(
            name: name,
            amount: amount,
            note: '',
            categoryFk: 'food',
            splitGroupFk: Value(group.groupPk),
            splitOrder: Value(order),
          ));
  return (await row('Bread', -3, 0), await row('Milk', -2, 1));
}

Future<void> pumpSplitWidget(WidgetTester tester, Widget child) async {
  // Build in the real zone so Drift queries do not wait on the fake clock.
  await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      )));
  await settleDb(tester);
}

// Drift completes queries outside the fake clock.
Future<void> settleDb(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}


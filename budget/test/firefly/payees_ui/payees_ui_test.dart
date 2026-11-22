import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/entry/payee_chip.dart';
import 'package:budget/firefly/ui/pages/payees/payees_page.dart';
import 'package:budget/firefly/ui/transaction/payee_section.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

/// Unmounts inside the test body: Drift stream queries leave a zero-length
/// timer that must fire before the binding checks for pending timers.
WidgetTester? _tester;

void widgetTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      _tester = tester;
      addTearDown(() => _tester = null);
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

/// Drift I/O awaited outside a pump never completes under fake async.
Future<T> io<T>(Future<T> Function() run) async {
  final tester = _tester;
  if (tester == null) return run();
  return (await tester.runAsync(run)) as T;
}

/// Alternates real and fake time so Drift queries and streams complete.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

ValueKey<String> _key(String value) => ValueKey(value);

void main() {
  late FinanceDatabase db;
  late int writes;

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await settle(tester);
  }

  Future<Payee> seed(String name, PayeeKind kind, {bool active = true}) =>
      io(() => db.fireflyCreatePayee(name: name, kind: kind, active: active));

  Future<Transaction> seedTransaction(String name, Payee payee) => io(() async {
        await db.into(db.wallets).insert(WalletsCompanion.insert(
            walletPk: const Value('0'),
            name: 'Wallet',
            order: 0,
            currency: const Value('usd'),
            decimals: const Value(2)));
        await db.into(db.categories).insert(CategoriesCompanion.insert(
            categoryPk: const Value(fireflyUncategorizedCategoryPk),
            name: 'Uncategorized',
            order: 0));
        return db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
                name: name,
                amount: -5,
                categoryFk: fireflyUncategorizedCategoryPk,
                note: '',
                payeeFk: Value(payee.payeePk),
                dateCreated: Value(DateTime(2026, 11, 1))));
      });

  setUp(() {
    db = inMemoryFinanceDatabase();
    writes = 0;
  });

  // Awaiting close inside a fake-async widget test never completes.
  tearDown(() {
    db.close();
  });

  group('picker', () {
    widgetTest('filters by kind and active, then stores the choice',
        (tester) async {
      final shop = await seed('Shop', PayeeKind.expense);
      await seed('Old shop', PayeeKind.expense, active: false);
      final employer = await seed('Employer', PayeeKind.revenue);
      final draft = FireflyTransactionDraft(db);
      await pump(tester, Scaffold(body: FireflyPayeePicker(draft: draft)));
      expect(find.text('firefly-payees-picker-none'), findsOneWidget);

      await tester.tap(find.byKey(_key('firefly-payee-picker')));
      await settle(tester);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Old shop'), findsNothing);
      expect(find.text('Employer'), findsNothing);

      await tester.tap(find.text('firefly-payees-picker-deposit'));
      await settle(tester);
      expect(find.text('Shop'), findsNothing);
      await tester.tap(
          find.byKey(_key('firefly-payee-picker-option-${employer.payeePk}')));
      await settle(tester);
      expect(draft.payeePk, employer.payeePk);
      expect(find.text('Employer'), findsOneWidget);

      await tester.tap(find.byKey(_key('firefly-payee-picker-clear')));
      await settle(tester);
      expect(draft.payeePk, isNull);
      expect(shop.kind, PayeeKind.expense);
    });

    widgetTest('search narrows and creates a payee inline', (tester) async {
      await seed('Bakery', PayeeKind.expense);
      final draft = FireflyTransactionDraft(db);
      await pump(
          tester,
          Scaffold(
              body: FireflyPayeePicker(draft: draft, onWrite: () => writes++)));
      await tester.tap(find.byKey(_key('firefly-payee-picker')));
      await settle(tester);

      await tester.enterText(
          find.byKey(_key('firefly-payee-picker-search')), 'Garage');
      await settle(tester);
      expect(find.text('Bakery'), findsNothing);
      await tester.tap(find.byKey(_key('firefly-payee-picker-create')));
      await settle(tester);

      final created =
          (await io(() => db.fireflyPayees(search: 'Garage'))).single;
      expect(created.kind, PayeeKind.expense);
      expect(draft.payeePk, created.payeePk);
      expect(writes, 1);
    });
  });

  group('chip', () {
    widgetTest('shows the payee name and hides without one', (tester) async {
      final shop = await seed('Shop', PayeeKind.expense);
      await pump(
          tester,
          Scaffold(
              body: Column(children: [
            FireflyPayeeChip(payeePk: shop.payeePk, db: db),
            FireflyPayeeChip(payeePk: 'missing', db: db),
          ])));
      expect(find.text('Shop'), findsOneWidget);
      expect(find.byKey(_key('firefly-payee-chip-missing')), findsNothing);
    });
  });

  group('list page', () {
    widgetTest('filters, searches and creates', (tester) async {
      await seed('Shop', PayeeKind.expense);
      await seed('Employer', PayeeKind.revenue);
      await pump(tester, FireflyPayeesPage(db: db, onWrite: () => writes++));
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Employer'), findsOneWidget);

      await tester.tap(find.byKey(_key('firefly-payees-filter-revenue')));
      await settle(tester);
      expect(find.text('Shop'), findsNothing);
      await tester.tap(find.byKey(_key('firefly-payees-filter-null')));
      await tester.enterText(find.byKey(_key('firefly-payees-search')), 'sho');
      await settle(tester);
      expect(find.text('Employer'), findsNothing);
      expect(find.text('Shop'), findsOneWidget);

      await tester.tap(find.byKey(_key('firefly-payee-add')));
      await settle(tester);
      await tester.tap(find.byKey(_key('firefly-payee-save')));
      await settle(tester);
      expect(find.text('firefly-payees-name-required'), findsOneWidget);
      await tester.enterText(
          find.byKey(_key('firefly-payee-name')), 'Landlord');
      await tester.enterText(
          find.byKey(_key('firefly-payee-iban')), 'NL00 TEST 0000 0000 00');
      await tester.tap(find.byKey(_key('firefly-payee-save')));
      await settle(tester);

      final saved =
          (await io(() => db.fireflyPayees(search: 'Landlord'))).single;
      expect(saved.iban, 'NL00TEST0000000000');
      expect(writes, 1);
    });

    widgetTest('edit shows history and renames', (tester) async {
      final shop = await seed('Shop', PayeeKind.expense);
      final row = await seedTransaction('Groceries', shop);
      await pump(tester, FireflyPayeesPage(db: db, onWrite: () => writes++));
      await tester.tap(find.byKey(_key('firefly-payee-${shop.payeePk}')));
      await settle(tester);
      expect(find.byKey(_key('firefly-payee-transaction-${row.transactionPk}')),
          findsOneWidget);
      expect(find.text('-5.00'), findsOneWidget);

      await tester.enterText(find.byKey(_key('firefly-payee-name')), 'Market');
      await tester.tap(find.byKey(_key('firefly-payee-save')));
      await settle(tester);
      expect((await io(() => db.fireflyPayee(shop.payeePk)))!.name, 'Market');
      expect(writes, 1);
    });

    widgetTest('delete warns about the cascade and defaults to deactivate',
        (tester) async {
      final shop = await seed('Shop', PayeeKind.expense);
      await pump(tester, FireflyPayeesPage(db: db, onWrite: () => writes++));
      await tester.tap(find.byKey(_key('firefly-payee-${shop.payeePk}')));
      await settle(tester);
      await tester.tap(find.byKey(_key('firefly-payee-delete')));
      await settle(tester);
      expect(find.text('firefly-payees-delete-warning'), findsOneWidget);
      final deactivate = tester.widget<FilledButton>(
          find.byKey(_key('firefly-payee-delete-deactivate')));
      expect(deactivate.autofocus, isTrue);
      await tester.tap(find.byKey(_key('firefly-payee-delete-deactivate')));
      await settle(tester);
      expect((await io(() => db.fireflyPayee(shop.payeePk)))!.active, isFalse);
      expect(writes, 1);

      await tester.tap(find.byKey(_key('firefly-payee-${shop.payeePk}')));
      await settle(tester);
      await tester.tap(find.byKey(_key('firefly-payee-delete')));
      await settle(tester);
      await tester.tap(find.byKey(_key('firefly-payee-delete-confirm')));
      await settle(tester);
      expect(await io(() => db.fireflyPayee(shop.payeePk)), isNull);
      final pending = await io(() => IdMapRepository(db)
          .byLocal(FireflyEntityType.payeeAccount, shop.payeePk));
      expect(writes, 2);
      expect(find.text('firefly-payees-empty'), findsOneWidget);
      expect(pending == null || pending.localPk == shop.payeePk, isTrue);
    });
  });
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/budgets/budget_limits_page.dart';
import 'package:budget/firefly/ui/transaction/budget_section.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/struct/databaseGlobal.dart' as global;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/incomeExpenseTabSelector.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_database.dart';

class _FakeTokens extends TokenStore {
  _FakeTokens(this.token);

  final String? token;

  @override
  Future<String?> read() async => token;
}

Future<void> _setMode(bool on) async {
  appStateSettings['fireflyMode'] = on;
  await FireflyMode.init(() => appStateSettings,
      tokenStore: _FakeTokens(on ? 'REDACTED' : null));
}

/// Lets Drift queries, which run outside the fake clock, reach the tree.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Taps a control whose handler awaits Drift, outside the fake clock.
Future<void> _tapAsync(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await _settle(tester);
}

void main() {
  late FinanceDatabase db;

  Future<Budget> envelope(String name,
          {bool addedOnly = true, int order = 0}) =>
      db.into(db.budgets).insertReturning(BudgetsCompanion.insert(
            name: name,
            startDate: DateTime(2026, 11),
            endDate: DateTime(2026, 11, 30),
            amount: 100,
            reoccurrence: const Value(BudgetReoccurence.monthly),
            periodLength: 1,
            addedTransactionsOnly: Value(addedOnly),
            order: order,
          ));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appStateSettings = await getDefaultPreferences();
    db = inMemoryFinanceDatabase();
    global.database = db;
  });

  // Widget tests run in a fake zone, so Drift work goes through runAsync.
  Future<void> seed(WidgetTester tester) =>
      tester.runAsync(() => db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('0'),
          name: 'Default',
          currency: const Value('eur'),
          order: 0)));

  tearDown(() => _setMode(false));

  /// Unmounts, then closes the database outside the fake clock, where Drift
  /// can finish the queries the stream builders left behind.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await tester.runAsync(db.close);
  }

  group('budget picker', () {
    testWidgets('lists envelopes only and writes the draft', (tester) async {
      late FireflyTransactionDraft draft;
      await seed(tester);
      await tester.runAsync(() async {
        await envelope('Groceries');
        await envelope('Rent', order: 1);
        await envelope('Everything', addedOnly: false, order: 2);
      });
      draft = FireflyTransactionDraft(db);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) =>
                      fireflyBudgetSection(context, draft)))));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('firefly-budget-picker')));
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Everything'), findsNothing);

      await tester.tap(find.text('Rent').last);
      await tester.pumpAndSettle();
      final rent = await tester.runAsync(() => (db.select(db.budgets)
            ..where((row) => row.name.equals('Rent')))
          .getSingle());
      expect(draft.budgetPk, rent!.budgetPk);
      await unmount(tester);
    });
  });

  group('limit editor', () {
    late Budget budget;
    late int writes;

    Future<void> pumpPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: FireflyBudgetLimitsPage(
              budgetPk: budget.budgetPk,
              db: db,
              onLocalWrite: () => writes++)));
      await _settle(tester);
    }

    Future<List<BudgetLimit>> limits(WidgetTester tester) async =>
        (await tester.runAsync(() => db.fireflyBudgetLimits(budget.budgetPk)))!;

    Future<void> seedBudget(WidgetTester tester) async {
      writes = 0;
      await seed(tester);
      budget = (await tester.runAsync(() => envelope('Groceries')))!;
    }

    testWidgets('adds, edits and deletes limits per period', (tester) async {
      await seedBudget(tester);
      await tester.runAsync(() => ResourceCacheRepository(db)
              .write(FireflyEntityType.budget, 'available:7', {
            'start': '2026-11-01',
            'end': '2026-11-30',
            'amount': '1200.00',
            'currency_code': 'EUR',
          }));
      await pumpPage(tester);
      expect(find.text('firefly-budgets-limits-empty'), findsOneWidget);
      // Available budgets are shown read-only above the limits
      expect(find.byKey(const ValueKey('firefly-available-7')), findsOneWidget);
      expect(find.text('1200.00 EUR'), findsOneWidget);
      expect(find.text('firefly-budgets-available-readonly'), findsOneWidget);

      await _tapAsync(tester, find.byKey(const ValueKey('firefly-limit-add')));
      await tester.tap(find.byKey(const ValueKey('firefly-limit-save')));
      await tester.pumpAndSettle();
      expect(find.text('firefly-budgets-limit-invalid-amount'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-limit-amount')), '250');
      await _tapAsync(tester, find.byKey(const ValueKey('firefly-limit-save')));
      var rows = await limits(tester);
      expect(rows, hasLength(1));
      expect(rows.single.amount, 250);
      expect(rows.single.end.isBefore(rows.single.start), isFalse);
      expect(writes, 1);

      // A past period next to the current one
      await tester.runAsync(() => db.fireflySaveBudgetLimit(
          BudgetLimitsCompanion.insert(
              budgetFk: budget.budgetPk,
              start: DateTime(2020, 1),
              end: DateTime(2020, 1, 31),
              amount: 90,
              currency: 'usd')));
      await _settle(tester);
      expect(find.textContaining('2020-01-01'), findsOneWidget);

      final current = rows.single;
      await _tapAsync(tester,
          find.byKey(ValueKey('firefly-limit-${current.budgetLimitPk}')));
      await tester.enterText(
          find.byKey(const ValueKey('firefly-limit-amount')), '300');
      await _tapAsync(tester, find.byKey(const ValueKey('firefly-limit-save')));
      rows = await limits(tester);
      expect(rows, hasLength(2));
      expect(
          rows
              .firstWhere((r) => r.budgetLimitPk == current.budgetLimitPk)
              .amount,
          300);

      await _tapAsync(
          tester,
          find.byKey(
              ValueKey('firefly-limit-delete-${current.budgetLimitPk}')));
      rows = await limits(tester);
      expect(rows.map((r) => r.amount), [90]);
      expect(writes, 3);
      await unmount(tester);
    });
  });

  group('restricted budget form', () {
    test('only Firefly auto-budget periods are representable', () {
      expect(fireflyRepresentablePeriod(BudgetReoccurence.daily, 1), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.weekly, 1), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.monthly, 1), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.monthly, 3), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.monthly, 6), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.yearly, 1), isTrue);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.weekly, 2), isFalse);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.monthly, 2), isFalse);
      expect(fireflyRepresentablePeriod(BudgetReoccurence.custom, 1), isFalse);
    });

    Future<void> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Provider<AllWallets>.value(
        value: AllWallets(list: [], indexedByPk: {}),
        child: MaterialApp(
            home: AddBudgetPage(
                routesToPopAfterDelete: RoutesToPopAfterDelete.None)),
      ));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(seconds: 1));
    }

    for (final on in [false, true]) {
      testWidgets('Firefly mode ${on ? 'on' : 'off'}', (tester) async {
        await seed(tester);
        await tester.runAsync(() => _setMode(on));
        expect(FireflyMode.enabled, on);
        await pumpForm(tester);
        final legacy = on ? findsNothing : findsWidgets;
        expect(find.byType(IncomeExpenseTabSelector), legacy);
        expect(find.text('budget-type'), legacy);
        // The legacy page leaves Drift work queued in the fake zone, so the
        // in-memory database is left open instead of closed.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  });
}

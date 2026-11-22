import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/entities/currency_syncer.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/entry/foreign_amount_chip.dart';
import 'package:budget/firefly/ui/pages/currencies/currencies_page.dart';
import 'package:budget/firefly/ui/transaction/foreign_amount_section.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  late List<FireflyCachedCurrency> currencies;
  late Transaction foreignRow;
  late Transaction plainRow;

  Future<void> seedCurrency(String code,
      {bool enabled = true, bool primary = false}) {
    return ResourceCacheRepository(db).write(FireflyEntityType.currency, code, {
      'code': code,
      'name': code.toUpperCase(),
      'symbol': code == 'eur' ? '€' : r'$',
      'enabled': enabled,
      'primary': primary,
      'remote_id': code,
    });
  }

  Future<Transaction> transaction({double? foreign, String? currency}) =>
      db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
              name: 'Lunch',
              amount: -10,
              note: '',
              categoryFk: '0',
              foreignAmount: Value(foreign),
              foreignCurrency: Value(currency),
            ),
          );

  setUp(() async {
    db = inMemoryFinanceDatabase();
    await seedCurrency('usd', primary: true);
    await seedCurrency('eur');
    await seedCurrency('gbp', enabled: false);
    currencies = await db.fireflyCurrencies();
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Wallet', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Balance', order: 0));
    foreignRow = await transaction(foreign: -12.5, currency: 'eur');
    plainRow = await transaction();
  });

  tearDown(() => db.close());

  group('foreign amount section', () {
    Future<FireflyTransactionDraft> pump(WidgetTester tester,
        {double? amount, String? currency}) async {
      final draft = FireflyTransactionDraft(db)
        ..foreignAmount = amount
        ..foreignCurrency = currency;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: FireflyForeignAmountSection(
                  draft: draft, currencies: Stream.value(currencies)))));
      await tester.pumpAndSettle();
      return draft;
    }

    testWidgets('sets amount and currency together', (tester) async {
      final draft = await pump(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-foreign-amount-field')), '12,5');
      expect(draft.foreignAmount, isNull, reason: 'no currency yet');

      await tester
          .tap(find.byKey(const ValueKey('firefly-foreign-currency-field')));
      await tester.pumpAndSettle();
      expect(find.text('GBP'), findsNothing, reason: 'disabled currency');
      await tester.tap(find.text('EUR').last);
      await tester.pumpAndSettle();

      expect(draft.foreignAmount, 12.5);
      expect(draft.foreignCurrency, 'eur');
    });

    testWidgets('rejects invalid input and clears', (tester) async {
      final draft = await pump(tester, amount: 15, currency: 'eur');
      expect(find.text('15'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-foreign-amount-field')), '-3');
      await tester.pump();
      expect(find.text('firefly-foreign-amount-invalid'), findsOneWidget);
      expect(draft.foreignAmount, isNull);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-foreign-amount-field')), '4');
      expect(draft.foreignAmount, 4);

      await tester
          .tap(find.byKey(const ValueKey('firefly-foreign-amount-clear')));
      await tester.pumpAndSettle();
      expect(draft.foreignAmount, isNull);
      expect(draft.foreignCurrency, isNull);
    });
  });

  group('foreign amount chip', () {
    Future<void> pump(WidgetTester tester, Transaction row) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) =>
                        fireflyForeignAmountChip(context, row)))));

    testWidgets('shows the foreign amount', (tester) async {
      await pump(tester, foreignRow);
      expect(find.text('12.50 EUR'), findsOneWidget);
    });

    testWidgets('is empty without a foreign amount', (tester) async {
      await pump(tester, plainRow);
      expect(find.byKey(const ValueKey('firefly-foreign-amount-chip')),
          findsNothing);
    });
  });

  group('currencies page', () {
    late FakeFireflyTransport transport;
    late _RecordingSyncer syncer;
    late bool serverRates;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FireflyCurrenciesPage(
          db: db,
          currencies: Stream.value(currencies),
          syncer: syncer,
          syncContext: () async => SyncContext(
            db: db,
            api: FireflyApi(transport),
            config: const FireflyConfig(mode: true),
          ),
          serverRates: () => serverRates,
          setServerRates: (value) async => serverRates = value,
        ),
      ));
      await tester.pumpAndSettle();
    }

    setUp(() {
      transport = FakeFireflyTransport();
      syncer = _RecordingSyncer();
      serverRates = false;
    });

    testWidgets('lists currencies with the primary marked', (tester) async {
      await pump(tester);
      expect(
          find.byKey(const ValueKey('firefly-currency-eur')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('firefly-currency-gbp')), findsOneWidget);
      final primary = tester.widget<IconButton>(
          find.byKey(const ValueKey('firefly-currency-primary-usd')));
      expect(primary.onPressed, isNull);
      final primarySwitch = tester.widget<Switch>(
          find.byKey(const ValueKey('firefly-currency-enabled-usd')));
      expect(primarySwitch.onChanged, isNull);
    });

    testWidgets('enables, disables and sets primary on the server',
        (tester) async {
      await pump(tester);
      await tester
          .tap(find.byKey(const ValueKey('firefly-currency-enabled-gbp')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('firefly-currency-enabled-eur')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('firefly-currency-primary-eur')));
      await tester.pumpAndSettle();

      expect(syncer.calls, ['gbp enable', 'eur disable', 'eur primary']);
    });

    testWidgets('reports a failed action', (tester) async {
      syncer.fail = true;
      await pump(tester);
      await tester
          .tap(find.byKey(const ValueKey('firefly-currency-enabled-eur')));
      await tester.pumpAndSettle();
      expect(find.text('firefly-currencies-action-failed'), findsOneWidget);
    });

    testWidgets('toggles server exchange rates', (tester) async {
      await pump(tester);
      await tester
          .tap(find.byKey(const ValueKey('firefly-currencies-server-rates')));
      await tester.pumpAndSettle();
      expect(serverRates, isTrue);
    });
  });
}

class _RecordingSyncer extends CurrencySyncer {
  final calls = <String>[];
  bool fail = false;

  @override
  Future<void> setEnabled(SyncContext context, String code,
      {required bool enabled}) async {
    if (fail) throw StateError('offline');
    calls.add('$code ${enabled ? 'enable' : 'disable'}');
  }

  @override
  Future<void> setPrimary(SyncContext context, String code) async {
    if (fail) throw StateError('offline');
    calls.add('$code primary');
  }
}

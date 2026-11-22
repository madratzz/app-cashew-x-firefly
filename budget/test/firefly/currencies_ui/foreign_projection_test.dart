import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/foreign_currency_contributor.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  late SyncContext context;
  const contributor = ForeignCurrencyContributor();
  const group = FireflyTransaction(id: '1');

  Transaction row(FireflyTransactionType? type) => Transaction(
        transactionPk: 'local',
        name: 'Loan payment',
        amount: -10,
        note: '',
        categoryFk: '0',
        walletFk: '0',
        dateCreated: fixtureTime,
        income: false,
        paid: true,
        skipPaid: false,
        reconciled: false,
        fireflyType: type,
      );

  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    context = SyncContext(
      db: db,
      api: FireflyApi(FakeFireflyTransport()),
      config: const FireflyConfig(mode: true),
    );
  });

  for (final wire in ['withdrawal', 'deposit']) {
    final split = FireflyTransactionSplit({
      'type': wire,
      'amount': '10.00',
      'foreign_amount': '9.20',
      'foreign_currency_code': 'EUR',
    });

    test('$wire projected as a transfer pair carries no foreign amount',
        () async {
      final stale = row(FireflyTransactionType.transfer).copyWith(
          foreignAmount: const Value(9.2), foreignCurrency: const Value('eur'));
      for (final side in [stale, stale.copyWith(amount: 10, income: true)]) {
        final projected =
            await contributor.projectRemote(context, group, split, side);
        expect(projected.foreignAmount, isNull);
        expect(projected.foreignCurrency, isNull);
      }
    });

    test('ordinary $wire keeps its foreign amount', () async {
      final kind = FireflyTransactionType.values.byName(wire);
      final projected =
          await contributor.projectRemote(context, group, split, row(kind));
      expect(projected.foreignAmount, 9.2);
      expect(projected.foreignCurrency, 'eur');
    });
  }
}

import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/resources/accounts_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';

void main() {
  test('account CRUD keeps typed filters, pagination and writable fields',
      () async {
    final server = FakeFireflyTransport(maxPageSize: 1);
    final api = AccountsApi(server);
    final liability = await api.create({
      'name': 'Loan',
      'type': 'liability',
      'currency_code': 'EUR',
      'liability_type': 'loan',
      'liability_direction': 'debit',
      'interest': '3.25',
      'interest_period': 'yearly',
    });
    await api.create({'name': 'Asset', 'type': 'asset'});
    await api.create({'name': 'Expense', 'type': 'expense'});
    final listing =
        await api.list(type: 'liability', query: {'type': 'asset'}, limit: 3);
    expect(listing.total, 1);
    expect(listing.perPage, 1);
    expect(listing.totalPages, 1);
    expect(listing.items.single.id, liability.id);
    expect(listing.items.single.type, 'liability');
    expect(listing.items.single.liabilityType, 'loan');
    expect(listing.items.single.liabilityDirection, 'debit');
    expect(listing.items.single.interest, 3.25);
    expect(listing.items.single.interestPeriod, 'yearly');
    expect((await api.list(page: 2)).items.single.type, 'asset');

    final changed = await api.update(liability.id, {'name': 'Renamed loan'});
    expect(changed.name, 'Renamed loan');
    expect((await api.get(liability.id)).currencyCode, 'EUR');
    await api.delete(liability.id);
    await expectLater(api.get(liability.id), throwsA(isA<FireflyNotFound>()));
  });

  test('account response parses credit card and signed balance fields', () {
    final account =
        FireflyAccount.fromResource(fireflyResource('accounts', '1', {
      'account_role': 'ccAsset',
      'credit_card_type': 'monthlyFull',
      'monthly_payment_date': '2024-01-01T04:00:00+04:00',
      'current_balance': '-250.75',
      'opening_balance': '0.00',
      'virtual_balance': null,
      'primary_currency_code': 'EUR',
    }));
    expect(account.accountRole, 'ccAsset');
    expect(account.creditCardType, 'monthlyFull');
    expect(account.monthlyPaymentDate, fixtureTime.toLocal());
    expect(account.currentBalance, -250.75);
    expect(account.openingBalance, 0);
    expect(account.virtualBalance, isNull);
    expect(account.primaryCurrencyCode, 'EUR');
    expect(
      () => FireflyAccount.fromResource({'id': '1', 'attributes': []}),
      throwsA(isA<FireflyInvalidPayload>()),
    );
  });
}

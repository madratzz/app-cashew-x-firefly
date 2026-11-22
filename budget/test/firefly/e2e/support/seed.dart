import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';

/// Ids of the seeded data set on the server.
class E2eSeed {
  E2eSeed(this.accounts, this.categories, this.groups);

  /// Checking (USD), Savings (USD), Travel (EUR).
  final List<String> accounts;
  final List<String> categories;
  final List<String> groups;
  late String splitGroup;
}

const e2eTransactionCount = 500;

/// Fictional fixture data: 3 asset accounts in 2 currencies, 20 categories and
/// 500 transaction groups including transfers and one split.
Future<E2eSeed> seedPhase1(FireflyApi admin, DateTime today) async {
  final enabled = await admin.currencies.primary();
  if (enabled.code != 'EUR') {
    try {
      await admin.currencies.enable('EUR');
    } on FireflyException {
      // Already enabled on this server.
    }
  }
  final accounts = <String>[];
  for (final (name, currency) in [
    ('E2E Checking', 'USD'),
    ('E2E Savings', 'USD'),
    ('E2E Travel', 'EUR'),
  ]) {
    final account = await admin.accounts.create({
      'name': name,
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': currency,
    });
    accounts.add(account.id);
  }
  final categories = <String>[];
  for (var index = 0; index < 20; index++) {
    final name = index < 2
        ? 'E2E Food / Sub ${index + 1}'
        : 'E2E Category ${index.toString().padLeft(2, '0')}';
    categories.add((await admin.categories.create({'name': name})).id);
  }
  String date(int index) => formatFireflyDate(
      today.subtract(Duration(days: 1 + index % 80, hours: index % 7)));
  String amount(int index) =>
      ((index % 97) + 1 + (index * 7) % 100 / 100).toStringAsFixed(2);

  final groups = <String>[];
  late String split;
  for (var index = 0; index < e2eTransactionCount; index++) {
    final JsonObject body;
    if (index == 3) {
      body = {
        'group_title': 'E2E split groceries',
        'transactions': [
          for (final part in [0, 1])
            {
              'type': 'withdrawal',
              'date': date(index),
              'amount': amount(index + part),
              'description': 'E2E split part ${part + 1}',
              'source_id': accounts[0],
              'destination_name': 'E2E Market',
              'category_id': categories[part],
            },
        ],
      };
    } else if (index % 10 == 0) {
      body = {
        'transactions': [
          {
            'type': 'transfer',
            'date': date(index),
            'amount': amount(index),
            'description': 'E2E transfer $index',
            'source_id': accounts[index % 20 == 0 ? 0 : 1],
            'destination_id': accounts[index % 20 == 0 ? 1 : 0],
          },
        ],
      };
    } else {
      final deposit = index % 7 == 0;
      final account = accounts[index % 3];
      body = {
        'transactions': [
          {
            'type': deposit ? 'deposit' : 'withdrawal',
            'date': date(index),
            'amount': amount(index),
            'description': 'E2E ${deposit ? 'income' : 'expense'} $index',
            if (deposit) ...{
              'source_name': 'E2E Employer',
              'destination_id': account,
            } else ...{
              'source_id': account,
              'destination_name': 'E2E Shop ${index % 5}',
            },
            'category_id': categories[index % categories.length],
          },
        ],
      };
    }
    final group = await admin.transactions.create(
        {'error_if_duplicate_hash': false, 'apply_rules': false, ...body});
    groups.add(group.id);
    if (index == 3) split = group.id;
  }
  return E2eSeed(accounts, categories, groups)..splitGroup = split;
}

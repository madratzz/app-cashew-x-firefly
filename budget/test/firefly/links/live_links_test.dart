@Tags(['live'])
library;

import 'package:budget/database/tables.dart' show FireflyEntityType;
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/object_group_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_link_syncer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/e2e_harness.dart';

void main() {
  final target = E2eTarget.fromEnvironment();
  test('Firefly 6.6.2 round-trips journal links and object group membership',
      skip: target == null ? 'Disposable Firefly credentials are unset' : false,
      () async {
    final transport = target!.transport();
    addTearDown(transport.close);
    final api = FireflyApi(transport);
    expect((await api.about.get()).version, '6.6.2');
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final context = SyncContext(db: db, api: api, config: e2eConfig);
    const links = TransactionLinkSyncer();
    const groups = ObjectGroupSyncer();
    final now = DateTime.now();
    final prefix = 'WP41 ${now.microsecondsSinceEpoch} ';
    addTearDown(() => _retryNetwork(() => _cleanup(transport, prefix)));

    final asset = await _retryNetwork(() => api.accounts.create({
          'name': '${prefix}Asset',
          'type': 'asset',
          'account_role': 'defaultAsset',
          'currency_code': 'USD',
        }));
    final expense = await _retryNetwork(() => api.accounts.create({
          'name': '${prefix}Expense',
          'type': 'expense',
        }));

    final title = '${prefix}Group';
    final bill = await _retryNetwork(() => api.bills.create({
          'name': '${prefix}Bill',
          'currency_code': 'USD',
          'amount_min': '1.00',
          'amount_max': '2.00',
          'date': formatFireflyDate(now),
          'repeat_freq': 'monthly',
          'object_group_title': title,
        }));
    final bank = await _retryNetwork(() => api.piggyBanks.create({
          'name': '${prefix}Bank',
          'target_amount': '50.00',
          'transaction_currency_code': 'USD',
          'start_date': formatFireflyDate(now),
          'accounts': [
            {'account_id': asset.id, 'current_amount': '0.00'},
          ],
          'object_group_title': title,
        }));
    expect(
        (await api.bills.get(bill.id)).attributes['object_group_title'], title);
    expect((await api.piggyBanks.get(bank.id)).attributes['object_group_title'],
        title);
    await groups.pull(context);
    final group = (await db.watchFireflyObjectGroups().first)
        .singleWhere((group) => group.title == title);
    expect(bill.attributes['object_group_id'].toString(), group.id);
    expect(bank.attributes['object_group_id'].toString(), group.id);

    final journalIds = <String>[];
    for (final pk in ['inward', 'outward']) {
      final transaction = await _retryNetwork(() => api.transactions.create({
            'apply_rules': false,
            'fire_webhooks': false,
            'transactions': [
              {
                'type': 'withdrawal',
                'date': formatFireflyDateTime(now),
                'amount': '1.00',
                'description': '$prefix$pk',
                'source_id': asset.id,
                'destination_id': expense.id,
              },
            ],
          }));
      final journalId = transaction.splits.single.journalId!;
      journalIds.add(journalId);
      await context.idMap.put(fixtureMapping(
        type: FireflyEntityType.transaction,
        localPk: pk,
        remoteId: transaction.id,
        subId: journalId,
      ));
    }

    await links.pull(context);
    final type = (await db.watchFireflyLinkTypes().first).first;
    final link = await links.createLink(
      context,
      inwardTransactionPk: 'inward',
      outwardTransactionPk: 'outward',
      linkTypeId: type.id,
      notes: prefix.trim(),
    );
    final remote = await api.transactionLinks.get(link.id);
    expect(remote.inwardJournalId, journalIds[0]);
    expect(remote.outwardJournalId, journalIds[1]);
    expect(remote.notes, prefix.trim());
    await links.pull(context);
    expect(
        (await db.watchFireflyTransactionLinks().first)
            .any((item) => item.id == link.id),
        isTrue);

    await _retryNetwork(() => links.deleteLink(context, link.id));
    await expectLater(
        api.transactionLinks.get(link.id), throwsA(isA<FireflyNotFound>()));
    await links.pull(context);
    expect(
        (await db.watchFireflyTransactionLinks().first)
            .any((item) => item.id == link.id),
        isFalse);
  });
}

Future<T> _retryNetwork<T>(Future<T> Function() request) async {
  for (var attempt = 1;; attempt++) {
    try {
      return await request();
    } on FireflyValidation catch (error) {
      fail('Firefly rejected the live fixture: ${error.errors}');
    } on FireflyNetworkError {
      if (attempt == 3) rethrow;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
}

Future<void> _cleanup(FireflyTransport transport, String prefix) async {
  final collections = {
    '/transaction-links': 'notes',
    '/transactions': 'transactions',
    '/piggy-banks': 'name',
    '/bills': 'name',
    '/object-groups': 'title',
    '/accounts': 'name',
  };
  for (final entry in collections.entries) {
    final ids = <String>{};
    for (var page = 1;; page++) {
      final result = await transport.getPage(entry.key, query: {
        'page': '$page',
        'limit': '100',
        if (entry.key == '/accounts' || entry.key == '/transactions')
          'type': 'all',
      });
      for (final item in result.items) {
        final attributes = item['attributes']! as JsonObject;
        final value = attributes[entry.value];
        final belongsToRun = switch (value) {
          String() => value == prefix.trim() || value.startsWith(prefix),
          List() => value.any((split) =>
              split is JsonObject &&
              (split['description'] as String?)?.startsWith(prefix) == true),
          _ => false,
        };
        if (belongsToRun) ids.add(item['id'].toString());
      }
      if (page >= result.totalPages) break;
    }
    for (final id in ids) {
      try {
        await transport.delete('${entry.key}/${Uri.encodeComponent(id)}');
      } on FireflyNotFound {
        // A prior request or deletion of a parent already removed the fixture.
      }
    }
  }
}

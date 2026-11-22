import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';
import 'seed.dart';

const _wallet = FireflyEntityType.walletAccount;
const _category = FireflyEntityType.category;
const _transaction = FireflyEntityType.transaction;

/// The Phase 1 acceptance flow (PLAN.md WP-19 items 2 to 6). Tests share one
/// server and one device and run in order.
void definePhase1Suite(Future<E2eTarget?> Function(E2eClock clock) open,
    {required bool live}) {
  final clock = E2eClock(live: live);
  E2eTarget? target;
  E2eServerSnapshot? snapshot;
  late E2eDevice device;
  late E2eSeed seed;

  setUpAll(() async {
    target = await open(clock);
    if (target == null) return;
    if (live) snapshot = await E2eServerSnapshot.take(target!);
    device = E2eDevice(target!, clock);
    final existing = await device.admin.transactions.list(limit: 1);
    if (existing.total > 0) {
      throw StateError('The E2E server must start empty. Use a fresh '
          'disposable instance from docker/firefly.');
    }
    seed = await seedPhase1(device.admin, clock.now());
  });

  tearDownAll(() async {
    if (target == null) return;
    await snapshot?.restore();
    await device.close();
    await target!.close();
  });

  bool skip() {
    if (target != null) return false;
    markTestSkipped('FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN are not set');
    return true;
  }

  Future<void> expectBalancesMatch() async {
    for (final id in seed.accounts) {
      final pk = (await device.localPk(_wallet, id))!;
      final local =
          await device.db.watchTotalOfWalletNoConversion(pk).first ?? 0;
      final remote = parseFireflyAmount(
          '${(await device.admin.accounts.get(id)).attributes['current_balance']}');
      expect(local, closeTo(remote, 0.005), reason: 'account $id');
    }
  }

  test('initial import matches the server', () async {
    if (skip()) return;
    final cycle = await device.sync();
    expect(cycle.report.issues.map((issue) => issue.message), isEmpty);
    expect(cycle.report.succeeded, isTrue);
    expect(cycle.report.balanceMismatches, isEmpty);
    for (final id in seed.accounts) {
      expect(await device.localPk(_wallet, id), isNotNull);
    }
    for (final id in seed.categories) {
      expect(await device.localPk(_category, id), isNotNull);
    }
    final mapped = await device.context.idMap.list(_transaction);
    expect({for (final mapping in mapped) mapping.remoteId},
        containsAll(seed.groups));
    final split = await device.context.idMap
        .forRemoteGroup(_transaction, seed.splitGroup);
    expect(split.map((mapping) => mapping.remoteSubId).toSet(), hasLength(2));
    await expectBalancesMatch();
  });

  test('a second sync with no changes sends no write request', () async {
    if (skip()) return;
    await clock.tick();
    final cycle = await device.sync();
    expect(cycle.report.succeeded, isTrue);
    expect(cycle.writes, isEmpty);
  });

  test('local create, edit and delete reach the server', () async {
    if (skip()) return;
    await clock.tick();
    final checking = (await device.localPk(_wallet, seed.accounts[0]))!;
    final savings = (await device.localPk(_wallet, seed.accounts[1]))!;
    final wallet = await device.addWallet('E2E Local wallet', 'USD');
    final category = await device.addCategory('E2E Local category');
    final withdrawal = await device.addTransaction(
        name: 'E2E local withdrawal',
        amount: -12.5,
        walletPk: checking,
        categoryPk: category);
    final deposit = await device.addTransaction(
        name: 'E2E local deposit',
        amount: 40,
        walletPk: checking,
        categoryPk: category);
    final (transferOut, _) =
        await device.addTransfer(checking, savings, 15, 'E2E local transfer');
    expect((await device.sync()).report.succeeded, isTrue);

    final walletId = (await device.remoteId(_wallet, wallet))!;
    final categoryId = (await device.remoteId(_category, category))!;
    final withdrawalId = (await device.remoteId(_transaction, withdrawal))!;
    final depositId = (await device.remoteId(_transaction, deposit))!;
    final transferId = (await device.remoteId(_transaction, transferOut))!;
    expect(
        (await device.admin.accounts.get(walletId)).name, 'E2E Local wallet');
    expect((await device.admin.categories.get(categoryId)).name,
        'E2E Local category');
    final pushedWithdrawal =
        (await device.admin.transactions.get(withdrawalId)).splits.single;
    expect(pushedWithdrawal.type, 'withdrawal');
    expect(parseFireflyAmount('${pushedWithdrawal.fields['amount']}'), 12.5);
    expect((await device.admin.transactions.get(depositId)).splits.single.type,
        'deposit');
    final transfer =
        (await device.admin.transactions.get(transferId)).splits.single;
    expect(transfer.type, 'transfer');
    expect(transfer.sourceId, seed.accounts[0]);
    expect(transfer.destinationId, seed.accounts[1]);

    await clock.tick();
    await device.renameWallet(wallet, 'E2E Local wallet edited');
    await device.renameCategory(category, 'E2E Local category edited');
    await device.editTransaction(withdrawal, amount: -13.75);
    await device.editTransaction(deposit, name: 'E2E local deposit edited');
    await device.editTransaction(transferOut, amount: -16);
    expect((await device.sync()).report.succeeded, isTrue);
    // DBG
    print('DBG map ${await device.context.idMap.byLocal(_wallet, wallet)}');
    print('DBG row ${await (device.db.select(device.db.wallets)..where((r) => r.walletPk.equals(wallet))).getSingle()}');
    print('DBG remote ${(await device.admin.accounts.get(walletId)).attributes}');
    print('DBG conflicts ${await device.db.select(device.db.fireflyConflicts).get()}');
    expect((await device.admin.accounts.get(walletId)).name,
        'E2E Local wallet edited');
    expect((await device.admin.categories.get(categoryId)).name,
        'E2E Local category edited');
    expect(
        parseFireflyAmount(
            '${(await device.admin.transactions.get(withdrawalId)).splits.single.fields['amount']}'),
        13.75);
    expect(
        (await device.admin.transactions.get(depositId))
            .splits
            .single
            .fields['description'],
        'E2E local deposit edited');
    expect(
        parseFireflyAmount(
            '${(await device.admin.transactions.get(transferId)).splits.single.fields['amount']}'),
        16);

    await clock.tick();
    await device.deleteTransaction(withdrawal);
    await device.deleteTransaction(deposit);
    final transferIn =
        (await device.db.fireflyTransaction(transferOut))!.pairedTransactionFk!;
    await device.deleteTransaction(transferOut);
    await device.deleteTransaction(transferIn);
    await device.deleteCategory(category);
    await device.db.deleteWalletLocally(wallet);
    final deleteCycle = await device.sync();
    expect(deleteCycle.report.succeeded, isTrue);
    final deleted = {
      'withdrawal': () => device.admin.transactions.get(withdrawalId),
      'deposit': () => device.admin.transactions.get(depositId),
      'transfer': () => device.admin.transactions.get(transferId),
      'category': () => device.admin.categories.get(categoryId),
      'wallet': () => device.admin.accounts.get(walletId),
    };
    for (final entry in deleted.entries) {
      await expectLater(entry.value(), throwsA(isA<FireflyNotFound>()),
          reason: entry.key);
    }
    await expectBalancesMatch();
  });

  test('server create, edit and delete reach the device', () async {
    if (skip()) return;
    await clock.tick();
    final admin = device.admin;
    final account = await admin.accounts.create({
      'name': 'E2E Server wallet',
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
    });
    final category =
        await admin.categories.create({'name': 'E2E Server category'});
    JsonObject split(String type, String amount, String description) => {
          'type': type,
          'date': formatFireflyDate(clock.now()),
          'amount': amount,
          'description': description,
          if (type == 'withdrawal') ...{
            'source_id': account.id,
            'destination_name': 'E2E Shop',
          },
          if (type == 'deposit') ...{
            'source_name': 'E2E Employer',
            'destination_id': account.id,
          },
          if (type == 'transfer') ...{
            'source_id': account.id,
            'destination_id': seed.accounts[0],
          },
          if (type != 'transfer') 'category_id': category.id,
        };
    final created = <String, String>{};
    for (final type in ['withdrawal', 'deposit', 'transfer']) {
      created[type] = (await admin.transactions.create({
        'error_if_duplicate_hash': false,
        'apply_rules': false,
        'transactions': [split(type, '21.00', 'E2E server $type')],
      }))
          .id;
    }
    expect((await device.sync()).report.succeeded, isTrue);
    final walletPk = (await device.localPk(_wallet, account.id))!;
    expect(
        (await device.db.fireflyWallet(walletPk))!.name, 'E2E Server wallet');
    final categoryPk = (await device.localPk(_category, category.id))!;
    for (final entry in created.entries) {
      final rows =
          await device.context.idMap.forRemoteGroup(_transaction, entry.value);
      expect(rows, isNotEmpty, reason: entry.key);
      final row = (await device.db.fireflyTransaction(rows.first.localPk))!;
      expect(row.amount.abs(), 21, reason: entry.key);
      if (entry.key != 'transfer') expect(row.categoryFk, categoryPk);
    }

    await clock.tick();
    await admin.accounts
        .update(account.id, {'name': 'E2E Server wallet edited'});
    await admin.categories
        .update(category.id, {'name': 'E2E Server category edited'});
    for (final entry in created.entries) {
      final group = await admin.transactions.get(entry.value);
      await admin.transactions.update(entry.value, {
        'apply_rules': false,
        'transactions': [
          {
            'transaction_journal_id': group.splits.single.journalId,
            'amount': '22.00',
            'description': 'E2E server ${entry.key} edited',
          },
        ],
      });
    }
    expect((await device.sync()).report.succeeded, isTrue);
    expect((await device.db.fireflyWallet(walletPk))!.name,
        'E2E Server wallet edited');
    expect((await device.db.getCategoryInstance(categoryPk)).name,
        'E2E Server category edited');
    for (final entry in created.entries) {
      final rows =
          await device.context.idMap.forRemoteGroup(_transaction, entry.value);
      for (final mapping in rows) {
        final row = (await device.db.fireflyTransaction(mapping.localPk))!;
        expect(row.amount.abs(), 22, reason: entry.key);
        expect(row.name, 'E2E server ${entry.key} edited');
      }
    }

    await clock.tick();
    final localTransactions = [
      for (final id in created.values)
        for (final mapping
            in await device.context.idMap.forRemoteGroup(_transaction, id))
          mapping.localPk,
    ];
    for (final id in created.values) {
      await admin.transactions.delete(id);
    }
    await admin.categories.delete(category.id);
    await admin.accounts.delete(account.id);
    expect((await device.sync()).report.succeeded, isTrue);
    for (final pk in localTransactions) {
      expect(await device.db.fireflyTransaction(pk), isNull);
    }
    expect(await device.db.fireflyWallet(walletPk), isNull);
    expect(await device.localPk(_category, category.id), isNull);
    await expectBalancesMatch();
  });

  test('an edit on both sides keeps the server version and logs the local one',
      () async {
    if (skip()) return;
    await clock.tick();
    final groupId = seed.groups[1];
    final mapping =
        (await device.context.idMap.forRemoteGroup(_transaction, groupId))
            .single;
    await device.editTransaction(mapping.localPk, name: 'E2E local side');
    final group = await device.admin.transactions.get(groupId);
    await device.admin.transactions.update(groupId, {
      'apply_rules': false,
      'transactions': [
        {
          'transaction_journal_id': group.splits.single.journalId,
          'description': 'E2E server side',
        },
      ],
    });
    expect((await device.sync()).report.succeeded, isTrue);
    expect((await device.db.fireflyTransaction(mapping.localPk))!.name,
        'E2E server side');
    expect(
        (await device.admin.transactions.get(groupId))
            .splits
            .single
            .fields['description'],
        'E2E server side');
    final conflicts = await device.context.conflicts.list();
    final conflict =
        conflicts.singleWhere((row) => row.localPk == mapping.localPk);
    expect(conflict.entityType, _transaction);
    expect(conflict.localJson, contains('E2E local side'));
  });

  test('ten offline edits are pushed exactly once after reconnecting',
      () async {
    if (skip()) return;
    await clock.tick();
    device.transport.offline = true;
    final edited = <String, String>{};
    for (final groupId in seed.groups
        .skip(100)
        .where((id) => id != seed.splitGroup)
        .take(10)) {
      final mapping =
          (await device.context.idMap.forRemoteGroup(_transaction, groupId))
              .first;
      await device.editTransaction(mapping.localPk,
          note: 'E2E offline edit $groupId');
      edited[groupId] = mapping.localPk;
    }
    final offline = await device.sync();
    expect(offline.report.succeeded, isFalse);
    expect(offline.writes, isEmpty);

    device.transport.offline = false;
    await clock.tick();
    final online = await device.sync();
    expect(online.report.succeeded, isTrue);
    expect(online.writes, hasLength(10));
    expect(online.writes.every((write) => write.method == 'PUT'), isTrue);
    expect(online.writes.map((write) => write.path).toSet(),
        {for (final id in edited.keys) '/transactions/$id'});
    for (final id in edited.keys) {
      expect(
          (await device.admin.transactions.get(id))
              .splits
              .first
              .fields['notes'],
          'E2E offline edit $id');
    }
    await clock.tick();
    expect((await device.sync()).writes, isEmpty);
  });
}

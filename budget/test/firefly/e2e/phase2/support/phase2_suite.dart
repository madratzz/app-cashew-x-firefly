import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/entities/piggy_bank_syncer.dart';
import 'package:budget/firefly/sync/entities/recurrence_syncer.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/e2e_harness.dart';

const _wallet = FireflyEntityType.walletAccount;
const _category = FireflyEntityType.category;
const _transaction = FireflyEntityType.transaction;
const _budget = FireflyEntityType.budget;
const _piggyBank = FireflyEntityType.piggyBank;
const _bill = FireflyEntityType.bill;
const _recurrence = FireflyEntityType.recurrence;

/// The Phase 2 acceptance flow (PLAN.md WP-29). Tests share one server and
/// one device and run in order.
void definePhase2Suite(Future<E2eTarget?> Function(E2eClock clock) open,
    {required bool live}) {
  final clock = E2eClock(live: live);
  E2eTarget? target;
  E2eServerSnapshot? snapshot;
  late E2eDevice device;
  late String checkingId;
  late String shopId;
  late String categoryId;

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
    final admin = device.admin;
    checkingId = (await admin.accounts.create({
      'name': 'E2E2 Checking',
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
      'opening_balance': '1000.00',
      'opening_balance_date': formatFireflyDate(clock.now()),
    }))
        .id;
    shopId = (await admin.accounts.create({
      'name': 'E2E2 Shop',
      'type': 'expense',
    }))
        .id;
    categoryId = (await admin.categories.create({'name': 'E2E2 Food'})).id;
    await admin.transactions.create({
      'transactions': [
        {
          'type': 'withdrawal',
          'date': formatFireflyDateTime(clock.now()),
          'amount': '5.00',
          'description': 'E2E2 seed withdrawal',
          'source_id': checkingId,
          'destination_id': shopId,
          'category_id': categoryId,
        },
      ],
    });
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

  Future<List<E2eWrite>> sync() async {
    final cycle = await device.sync();
    expect(cycle.report.issues.map((issue) => issue.message), isEmpty);
    expect(cycle.report.succeeded, isTrue);
    return cycle.writes;
  }

  int fullListings() =>
      target!.emulator?.requests
          .where((request) =>
              request.method == 'GET' &&
              request.path == '/transactions' &&
              !request.query.containsKey('start'))
          .length ??
      0;

  Future<Transaction> localSplit(String groupId) async {
    final mapping =
        (await device.context.idMap.forRemoteGroup(_transaction, groupId))
            .single;
    return (await device.db.fireflyTransaction(mapping.localPk))!;
  }

  Future<String> localWithdrawal(String name, double amount) async {
    final checking = (await device.localPk(_wallet, checkingId))!;
    final category = (await device.localPk(_category, categoryId))!;
    return device.addTransaction(
        name: name, amount: -amount, walletPk: checking, categoryPk: category);
  }

  test('a contributor version change re-pulls transactions exactly once',
      () async {
    if (skip()) return;
    await sync();
    expect(await device.localPk(_wallet, checkingId), isNotNull);
    final meta = device.context.meta;
    // A Phase 1 install stored the stub contributor versions.
    for (final contributor in transactionContributors) {
      await meta.write(
          SyncMetaRepository.contributorVersion(contributor.id), '0');
    }
    final lastFull = await meta.readDate(SyncMetaRepository.lastFullReconcile);

    await clock.tick();
    final before = fullListings();
    expect(await sync(), isEmpty);
    final afterUpgrade =
        await meta.readDate(SyncMetaRepository.lastFullReconcile);
    expect(afterUpgrade, isNot(lastFull), reason: 'full pull ran');
    if (!live) expect(fullListings() - before, 1);
    for (final contributor in transactionContributors) {
      expect(
          await meta
              .read(SyncMetaRepository.contributorVersion(contributor.id)),
          '${contributor.version}');
    }

    await clock.tick();
    final again = fullListings();
    expect(await sync(), isEmpty);
    expect(await meta.readDate(SyncMetaRepository.lastFullReconcile),
        afterUpgrade);
    if (!live) expect(fullListings(), again);
  });

  test('budgets with limits and assignments sync in both directions', () async {
    if (skip()) return;
    await clock.tick();
    final now = clock.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // Local budget with a limit and an assigned withdrawal.
    final local = await device.db
        .into(device.db.budgets)
        .insertReturning(BudgetsCompanion.insert(
          name: 'E2E2 Local budget',
          startDate: monthStart,
          endDate: monthEnd,
          amount: 200,
          reoccurrence: const Value(BudgetReoccurence.monthly),
          periodLength: 1,
          order: 50,
          addedTransactionsOnly: const Value(true),
          dateTimeModified: Value(now),
        ));
    await device.db.fireflySaveBudgetLimit(BudgetLimitsCompanion.insert(
      budgetFk: local.budgetPk,
      start: monthStart,
      end: monthEnd,
      amount: 150,
      currency: 'usd',
    ));
    final withdrawal = await localWithdrawal('E2E2 budgeted', 20);
    await (device.db.update(device.db.transactions)
          ..where((row) => row.transactionPk.equals(withdrawal)))
        .write(TransactionsCompanion(
            sharedReferenceBudgetPk: Value(local.budgetPk),
            dateTimeModified: Value(clock.now())));
    await sync();

    final budgetId = (await device.remoteId(_budget, local.budgetPk))!;
    expect(
        (await device.admin.budgets.get(budgetId)).name, 'E2E2 Local budget');
    final limits = (await device.admin.budgets.listLimits(budgetId)).items;
    expect(limits.map((limit) => limit.amount), [150]);
    final groupId = (await device.remoteId(_transaction, withdrawal))!;
    expect(
        (await device.admin.transactions.get(groupId)).splits.single.budgetId,
        budgetId);

    // Server budget with a limit and an assigned withdrawal.
    await clock.tick();
    final remote = await device.admin.budgets
        .create({'name': 'E2E2 Server budget', 'active': true});
    final remoteLimit = await device.admin.budgets.createLimit(remote.id, {
      'start': formatFireflyDate(monthStart),
      'end': formatFireflyDate(monthEnd),
      'amount': '60.00',
      'currency_code': 'USD',
    });
    final assigned = await device.admin.transactions.create({
      'transactions': [
        {
          'type': 'withdrawal',
          'date': formatFireflyDateTime(clock.now()),
          'amount': '7.00',
          'description': 'E2E2 server budgeted',
          'source_id': checkingId,
          'destination_id': shopId,
          'budget_id': remote.id,
        },
      ],
    });
    await clock.tick();
    await sync();
    final remotePk = (await device.localPk(_budget, remote.id))!;
    expect(
        (await device.db.fireflyBudget(remotePk))!.name, 'E2E2 Server budget');
    expect(remoteLimit.amount, 60);
    final pulled = await device.db.fireflyBudgetLimits(remotePk);
    expect(pulled.map((limit) => limit.amount), [60]);
    expect((await localSplit(assigned.id)).sharedReferenceBudgetPk, remotePk);

    await clock.tick();
    expect(await sync(), isEmpty);
  });

  test('piggy bank money added on both sides reaches the other', () async {
    if (skip()) return;
    await clock.tick();
    final bank = await device.admin.piggyBanks.create({
      'name': 'E2E2 Holiday',
      'target_amount': '500.00',
      'start_date': formatFireflyDate(clock.now()),
      'transaction_currency_code': 'USD',
      'accounts': [
        {'account_id': checkingId, 'current_amount': '10.00'},
      ],
    });
    await sync();
    final pk = (await device.localPk(_piggyBank, bank.id))!;
    expect(await device.db.fireflyPiggyBankCurrentAmount(pk), 10);

    // Money added on the device.
    await clock.tick();
    await setFireflyPiggyBankAmount(device.context, pk, 35);
    expect((await device.admin.piggyBanks.get(bank.id)).currentAmount, 35);

    // Money added on the server.
    await clock.tick();
    await device.admin.piggyBanks.update(bank.id, {
      'accounts': [
        {'account_id': checkingId, 'current_amount': '50.00'},
      ],
    });
    await clock.tick();
    await sync();
    expect(await device.db.fireflyPiggyBankCurrentAmount(pk), 50);
    final events = await device.db.fireflyPiggyBankEvents(pk);
    expect(events.map((event) => event.amount), containsAll([25, 15]));

    await clock.tick();
    expect(await sync(), isEmpty);
  });

  test('bills are linked to transactions in both directions', () async {
    if (skip()) return;
    await clock.tick();
    final bill = await device.admin.bills.create({
      'name': 'E2E2 Internet',
      'amount_min': '30.00',
      'amount_max': '40.00',
      'currency_code': 'USD',
      'date': formatFireflyDate(clock.now()),
      'repeat_freq': 'monthly',
      'skip': 0,
      'active': true,
    });
    await sync();
    final billPk = (await device.localPk(_bill, bill.id))!;
    expect(await device.db.fireflyBill(billPk), isNotNull);

    // Linked on the device.
    await clock.tick();
    final local = await localWithdrawal('E2E2 internet local', 35);
    await (device.db.update(device.db.transactions)
          ..where((row) => row.transactionPk.equals(local)))
        .write(TransactionsCompanion(
            billFk: Value(billPk), dateTimeModified: Value(clock.now())));
    await sync();
    final localGroup = (await device.remoteId(_transaction, local))!;
    final pushed =
        (await device.admin.transactions.get(localGroup)).splits.single;
    expect(pushed.subscriptionId ?? pushed.billId, bill.id);

    // Linked on the server.
    await clock.tick();
    final remote = await device.admin.transactions.create({
      'transactions': [
        {
          'type': 'withdrawal',
          'date': formatFireflyDateTime(clock.now()),
          'amount': '32.00',
          'description': 'E2E2 internet server',
          'source_id': checkingId,
          'destination_id': shopId,
          'bill_id': bill.id,
        },
      ],
    });
    await clock.tick();
    await sync();
    expect((await localSplit(remote.id)).billFk, billPk);

    await clock.tick();
    expect(await sync(), isEmpty);
  });

  late String recurrencePk;
  late String recurrenceId;

  test('a triggered recurrence imports its transaction once', () async {
    if (skip()) return;
    await clock.tick();
    final first = clock.now().add(const Duration(days: 1));
    final recurrence = await device.admin.recurrences.create({
      'type': 'withdrawal',
      'title': 'E2E2 Rent',
      'first_date': formatFireflyDate(first),
      'repeat_until': null,
      'apply_rules': false,
      'active': true,
      'repetitions': [
        {'type': 'weekly', 'moment': '7', 'skip': 0, 'weekend': 1},
      ],
      'transactions': [
        {
          'description': 'E2E2 Rent',
          'amount': '9.00',
          'currency_code': 'USD',
          'source_id': checkingId,
          'destination_id': shopId,
        },
      ],
    });
    recurrenceId = recurrence.id;
    await sync();
    recurrencePk = (await device.localPk(_recurrence, recurrence.id))!;
    expect(await device.db.fireflyRecurrence(recurrencePk), isNotNull);

    await clock.tick();
    final created = await const RecurrenceSyncer()
        .trigger(device.context, recurrencePk, date: first);
    expect(created, isNotNull);
    final row = await localSplit(created!.id);
    expect(row.name, 'E2E2 Rent');
    expect(row.amount, closeTo(-9, 0.005));

    await clock.tick();
    expect(await sync(), isEmpty);
    final rows = await (device.db.select(device.db.transactions)
          ..where((row) => row.name.equals('E2E2 Rent')))
        .get();
    expect(rows, hasLength(1), reason: 'no local auto-created duplicate');
  });

  test('a rejected repetition moment is kept and reported, not dropped',
      () async {
    if (skip()) return;
    await clock.tick();
    final cached = (await device.db.fireflyRecurrence(recurrencePk))!;
    final repetitions = [
      for (final repetition
          in ResourceCacheRepository.decode(cached)['repetitions'] as List)
        {...(repetition as JsonObject), 'moment': '3'},
    ];
    await device.db
        .saveFireflyRecurrence({'repetitions': repetitions}, pk: recurrencePk);

    final cycle = await device.sync();
    final mapping =
        (await device.context.idMap.byLocal(_recurrence, recurrencePk))!;
    final remoteMoment = (await device.admin.recurrences.get(recurrenceId))
        .attributes['repetitions'] as List;
    if (mapping.state == FireflySyncState.error) {
      // Firefly 6.6.2 UpdateRequest rejects moments 0 to 10 on PUT. The
      // error is stored for the editor and the local edit stays in place.
      expect(mapping.lastError, contains('moment'));
      expect(cycle.writes.where((write) => write.method == 'PUT'), isNotEmpty);
      final kept = ResourceCacheRepository.decode(
          (await device.db.fireflyRecurrence(recurrencePk))!);
      expect((kept['repetitions'] as List).first['moment'], '3');
      expect((remoteMoment.first as JsonObject)['moment'], '7');
    } else {
      expect(live, isTrue, reason: 'the emulator models the rejection');
      expect('${(remoteMoment.first as JsonObject)['moment']}', '3');
    }
  });
}

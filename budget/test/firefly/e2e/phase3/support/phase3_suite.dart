import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/e2e_harness.dart';

const _wallet = FireflyEntityType.walletAccount;
const _liability = FireflyEntityType.liabilityAccount;
const _category = FireflyEntityType.category;
const _transaction = FireflyEntityType.transaction;
const _budget = FireflyEntityType.budget;
const _bill = FireflyEntityType.bill;
const _payee = FireflyEntityType.payeeAccount;

/// The Phase 3 acceptance flow (PLAN.md WP-39). Tests share one server and
/// two devices and run in order. Every object carries a per-run suffix and
/// is deleted at the end, so the suite also runs on a server that keeps data.
void definePhase3Suite(Future<E2eTarget?> Function(E2eClock clock) open,
    {required bool live}) {
  final clock = E2eClock(live: live);
  final run = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  String named(String name) => 'E2E3 $name $run';
  E2eTarget? target;
  late E2eDevice device;
  late E2eDevice second;
  late Directory support;
  late String checkingId;
  late String loanId;
  late String categoryId;
  late String budgetId;
  late String billId;
  String? richGroupId;
  final cleanup = <Future<void> Function()>[];

  setUpAll(() async {
    target = await open(clock);
    if (target == null) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    // The binding fakes every HttpClient; the suite needs real loopback.
    HttpOverrides.global = null;
    support = await Directory.systemTemp.createTemp('firefly-e2e3-');
    // Attachment drafts and the syncer store files through path_provider.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => support.path);
    device = E2eDevice(target!, clock);
    second = E2eDevice(target!, clock);
    final admin = device.admin;
    checkingId = (await admin.accounts.create({
      'name': named('Checking'),
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
      'opening_balance': '1000.00',
      'opening_balance_date': formatFireflyDate(clock.now()),
    }))
        .id;
    cleanup.add(() => admin.accounts.delete(checkingId));
    loanId = (await admin.accounts.create({
      'name': named('Loan'),
      'type': 'liabilities',
      'liability_type': 'loan',
      'liability_direction': 'credit',
      'currency_code': 'USD',
      'opening_balance': '500.00',
      'opening_balance_date': formatFireflyDate(clock.now()),
      'interest': '5',
      'interest_period': 'yearly',
    }))
        .id;
    cleanup.add(() => admin.accounts.delete(loanId));
    categoryId = (await admin.categories.create({'name': named('Food')})).id;
    cleanup.add(() => admin.categories.delete(categoryId));
    budgetId = (await admin.budgets.create({'name': named('Groceries')})).id;
    cleanup.add(() => admin.budgets.delete(budgetId));
    billId = (await admin.bills.create({
      'name': named('Market'),
      'amount_min': '1.00',
      'amount_max': '50.00',
      'date': formatFireflyDate(clock.now()),
      'repeat_freq': 'monthly',
      'currency_code': 'USD',
    }))
        .id;
    cleanup.add(() => admin.bills.delete(billId));
  });

  tearDownAll(() async {
    if (target == null) return;
    for (final step in cleanup.reversed) {
      try {
        await step();
      } on FireflyNotFound {
        // Already gone, for example through an account cascade.
      }
    }
    await device.close();
    await second.close();
    await target!.close();
    await support.delete(recursive: true);
  });

  bool skip() {
    if (target != null) return false;
    markTestSkipped('FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN are not set');
    return true;
  }

  Future<List<E2eWrite>> sync([E2eDevice? on]) async {
    final cycle = await (on ?? device).sync();
    expect(cycle.report.issues.map((issue) => issue.message), isEmpty);
    expect(cycle.report.succeeded, isTrue);
    return cycle.writes;
  }

  Future<String> localWithdrawal(String name, double amount) async {
    final checking = (await device.localPk(_wallet, checkingId))!;
    final category = (await device.localPk(_category, categoryId))!;
    return device.addTransaction(
        name: name, amount: -amount, walletPk: checking, categoryPk: category);
  }

  Future<FireflySplitView> remoteSplit(String localPk) async {
    final mapping =
        (await device.context.idMap.byLocal(_transaction, localPk))!;
    final group = await device.admin.transactions.get(mapping.remoteId);
    final split = group.splits
        .firstWhere((split) => split.journalId == mapping.remoteSubId);
    return (group: group, split: split, groupId: mapping.remoteId);
  }

  test(
      'a transaction with payee, tags, foreign amount, budget, bill and '
      'attachment reaches the server and a second device', () async {
    if (skip()) return;
    await sync();
    expect(await device.localPk(_budget, budgetId), isNotNull);
    expect(await device.localPk(_bill, billId), isNotNull);

    final db = device.db;
    final payee = await db.fireflyCreatePayee(
        name: named('Corner shop'), kind: PayeeKind.expense);
    final fresh = await db.saveFireflyTag(name: named('fresh'));
    final weekly = await db.saveFireflyTag(name: named('weekly'));
    final pk = await localWithdrawal(named('Groceries'), 12.5);
    final draft = FireflyTransactionDraft(db);
    await draft.load(pk);
    draft
      ..payeePk = payee.payeePk
      ..tagPks = {fresh.tagPk, weekly.tagPk}
      ..foreignAmount = 11.25
      ..foreignCurrency = 'eur'
      ..budgetPk = await device.localPk(_budget, budgetId)
      ..billPk = await device.localPk(_bill, billId)
      ..attachments = [
        await db.prepareFireflyAttachment(
          filename: 'receipt.txt',
          title: 'Receipt',
          bytes: Stream.value('E2E3 receipt'.codeUnits),
          mime: 'text/plain',
        ),
      ];
    await draft.persist(pk);
    await clock.tick();
    await sync();
    // The attachment uploads once its journal id is known.
    await sync();

    final remote = await remoteSplit(pk);
    richGroupId = remote.groupId;
    cleanup.add(() => device.admin.transactions.delete(remote.groupId));
    final payeeId = (await device.remoteId(_payee, payee.payeePk))!;
    cleanup.add(() => device.admin.accounts.delete(payeeId));
    for (final tag in [fresh, weekly]) {
      final id = await device.remoteId(FireflyEntityType.tag, tag.tagPk);
      if (id != null) cleanup.add(() => device.admin.tags.delete(id));
    }
    final split = remote.split;
    expect(split.destinationId, payeeId);
    expect(split.fields['tags'], unorderedEquals([fresh.name, weekly.name]));
    expect(split.foreignAmount, 11.25);
    expect(split.foreignCurrencyCode, 'EUR');
    expect('${split.fields['budget_id']}', budgetId);
    expect('${split.fields['bill_id']}', billId);
    final attachments = await device.admin.attachments.list(limit: 100);
    final uploaded = attachments.items
        .where((item) => item.attachableId == split.journalId)
        .toList();
    expect(uploaded.map((item) => item.filename), ['receipt.txt']);
    cleanup.add(() => device.admin.attachments.delete(uploaded.single.id));

    await sync(second);
    final otherPk = (await second.localPk(_transaction, remote.groupId,
        subId: split.journalId!))!;
    final row = (await second.db.fireflyTransaction(otherPk))!;
    expect((row.name, row.amount), (named('Groceries'), -12.5));
    expect((row.foreignAmount, row.foreignCurrency), (11.25, 'eur'));
    expect((await second.db.fireflyPayee(row.payeeFk!))!.name,
        named('Corner shop'));
    expect(
        (await second.db.fireflyTransactionTags(otherPk))
            .map((tag) => tag.name),
        unorderedEquals([fresh.name, weekly.name]));
    expect(
        row.sharedReferenceBudgetPk, await second.localPk(_budget, budgetId));
    expect(row.billFk, await second.localPk(_bill, billId));
    final files = await second.db.fireflyTransactionAttachments(otherPk);
    expect(files.map((file) => (file.filename, file.title)),
        [('receipt.txt', 'Receipt')]);

    // Nothing changed, so a further cycle on either device writes nothing.
    await clock.tick();
    expect(await sync(), isEmpty);
    expect(await sync(second), isEmpty);
  });

  test('a split group round trips: create, retitle and remove a split',
      () async {
    if (skip()) return;
    final anchor = await localWithdrawal(named('Market run'), 30);
    final base = (await device.db.fireflyTransaction(anchor))!;
    await device.db.persistFireflyGroupDraft(
        anchor,
        [
          base.copyWith(name: named('Bread'), amount: -10),
          base.copyWith(
              transactionPk: 'e2e3-milk', name: named('Milk'), amount: -8),
          base.copyWith(
              transactionPk: 'e2e3-eggs', name: named('Eggs'), amount: -12),
        ],
        named('Market'));
    await clock.tick();
    await sync();

    final remote = await remoteSplit(anchor);
    cleanup.add(() => device.admin.transactions.delete(remote.groupId));
    expect(remote.group.groupTitle, named('Market'));
    expect(remote.group.splits.map((split) => split.amount),
        unorderedEquals([10.0, 8.0, 12.0]));

    await sync(second);
    final mappings =
        await second.context.idMap.forRemoteGroup(_transaction, remote.groupId);
    expect(mappings, hasLength(3));
    final otherAnchor =
        (await second.db.fireflyTransaction(mappings.first.localPk))!;
    final groupPk = otherAnchor.splitGroupFk!;
    expect(await second.db.fireflyGroupTitle(groupPk), named('Market'));
    expect(
        (await second.db.fireflyGroupSplits(groupPk)).map((row) => row.amount),
        unorderedEquals([-10.0, -8.0, -12.0]));

    // The second device retitles the group and drops the eggs.
    await clock.tick();
    final rows = await second.db.fireflyGroupSplits(groupPk);
    await second.db.persistFireflyGroupDraft(
        otherAnchor.transactionPk,
        [
          for (final row in rows)
            if (row.name != named('Eggs')) row
        ],
        named('Market trip'));
    await sync(second);
    final edited = await device.admin.transactions.get(remote.groupId);
    expect(edited.groupTitle, named('Market trip'));
    expect(edited.splits.map((split) => split.amount),
        unorderedEquals([10.0, 8.0]));

    await clock.tick();
    await sync();
    final local = (await device.db.fireflyTransaction(anchor))!;
    expect(await device.db.fireflyGroupTitle(local.splitGroupFk!),
        named('Market trip'));
    expect(
        (await device.db.fireflyGroupSplits(local.splitGroupFk!))
            .map((row) => row.amount),
        unorderedEquals([-10.0, -8.0]));
  });

  test('a liability payment round trips as a local transfer pair', () async {
    if (skip()) return;
    final checking = (await device.localPk(_wallet, checkingId))!;
    final loan = (await device.localPk(_liability, loanId))!;
    final wallet = await (device.db.select(device.db.wallets)
          ..where((row) => row.walletPk.equals(loan)))
        .getSingle();
    expect(wallet.accountKind, AccountKind.liability);

    final (out, _) =
        await device.addTransfer(checking, loan, 75, named('Loan payment'));
    await clock.tick();
    await sync();
    final remote = await remoteSplit(out);
    cleanup.add(() => device.admin.transactions.delete(remote.groupId));
    // Firefly books asset to liability as a withdrawal; Cashew shows the
    // local transfer pair.
    expect(remote.split.type, 'withdrawal');
    expect((remote.split.sourceId, remote.split.destinationId),
        (checkingId, loanId));
    expect(remote.split.amount, 75.0);

    await sync(second);
    // Each side of the local pair maps to the journal under its own role.
    final sides =
        await second.context.idMap.forRemoteGroup(_transaction, remote.groupId);
    expect(sides, hasLength(2));
    final otherOut = sides.first.localPk;
    final row = (await second.db.fireflyTransaction(otherOut))!;
    expect(row.pairedTransactionFk, isNotNull);
    final paired =
        (await second.db.fireflyTransaction(row.pairedTransactionFk!))!;
    expect({
      row.walletFk,
      paired.walletFk
    }, {
      await second.localPk(_wallet, checkingId),
      await second.localPk(_liability, loanId),
    });
    expect({row.amount, paired.amount}, {-75.0, 75.0});
  });

  test('deleting the rich transaction locally removes it everywhere', () async {
    if (skip() || richGroupId == null) return;
    final mapping =
        (await device.context.idMap.forRemoteGroup(_transaction, richGroupId!))
            .single;
    await device.deleteTransaction(mapping.localPk);
    await clock.tick();
    await sync();
    await expectLater(device.admin.transactions.get(richGroupId!),
        throwsA(isA<FireflyNotFound>()));
    await sync(second);
    final links = await second.db.select(second.db.transactionTags).get();
    final rows = {
      for (final row in await second.db.fireflyTransactions()) row.transactionPk
    };
    expect(links.where((link) => !rows.contains(link.transactionFk)), isEmpty);
  });
}

typedef FireflySplitView = ({
  FireflyTransaction group,
  FireflyTransactionSplit split,
  String groupId,
});

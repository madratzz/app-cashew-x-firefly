import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/sync/bootstrap_upload.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/meta_roaming.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/firefly/ui/slots.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/test_database.dart';

void main() {
  test('the frozen registries order dependencies and every stub is inert',
      () async {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final transport = FakeFireflyTransport();
    final context = SyncContext(
        db: db, api: FireflyApi(transport), config: const FireflyConfig());
    expect(context.isCancelled(), isFalse);
    final visited = <FireflyEntityType>{};
    for (final syncer in entitySyncers) {
      expect(visited.containsAll(syncer.dependsOn), isTrue,
          reason: '${syncer.type}');
      expect(visited.add(syncer.type), isTrue);
      await syncer.pull(context);
      await syncer.push(context);
      await syncer.pushDeletes(context);
      await syncer.rereadPushed(context);
    }
    expect(visited, {
      FireflyEntityType.currency,
      FireflyEntityType.walletAccount,
      FireflyEntityType.liabilityAccount,
      FireflyEntityType.payeeAccount,
      FireflyEntityType.category,
      FireflyEntityType.tag,
      FireflyEntityType.budget,
      FireflyEntityType.budgetLimit,
      FireflyEntityType.bill,
      FireflyEntityType.piggyBank,
      FireflyEntityType.recurrence,
      FireflyEntityType.transaction,
      FireflyEntityType.attachment,
      FireflyEntityType.objectGroup,
      FireflyEntityType.transactionLink,
      FireflyEntityType.rule,
    });

    final ids = <String>{};
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Default', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Default', order: 0));
    final transaction = TransactionsCompanion.insert(
      categoryFk: '0',
      name: 'Sample',
      amount: -1,
      note: '',
    );
    // Use a real row to prove the callbacks keep the draft split map unchanged.
    final row = await db.into(db.transactions).insertReturning(transaction);
    final split = <String, Object?>{'description': 'Sample'};
    for (final contributor in transactionContributors) {
      expect(ids.add(contributor.id), isTrue);
      expect(
          contributor.version,
          const {'payee', 'budget', 'bill', 'piggyBank', 'foreignCurrency'}
                  .contains(contributor.id)
              ? 1
              : 0);
      await contributor.pull(
        context,
        const FireflyTransaction(id: '0'),
        FireflyTransactionSplit(split),
        row.transactionPk,
      );
      await contributor.push(context, row, split);
    }
    expect(ids, {
      'payee',
      'tags',
      'budget',
      'bill',
      'piggyBank',
      'splitGroup',
      'foreignCurrency',
      'attachments'
    });
    expect(split, {'description': 'Sample'});
    expect(fireflyTransactionSections, hasLength(8));
    expect(fireflyTransactionChips, hasLength(5));
    expect(fireflyHubEntries, hasLength(8));
    expect(fireflyWalletSections, hasLength(1));

    final engine = SyncEngine(context);
    final scheduler = SyncScheduler(engine);
    expect(engine.isRunning, isFalse);
    scheduler.start();
    scheduler.resume();
    scheduler.localWrite();
    expect((await scheduler.syncNow()).cancelled, isTrue);
    scheduler.pause();
    scheduler.dispose();
    engine.cancel();
    await engine.dispose();

    final upload = FireflyBootstrapUpload(context);
    expect(await upload.canUpload(), isFalse);
    expect((await upload.run()).succeeded, isFalse);
    final roaming = FireflyMetaRoaming(context);
    await roaming.pull();
    await roaming.push();
    expect(
      transport.requests
          .where((request) =>
              request.path == '/budgets' ||
              request.path == '/available-budgets')
          .map((request) => (request.method, request.path)),
      [('GET', '/budgets'), ('GET', '/available-budgets')],
    );
    transport.requests.removeWhere((request) =>
        request.path == '/budgets' || request.path == '/available-budgets');
    expect(
      transport.requests
          .where((request) => request.path == '/attachments')
          .map((request) => request.method),
      ['GET'],
    );
    transport.requests.removeWhere((request) => request.path == '/attachments');
    expect(transport.requests, isEmpty);
  });
}

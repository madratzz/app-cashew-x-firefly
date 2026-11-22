import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/payee_contributor.dart';
import 'package:budget/firefly/sync/entities/payee_account_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/firefly_emulator.dart';

const _accountsPath = '/accounts';
const _groupsPath = '/transactions';
const _payeeType = FireflyEntityType.payeeAccount;
const _payees = PayeeAccountSyncer();
const _transactions = TransactionSyncer();
const _contributor = PayeeContributor();

void main() {
  late FinanceDatabase db;
  late FireflyEmulator server;
  late SyncContext context;

  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    server = FireflyEmulator(clock: () => fixtureTime);
    context = _context(db, server);
  });

  Future<Payee> payeeFor(String remoteId) async {
    final mapping = (await context.idMap.byRemote(_payeeType, remoteId))!;
    return (await db.fireflyPayee(mapping.localPk))!;
  }

  Future<void> setupTransactions() async {
    server.seed(_accountsPath, '1', _account('Wallet', 'asset'));
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'),
        name: 'Wallet',
        order: 0,
        currency: const Value('usd'),
        decimals: const Value(2)));
    await context.idMap.put(fixtureMapping(
      type: FireflyEntityType.walletAccount,
      localPk: '0',
      remoteId: '1',
    ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value(fireflyUncategorizedCategoryPk),
        name: 'Uncategorized',
        order: 0));
  }

  Future<Transaction> localRow(String name,
          {Payee? payee, bool income = false}) =>
      db.into(db.transactions).insertReturning(TransactionsCompanion.insert(
          name: name,
          amount: income ? 5 : -5,
          income: Value(income),
          categoryFk: fireflyUncategorizedCategoryPk,
          note: '',
          payeeFk: Value(payee?.payeePk),
          dateCreated: Value(fixtureTime),
          dateTimeModified: Value(fixtureTime)));

  Future<Transaction> reloadTransaction(Transaction row) async =>
      (await db.fireflyTransaction(row.transactionPk))!;

  Future<JsonObject> savedSplit(Transaction row) async {
    final mapping = await context.idMap
        .byLocal(FireflyEntityType.transaction, row.transactionPk);
    final group = await context.api.transactions.get(mapping!.remoteId);
    return group.splits.single.fields;
  }

  test('paginates both kinds and links local rows by name and kind', () async {
    final local = await db.fireflyCreatePayee(
        name: '  Studio  ', kind: PayeeKind.expense);
    server.seed(_accountsPath, '10', _account('Studio', 'expense'));
    server.seed(_accountsPath, '11', _account('Cafe', 'expense'));
    server.seed(_accountsPath, '12', _account('Store', 'expense'));
    server.seed(
        _accountsPath,
        '20',
        _account('Studio', 'revenue', extra: {
          'active': false,
          'notes': 'Synthetic billing contact',
        }));
    server.seed(_accountsPath, '30', _account('Cash account', 'cash'));

    await _payees.pull(context);
    expect((await payeeFor('10')).payeePk, local.payeePk);
    final revenue = await payeeFor('20');
    expect(revenue.kind, PayeeKind.revenue);
    expect(revenue.active, isFalse);
    expect(revenue.notes, 'Synthetic billing contact');
    expect(revenue.dateCreated, fixtureTime.toLocal());
    expect(await db.fireflyPayees(search: ' stUDio '), hasLength(2));
    expect(await db.fireflyPayees(search: '%'), isEmpty);
    expect(
      await db
          .watchFireflyPayees(kind: PayeeKind.revenue, activeOnly: true)
          .first,
      isEmpty,
    );
    expect((await db.fireflyPayees()).map((payee) => payee.name),
        ['Cafe', 'Store', 'Studio', 'Studio']);
    expect(
      server.requests.map((r) => (r.query['type'], r.query['page'])),
      [('expense', '1'), ('revenue', '1'), ('expense', '2'), ('expense', '3')],
    );

    await _payees.push(context);
    expect(
        server.requests.where((request) => request.method != 'GET'), isEmpty);
  });

  test('creates, renames and deletes payees locally and remotely', () async {
    await setupTransactions();
    final local = await db.fireflyCreatePayee(
      name: 'Bakery',
      kind: PayeeKind.expense,
      notes: 'Synthetic note',
    );
    await _payees.pull(context);
    await _payees.push(context);
    final mapping = (await context.idMap.byLocal(_payeeType, local.payeePk))!;
    final id = mapping.remoteId;
    final created = await context.api.accounts.get(id);
    expect(created.name, 'Bakery');
    expect(created.type, 'expense');
    expect(created.notes, 'Synthetic note');

    final edited = await db.fireflyUpdatePayee(local.copyWith(
        name: 'Bread Shop', active: false, notes: const Value(null)));
    expect(edited!.dateTimeModified!.isAfter(local.dateTimeModified!), isTrue);
    await _payees.push(context);
    final renamed = await context.api.accounts.get(id);
    expect(renamed.name, 'Bread Shop');
    expect(renamed.active, isFalse);
    expect(renamed.notes, isNull);

    await context.api.accounts.update(id, {
      'name': 'Corner Shop',
      'iban': 'GB00TEST00000000000000',
    });
    await _payees.pull(context);
    final pulled = await payeeFor(id);
    expect(pulled.name, 'Corner Shop');
    expect(pulled.iban, 'GB00TEST00000000000000');
    expect(pulled.payeePk, local.payeePk);

    final localTransaction = await localRow('Bread', payee: pulled);
    expect(await db.watchFireflyPayeeTransactions(pulled.payeePk).first,
        [localTransaction]);
    await _transactions.push(context);
    await _transactions.rereadPushed(context);
    final group = (await context.idMap.byLocal(
      FireflyEntityType.transaction,
      localTransaction.transactionPk,
    ))!;
    await db.fireflyDeletePayee(local.payeePk);
    expect((await reloadTransaction(localTransaction)).payeeFk, isNull);
    expect(
      (await context.idMap.byLocal(_payeeType, local.payeePk))!.state,
      FireflySyncState.pendingDelete,
    );
    await _payees.pushDeletes(context);
    expect(await db.fireflyPayee(local.payeePk), isNull);
    expect(await context.idMap.byLocal(_payeeType, local.payeePk), isNull);
    await expectLater(
        context.api.accounts.get(id), throwsA(isA<FireflyNotFound>()));
    await expectLater(context.api.transactions.get(group.remoteId),
        throwsA(isA<FireflyNotFound>()));
    await _transactions.pull(context);
    expect(await db.fireflyTransaction(localTransaction.transactionPk), isNull);

    server.seed(_accountsPath, '30', _account('Studio', 'revenue'));
    await _payees.pull(context);
    final imported = await payeeFor('30');
    final deposit = await localRow('Invoice', payee: imported, income: true);
    await context.api.accounts.delete('30');
    await _payees.pull(context);
    expect(await db.fireflyPayee(imported.payeePk), isNull);
    expect((await reloadTransaction(deposit)).payeeFk, isNull);
    expect(await context.idMap.byRemote(_payeeType, '30'), isNull);
  });

  test('suppresses deletes when either account listing changes mid-pull',
      () async {
    for (final id in ['10', '11', '12']) {
      server.seed(_accountsPath, id, _account('Payee $id', 'expense'));
    }
    server.seed(_accountsPath, '20', _account('Studio', 'revenue'));
    await _payees.pull(context);
    final revenue = await payeeFor('20');
    server.removeSeed(_accountsPath, '20');
    server.onRequest = (request) {
      if (request.query['type'] == 'expense' && request.query['page'] == '2') {
        server.removeSeed(_accountsPath, '12');
      }
    };

    await _payees.pull(context);
    expect(await db.fireflyPayee(revenue.payeePk), revenue);

    server.onRequest = null;
    await _payees.pull(context);
    expect(await db.fireflyPayee(revenue.payeePk), isNull);
    expect(await context.idMap.byRemote(_payeeType, '12'), isNull);
  });

  test('recovers a matching account created between pull and push', () async {
    final local =
        await db.fireflyCreatePayee(name: 'Studio', kind: PayeeKind.revenue);
    await _payees.pull(context);
    server.seed(_accountsPath, '10', _account('Studio', 'expense'));
    server.seed(_accountsPath, '20', _account('Studio', 'revenue'));
    server.onRequest = (request) {
      if (request.method == 'POST' && request.path == _accountsPath) {
        throw const FireflyValidation('Invalid data', errors: {
          'name': ['This account name is already in use.'],
        });
      }
    };

    await _payees.push(context);
    expect((await payeeFor('20')).payeePk, local.payeePk);
    expect(await context.idMap.byRemote(_payeeType, '10'), isNull);
  });

  test(
      'withdrawal and deposit payees round trip through the transaction syncer',
      () async {
    await setupTransactions();
    server.seed(_accountsPath, '10', _account('Cafe', 'expense'));
    server.seed(_accountsPath, '11', _account('Market', 'expense'));
    server.seed(_accountsPath, '20', _account('Studio', 'revenue'));
    await _payees.pull(context);
    final cafe = await payeeFor('10');
    final market = await payeeFor('11');
    final studio = await payeeFor('20');
    final withdrawal = await localRow('Lunch', payee: cafe);
    final deposit = await localRow('Invoice', payee: studio, income: true);
    final withoutPayee = await localRow('Other');

    await _transactions.push(context);
    await _transactions.rereadPushed(context);
    expect(await savedSplit(withdrawal), containsPair('destination_id', '10'));
    expect(await savedSplit(deposit), containsPair('source_id', '20'));
    expect(await savedSplit(withoutPayee), isNot(contains('destination_name')));
    expect(await savedSplit(withoutPayee), isNot(contains('destination_id')));
    expect((await reloadTransaction(withdrawal)).payeeFk, cafe.payeePk);
    expect((await reloadTransaction(deposit)).payeeFk, studio.payeePk);

    final mapping = (await context.idMap
        .byLocal(FireflyEntityType.transaction, withoutPayee.transactionPk))!;
    Future<void> setRemoteDestination(String? id) async {
      await server.put('$_groupsPath/${mapping.remoteId}', {
        'transactions': [
          {
            'transaction_journal_id': mapping.remoteSubId,
            'destination_id': id,
          },
        ],
      });
      await _transactions.pull(context);
    }

    await setRemoteDestination('11');
    expect((await reloadTransaction(withoutPayee)).payeeFk, market.payeePk);
    await setRemoteDestination(null);
    expect((await reloadTransaction(withoutPayee)).payeeFk, isNull);
    await setRemoteDestination('11');
    expect((await reloadTransaction(withoutPayee)).payeeFk, market.payeePk);

    await (db.update(db.transactions)
          ..where(
              (row) => row.transactionPk.equals(withoutPayee.transactionPk)))
        .write(TransactionsCompanion(
      payeeFk: const Value(null),
      dateTimeModified: Value(fixtureTime.add(const Duration(seconds: 2))),
    ));
    server.requests.clear();
    await _transactions.push(context);
    await _transactions.rereadPushed(context);
    final update = server.requests.singleWhere((r) => r.method == 'PUT');
    final split = FireflyEmulator.splitsOf(update.body!).single;
    expect(split, containsPair('destination_id', null));
    expect(split, isNot(contains('destination_name')));
    expect((await reloadTransaction(withoutPayee)).payeeFk, isNull);
  });

  test('projects missing counterparts to null without changing the database',
      () async {
    await setupTransactions();
    server.seed(_accountsPath, '10', _account('Cafe', 'expense'));
    await _payees.pull(context);
    final cafe = await payeeFor('10');
    final row = await localRow('Lunch', payee: cafe);
    const group = FireflyTransaction(id: '1');
    final projected = await _contributor.projectRemote(context, group,
        const FireflyTransactionSplit({'type': 'withdrawal'}), row);
    expect(projected.payeeFk, isNull);
    expect(await reloadTransaction(row), row);

    final fields = <String, Object?>{};
    expect(
      await _contributor.pushSplitWrite(context, projected, fields,
          prior: const FireflyTransactionSplit({
            'type': 'withdrawal',
            'destination_id': '90',
            'destination_type': 'Cash account',
          })),
      isTrue,
    );
    expect(fields, isEmpty);

    final local =
        await db.fireflyCreatePayee(name: 'Local', kind: PayeeKind.expense);
    expect(
      await _contributor.pushSplitWrite(
          context, row.copyWith(payeeFk: Value(local.payeePk)), fields),
      isFalse,
    );
    expect(fields, isEmpty);
  });
}

SyncContext _context(FinanceDatabase db, FakeFireflyTransport transport) =>
    SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: const FireflyConfig(
        mode: true,
        pageSize: 1,
        applyRules: false,
        fireWebhooks: false,
      ),
      pullMode: SyncPullMode.full,
      now: () => fixtureTime,
    );

JsonObject _account(String name, String type, {JsonObject extra = const {}}) =>
    {
      'type': type,
      'name': name,
      'active': true,
      'created_at': fixtureTime.toIso8601String(),
      'updated_at': fixtureTime.toIso8601String(),
      'currency_code': 'USD',
      ...extra,
    };

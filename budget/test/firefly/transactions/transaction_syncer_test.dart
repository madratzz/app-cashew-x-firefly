import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _type = FireflyEntityType.transaction;
const _syncer = TransactionSyncer();
const _path = '/transactions';
const _search = '/search/transactions';

void main() {
  late FinanceDatabase db;
  late _TransactionTransport transport;
  late SyncContext context;

  SyncContext cycle(SyncPullMode mode, {DateTime? time}) => SyncContext(
        db: db,
        api: FireflyApi(transport),
        config: const FireflyConfig(
          mode: true,
          applyRules: false,
          fireWebhooks: false,
        ),
        pullMode: mode,
        now: () => time ?? fixtureTime,
      );

  Future<void> wallet(
      String pk, String id, String currency, int decimals) async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: Value(pk),
          name: pk,
          order: 0,
          currency: Value(currency),
          decimals: Value(decimals),
        ));
    await context.idMap.put(fixtureMapping(
      type: FireflyEntityType.walletAccount,
      localPk: pk,
      remoteId: id,
    ));
  }

  Future<Transaction> remoteRow(String group, String journal,
      {int role = 0}) async {
    final mapping =
        await context.idMap.byRemote(_type, group, subId: journal, role: role);
    return (await db.fireflyTransaction(mapping!.localPk))!;
  }

  Future<Transaction> edit(
      Transaction row, TransactionsCompanion update) async {
    await (db.update(db.transactions)
          ..where((table) => table.transactionPk.equals(row.transactionPk)))
        .write(update.copyWith(
      dateTimeModified: Value(fixtureTime.add(const Duration(minutes: 1))),
    ));
    return (await db.fireflyTransaction(row.transactionPk))!;
  }

  Future<void> incremental() async {
    context = cycle(SyncPullMode.incremental);
    await context.meta
        .writeDate(SyncMetaRepository.transactionCursor, fixtureTime);
    await context.meta
        .writeDate(SyncMetaRepository.lastFullReconcile, fixtureTime);
  }

  Future<Transaction> local(String key,
          {String wallet = 'usd',
          double amount = -1.25,
          TransactionSpecialType? type}) =>
      db.into(db.transactions).insertReturning(TransactionsCompanion.insert(
            transactionPk: Value(key),
            name: key,
            amount: amount,
            note: '',
            categoryFk: 'food',
            walletFk: Value(wallet),
            dateCreated: Value(fixtureTime),
            dateTimeModified: Value(fixtureTime),
            type: Value(type),
            income: Value(amount > 0),
            paid: Value(type == null),
          ));

  setUp(() async {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    transport = _TransactionTransport();
    context = cycle(SyncPullMode.initial);
    await wallet('usd', '101', 'usd', 2);
    await wallet('another-usd', '102', 'usd', 2);
    await wallet('jpy', '103', 'jpy', 0);
    await wallet('kwd', '104', 'kwd', 3);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('food'),
          name: 'Food',
          order: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('groceries'),
          name: 'Groceries',
          order: 1,
          mainCategoryPk: const Value('food'),
        ));
    for (final (local, remote) in [('food', '201'), ('groceries', '202')]) {
      await context.idMap.put(fixtureMapping(localPk: local, remoteId: remote));
    }
  });

  test('maps five Firefly types and both transfer currency cases both ways',
      () async {
    transport.group('10', [
      _split('11', fields: {'category_id': '202', 'description': ' '}),
    ]);
    transport.group('20', [
      _split('21', type: 'deposit', fields: {
        'source_id': '902',
        'destination_id': '101',
        'category_id': null,
      }),
    ]);
    transport.group('30', [
      _split('31', type: 'transfer', fields: {
        'destination_id': '102',
        'foreign_amount': '42',
      }),
    ]);
    transport.group('40', [
      _split('41', type: 'transfer', fields: {
        'destination_id': '103',
        'foreign_amount': '425',
        'foreign_currency_code': 'JPY',
      }),
    ]);
    transport.group('50', [
      _split('51', type: 'opening balance', fields: {
        'source_id': '901',
        'destination_id': '101',
      }),
    ]);
    transport.group('60', [_split('61', type: 'reconciliation')]);

    await _syncer.pull(context);
    final withdrawal = await remoteRow('10', '11');
    expect((
      withdrawal.name,
      withdrawal.amount,
      withdrawal.income,
      withdrawal.categoryFk,
      withdrawal.subCategoryFk
    ), (
      'Groceries',
      -12.5,
      false,
      'food',
      'groceries'
    ));
    final deposit = await remoteRow('20', '21');
    expect((deposit.amount, deposit.income, deposit.categoryFk),
        (12.5, true, 'firefly-uncategorized'));

    for (final (id, journal, wallet, amount) in [
      ('30', '31', 'another-usd', 12.5),
      ('40', '41', 'jpy', 425.0),
    ]) {
      final from = await remoteRow(id, journal, role: 1);
      final to = await remoteRow(id, journal, role: 2);
      expect(
          (from.amount, from.walletFk, from.categoryFk), (-12.5, 'usd', '0'));
      expect((to.amount, to.walletFk, to.categoryFk), (amount, wallet, '0'));
      expect(from.pairedTransactionFk, to.transactionPk);
      expect(to.pairedTransactionFk, from.transactionPk);
      await edit(to, const TransactionsCompanion(note: Value('New note')));
    }
    final opening = await remoteRow('50', '51');
    final reconciliation = await remoteRow('60', '61');
    expect((opening.fireflyType, opening.amount, opening.categoryFk),
        (FireflyTransactionType.openingBalance, 12.5, '0'));
    expect((
      reconciliation.fireflyType,
      reconciliation.amount,
      reconciliation.categoryFk
    ), (
      FireflyTransactionType.reconciliation,
      -12.5,
      '0'
    ));

    for (final row in [withdrawal, deposit, opening, reconciliation]) {
      await edit(row, const TransactionsCompanion(note: Value('New note')));
    }
    await _syncer.push(context);
    final sent = {
      for (final request
          in transport.requests.where((entry) => entry.method == 'PUT'))
        request.path: _splits(request.body!).single,
    };
    expect(sent, hasLength(6));
    expect(sent['/transactions/10'], containsPair('category_id', '202'));
    expect(sent['/transactions/10'], containsPair('source_id', '101'));
    expect(sent['/transactions/20'], containsPair('category_id', null));
    expect(sent['/transactions/20'], containsPair('destination_id', '101'));
    expect(sent['/transactions/30'], isNot(contains('foreign_amount')));
    expect(sent['/transactions/40'], containsPair('foreign_amount', '425'));
    expect(
        sent['/transactions/40'], containsPair('foreign_currency_code', 'JPY'));
    expect(sent['/transactions/50'], containsPair('destination_id', '101'));
    expect(sent['/transactions/60'], containsPair('source_id', '101'));
    for (final fields in sent.values) {
      expect(fields, containsPair('amount', '12.50'));
      expect(fields, containsPair('notes', 'New note'));
      expect(fields['transaction_journal_id'], isA<String>());
    }
  });

  test('three-split edits preserve the other journals and server-only fields',
      () async {
    transport.group(
        '10',
        [
          _split('11', fields: {'order': 0, 'external_id': 'external'}),
          _split('12', fields: {'order': 1}),
          _split('13', fields: {'order': 2}),
        ],
        title: 'Group');
    await _syncer.pull(context);
    final rows = await Future.wait([
      for (final journal in ['11', '12', '13']) remoteRow('10', journal),
    ]);
    expect(rows.map((row) => row.splitGroupFk).toSet(), hasLength(1));
    expect(rows.map((row) => row.splitOrder), [0, 1, 2]);
    expect((await db.fireflyTransactionGroup(rows.first.splitGroupFk!))!.title,
        'Group');

    await edit(rows.first, const TransactionsCompanion(name: Value('Edited')));
    await _syncer.push(context);
    final request =
        transport.requests.singleWhere((entry) => entry.method == 'PUT');
    final splits = _splits(request.body!);
    expect(splits[0], containsPair('description', 'Edited'));
    expect(splits[0], isNot(contains('external_id')));
    expect(splits[1], {'transaction_journal_id': '12'});
    expect(splits[2], {'transaction_journal_id': '13'});
    await _syncer.rereadPushed(context);
    final remote = await context.api.transactions.get('10');
    expect(remote.splits.first.externalId, 'external');
    expect(remote.groupTitle, 'Group');

    await db.removeFireflyTransactions([rows.first.transactionPk]);
    await context.idMap.markPendingDelete(_type, rows.first.transactionPk);
    await _syncer.pushDeletes(context);
    expect(
        transport.requests.any((entry) =>
            entry.method == 'DELETE' &&
            entry.path == '/transaction-journals/11'),
        isTrue);
    expect((await context.api.transactions.get('10')).splits, hasLength(2));
  });

  test('title and order edits round trip without replacing group members',
      () async {
    transport.group(
        '10',
        [
          _split('11', fields: {'order': 0}),
          _split('12', fields: {'order': 1}),
        ],
        title: 'Group');
    await _syncer.pull(context);
    final row = await remoteRow('10', '11');
    await (db.update(db.transactionGroups)
          ..where((group) => group.groupPk.equals(row.splitGroupFk!)))
        .write(TransactionGroupsCompanion(
      title: const Value('New group'),
      dateTimeModified: Value(fixtureTime.add(const Duration(seconds: 1))),
    ));
    await edit(row, const TransactionsCompanion(splitOrder: Value(2)));
    await _syncer.push(context);
    await _syncer.rereadPushed(context);
    final remote = await context.api.transactions.get('10');
    expect(remote.groupTitle, 'New group');
    expect(remote.splits.map((split) => split.order), [2, 1]);
    expect((await remoteRow('10', '11')).splitOrder, 2);
  });

  test('local transfer creates one journal and preserves an edit before reread',
      () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('0'),
          name: 'Corrections',
          order: 2,
        ));
    final localSource = await local('outbound', amount: -20);
    final localDestination =
        await local('inbound', wallet: 'jpy', amount: 3100);
    await edit(
        localSource,
        TransactionsCompanion(
          categoryFk: const Value('0'),
          pairedTransactionFk: Value(localDestination.transactionPk),
        ));
    await edit(
        localDestination,
        TransactionsCompanion(
          categoryFk: const Value('0'),
          pairedTransactionFk: Value(localSource.transactionPk),
        ));
    await _syncer.push(context);
    final post =
        transport.requests.singleWhere((entry) => entry.method == 'POST');
    final split = _splits(post.body!).single;
    expect(split['type'], 'transfer');
    expect(split['source_id'], '101');
    expect(split['destination_id'], '103');
    expect(split['amount'], '20.00');
    expect(split['foreign_amount'], '3100');

    // A local edit can arrive after the POST completed but before its reread.
    await edit(localDestination,
        const TransactionsCompanion(note: Value('Offline edit')));
    await _syncer.rereadPushed(context);
    expect((await db.fireflyTransaction('inbound'))!.note, 'Offline edit');
    await _syncer.push(context);
    expect(transport.requests.where((entry) => entry.method == 'POST'),
        hasLength(1));
    final update =
        transport.requests.singleWhere((entry) => entry.method == 'PUT');
    expect(_splits(update.body!).single['notes'], 'Offline edit');
  });

  test('balance correction tries reconciliation and falls back on validation',
      () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('0'),
          name: 'Corrections',
          order: 2,
        ));
    final row = await local('adjustment', amount: -20);
    await edit(row, const TransactionsCompanion(categoryFk: Value('0')));
    transport.onRequest = (request) {
      if (request.method == 'POST' &&
          _splits(request.body!).single['type'] == 'reconciliation') {
        throw const FireflyValidation('Reconciliation unavailable', errors: {
          'transactions.0.type': ['Unsupported']
        });
      }
    };
    await _syncer.push(context);
    final posts = transport.requests.where((entry) => entry.method == 'POST');
    expect(posts.map((post) => _splits(post.body!).single['type']),
        ['reconciliation', 'withdrawal']);
    expect((await context.idMap.byLocal(_type, row.transactionPk))!.state,
        FireflySyncState.synced);
  });

  test('initial import resumes after a page request is interrupted', () async {
    for (var index = 1; index <= 3; index++) {
      transport.group('$index', [_split('${index}1')]);
    }
    transport.onRequest = (request) {
      if (request.path == _path && request.query['page'] == '2') {
        throw const FireflyNetworkError();
      }
    };
    await expectLater(
        _syncer.pull(context), throwsA(isA<FireflyNetworkError>()));
    expect(await context.meta.read(SyncMetaRepository.transactionPage), '2');
    expect(await db.fireflyTransactions(), hasLength(1));
    transport.onRequest = null;
    transport.requests.clear();
    await _syncer.pull(cycle(SyncPullMode.initial));
    expect(transport.requests.map((entry) => entry.query['page']), ['2', '3']);
    expect(await db.fireflyTransactions(), hasLength(3));
    expect(await context.meta.read(SyncMetaRepository.transactionPage), isNull);
  });

  test('incremental pull imports search hits and confirms window deletions',
      () async {
    transport.group('10', [_split('11')]);
    transport.group('20', [_split('21')]);
    await _syncer.pull(context);
    await incremental();

    transport.removeSeed(_path, '10');
    transport.group('20', [
      _split('21', fields: {'date': '2020-01-01T00:00:00Z'})
    ]);
    transport.seed(
        _search,
        '30',
        _group([
          _split('31', fields: {
            'date': '2020-01-01T00:00:00Z',
          })
        ]));
    await _syncer.pull(context);
    expect(
        transport.requests.any((entry) =>
            entry.path == _search &&
            entry.query['query']!.startsWith('updated_at_after:')),
        isTrue);
    expect(
        transport.requests.any((entry) => entry.path == '$_path/10'), isTrue);
    expect(
        transport.requests.any((entry) => entry.path == '$_path/20'), isTrue);
    expect(await context.idMap.byRemote(_type, '10', subId: '11'), isNull);
    expect(await remoteRow('20', '21'), isNotNull);
    expect(await remoteRow('30', '31'), isNotNull);
  });

  test('unsupported search leaves window sync active and reconciles daily',
      () async {
    transport.group('10', [_split('11')]);
    await _syncer.pull(context);
    await incremental();
    transport.onRequest = (request) {
      if (request.path == _search) {
        throw const FireflyValidation('Unknown operator');
      }
    };
    await _syncer.pull(context);
    expect(transport.requests.any((entry) => entry.query.containsKey('start')),
        isTrue);

    transport.requests.clear();
    await _syncer.pull(cycle(SyncPullMode.incremental,
        time: fixtureTime.add(const Duration(days: 1))));
    expect(transport.requests.single.path, _path);
    expect(transport.requests.single.query, isNot(contains('start')));
  });

  for (final endpoint in [_path, _search]) {
    test('incomplete incremental $endpoint fails without deleting rows',
        () async {
      transport.group('10', [_split('11')]);
      await _syncer.pull(context);
      await incremental();
      transport.removeSeed(_path, '10');
      transport.incomplete = endpoint;

      await expectLater(
          _syncer.pull(context), throwsA(isA<FireflyInvalidPayload>()));
      expect(await remoteRow('10', '11'), isNotNull);
    });
  }

  test('incomplete full reconcile never removes mappings', () async {
    transport.group('10', [_split('11')]);
    await _syncer.pull(context);
    transport.removeSeed(_path, '10');
    transport.incomplete = _path;
    await expectLater(_syncer.pull(cycle(SyncPullMode.full)),
        throwsA(isA<FireflyInvalidPayload>()));
    expect(await remoteRow('10', '11'), isNotNull);

    transport.incomplete = null;
    await _syncer.pull(cycle(SyncPullMode.full));
    expect(await db.fireflyTransactions(), isEmpty);
  });

  test('creates paid rows with Firefly flags and currency-specific decimals',
      () async {
    final later = await local('later', type: TransactionSpecialType.upcoming);
    await local('yen', wallet: 'jpy', amount: -100);
    await local('dollar', amount: -0.1 - 0.2);
    await local('dinar', wallet: 'kwd', amount: -1.234);
    await local('loan', type: TransactionSpecialType.credit);
    await _syncer.push(context);
    final posts = transport.requests.where((entry) => entry.method == 'POST');
    final amounts = <String, Object?>{};
    for (final request in posts) {
      expect(request.body, containsPair('apply_rules', false));
      expect(request.body, containsPair('fire_webhooks', false));
      final split = _splits(request.body!).single;
      amounts[split['currency_code']! as String] = split['amount'];
      expect(split['internal_reference'], startsWith('cashew:'));
    }
    expect(amounts, {'JPY': '100', 'USD': '0.30', 'KWD': '1.234'});
    expect((await context.idMap.byLocal(_type, 'later'))!.state,
        FireflySyncState.localOnly);
    await edit(later, const TransactionsCompanion(paid: Value(true)));
    await _syncer.rereadPushed(context);
    await _syncer.push(context);
    expect(posts, hasLength(4));
  });

  test(
      'reread imports rules and delete on either transfer side removes the pair',
      () async {
    transport.group('10', [
      _split('11', type: 'transfer', fields: {'destination_id': '102'}),
    ]);
    await _syncer.pull(context);
    final source = await remoteRow('10', '11', role: 1);
    final destination = await remoteRow('10', '11', role: 2);
    await edit(source, const TransactionsCompanion(name: Value('Local')));
    await _syncer.push(context);
    transport.group(
        '10',
        [
          _split('11', type: 'transfer', fields: {
            'destination_id': '102',
            'description': 'Rule title',
          }),
        ],
        updatedAt: fixtureTime.add(const Duration(seconds: 2)));
    await _syncer.rereadPushed(context);
    expect((await db.fireflyTransaction(source.transactionPk))!.name,
        'Rule title');
    await db.removeFireflyTransactions([destination.transactionPk]);
    await context.idMap.markPendingDelete(_type, destination.transactionPk);
    await _syncer.pushDeletes(context);
    expect(await db.fireflyTransactions(), isEmpty);
    expect(await context.idMap.list(_type), isEmpty);
    expect(
        transport.requests.any(
            (entry) => entry.method == 'DELETE' && entry.path == '$_path/10'),
        isTrue);
  });

  test('a rejected create or update stays on the issues list until edited',
      () async {
    transport.group('10', [_split('11')]);
    await _syncer.pull(context);
    final imported = await remoteRow('10', '11');
    await edit(imported, const TransactionsCompanion(name: Value('Edit')));
    await local('new');
    transport.onRequest = (request) {
      if (request.method == 'POST' || request.method == 'PUT') {
        throw const FireflyValidation('Invalid fields');
      }
    };
    await _syncer.push(context);
    for (final pk in ['new', imported.transactionPk]) {
      final map = (await context.idMap.byLocal(_type, pk))!;
      expect((map.state, map.lastError),
          (FireflySyncState.error, 'Invalid fields'));
    }
    transport.requests.clear();
    await _syncer.pull(context);
    await _syncer.push(context);
    expect(
        transport.requests
            .where((entry) => ['POST', 'PUT'].contains(entry.method)),
        isEmpty);
    expect((await db.fireflyTransaction(imported.transactionPk))!.name, 'Edit');

    transport.onRequest = null;
    final rejected = (await db.fireflyTransaction('new'))!;
    await edit(rejected, const TransactionsCompanion(name: Value('Valid')));
    await _syncer.push(context);
    expect((await context.idMap.byLocal(_type, 'new'))!.state,
        FireflySyncState.synced);
  });

  test('recovers an ambiguous backdated POST from its internal reference',
      () async {
    final draft = await local('offline');
    await (db.update(db.transactions)
          ..where((row) => row.transactionPk.equals(draft.transactionPk)))
        .write(TransactionsCompanion(dateCreated: Value(DateTime.utc(2020))));
    await incremental();
    transport.loseCreateResponse = true;
    await expectLater(
        _syncer.push(context), throwsA(isA<FireflyNetworkError>()));
    expect((await context.idMap.byLocal(_type, 'offline'))!.state,
        FireflySyncState.creating);
    await _syncer.pull(context);
    await _syncer.push(context);
    expect(transport.requests.where((entry) => entry.method == 'POST'),
        hasLength(1));
    expect((await db.fireflyTransactions()).single.transactionPk, 'offline');
    expect((await context.idMap.byLocal(_type, 'offline'))!.state,
        FireflySyncState.synced);
  });

  test('lossy text is omitted until edited, then replaces the server value',
      () async {
    final longNote = 'x' * 600;
    final longTitle = 'y' * 275;
    transport.group('10', [
      _split('11', fields: {'notes': longNote, 'description': longTitle}),
    ]);
    await _syncer.pull(context);
    final imported = await remoteRow('10', '11');
    expect(imported.note, hasLength(500));
    expect(imported.name, hasLength(250));
    await edit(imported, const TransactionsCompanion(reconciled: Value(true)));
    await _syncer.push(context);
    final request =
        transport.requests.singleWhere((entry) => entry.method == 'PUT');
    final fields = _splits(request.body!).single;
    expect(fields, isNot(contains('notes')));
    expect(fields, isNot(contains('description')));
    expect(fields, containsPair('reconciled', true));

    await _syncer.rereadPushed(context);
    await edit(imported, const TransactionsCompanion(note: Value('short')));
    await _syncer.push(context);
    final updated = await context.api.transactions.get('10');
    expect(updated.splits.single.notes, 'short');
    expect(updated.splits.single.description, longTitle);
  });

  test('remote changes win and retain a snapshot of conflicting edits',
      () async {
    transport.group('10', [_split('11')]);
    await _syncer.pull(context);
    final row = await remoteRow('10', '11');
    await edit(row, const TransactionsCompanion(name: Value('Local')));
    transport.group(
        '10',
        [
          _split('11', fields: {'description': 'Server'}),
        ],
        updatedAt: fixtureTime.add(const Duration(seconds: 1)));
    await _syncer.pull(context);
    expect((await remoteRow('10', '11')).name, 'Server');
    expect((await context.conflicts.list()).single.localPk, row.transactionPk);
  });
}

JsonObject _split(String journal,
        {String type = 'withdrawal', JsonObject fields = const {}}) =>
    {
      'transaction_journal_id': journal,
      'type': type,
      'date': fixtureTime.toIso8601String(),
      'description': 'Transaction',
      'amount': '12.500000000000',
      'source_id': '101',
      'destination_id': '901',
      'category_id': '201',
      'reconciled': false,
      ...fields,
    };

JsonObject _group(List<JsonObject> splits,
        {String? title, DateTime? updatedAt}) =>
    {
      'group_title': title,
      'updated_at': (updatedAt ?? fixtureTime).toIso8601String(),
      'transactions': splits,
    };

List<JsonObject> _splits(JsonObject json) =>
    (json['transactions']! as List<Object?>).cast<JsonObject>();

class _TransactionTransport extends FakeFireflyTransport {
  _TransactionTransport() : super(maxPageSize: 1);

  final _groups = <String, JsonObject>{};
  var _nextJournal = 1000;
  bool loseCreateResponse = false;
  String? incomplete;

  void group(String id, List<JsonObject> splits,
          {String? title, DateTime? updatedAt}) =>
      seed(_path, id, _group(splits, title: title, updatedAt: updatedAt));

  @override
  void seed(String path, String id, JsonObject attributes) {
    super.seed(path, id, attributes);
    if (path == _path) _groups[id] = attributes;
  }

  @override
  void removeSeed(String path, String id) {
    super.removeSeed(path, id);
    if (path == _path) _groups.remove(id);
  }

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    final response = await super.getPage(path, query: query);
    final start = query['start'];
    final end = query['end'];
    final matches = start == null || end == null
        ? null
        : _groups.entries
            .where((entry) => _splits(entry.value).any((split) {
                  final date = (split['date']! as String).substring(0, 10);
                  return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
                }))
            .toList();
    final index = response.currentPage - 1;
    final items = matches == null
        ? response.items
        : [
            if (index < matches.length)
              fireflyResource(
                  'transactions', matches[index].key, matches[index].value),
          ];
    final total = matches?.length ?? response.total;
    return FireflyPage(
      items: items,
      total: total + (incomplete == path ? 1 : 0),
      currentPage: response.currentPage,
      perPage: 1,
      totalPages: matches?.length ?? response.totalPages,
    );
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final splits = [
      for (final split in _splits(body))
        {...split, 'transaction_journal_id': '${_nextJournal++}'},
    ];
    final response =
        await super.post(path, {...body, 'transactions': splits}, query: query);
    seed(
        path, response['id']! as String, response['attributes']! as JsonObject);
    if (loseCreateResponse) {
      loseCreateResponse = false;
      throw const FireflyNetworkError();
    }
    return response;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final id = path.split('/').last;
    final originals = {
      for (final split in _splits(_groups[id]!))
        split['transaction_journal_id']: split,
    };
    final splits = body.containsKey('transactions')
        ? [
            for (final split in _splits(body))
              {...originals[split['transaction_journal_id']]!, ...split},
          ]
        : originals.values.toList();
    final result = await super.put(path, body, query: query);
    seed(_path, id,
        {...result['attributes']! as JsonObject, 'transactions': splits});
    return fireflyResource('transactions', id, _groups[id]!);
  }

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) async {
    final id = path.split('/').last;
    if (path.startsWith('/transaction-journals/')) {
      try {
        await super.delete(path, query: query);
      } on FireflyNotFound {
        for (final entry in _groups.entries.toList()) {
          final splits = _splits(entry.value);
          final rest = splits
              .where((split) => split['transaction_journal_id'] != id)
              .toList();
          if (rest.length != splits.length) {
            seed(_path, entry.key, {...entry.value, 'transactions': rest});
            return;
          }
        }
        rethrow;
      }
    }
    await super.delete(path, query: query);
    _groups.remove(id);
  }
}

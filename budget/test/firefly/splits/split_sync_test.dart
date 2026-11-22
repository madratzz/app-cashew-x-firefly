import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/split_group_contributor.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/firefly_emulator.dart';

const _transaction = FireflyEntityType.transaction;
const _group = FireflyEntityType.transactionGroup;
const _path = '/transactions';

void main() {
  late FinanceDatabase db;
  late _SplitEmulator remote;
  late SyncContext context;
  late DateTime now;

  Future<void> addWallet(String pk, String id, {bool liability = false}) async {
    final type = liability
        ? FireflyEntityType.liabilityAccount
        : FireflyEntityType.walletAccount;
    remote.seed('/accounts', id, {
      'name': pk,
      'type': liability ? 'loan' : 'asset',
      'currency_code': 'USD',
    });
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: Value(pk),
          name: pk,
          order: 0,
          currency: const Value('usd'),
          accountKind:
              Value(liability ? AccountKind.liability : AccountKind.asset),
        ));
    await context.idMap
        .put(fixtureMapping(type: type, localPk: pk, remoteId: id));
  }

  setUp(() async {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    now = fixtureTime;
    remote = _SplitEmulator(clock: () => now);
    context = SyncContext(
      db: db,
      api: FireflyApi(remote),
      config: const FireflyConfig(
          mode: true, applyRules: false, fireWebhooks: false),
      pullMode: SyncPullMode.full,
      now: () => now,
    );
    await addWallet('cash', '101');
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('food'),
          name: 'Food',
          order: 0,
        ));
    await context.idMap.put(fixtureMapping(localPk: 'food', remoteId: '201'));
  });

  Transaction draftRow(String key, double amount, {String wallet = 'cash'}) =>
      Transaction(
        transactionPk: key,
        name: key,
        amount: amount,
        note: '',
        categoryFk: 'food',
        walletFk: wallet,
        dateCreated: fixtureTime,
        income: amount > 0,
        paid: true,
        skipPaid: false,
      );

  Future<Transaction> insert(String key, double amount) async {
    final row = draftRow(key, amount);
    await db.into(db.transactions).insert(row);
    return row;
  }

  Future<void> cycle(
      {TransactionSyncer syncer = const TransactionSyncer()}) async {
    now = now.add(const Duration(seconds: 1));
    await syncer.pull(context);
    await syncer.push(context);
    await syncer.pushDeletes(context);
    await syncer.rereadPushed(context);
  }

  List<FakeFireflyRequest> writes() => remote.requests
      .where(
          (request) => const {'POST', 'PUT', 'DELETE'}.contains(request.method))
      .toList();

  Future<void> expectSynced(
    String groupId,
    String? localGroupPk,
    Map<String, double> expected, {
    String? title,
  }) async {
    final server = await context.api.transactions.get(groupId);
    expect(server.splits.map((split) => split.amount),
        unorderedEquals(expected.values.map((amount) => amount.abs())));
    expect(server.groupTitle == '' ? null : server.groupTitle, title);
    final mappings = await context.idMap.forRemoteGroup(_transaction, groupId);
    expect(mappings.map((map) => map.localPk), unorderedEquals(expected.keys));
    for (final mapping in mappings) {
      final local = (await db.fireflyTransaction(mapping.localPk))!;
      final split = server.splits
          .singleWhere((split) => split.journalId == mapping.remoteSubId);
      expect(local.amount, expected[local.transactionPk]);
      expect(split.amount, local.amount.abs());
      expect(mapping.state, FireflySyncState.synced);
      expect(local.splitGroupFk, localGroupPk);
      expect(local.splitOrder, localGroupPk == null ? null : split.order);
    }
    final account = await context.api.accounts.get('101');
    expect(double.parse(account.attributes['current_balance'] as String),
        closeTo(expected.values.reduce((a, b) => a + b), 0.000001));
  }

  test(
      'creates three journals in one group, appends, removes, renames and deletes',
      () async {
    final first = await insert('first', -1.25);
    final second = draftRow('second', -2.50);
    final third = draftRow('third', -3.75);
    await db.persistFireflyGroupDraft(
        'first', [first, second, third], ' Market ');
    final pk = (await db.fireflyTransaction('first'))!.splitGroupFk!;

    await cycle();
    final id = (await context.idMap.byLocal(_group, pk))!.remoteId;
    expect(writes().map((request) => request.method), ['POST']);
    final posted = FireflyEmulator.splitsOf(writes().single.body!);
    expect(posted.map((split) => split['internal_reference']),
        ['cashew:first', 'cashew:second', 'cashew:third']);
    expect(posted.map((split) => split['order']), [0, 1, 2]);
    expect(posted.map((split) => split['amount']), ['1.25', '2.50', '3.75']);
    await expectSynced(
        id, pk, {'first': -1.25, 'second': -2.50, 'third': -3.75},
        title: 'Market');

    final former = {
      for (final map in await context.idMap.forRemoteGroup(_transaction, id))
        map.localPk: map.remoteSubId,
    };
    remote.requests.clear();
    await db.persistFireflyGroupDraft(
        'first',
        [...await db.fireflyGroupSplits(pk), draftRow('fourth', -4.25)],
        'Market');
    await cycle();
    expect(writes().map((request) => (request.method, request.path)), [
      ('PUT', '$_path/$id'),
    ]);
    final added = FireflyEmulator.splitsOf(writes().single.body!);
    expect(added.map((split) => split['transaction_journal_id']),
        [...former.values, null]);
    expect(added.last['internal_reference'], 'cashew:fourth');
    await expectSynced(id, pk,
        {'first': -1.25, 'second': -2.50, 'third': -3.75, 'fourth': -4.25},
        title: 'Market');

    remote.requests.clear();
    final keep = (await db.fireflyGroupSplits(pk))
        .where((row) => row.transactionPk != 'second')
        .toList();
    await db.persistFireflyGroupDraft('first', keep, 'Market');
    await cycle();
    expect(writes().map((request) => (request.method, request.path)), [
      ('DELETE', '/transaction-journals/${former['second']}'),
    ]);
    await expectSynced(
        id, pk, {'first': -1.25, 'third': -3.75, 'fourth': -4.25},
        title: 'Market');

    remote.requests.clear();
    await db.persistFireflyGroupDraft(
        'first', await db.fireflyGroupSplits(pk), 'Sunday shop');
    await cycle();
    expect(writes().single.body, {
      'apply_rules': false,
      'fire_webhooks': false,
      'group_title': 'Sunday shop',
    });
    await expectSynced(
        id, pk, {'first': -1.25, 'third': -3.75, 'fourth': -4.25},
        title: 'Sunday shop');

    await db.persistFireflyGroupDraft(
        'first', await db.fireflyGroupSplits(pk), '');
    await cycle();
    expect(writes().last.body!['group_title'], isNull);
    expect(await db.fireflyGroupTitle(pk), isNull);
    expect((await context.api.transactions.get(id)).groupTitle, '');

    remote.requests.clear();
    await db.deleteFireflyGroup(pk);
    await cycle();
    expect(writes().map((request) => (request.method, request.path)), [
      ('DELETE', '$_path/$id'),
    ]);
    expect(await db.fireflyTransactions(), isEmpty);
    expect(await db.fireflyTransactionGroup(pk), isNull);
    expect(await context.idMap.forRemoteGroup(_transaction, id), isEmpty);
    await expectLater(
        context.api.transactions.get(id), throwsA(isA<FireflyNotFound>()));
    final account = await context.api.accounts.get('101');
    expect(double.parse(account.attributes['current_balance'] as String), 0);
  });

  test('single to split and back keeps the original group and journal ids',
      () async {
    await insert('first', -6);
    await cycle();
    final original = (await context.idMap.byLocal(_transaction, 'first'))!;
    final first = (await db.fireflyTransaction('first'))!;
    await db.persistFireflyGroupDraft(
        'first', [first.copyWith(amount: -2), draftRow('second', -4)], 'Split');
    final pk = (await db.fireflyTransaction('first'))!.splitGroupFk!;

    // An unchanged payload with a newer stamp must not erase staged topology.
    now = now.add(const Duration(seconds: 1));
    await context.api.transactions.update(original.remoteId, {});
    remote.requests.clear();
    await cycle();
    expect(writes().single.path, '$_path/${original.remoteId}');
    expect(writes().single.method, 'PUT');
    await expectSynced(original.remoteId, pk, {'first': -2, 'second': -4},
        title: 'Split');
    final added = (await context.idMap.byLocal(_transaction, 'second'))!;
    expect((await context.idMap.byLocal(_transaction, 'first'))!.remoteSubId,
        original.remoteSubId);

    remote.requests.clear();
    final survivor =
        (await db.fireflyTransaction('first'))!.copyWith(amount: -6);
    await db.persistFireflyGroupDraft('first', [survivor], null);
    expect((await db.fireflyTransaction('first'))!.splitGroupFk, isNull);
    await cycle();
    expect(writes().map((request) => (request.method, request.path)), [
      ('PUT', '$_path/${original.remoteId}'),
      ('DELETE', '/transaction-journals/${added.remoteSubId}'),
    ]);
    await expectSynced(original.remoteId, null, {'first': -6}, title: 'Split');
    expect(await db.fireflyTransactionGroup(pk), isNull);
    expect((await context.idMap.byLocal(_transaction, 'first'))!.remoteSubId,
        original.remoteSubId);
    expect(await context.conflicts.list(), isEmpty);
    remote.requests.clear();
    await cycle();
    expect(writes(), isEmpty);
  });

  test('recovers every created and appended journal after a lost response',
      () async {
    final first = await insert('first', -1);
    await db.persistFireflyGroupDraft('first',
        [first, draftRow('second', -2), draftRow('third', -3)], 'Market');
    final pk = (await db.fireflyTransaction('first'))!.splitGroupFk!;
    remote.dropResponse = 'POST';
    await expectLater(cycle(), throwsA(isA<FireflyNetworkError>()));
    await cycle();
    final id = (await context.idMap.byLocal(_group, pk))!.remoteId;
    await expectSynced(id, pk, {'first': -1, 'second': -2, 'third': -3},
        title: 'Market');
    expect(writes().map((request) => request.method), ['POST']);

    await db.persistFireflyGroupDraft(
        'first',
        [
          ...await db.fireflyGroupSplits(pk),
          draftRow('fourth', -4),
          draftRow('fifth', -5),
        ],
        'Market');
    remote.dropResponse = 'PUT';
    await expectLater(cycle(), throwsA(isA<FireflyNetworkError>()));
    await cycle();
    expect(writes().map((request) => request.method), ['POST', 'PUT']);
    await expectSynced(id, pk,
        {'first': -1, 'second': -2, 'third': -3, 'fourth': -4, 'fifth': -5},
        title: 'Market');
    expect(await context.conflicts.list(), isEmpty);
  });

  test('remote order and title edits project locally, including omitted fields',
      () async {
    final created = await context.api.transactions.create({
      'group_title': 'Server title',
      'transactions': [_wire('one', order: 1), _wire('two', order: 0)],
    });
    await cycle();
    final pk = (await context.idMap.byRemote(_group, created.id))!.localPk;
    expect((await db.fireflyGroupSplits(pk)).map((row) => row.name),
        ['two', 'one']);
    expect(await db.fireflyGroupTitle(pk), 'Server title');
    final first = created.splits.first;
    final second = created.splits.last;
    now = now.add(const Duration(seconds: 1));
    remote.seed(_path, created.id, {
      'updated_at': now.toIso8601String(),
      'transactions': [
        {...first.fields}..remove('order'),
        {...second.fields, 'order': 4},
      ],
    });
    await cycle();
    expect(await db.fireflyGroupTitle(pk), isNull);
    final rows = await db.fireflyGroupSplits(pk);
    expect(rows.map((row) => (row.name, row.splitOrder)),
        [('two', 4), ('one', null)]);
    expect(await context.conflicts.list(), isEmpty);
  });

  test(
      'projection is pure, and default hash and write hooks retain push fields',
      () async {
    final row = draftRow('first', -1).copyWith(
      splitGroupFk: const Value('draft-group'),
      splitOrder: const Value(7),
    );
    const split = FireflyTransactionSplit({'order': 2});
    const group = FireflyTransaction(id: '101');
    const contributor = SplitGroupContributor();
    final projected =
        await contributor.projectRemote(context, group, split, row);
    expect(projected.splitOrder, 2);
    expect(
        (await contributor.projectRemote(
                context, group, const FireflyTransactionSplit({}), row))
            .splitOrder,
        isNull);
    expect(await db.fireflyTransactions(), isEmpty);
    expect(await db.select(db.transactionGroups).get(), isEmpty);
    expect(remote.requests, isEmpty);

    const legacy = _LegacyContributor();
    final oldFields = <String, Object?>{};
    final localFields = <String, Object?>{};
    final remoteFields = <String, Object?>{};
    final writeFields = <String, Object?>{};
    await legacy.push(context, row, oldFields);
    await legacy.contributeHash(context, row, localFields);
    await legacy.contributeHash(context, row, remoteFields,
        group: group, split: split);
    expect(await legacy.pushSplitWrite(context, row, writeFields, prior: split),
        isTrue);
    for (final fields in [localFields, remoteFields, writeFields]) {
      expect(canonicalJson(fields), canonicalJson(oldFields));
      expect(syncedFieldsHash(fields), syncedFieldsHash(oldFields));
    }
  });

  test('write deferral keeps a new or mapped journal dirty without dropping it',
      () async {
    final contributor = _DeferredContributor();
    final syncer = TransactionSyncer(
        contributors: [...transactionContributors, contributor]);
    await insert('first', -1);
    await cycle(syncer: syncer);
    expect(writes(), isEmpty);
    expect(await context.idMap.byLocal(_transaction, 'first'), isNull);

    contributor.ready = true;
    await cycle(syncer: syncer);
    final map = (await context.idMap.byLocal(_transaction, 'first'))!;
    final row = (await db.fireflyTransaction('first'))!;
    contributor.ready = false;
    await db.persistFireflyGroupDraft(
        'first', [row.copyWith(amount: -2)], null);
    remote.requests.clear();
    await cycle(syncer: syncer);
    expect(writes(), isEmpty);
    expect(await context.idMap.byLocal(_transaction, 'first'), map);
    expect(contributor.priorJournal, map.remoteSubId);

    contributor.ready = true;
    await cycle(syncer: syncer);
    expect(writes().single.method, 'PUT');
    await expectSynced(map.remoteId, null, {'first': -2});
  });

  test('an append preserves an existing deferred journal by its id', () async {
    await insert('first', -1);
    await cycle();
    final original = (await context.idMap.byLocal(_transaction, 'first'))!;
    final first = (await db.fireflyTransaction('first'))!;
    await db.persistFireflyGroupDraft(
        'first', [first.copyWith(amount: -2), draftRow('second', -3)], null);
    final contributor = _DeferredContributor()..deferredPk = 'first';
    final syncer = TransactionSyncer(
        contributors: [...transactionContributors, contributor]);
    remote.requests.clear();

    await cycle(syncer: syncer);
    final outgoing = FireflyEmulator.splitsOf(writes().single.body!);
    expect(outgoing.first, {'transaction_journal_id': original.remoteSubId});
    expect(outgoing.last['internal_reference'], 'cashew:second');
    expect((await db.fireflyTransaction('first'))!.amount, -2);

    contributor.ready = true;
    await cycle(syncer: syncer);
    final pk = (await db.fireflyTransaction('first'))!.splitGroupFk;
    await expectSynced(original.remoteId, pk, {'first': -2, 'second': -3},
        title: 'first');
  });

  test('mixed liability withdrawals and deposits round-trip as paired rows',
      () async {
    await addWallet('loan', '102', liability: true);
    for (final (kind, source, destination) in [
      ('withdrawal', '101', '102'),
      ('deposit', '102', '101'),
    ]) {
      final server = await context.api.transactions.create({
        'transactions': [
          {
            ..._wire(kind),
            'type': kind,
            'source_id': source,
            'destination_id': destination
          },
        ],
      });
      await cycle();
      final maps = await context.idMap.forRemoteGroup(_transaction, server.id);
      final outMap = maps.singleWhere((map) => map.remoteRole == 1);
      final inMap = maps.singleWhere((map) => map.remoteRole == 2);
      final outgoing = (await db.fireflyTransaction(outMap.localPk))!;
      final incoming = (await db.fireflyTransaction(inMap.localPk))!;
      expect(outgoing.pairedTransactionFk, incoming.transactionPk);
      expect(incoming.pairedTransactionFk, outgoing.transactionPk);
      expect(outgoing.walletFk, kind == 'withdrawal' ? 'cash' : 'loan');
      expect(incoming.walletFk, kind == 'withdrawal' ? 'loan' : 'cash');
      expect(outgoing.fireflyType, FireflyTransactionType.transfer);
      expect(outgoing.amount, -1);
      expect(incoming.amount, 1);

      final edited = outgoing.copyWith(
          name: 'edited',
          dateTimeModified: Value(now.add(const Duration(seconds: 1))));
      await db.into(db.transactions).insertOnConflictUpdate(edited);
      remote.requests.clear();
      await cycle();
      final payload = FireflyEmulator.splitsOf(writes().single.body!).single;
      expect(payload['transaction_journal_id'], outMap.remoteSubId);
      expect(payload['description'], 'edited');
      expect(payload['source_id'], source);
      expect(payload['destination_id'], destination);
      expect((await context.api.transactions.get(server.id)).splits.single.type,
          kind);
    }

    for (final (from, to, wire) in [
      ('cash', 'loan', 'withdrawal'),
      ('loan', 'cash', 'deposit'),
    ]) {
      final out = draftRow('out-$from', -12, wallet: from);
      final incoming = draftRow('in-$to', 12, wallet: to);
      await db.into(db.transactions).insert(out);
      await db.into(db.transactions).insert(
            incoming.copyWith(pairedTransactionFk: Value(out.transactionPk)),
          );
      await db.into(db.transactions).insertOnConflictUpdate(
            out.copyWith(pairedTransactionFk: Value(incoming.transactionPk)),
          );
      remote.requests.clear();
      await cycle();
      final posted = FireflyEmulator.splitsOf(writes().single.body!).single;
      expect(posted['type'], wire);
      expect(posted['source_id'], from == 'cash' ? '101' : '102');
      expect(posted['destination_id'], to == 'cash' ? '101' : '102');
    }
  });
}

JsonObject _wire(String name, {int? order}) => {
      'type': 'withdrawal',
      'amount': '1.00',
      'description': name,
      'date': fixtureTime.toIso8601String(),
      'source_id': '101',
      'category_id': '201',
      if (order != null) 'order': order,
    };

class _SplitEmulator extends FireflyEmulator {
  _SplitEmulator({required super.clock});

  String? dropResponse;

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    _validateTitle(body);
    final result = await super.post(path, body, query: query);
    requests.last = (method: 'POST', path: path, query: query, body: body);
    _checkResponse('POST');
    return result;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    _validateTitle(body);
    final result = await super.put(
      path,
      {
        ...body,
        if (body.containsKey('group_title'))
          'group_title': body['group_title'] ?? ''
      },
      query: query,
    );
    requests.last = (method: 'PUT', path: path, query: query, body: body);
    _checkResponse('PUT');
    return result;
  }

  void _checkResponse(String method) {
    if (dropResponse != method) return;
    dropResponse = null;
    throw const FireflyNetworkError();
  }

  void _validateTitle(JsonObject body) {
    if (FireflyEmulator.splitsOf(body).length > 1 &&
        (body['group_title'] as String? ?? '').isEmpty) {
      throw const FireflyValidation('A group title is required for splits.');
    }
  }
}

class _LegacyContributor extends TransactionContributor {
  const _LegacyContributor();

  @override
  String get id => 'legacy';

  @override
  Future<void> push(
      SyncContext context, Transaction transaction, JsonObject split) async {
    split['legacy'] = {'name': transaction.name, 'amount': transaction.amount};
  }
}

class _DeferredContributor extends TransactionContributor {
  bool ready = false;
  String? deferredPk;
  String? priorJournal;

  @override
  String get id => 'deferred';

  @override
  Future<bool> pushSplitWrite(
    SyncContext context,
    Transaction row,
    JsonObject fields, {
    FireflyTransactionSplit? prior,
  }) async {
    priorJournal = prior?.journalId;
    return ready || (deferredPk != null && deferredPk != row.transactionPk);
  }
}

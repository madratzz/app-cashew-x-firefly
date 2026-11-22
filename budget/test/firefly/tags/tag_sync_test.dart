import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/tag.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/tags_contributor.dart';
import 'package:budget/firefly/sync/entities/tag_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _tagSyncer = TagSyncer();
const _transactionSyncer = TransactionSyncer();
const _tagType = FireflyEntityType.tag;
const _tags = '/tags';
const _transactions = '/transactions';
const _name = 'Épicerie / 食料品';

void main() {
  late FinanceDatabase db;
  late FakeFireflyTransport transport;
  late FireflyApi api;

  SyncContext cycle({bool enabled = true}) => SyncContext(
        db: db,
        api: api,
        config: FireflyConfig(
          mode: enabled,
          pageSize: 100,
          applyRules: false,
          fireWebhooks: false,
        ),
        pullMode: SyncPullMode.full,
        now: () => fixtureTime,
      );

  Future<void> sync(SyncContext context) async {
    await _tagSyncer.pull(context);
    await _transactionSyncer.pull(context);
    await _tagSyncer.push(context);
    await _transactionSyncer.push(context);
    await _tagSyncer.pushDeletes(context);
    await _transactionSyncer.rereadPushed(context);
  }

  void seedTag(String id, String name, [JsonObject fields = const {}]) {
    transport.seed(_tags, id, {
      'tag': name,
      'created_at': fixtureTime.toIso8601String(),
      'updated_at': fixtureTime.toIso8601String(),
      ...fields,
    });
  }

  void seedTransaction({
    List<String>? tags,
    int revision = 0,
    String type = 'withdrawal',
  }) {
    transport.seed(_transactions, '20', {
      'updated_at':
          fixtureTime.add(Duration(seconds: revision)).toIso8601String(),
      'transactions': [
        {
          'transaction_journal_id': '21',
          'type': type,
          'date': fixtureTime.toIso8601String(),
          'currency_code': 'USD',
          'amount': '5.00',
          'description': 'Groceries',
          'source_id': '101',
          'destination_id': '102',
          'category_id': '201',
          if (tags != null) 'tags': tags,
        }
      ],
    });
  }

  Future<String> transactionPk(SyncContext context, {int role = 0}) async =>
      (await context.idMap.byRemote(FireflyEntityType.transaction, '20',
              subId: '21', role: role))!
          .localPk;

  Future<List<String>> localTagNames(String pk) async =>
      (await db.fireflyTransactionTags(pk)).map((row) => row.name).toList();

  Future<Object?> remoteTagNames() async =>
      (await api.transactions.get('20')).splits.single.fields['tags'];

  Future<void> draftTags(String pk, Set<String> tagPks) async {
    final draft = FireflyTransactionDraft(db);
    await draft.load(pk);
    draft.tagPks = tagPks;
    await draft.persist(pk);
  }

  setUp(() async {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    transport = _TagTestTransport();
    api = FireflyApi(transport);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('wallet'),
          name: 'Wallet',
          order: 0,
          currency: const Value('usd'),
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('food'),
          name: 'Food',
          order: 0,
        ));
    await cycle().idMap.put(fixtureMapping(localPk: 'food', remoteId: '201'));
    await cycle().idMap.put(fixtureMapping(
          type: FireflyEntityType.walletAccount,
          localPk: 'wallet',
          remoteId: '101',
        ));
  });

  test('local tag CRUD uses a stable numeric ID and clears optional fields',
      () async {
    final tag = await db.saveFireflyTag(
      name: '  $_name  ',
      description: 'Shopping',
      date: DateTime(2024, 2, 3),
    );
    await sync(cycle());
    final mapping = (await cycle().idMap.byLocal(_tagType, tag.tagPk))!;
    final remote = await api.tags.get(mapping.remoteId);
    expect(remote.name, _name);
    expect(remote.description, 'Shopping');
    expect(remote.attributes['date'], '2024-02-03');
    expect(await db.fireflyTags(search: 'épi'), [tag]);

    await db.saveFireflyTag(tagPk: tag.tagPk, name: '食品');
    await sync(cycle());
    final renamed = await api.tags.get(mapping.remoteId);
    expect(renamed.name, '食品');
    expect(renamed.description, isNull);
    expect(renamed.date, isNull);

    await db.deleteFireflyTag(tag.tagPk);
    expect((await cycle().idMap.byLocal(_tagType, tag.tagPk))!.state,
        FireflySyncState.pendingDelete);
    await sync(cycle());
    expect(await db.fireflyTags(), isEmpty);
    expect(await cycle().idMap.byLocal(_tagType, tag.tagPk), isNull);
    expect((await api.tags.list()).items, isEmpty);
    expect(
      transport.requests
          .where((request) => ['PUT', 'DELETE'].contains(request.method))
          .map((request) => request.path),
      ['$_tags/${mapping.remoteId}', '$_tags/${mapping.remoteId}'],
    );
  });

  test('deleting an interrupted create removes the server copy by ID',
      () async {
    final tag = await db.saveFireflyTag(name: _name);
    transport.onRequest = (request) {
      if (request.method == 'POST' && request.path == _tags) {
        seedTag('10', _name);
        throw const FireflyNetworkError();
      }
    };
    final interrupted = cycle();
    await _tagSyncer.pull(interrupted);
    await expectLater(
        _tagSyncer.push(interrupted), throwsA(isA<FireflyNetworkError>()));
    transport.onRequest = null;

    await db.deleteFireflyTag(tag.tagPk);
    await sync(cycle());
    expect(await db.fireflyTags(), isEmpty);
    expect((await api.tags.list()).items, isEmpty);
    expect(await interrupted.idMap.byLocal(_tagType, tag.tagPk), isNull);
    expect(await interrupted.meta.read(fireflyTagDeleteKey(tag.tagPk)), isNull);
    expect(transport.requests.where((request) => request.method == 'POST'),
        hasLength(1));
    expect(
        transport.requests
            .where((request) => request.method == 'DELETE')
            .map((request) => request.path),
        ['$_tags/10']);
  });

  test('remote CRUD keeps the local key and cascades deleted memberships',
      () async {
    seedTag('10', _name);
    seedTag('11', 'Other');
    seedTransaction(tags: [_name]);
    final initial = cycle();
    await sync(initial);
    final pk = await transactionPk(initial);
    final tag = (await db.fireflyTransactionTags(pk)).single;
    expect(tag.name, _name);
    expect(await db.fireflyTags(), hasLength(2));
    expect(
        transport.requests.where((request) => request.path == _tags).length, 2);

    // Firefly returns the renamed tag in the journal without changing its ID.
    seedTag('10', 'Marché', {'date': '2024-02-03', 'description': 'Market'});
    seedTransaction(tags: ['Marché']);
    await sync(cycle());
    final renamed = (await db.fireflyTransactionTags(pk)).single;
    expect(renamed.tagPk, tag.tagPk);
    expect(renamed.name, 'Marché');
    expect(renamed.description, 'Market');
    expect(renamed.date, DateTime(2024, 2, 3));

    transport.removeSeed(_tags, '10');
    seedTransaction();
    await sync(cycle());
    expect(await localTagNames(pk), isEmpty);
    expect(await db.fireflyTag(tag.tagPk), isNull);
    expect(await cycle().idMap.byLocal(_tagType, tag.tagPk), isNull);
    expect(transport.requests.map((request) => request.method),
        everyElement('GET'));
  });

  test('draft membership adds and clears the Firefly string array', () async {
    seedTransaction();
    final initial = cycle();
    await sync(initial);
    final pk = await transactionPk(initial);
    final tag = await db.saveFireflyTag(name: _name);

    await draftTags(pk, {tag.tagPk});
    await sync(cycle());
    expect(await remoteTagNames(), [_name]);
    expect(await localTagNames(pk), [_name]);

    // Renaming the tag collection resource leaves its journal link intact.
    // The generic fake transport has no foreign-key behavior, so mirror that
    // behavior on the response used by the transaction pull.
    await db.saveFireflyTag(tagPk: tag.tagPk, name: 'Marché');
    transport.requests.clear();
    final rename = cycle();
    await _tagSyncer.pull(rename);
    await _transactionSyncer.pull(rename);
    await _tagSyncer.push(rename);
    seedTransaction(tags: ['Marché'], revision: 1);
    await _transactionSyncer.push(rename);
    expect(
        transport.requests.where((request) =>
            request.method == 'PUT' && request.path.startsWith(_transactions)),
        isEmpty);
    expect(await localTagNames(pk), ['Marché']);

    await draftTags(pk, {});
    await sync(cycle());
    expect(await remoteTagNames(), isEmpty);
    expect(await localTagNames(pk), isEmpty);

    transport.requests.clear();
    await sync(cycle());
    expect(transport.requests.map((request) => request.method),
        everyElement('GET'));
  });

  test('editing either transfer row updates the shared journal tags', () async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('destination'),
          name: 'Destination',
          order: 1,
          currency: const Value('usd'),
        ));
    final initial = cycle();
    await initial.idMap.put(fixtureMapping(
      type: FireflyEntityType.walletAccount,
      localPk: 'destination',
      remoteId: '102',
    ));
    seedTag('10', _name);
    seedTag('11', 'Other');
    seedTransaction(type: 'transfer', tags: [_name]);
    await sync(initial);
    final source = await transactionPk(initial, role: 1);
    final destination = await transactionPk(initial, role: 2);
    expect(await localTagNames(source), [_name]);
    expect(await localTagNames(destination), [_name]);

    final other = (await db.fireflyTags(search: 'Other')).single;
    await draftTags(destination, {other.tagPk});
    await sync(cycle());
    expect(await remoteTagNames(), ['Other']);
    expect(await localTagNames(source), ['Other']);
    expect(await localTagNames(destination), ['Other']);

    await draftTags(source, {});
    await sync(cycle());
    expect(await remoteTagNames(), isEmpty);
    expect(await localTagNames(source), isEmpty);
    expect(await localTagNames(destination), isEmpty);
  });

  test('pure remote hashing uses incoming links and clears omitted tags',
      () async {
    seedTag('10', _name);
    seedTag('11', 'Other');
    seedTransaction(tags: [_name]);
    final initial = cycle();
    await sync(initial);
    final pk = await transactionPk(initial);
    final row = await (db.select(db.transactions)
          ..where((table) => table.transactionPk.equals(pk)))
        .getSingle();
    final group = await api.transactions.get('20');
    final split = FireflyTransactionSplit({
      ...group.splits.single.fields,
      'tags': ['Other', 'Other'],
    });
    const contributor = TagsContributor();
    final projected =
        await contributor.projectRemote(initial, group, split, row);
    final fields = <String, Object?>{};
    await contributor.contributeHash(initial, projected, fields,
        group: group, split: split);
    expect(fields, {
      'tags': [(await db.fireflyTags(search: 'Other')).single.tagPk]
    });
    final withoutTags = {...split.fields}..remove('tags');
    await contributor.contributeHash(initial, projected, fields,
        group: group, split: FireflyTransactionSplit(withoutTags));
    expect(fields, isEmpty);
    expect(projected, row);
    expect(await localTagNames(pk), [_name]);

    // Membership may change without the group timestamp advancing.
    seedTransaction(tags: ['Other', 'Other']);
    await sync(cycle());
    expect(await localTagNames(pk), ['Other']);

    seedTransaction();
    await sync(cycle());
    expect(await localTagNames(pk), isEmpty);
    expect(transport.requests.map((request) => request.method),
        everyElement('GET'));
  });

  test('simultaneous membership edits keep the server version', () async {
    seedTag('10', _name);
    seedTag('11', 'Other');
    seedTag('12', 'Third');
    seedTransaction(tags: [_name]);
    final initial = cycle();
    await sync(initial);
    final pk = await transactionPk(initial);
    final other = (await db.fireflyTags(search: 'Other')).single;
    await draftTags(pk, {other.tagPk});

    seedTransaction(tags: ['Third']);
    await sync(cycle());
    expect(await localTagNames(pk), ['Third']);
    expect(await remoteTagNames(), ['Third']);
    final conflicts = await initial.conflicts.list();
    expect(conflicts.single.localPk, pk);
    expect(conflicts.single.resolution, 'remoteWins');
    expect(transport.requests.map((request) => request.method),
        everyElement('GET'));
  });

  test('mode off does not request tags', () async {
    final context = cycle(enabled: false);
    await _tagSyncer.pull(context);
    await _tagSyncer.push(context);
    await _tagSyncer.pushDeletes(context);
    expect(transport.requests, isEmpty);
  });

  test('tag decoding validates the resource shape', () {
    expect(
      () => FireflyTag.fromJson(fireflyResource('tags', '10', {'name': _name})),
      throwsA(isA<FireflyInvalidPayload>()),
    );
  });
}

// Firefly merges journal fields on PUT. The generic fake stores the supplied
// transactions array verbatim, so emulate the merge for this suite.
class _TagTestTransport extends FakeFireflyTransport {
  _TagTestTransport() : super(maxPageSize: 1);

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    if (!path.startsWith('$_transactions/') ||
        !body.containsKey('transactions')) {
      return super.put(path, body, query: query);
    }
    final before = FireflyTransaction.fromJson(await super.get(path));
    final response = await super.put(path, body, query: query);
    final attributes = response['attributes'] as JsonObject;
    final previous = {
      for (final split in before.splits) split.journalId: split.fields,
    };
    final merged = {
      ...attributes,
      'transactions': [
        for (final split in (body['transactions'] as List).cast<JsonObject>())
          {...?previous[split['transaction_journal_id']], ...split},
      ],
    };
    seed(_transactions, before.id, merged);
    return {...response, 'attributes': merged};
  }
}

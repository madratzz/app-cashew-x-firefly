import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/object_group_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_link_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/e2e_harness.dart';

const _objectGroups = ObjectGroupSyncer();
const _links = TransactionLinkSyncer();
const _linkType = {
  'name': 'Paid',
  'inward': 'is paid by',
  'outward': 'pays for',
};

void main() {
  test('links round-trip over HTTP and appear on a second device', () async {
    final target = await E2eTarget.fake(() => fixtureTime);
    addTearDown(target.close);
    final transport = target.transport();
    addTearDown(transport.close);
    final api = FireflyApi(transport);
    final server = target.emulator!;
    server.seed('/link-types', '1', _linkType);
    server.seed('/object-groups', '1', {'title': 'Household', 'order': 0});
    final first = _context(api);
    final second = _context(api);
    await seedLocalTargets(first);

    await _objectGroups.pull(first);
    expect((await first.db.watchFireflyObjectGroups().first).single.title,
        'Household');
    expect((await api.objectGroups.get('1')).title, 'Household');
    expect(
        (await api.objectGroups.update('1', {'title': 'Home'})).title, 'Home');
    await _objectGroups.pull(first);
    expect(
        (await first.db.watchFireflyObjectGroups().first).single.title, 'Home');
    await api.objectGroups.delete('1');
    await _objectGroups.pull(first);
    expect(await first.db.watchFireflyObjectGroups().first, isEmpty);

    final type = (await api.transactionLinks.listTypes()).items.single;
    final link = await _links.createLink(
      first,
      inwardTransactionPk: 'local-inward',
      outwardTransactionPk: 'local-outward',
      linkTypeId: type['id']! as String,
      notes: ' Monthly bill ',
    );
    expect(link.id, type['id']);
    expect(link.inwardJournalId, '111');
    expect(link.outwardJournalId, '222');
    expect(link.notes, 'Monthly bill');
    expect((await api.transactionLinks.get(link.id)).linkTypeId, '1');
    expect((await first.db.watchFireflyTransactionLinks().first).single.id,
        link.id);

    await _links.pull(second);
    expect((await second.db.watchFireflyLinkTypes().first).single.inward,
        'is paid by');
    expect((await second.db.watchFireflyTransactionLinks().first).single.id,
        link.id);

    await _links.deleteLink(second, link.id);
    await _links.deleteLink(second, link.id); // Already deleted server-side.
    expect(await second.db.watchFireflyTransactionLinks().first, isEmpty);
    await _links.pull(first);
    expect(await first.db.watchFireflyTransactionLinks().first, isEmpty);
    expect(await first.db.watchFireflyLinkTypes().first, hasLength(1));
  });

  test('incomplete pages preserve the old cache and complete pulls prune it',
      () async {
    final transport = FakeFireflyTransport(maxPageSize: 1)
      ..seed('/link-types', '1', _linkType)
      ..seed('/link-types', '2', _linkType);
    final context = _context(FireflyApi(transport));
    await _links.pull(context);
    expect(await context.db.watchFireflyLinkTypes().first, hasLength(2));

    transport.onRequest = (request) {
      if (request.path == '/link-types' && request.query['page'] == '2') {
        transport.removeSeed('/link-types', '1');
      }
    };
    await expectLater(
        _links.pull(context), throwsA(isA<FireflyInvalidPayload>()));
    expect(await context.db.watchFireflyLinkTypes().first, hasLength(2));

    transport.onRequest = null;
    await _links.pull(context);
    expect((await context.db.watchFireflyLinkTypes().first).single.id, '2');
  });

  test('missing journal mappings and paired rows cannot create invalid links',
      () async {
    final transport = FakeFireflyTransport();
    final context = _context(FireflyApi(transport));
    await seedLocalTargets(context);

    await expectLater(
      _links.createLink(
        context,
        inwardTransactionPk: 'local-inward',
        outwardTransactionPk: 'missing',
        linkTypeId: '1',
      ),
      throwsA(isA<FireflyValidation>()),
    );
    await expectLater(
      _links.createLink(
        context,
        inwardTransactionPk: 'local-inward',
        outwardTransactionPk: 'local-inward',
        linkTypeId: '1',
      ),
      throwsA(isA<FireflyValidation>()),
    );
    expect(transport.requests, isEmpty);
  });

  test('disabled mode and a cancelled pull send no requests', () async {
    final transport = FakeFireflyTransport();
    final disabled =
        _context(FireflyApi(transport), config: const FireflyConfig());
    final cancelled = _context(FireflyApi(transport), cancelled: () => true);
    for (final context in [disabled, cancelled]) {
      await _links.pull(context);
      await _objectGroups.pull(context);
      await expectLater(
        _links.deleteLink(context, '1'),
        throwsA(isA<FireflyTransportUnavailable>()),
      );
    }
    expect(transport.requests, isEmpty);
  });
}

SyncContext _context(
  FireflyApi api, {
  FireflyConfig config = e2eConfig,
  bool Function()? cancelled,
}) {
  final db = inMemoryFinanceDatabase();
  addTearDown(db.close);
  return SyncContext(db: db, api: api, config: config, isCancelled: cancelled);
}

Future<void> seedLocalTargets(SyncContext context) async {
  final db = context.db;
  await db.into(db.wallets).insert(WalletsCompanion.insert(
      walletPk: const Value('0'), name: 'Default', order: 0));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      categoryPk: const Value('0'), name: 'Default', order: 0));
  for (final (pk, name, journal) in [
    ('local-inward', 'Internet bill', '111'),
    ('local-outward', 'Payment', '222'),
  ]) {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: Value(pk),
          categoryFk: '0',
          name: name,
          amount: -1,
          note: '',
        ));
    await context.idMap.put(fixtureMapping(
      type: FireflyEntityType.transaction,
      localPk: pk,
      remoteId: '1000',
      subId: journal,
    ));
  }
}

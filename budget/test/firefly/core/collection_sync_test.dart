import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _type = FireflyEntityType.category;
const _path = '/categories';

void main() {
  late FakeFireflyTransport transport;
  late ResourceCacheRepository cache;
  late IdMapRepository mappings;
  late ConflictRepository conflicts;
  late _CategoryCollection adapter;
  late CollectionSync<JsonObject> sync;
  final later = fixtureTime.add(const Duration(seconds: 5));
  final latest = fixtureTime.add(const Duration(seconds: 10));

  setUp(() {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    transport = FakeFireflyTransport(maxPageSize: 1);
    cache = ResourceCacheRepository(db);
    mappings = IdMapRepository(db);
    conflicts = ConflictRepository(db);
    adapter = _CategoryCollection(transport, cache);
    sync = CollectionSync(
        adapter: adapter, idMap: mappings, conflicts: conflicts, pageSize: 100);
  });

  void seed(String id, String name, {DateTime? at, String? reference}) {
    transport.seed(_path, id, {
      'name': name,
      if (at != null) 'updated_at': at.toIso8601String(),
      if (reference != null) 'internal_reference': reference,
    });
  }

  Future<void> edit(String pk, String name, {DateTime? at}) => cache
      .write(_type, pk, {'name': name, 'localOnly': 'color'}, modifiedAt: at);

  Future<String> name(String pk) async =>
      ResourceCacheRepository.decode((await cache.read(_type, pk))!)['name']!
          as String;

  List<FakeFireflyRequest> writes() =>
      transport.requests.where((r) => r.method != 'GET').toList();

  test(
      'paginates at the server limit, links a natural key and does no noop writes',
      () async {
    seed('10', 'Food', at: fixtureTime);
    seed('11', 'Travel', at: fixtureTime);
    seed('12', 'Gift', at: fixtureTime);
    await edit('local-food', 'Food');
    final result = await sync.pull();
    expect(result.complete, isTrue);
    expect(result.seen, 3);
    expect(transport.requests.map((r) => r.query['page']), ['1', '2', '3']);
    expect(transport.requests.every((r) => r.query['limit'] == '100'), isTrue);
    expect((await mappings.byRemote(_type, '10'))?.localPk, 'local-food');
    expect(
        ResourceCacheRepository.decode(
            (await cache.read(_type, 'local-food'))!),
        {'name': 'Food', 'localOnly': 'color'});
    await sync.push();
    expect(writes(), isEmpty);

    // A second remote object with the same key may never steal this mapping.
    seed('13', 'Food', at: later);
    await sync.pull();
    expect((await mappings.byRemote(_type, '10'))?.localPk, 'local-food');
    expect((await mappings.byRemote(_type, '13'))?.localPk, 'remote-13');
  });

  test('keeps missing rows when the advertised total changes between pages',
      () async {
    seed('10', 'First');
    seed('11', 'Second');
    seed('12', 'Third');
    await sync.pull();
    transport.removeSeed(_path, '10');
    transport.onRequest = (request) {
      if (request.query['page'] == '2') seed('13', 'Added mid-pull');
    };

    final result = await sync.pull();
    expect(result.complete, isFalse);
    expect(result.seen, 3);
    expect(await name('remote-10'), 'First');

    transport.onRequest = null;
    expect((await sync.pull()).complete, isTrue);
    expect(await cache.read(_type, 'remote-10'), isNull);
    expect(await mappings.byRemote(_type, '10'), isNull);
  });

  test('keeps rows on a malformed page and on an interrupted listing',
      () async {
    seed('10', 'First');
    seed('11', 'Second');
    await sync.pull();
    transport.removeSeed(_path, '11');
    adapter.rewritePage = (page) => FireflyPage(
          items: page.items,
          total: page.total,
          currentPage: 2,
          perPage: page.perPage,
          totalPages: page.totalPages,
        );
    expect((await sync.pull()).complete, isFalse);
    expect(await name('remote-11'), 'Second');
    adapter.rewritePage = null;
    seed('12', 'Third');
    transport.onRequest = (request) {
      if (request.query['page'] == '2') throw const FireflyNetworkError();
    };
    await expectLater(sync.pull(), throwsA(isA<FireflyNetworkError>()));
    expect(await name('remote-11'), 'Second');
  });

  test(
      'interrupted creates recover by reference and natural key without a second POST',
      () async {
    await edit('reference-pk', 'Original name', at: fixtureTime);
    await edit('natural-pk', 'By name', at: fixtureTime);
    adapter.afterCreate = (local, remote) async {
      expect((await mappings.byLocal(_type, local.pk))?.state,
          FireflySyncState.creating);
      throw const FireflyNetworkError();
    };
    await expectLater(sync.push(), throwsA(isA<FireflyNetworkError>()));
    final first = writes().single.body?['name'];
    final firstPk = first == 'Original name' ? 'reference-pk' : 'natural-pk';
    final firstMap = (await mappings.byLocal(_type, firstPk))!;
    expect(IdMapRepository.isProvisional(firstMap), isTrue);

    // Send the other create before recovery. Its creating slot must not collide.
    await expectLater(sync.push(), throwsA(isA<FireflyNetworkError>()));
    expect(writes(), hasLength(2));
    final pending =
        await mappings.list(_type, state: FireflySyncState.creating);
    expect(pending, hasLength(2));

    // The server changed the name, so only the explicit reference can link it.
    final referenceId =
        writes().first.body?['name'] == 'Original name' ? '1' : '2';
    final naturalId = referenceId == '1' ? '2' : '1';
    seed(referenceId, 'Server rename',
        at: later, reference: 'cashew:reference-pk');
    seed(naturalId, 'By name', at: later);
    expect((await sync.pull()).complete, isTrue);
    expect(
        (await mappings.byRemote(_type, referenceId))?.localPk, 'reference-pk');
    expect((await mappings.byRemote(_type, naturalId))?.localPk, 'natural-pk');
    expect(await name('reference-pk'), 'Server rename');
    await sync.push();
    expect(writes(), hasLength(2));
  });

  test('retries a create after a complete pull when the server never stored it',
      () async {
    await sync.pull();
    await edit('new', 'New', at: fixtureTime);
    transport.onRequest = (request) {
      if (request.method == 'POST') throw const FireflyNetworkError();
    };
    await expectLater(sync.push(), throwsA(isA<FireflyNetworkError>()));
    transport.onRequest = null;
    await sync.push();
    expect(writes(), hasLength(1));
    await sync.pull();
    await sync.push();
    expect(writes(), hasLength(2));
    expect((await mappings.byRemote(_type, '1'))?.localPk, 'new');
  });

  test('recovers duplicate validation errors with the existing resource',
      () async {
    await edit('new', 'New', at: fixtureTime);
    transport.onRequest = (request) {
      if (request.method == 'POST') {
        seed('9', 'Canonical name', at: later);
        throw const FireflyValidation('already exists');
      }
    };
    adapter.duplicateId = '9';
    await sync.push();
    expect((await mappings.byRemote(_type, '9'))?.localPk, 'new');
    expect(await name('new'), 'Canonical name');
    expect((await conflicts.list()).single.resolution, 'remoteWins');
  });

  test('applies server versions and records only losing local versions',
      () async {
    seed('10', 'Baseline', at: fixtureTime);
    await sync.pull();
    seed('10', 'Remote clean update', at: later);
    await sync.pull();
    expect(await name('remote-10'), 'Remote clean update');

    await edit('remote-10', 'Same edit', at: latest);
    seed('10', 'Same edit', at: latest);
    await sync.pull();
    expect(await conflicts.list(), isEmpty);
    await sync.push();
    expect(writes(), isEmpty);

    await edit('remote-10', 'Losing edit');
    seed('10', 'Winning edit');
    await sync.pull();
    final conflict = (await conflicts.list()).single;
    expect(jsonDecode(conflict.localJson),
        {'name': 'Losing edit', 'localOnly': 'color'});
    expect(
        jsonDecode(conflict.remoteJson!), containsPair('name', 'Winning edit'));
    expect(await name('remote-10'), 'Winning edit');
  });

  test('compares remote timestamps at the stored Drift precision', () async {
    final remoteTime = fixtureTime.add(const Duration(milliseconds: 250));
    seed('10', 'Baseline', at: remoteTime);
    await sync.pull();
    await edit('remote-10', 'Local edit', at: later);
    await sync.pull();
    expect(await name('remote-10'), 'Local edit');
    expect(await conflicts.list(), isEmpty);
    await sync.push();
    expect(writes().single.method, 'PUT');
  });

  test('rolls back a failed local write and its associated conflict', () async {
    seed('10', 'Baseline', at: fixtureTime);
    await sync.pull();
    await edit('remote-10', 'Keep this pending', at: later);
    seed('10', 'Remote edit', at: latest);
    adapter.failApply = true;
    await expectLater(sync.pull(), throwsStateError);
    expect(await conflicts.list(), isEmpty);
    expect(await name('remote-10'), 'Keep this pending');
    expect((await mappings.byRemote(_type, '10'))?.remoteUpdatedAt?.toUtc(),
        fixtureTime);
  });

  test(
      'restores a pending delete changed remotely and treats DELETE 404 as success',
      () async {
    seed('10', 'Deleted locally', at: fixtureTime);
    seed('11', 'Deleted remotely', at: fixtureTime);
    await sync.pull();
    for (final id in ['10', '11']) {
      await cache.remove(_type, 'remote-$id');
      await mappings.markPendingDelete(_type, 'remote-$id');
    }
    seed('10', 'Restored', at: later);
    await sync.pull();
    expect(await name('remote-10'), 'Restored');
    expect(jsonDecode((await conflicts.list()).single.localJson),
        {'deleted': true});
    transport.removeSeed(_path, '11');
    await sync.pushDeletes();
    expect(writes().single.path, '/categories/11');
    expect(await mappings.byRemote(_type, '11'), isNull);
  });

  test('preserves a dirty row as a conflict on remote delete and on update 404',
      () async {
    seed('10', 'Edited', at: fixtureTime);
    seed('11', 'Also edited', at: fixtureTime);
    await sync.pull();
    await edit('remote-10', 'Local first', at: later);
    await edit('remote-11', 'Local second', at: later);
    transport.removeSeed(_path, '10');
    await sync.pull();
    transport.removeSeed(_path, '11');
    await sync.push();
    expect(await cache.list(_type), isEmpty);
    expect(await mappings.list(_type), isEmpty);
    expect(
        (await conflicts.list())
            .map((entry) => (entry.resolution, entry.remoteJson)),
        everyElement(('remoteDeleted', null)));
    expect(await conflicts.list(), hasLength(2));
  });

  test(
      'validation errors are redacted and suppressed until the local hash changes',
      () async {
    seed('10', 'Baseline', at: fixtureTime);
    await sync.pull();
    await edit('remote-10', 'Invalid', at: later);
    transport.onRequest = (request) {
      if (request.method == 'PUT') {
        throw const FireflyValidation('Rejected Bearer sample-value');
      }
    };
    await sync.push();
    final rejected = (await mappings.byRemote(_type, '10'))!;
    expect(rejected.state, FireflySyncState.error);
    expect(rejected.attempts, 1);
    expect(rejected.lastError, 'Rejected Bearer REDACTED');
    expect(rejected.lastAttemptAt, isNotNull);
    await sync.pull();
    await sync.push();
    expect(writes(), hasLength(1));
    transport.onRequest = null;
    await edit('remote-10', 'Valid', at: latest);
    await sync.push();
    expect(writes(), hasLength(2));
    expect(
        (await mappings.byRemote(_type, '10'))?.state, FireflySyncState.synced);
    expect((await mappings.byRemote(_type, '10'))?.lastError, isNull);
    expect(await name('remote-10'), 'Valid');
  });

  test('a rejected create waits for a changed payload and complete pull',
      () async {
    await sync.pull();
    await edit('new', 'Rejected', at: fixtureTime);
    transport.onRequest = (request) {
      if (request.method == 'POST') {
        throw const FireflyValidation('Invalid name');
      }
    };
    await sync.push();
    final rejected = (await mappings.byLocal(_type, 'new'))!;
    expect(rejected.state, FireflySyncState.error);
    expect(IdMapRepository.isProvisional(rejected), isTrue);

    transport.onRequest = null;
    await sync.pull();
    await sync.push();
    expect(writes(), hasLength(1));
    await edit('new', 'Valid', at: later);
    await sync.push();
    expect(writes(), hasLength(2));
    expect(
        (await mappings.byRemote(_type, '1'))?.state, FireflySyncState.synced);
  });

  test('records the sent version when the user edits or deletes during a push',
      () async {
    await edit('new', 'First version', at: fixtureTime);
    adapter.afterCreate =
        (local, _) => edit(local.pk, 'Second version', at: later);
    await sync.push();
    expect((await mappings.byLocal(_type, 'new'))?.localVersionAt?.toUtc(),
        fixtureTime);
    await sync.push();
    expect(writes().last.body, {'name': 'Second version'});
    expect(
        (await mappings.byLocal(_type, 'new'))?.localVersionAt?.toUtc(), later);

    await edit('removed', 'Removed', at: fixtureTime);
    adapter.afterCreate = (local, _) => cache.remove(_type, local.pk);
    await sync.push();
    expect((await mappings.byLocal(_type, 'removed'))?.state,
        FireflySyncState.pendingDelete);
    await sync.pushDeletes();
    expect(await mappings.byLocal(_type, 'removed'), isNull);
  });

  test('deletes a recovered pending create by server id', () async {
    await mappings.put(fixtureMapping(
      localPk: 'old',
      remoteId: IdMapRepository.creatingId('old'),
      state: FireflySyncState.pendingDelete,
    ));
    await mappings.put(fixtureMapping(
      localPk: 'orphan',
      remoteId: IdMapRepository.creatingId('orphan'),
      state: FireflySyncState.pendingDelete,
    ));
    seed('10', 'Former local row', reference: 'cashew:old', at: fixtureTime);
    await sync.pushDeletes();
    expect(writes(), isEmpty);
    await sync.pull();
    await sync.pushDeletes();
    expect(writes().single.path, '/categories/10');
    expect(await mappings.list(_type), isEmpty);
    expect(await cache.list(_type), isEmpty);
  });
}

class _CategoryCollection extends CollectionAdapter<JsonObject> {
  _CategoryCollection(this.transport, this.cache);

  final FakeFireflyTransport transport;
  final ResourceCacheRepository cache;
  Future<void> Function(LocalCollectionRow, RemoteCollectionRow<JsonObject>)?
      afterCreate;
  FireflyPage<RemoteCollectionRow<JsonObject>> Function(
      FireflyPage<RemoteCollectionRow<JsonObject>>)? rewritePage;
  String? duplicateId;
  bool failApply = false;

  @override
  FireflyEntityType get type => _type;

  @override
  Future<FireflyPage<RemoteCollectionRow<JsonObject>>> page(
      int page, int limit) async {
    final result = (await transport
            .getPage(_path, query: {'page': '$page', 'limit': '$limit'}))
        .map(_readRemote);
    return rewritePage?.call(result) ?? result;
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async =>
      (await cache.list(type)).map(_readLocal).toList();

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final local = await cache.read(type, pk);
    return local == null ? null : _readLocal(local);
  }

  @override
  Future<String?> findNaturalKey(RemoteCollectionRow<JsonObject> remote) async {
    for (final row in await listLocal()) {
      if (row.fields['name'] == remote.fields['name']) return row.pk;
    }
    return null;
  }

  @override
  Future<String?> recoverLocalPk(RemoteCollectionRow<JsonObject> remote) async {
    final reference = remote.value['internal_reference'];
    if (reference is String && reference.startsWith('cashew:')) {
      return reference.substring('cashew:'.length);
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(RemoteCollectionRow<JsonObject> remote,
      {String? localPk}) async {
    final pk = localPk ?? 'remote-${remote.id}';
    final old = await readLocal(pk);
    await cache.write(type, pk, {...?old?.snapshot, ...remote.fields},
        modifiedAt: remote.updatedAt);
    if (failApply) throw StateError('Apply failed after the local write');
    return (await readLocal(pk))!;
  }

  @override
  Future<void> removeLocal(String pk) => cache.remove(type, pk);

  @override
  Future<RemoteCollectionRow<JsonObject>> createRemote(
      LocalCollectionRow local) async {
    final remote = _readRemote(await transport.post(
        _path, {...local.fields, 'internal_reference': 'cashew:${local.pk}'}));
    await afterCreate?.call(local, remote);
    return remote;
  }

  @override
  Future<RemoteCollectionRow<JsonObject>> updateRemote(
          FireflyIdMapping mapping, LocalCollectionRow local) async =>
      _readRemote(
          await transport.put('$_path/${mapping.remoteId}', local.fields));

  @override
  Future<void> removeRemote(String id) => transport.delete('$_path/$id');

  @override
  Future<RemoteCollectionRow<JsonObject>?> findDuplicate(
          LocalCollectionRow local, FireflyValidation error) async =>
      error.message == 'already exists' && duplicateId != null
          ? _readRemote(await transport.get('$_path/$duplicateId'))
          : null;

  RemoteCollectionRow<JsonObject> _readRemote(JsonObject data) {
    final attributes = data['attributes']! as JsonObject;
    return RemoteCollectionRow(
      id: data['id']! as String,
      value: attributes,
      fields: {'name': attributes['name']},
      updatedAt: DateTime.tryParse(attributes['updated_at'] as String? ?? ''),
    );
  }

  LocalCollectionRow _readLocal(FireflyCachedResource row) {
    final data = ResourceCacheRepository.decode(row);
    return LocalCollectionRow(
      pk: row.resourcePk.substring('${type.name}:'.length),
      fields: {'name': data['name']},
      modifiedAt: row.dateTimeModified,
      snapshot: data,
    );
  }
}

import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
  });

  test('maps remote journal sides independently and updates by local key',
      () async {
    const type = FireflyEntityType.transaction;
    final maps = IdMapRepository(db);
    final debit =
        fixtureMapping(type: type, localPk: 'source', subId: '7', role: 1);
    final credit =
        fixtureMapping(type: type, localPk: 'destination', subId: '7', role: 2);
    await maps.put(debit);
    await maps.put(credit);
    expect(await maps.byRemote(type, '1', subId: '7', role: 1), debit);
    expect(await maps.byRemote(type, '1', subId: '7', role: 2), credit);
    expect(await maps.byRemote(type, '1'), isNull);
    expect(
        await maps.forRemoteGroup(type, '1'), unorderedEquals([debit, credit]));
    expect(await maps.markPendingDelete(type, 'source'), isTrue);
    expect((await maps.byLocal(type, 'source'))?.state,
        FireflySyncState.pendingDelete);
    expect(await maps.markPendingDelete(type, 'missing'), isFalse);
    await maps.put(credit.copyWith(state: FireflySyncState.localOnly));
    expect(await maps.markPendingDelete(type, 'destination'), isFalse);
    await maps.put(debit.copyWith(remoteId: '2'));
    expect(await maps.byRemote(type, '2', subId: '7', role: 1), isNotNull);
    await maps.remove(type, 'source');
    expect(await maps.list(type), hasLength(1));
  });

  test('stores and replaces metadata and UTC cursor values', () async {
    final meta = SyncMetaRepository(db);
    final key = SyncMetaRepository.contributorVersion('tags');
    expect(await meta.read(key), isNull);
    expect(await meta.readDate(key), isNull);
    await meta.write(key, '1');
    await meta.write(key, '2');
    expect(await meta.read(key), '2');
    expect(await meta.readDate(key), isNull);
    await meta.writeDate(
        SyncMetaRepository.deleteLogCursor, fixtureTime.toLocal());
    expect((await meta.readDate(SyncMetaRepository.deleteLogCursor))?.toUtc(),
        fixtureTime);
    await meta.remove(key);
    expect(await meta.read(key), isNull);
  });

  test('observes and acknowledges a saved conflict', () async {
    final conflicts = ConflictRepository(db);
    final entry = await conflicts.record(
      type: FireflyEntityType.category,
      localPk: 'local',
      remoteId: '1',
      local: {'name': 'Local'},
      remote: {'name': 'Remote'},
      resolution: 'remoteWins',
    );
    expect(jsonDecode((await conflicts.read(entry.conflictPk))!.localJson),
        {'name': 'Local'});
    expect(await conflicts.watch(unacknowledgedOnly: true).first, [entry]);
    await conflicts.acknowledge(entry.conflictPk);
    expect(await conflicts.list(unacknowledgedOnly: true), isEmpty);
    expect((await conflicts.list()).single.acknowledged, isTrue);
  });

  test('caches independent resource types with overlapping server IDs',
      () async {
    const bill = FireflyEntityType.bill;
    const rule = FireflyEntityType.rule;
    final cache = ResourceCacheRepository(db);
    await cache.write(bill, '1', {'name': 'Bill'});
    await cache.write(rule, '1', {'name': 'Rule'});
    await cache.write(bill, '1', {'name': 'Renamed'}, modifiedAt: fixtureTime);
    final read = await cache.read(bill, '1');
    expect(read?.dateTimeModified?.toUtc(), fixtureTime);
    expect(ResourceCacheRepository.decode(read!), {'name': 'Renamed'});
    expect(await cache.watch(bill).first, [read]);
    expect(await cache.list(rule), hasLength(1));
    await cache.remove(bill, '1');
    expect(await cache.read(bill, '1'), isNull);
    expect(await cache.read(rule, '1'), isNotNull);
  });
}

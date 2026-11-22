import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:drift/drift.dart' show Value;

class BillSyncer extends BillRecurrenceSyncer<FireflyBill> {
  const BillSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.bill;

  @override
  FireflyResourceApi<FireflyBill> api(SyncContext context) => context.api.bills;

  @override
  JsonObject writable(JsonObject attributes) =>
      FireflyBill(id: '', attributes: attributes).toWriteJson();

  @override
  String get keyField => 'name';

  @override
  JsonObject updateBody(JsonObject local, JsonObject remote) => {
        'name': local['name'],
        ...super.updateBody(local, remote),
        if (local['amount_min'] != remote['amount_min'] ||
            local['amount_max'] != remote['amount_max']) ...{
          'amount_min': local['amount_min'],
          'amount_max': local['amount_max'],
        },
      };
}

/// Shared cache-backed lifecycle for WP-22a's two editable resources.
abstract class BillRecurrenceSyncer<T extends FireflyResource>
    extends EntitySyncer {
  const BillRecurrenceSyncer();

  static final _cycles =
      Expando<Map<FireflyEntityType, _ScheduleCycle<FireflyResource>>>();

  FireflyResourceApi<T> api(SyncContext context);
  JsonObject writable(JsonObject attributes);
  String get keyField;

  String? naturalKey(JsonObject attributes) =>
      (attributes[keyField] as String?)?.trim().toLowerCase();

  JsonObject updateBody(JsonObject local, JsonObject remote) => {
        for (final entry in local.entries)
          if (canonicalJson({entry.key: entry.value}) !=
              canonicalJson({entry.key: remote[entry.key]}))
            entry.key: entry.value,
      };

  _ScheduleCycle<T> _cycle(SyncContext context) {
    final cycles = _cycles[context] ??= {};
    return (cycles[type] ??= _ScheduleCycle<T>(context, this))
        as _ScheduleCycle<T>;
  }

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    final result = await cycle.sync.pull();
    await cycle.refreshPulled();
    if (!result.complete && !context.isCancelled()) {
      throw const FireflyInvalidPayload();
    }
  }

  @override
  Future<void> push(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    try {
      await cycle.sync.push();
    } finally {
      await cycle.refreshPushed();
    }
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final pending =
        await context.idMap.list(type, state: FireflySyncState.pendingDelete);
    try {
      await _cycle(context).sync.pushDeletes();
    } finally {
      for (final mapping in pending) {
        if (await context.idMap.byLocal(type, mapping.localPk) == null) {
          await context.meta.remove(fireflyScheduleDeleteKey(mapping.localPk));
        }
      }
    }
  }
}

class _ScheduleCycle<T extends FireflyResource> extends CollectionAdapter<T> {
  _ScheduleCycle(this.context, this.owner);

  final SyncContext context;
  final BillRecurrenceSyncer<T> owner;
  final _pulled = <String, RemoteCollectionRow<T>>{};
  final _pushed =
      <({RemoteCollectionRow<T> remote, LocalCollectionRow sent})>[];

  late final sync = CollectionSync<T>(
    adapter: this,
    idMap: context.idMap,
    conflicts: context.conflicts,
    pageSize: context.config.pageSize,
    now: context.now,
  );

  FinanceDatabase get _db => context.db;
  FireflyResourceApi<T> get _api => owner.api(context);

  @override
  FireflyEntityType get type => owner.type;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  @override
  Future<FireflyPage<RemoteCollectionRow<T>>> page(int page, int limit) async {
    if (page == 1) _pulled.clear();
    return (await _api.list(page: page, limit: limit)).map((value) {
      final remote = _remote(value);
      _pulled[remote.id] = remote;
      return remote;
    });
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async =>
      (await context.cache.list(type)).map(_local).toList();

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final row = await _db.readFireflySchedule(type, pk);
    return row == null ? null : _local(row);
  }

  @override
  Future<String?> findNaturalKey(RemoteCollectionRow<T> remote) async {
    final key = owner.naturalKey(remote.value.attributes);
    if (key == null || key == '') return null;
    final matches = <String>[];
    for (final row in await listLocal()) {
      final map = await context.idMap.byLocal(type, row.pk);
      if (map != null && !IdMapRepository.isProvisional(map)) continue;
      if (owner.naturalKey(row.snapshot!) == key) matches.add(row.pk);
    }
    for (final map in await context.idMap
        .list(type, state: FireflySyncState.pendingDelete)) {
      if (IdMapRepository.isProvisional(map) &&
          await context.meta.read(fireflyScheduleDeleteKey(map.localPk)) ==
              key) {
        matches.add(map.localPk);
      }
    }
    return matches.length == 1 ? matches.single : null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(RemoteCollectionRow<T> remote,
      {String? localPk}) async {
    final pk = localPk ?? ResourceCacheRepository.resourcePk(type, remote.id);
    await _db.writeFireflySchedule(type, pk, remote.value.attributes,
        modifiedAt: remote.updatedAt);
    return (await readLocal(pk))!;
  }

  @override
  Future<void> removeLocal(String pk) => _db.removeFireflySchedule(type, pk);

  @override
  Future<RemoteCollectionRow<T>> createRemote(LocalCollectionRow local) async {
    final remote = _remote(await _api.create(local.snapshot!));
    _pushed.add((remote: remote, sent: local));
    return remote;
  }

  @override
  Future<RemoteCollectionRow<T>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local) async {
    // Firefly 6.6.2 can reject an unchanged recurrence template or
    // repetition when resubmitted. Send only edited fields.
    final previous =
        _pulled[mapping.remoteId] ?? _remote(await _api.get(mapping.remoteId));
    final body = owner.updateBody(local.fields, previous.fields);
    final remote = _remote(await _api.update(mapping.remoteId, body));
    _pushed.add((remote: remote, sent: local));
    return remote;
  }

  @override
  Future<RemoteCollectionRow<T>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate =
        RegExp(r'already (?:in use|exists|been taken)', caseSensitive: false);
    final messages = error.errors[owner.keyField] ?? [error.message];
    if (!messages.any(duplicate.hasMatch)) return null;
    final key = owner.naturalKey(local.snapshot!);
    if (key == null || key.isEmpty) return null;
    final matches = <String, RemoteCollectionRow<T>>{};
    for (var page = 1;; page++) {
      final result =
          await _api.list(page: page, limit: context.config.pageSize);
      if (result.currentPage != page) return null;
      for (final remote in result.items) {
        if (owner.naturalKey(remote.attributes) == key) {
          matches[remote.id] = _remote(remote);
        }
      }
      if (page >= result.totalPages) break;
      if (result.items.isEmpty || context.isCancelled()) return null;
    }
    return matches.length == 1 ? matches.values.single : null;
  }

  @override
  Future<void> removeRemote(String id) => _api.delete(id);

  /// Refresh calculated dates and other response fields even when editable
  /// fields and the server's updated_at have stayed the same.
  Future<void> refreshPulled() async {
    for (final remote in _pulled.values) {
      await _db.transaction(() async {
        final mapping = await context.idMap.byRemote(type, remote.id);
        if (mapping == null ||
            mapping.state != FireflySyncState.synced ||
            mapping.syncedHash != remote.hash ||
            (remote.updatedAt != null &&
                mapping.remoteUpdatedAt != null &&
                remote.updatedAt!.millisecondsSinceEpoch ~/ 1000 <
                    mapping.remoteUpdatedAt!.millisecondsSinceEpoch ~/ 1000)) {
          return;
        }
        final local = await readLocal(mapping.localPk);
        if (local?.hash != remote.hash ||
            canonicalJson(local!.snapshot!) ==
                canonicalJson(remote.snapshot!)) {
          return;
        }
        await _db.writeFireflySchedule(type, local.pk, remote.value.attributes,
            modifiedAt: local.modifiedAt);
      });
    }
  }

  /// A successful write can assign IDs and normalize values. Only replace
  /// the draft when the user has not edited or deleted it during the request.
  Future<void> refreshPushed() async {
    for (final result in _pushed) {
      await _db.transaction(() async {
        final mapping = await context.idMap.byRemote(type, result.remote.id);
        if (mapping?.state != FireflySyncState.synced ||
            mapping?.localPk != result.sent.pk ||
            mapping?.syncedHash != result.sent.hash) {
          return;
        }
        final current = await readLocal(result.sent.pk);
        if (current == null) return;
        final unchanged = current.modifiedAt == result.sent.modifiedAt &&
            current.hash == result.sent.hash;
        final saved = unchanged
            ? await applyRemote(result.remote, localPk: result.sent.pk)
            : result.sent;
        await context.idMap.put(mapping!.copyWith(
          localVersionAt: Value(saved.modifiedAt),
          syncedHash: Value(result.remote.hash),
        ));
      });
    }
    _pushed.clear();
  }

  LocalCollectionRow _local(FireflyCachedResource row) {
    final attributes = ResourceCacheRepository.decode(row);
    return LocalCollectionRow(
      pk: row.resourcePk,
      fields: owner.writable(attributes),
      modifiedAt: row.dateTimeModified,
      snapshot: attributes,
    );
  }

  RemoteCollectionRow<T> _remote(T value) => RemoteCollectionRow(
        id: value.id,
        value: value,
        fields: owner.writable(value.attributes),
        updatedAt: value.updatedAt,
        snapshot: value.attributes,
      );
}

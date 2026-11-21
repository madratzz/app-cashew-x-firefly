import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/sync/conflict_policy.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:drift/drift.dart';

class LocalCollectionRow {
  const LocalCollectionRow({
    required this.pk,
    required this.fields,
    this.modifiedAt,
    this.snapshot,
  });

  final String pk;
  final DateTime? modifiedAt;
  final JsonObject fields;
  final JsonObject? snapshot;
  String get hash => syncedFieldsHash(fields);
}

class RemoteCollectionRow<T> {
  const RemoteCollectionRow({
    required this.id,
    required this.value,
    required this.fields,
    this.updatedAt,
    this.snapshot,
  });

  final String id;
  final DateTime? updatedAt;
  final T value;
  final JsonObject fields;
  final JsonObject? snapshot;
  String get hash => syncedFieldsHash(fields);
}

/// Adapter for a collection with one local row per Firefly resource.
/// Local writes must preserve Cashew-only fields and bypass legacy side effects.
abstract class CollectionAdapter<T> {
  const CollectionAdapter();

  FireflyEntityType get type;
  Future<FireflyPage<RemoteCollectionRow<T>>> page(int page, int limit);
  Future<List<LocalCollectionRow>> listLocal();
  Future<LocalCollectionRow?> readLocal(String pk);
  Future<String?> findNaturalKey(RemoteCollectionRow<T> remote);
  Future<String?> recoverLocalPk(RemoteCollectionRow<T> remote) async => null;
  Future<LocalCollectionRow> applyRemote(RemoteCollectionRow<T> remote,
      {String? localPk});
  Future<void> removeLocal(String pk);
  Future<RemoteCollectionRow<T>> createRemote(LocalCollectionRow local);
  Future<RemoteCollectionRow<T>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local);
  Future<void> removeRemote(String id);

  /// Return the matching resource after a duplicate-create validation error.
  Future<RemoteCollectionRow<T>?> findDuplicate(
          LocalCollectionRow local, FireflyValidation error) async =>
      null;
}

class CollectionPullResult {
  const CollectionPullResult({required this.complete, required this.seen});
  final bool complete;
  final int seen;
}

class CollectionSync<T> {
  CollectionSync({
    required this.adapter,
    required this.idMap,
    required this.conflicts,
    required this.pageSize,
    DateTime Function()? now,
    this.redactError = redactFireflyLog,
  }) : now = now ?? DateTime.now {
    if (pageSize < 1) throw ArgumentError.value(pageSize, 'pageSize');
  }

  final CollectionAdapter<T> adapter;
  final IdMapRepository idMap;
  final ConflictRepository conflicts;
  final int pageSize;
  final DateTime Function() now;
  final String Function(String) redactError;

  bool _completePull = false;

  FinanceDatabase get _db => idMap.db;
  SyncMetaRepository get _meta => SyncMetaRepository(_db);
  String _rejectedHashKey(String pk) => 'rejectedHash.${_type.name}.$pk';
  FireflyEntityType get _type => adapter.type;

  Future<CollectionPullResult> pull() async {
    _completePull = false;
    final rows = <String, RemoteCollectionRow<T>>{};
    int? total;
    var requested = 1;
    var complete = true;
    while (true) {
      final result = await adapter.page(requested, pageSize);
      total ??= result.total;
      complete = complete &&
          result.total == total &&
          result.total >= 0 &&
          result.totalPages >= 0 &&
          result.perPage > 0 &&
          result.items.length <= result.perPage;
      for (final remote in result.items) {
        if (rows.containsKey(remote.id)) complete = false;
        rows[remote.id] = remote;
      }
      if (result.currentPage != requested ||
          (result.totalPages < requested &&
              !(requested == 1 &&
                  result.totalPages == 0 &&
                  result.total == 0))) {
        complete = false;
        break;
      }
      if (requested == result.totalPages || result.totalPages == 0) break;
      if (result.items.isEmpty) {
        complete = false;
        break;
      }
      requested++;
    }
    for (final remote in rows.values) {
      await _db.transaction(() => _pullRow(remote));
    }
    complete = complete && rows.length == total;
    if (complete) {
      for (final mapping in await idMap.list(_type)) {
        if (!IdMapRepository.isProvisional(mapping) &&
            mapping.state != FireflySyncState.localOnly &&
            !rows.containsKey(mapping.remoteId)) {
          await _db.transaction(() => _deleteLocal(mapping));
        }
      }
    }
    _completePull = complete;
    return CollectionPullResult(complete: complete, seen: rows.length);
  }

  Future<void> _pullRow(RemoteCollectionRow<T> remote) async {
    final mapping = await idMap.byRemote(_type, remote.id);
    if (mapping == null) {
      final candidate =
          await _linkCandidate(await adapter.recoverLocalPk(remote)) ??
              await _linkCandidate(await adapter.findNaturalKey(remote));
      final provisional =
          candidate == null ? null : await idMap.byLocal(_type, candidate);
      if (provisional?.state == FireflySyncState.pendingDelete) {
        await idMap.put(provisional!.copyWith(
          remoteId: remote.id,
          remoteUpdatedAt: Value(_driftInstant(remote.updatedAt)),
          syncedHash: Value(remote.hash),
        ));
      } else {
        await _applyRemote(remote, localPk: candidate, mapping: provisional);
      }
      return;
    }
    if (mapping.state == FireflySyncState.localOnly) return;
    final local = await adapter.readLocal(mapping.localPk);
    final updatedAt = _driftInstant(remote.updatedAt);
    final previous = mapping.remoteUpdatedAt;
    // Some resources omit updated_at. Compare canonical fields in that case.
    final changed = updatedAt == null
        ? remote.hash != mapping.syncedHash
        : previous == null || updatedAt.isAfter(previous);
    final decision = resolveConflict(
      local: _localVersion(mapping, local),
      remote: changed ? RemoteSyncVersion.changed : RemoteSyncVersion.unchanged,
      sameHash: local?.hash == remote.hash,
    );
    switch (decision) {
      case ConflictDecision.applyRemoteWithConflict:
        await _recordConflict(mapping, local, remote, 'remoteWins');
        await _applyRemote(remote, localPk: mapping.localPk, mapping: mapping);
      case ConflictDecision.applyRemote:
      case ConflictDecision.insertLocal:
        await _applyRemote(remote, localPk: mapping.localPk, mapping: mapping);
      case ConflictDecision.markSynced:
        await _markSynced(remote, local!, mapping: mapping);
      default:
        break;
    }
  }

  Future<String?> _linkCandidate(String? pk) async {
    if (pk == null) return null;
    final existing = await idMap.byLocal(_type, pk);
    if (existing == null) {
      return await adapter.readLocal(pk) == null ? null : pk;
    }
    return existing.state != FireflySyncState.localOnly &&
            IdMapRepository.isProvisional(existing)
        ? pk
        : null;
  }

  LocalSyncVersion _localVersion(
      FireflyIdMapping mapping, LocalCollectionRow? local) {
    if (mapping.state == FireflySyncState.pendingDelete || local == null) {
      return LocalSyncVersion.pendingDelete;
    }
    return detectLocalChange(
                mapping: mapping,
                modifiedAt: local.modifiedAt,
                hash: local.hash) ==
            LocalChange.clean
        ? LocalSyncVersion.clean
        : LocalSyncVersion.dirty;
  }

  Future<void> _applyRemote(RemoteCollectionRow<T> remote,
      {String? localPk, FireflyIdMapping? mapping}) async {
    final local = await adapter.applyRemote(remote, localPk: localPk);
    await _markSynced(remote, local, mapping: mapping);
  }

  Future<void> _markSynced(
      RemoteCollectionRow<T> remote, LocalCollectionRow local,
      {FireflyIdMapping? mapping, bool pendingDelete = false}) async {
    await idMap.put(FireflyIdMapping(
      entityType: _type,
      localPk: local.pk,
      remoteId: remote.id,
      remoteSubId: '',
      remoteRole: 0,
      remoteUpdatedAt: _driftInstant(remote.updatedAt),
      localVersionAt: local.modifiedAt,
      syncedHash: local.hash,
      lossyFields: mapping?.lossyFields,
      state: pendingDelete
          ? FireflySyncState.pendingDelete
          : FireflySyncState.synced,
      attempts: 0,
    ));
    if (mapping?.state == FireflySyncState.error ||
        await _meta.read(_rejectedHashKey(local.pk)) != null) {
      await _meta.remove(_rejectedHashKey(local.pk));
    }
  }

  Future<void> _recordConflict(
          FireflyIdMapping mapping,
          LocalCollectionRow? local,
          RemoteCollectionRow<T>? remote,
          String resolution) =>
      conflicts.record(
        type: _type,
        localPk: mapping.localPk,
        remoteId: mapping.remoteId,
        local: local?.snapshot ?? local?.fields ?? const {'deleted': true},
        remote: remote?.snapshot ?? remote?.fields,
        resolution: resolution,
        createdAt: now(),
      );

  Future<void> _deleteLocal(FireflyIdMapping mapping) async {
    final local = await adapter.readLocal(mapping.localPk);
    if (resolveConflict(
          local: _localVersion(mapping, local),
          remote: RemoteSyncVersion.deleted,
        ) ==
        ConflictDecision.deleteLocalWithConflict) {
      await _recordConflict(mapping, local, null, 'remoteDeleted');
    }
    if (local != null) await adapter.removeLocal(mapping.localPk);
    await _forgetMapping(mapping.localPk);
  }

  Future<void> _forgetMapping(String pk) async {
    await idMap.remove(_type, pk);
    await _meta.remove(_rejectedHashKey(pk));
  }

  Future<void> push() async {
    for (final row in await adapter.listLocal()) {
      // Re-read to avoid pushing a row edited or removed since enumeration.
      final local = await adapter.readLocal(row.pk);
      if (local == null) continue;
      final mapping = await idMap.byLocal(_type, local.pk);
      final change = detectLocalChange(
          mapping: mapping, modifiedAt: local.modifiedAt, hash: local.hash);
      if (change == LocalChange.clean || change == LocalChange.deleted) {
        continue;
      }
      if (mapping?.state == FireflySyncState.error &&
          await _meta.read(_rejectedHashKey(local.pk)) == local.hash) {
        continue;
      }
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        if (mapping == null || _completePull) {
          try {
            await _create(local, mapping);
          } catch (_) {
            _completePull = false;
            rethrow;
          }
        }
      } else {
        await _update(local, mapping);
      }
    }
  }

  Future<void> _create(
      LocalCollectionRow local, FireflyIdMapping? mapping) async {
    final creating = FireflyIdMapping(
      entityType: _type,
      localPk: local.pk,
      remoteId: IdMapRepository.creatingId(local.pk),
      remoteSubId: '',
      remoteRole: 0,
      state: FireflySyncState.creating,
      attempts: mapping?.attempts ?? 0,
    );
    await idMap.put(creating);
    final RemoteCollectionRow<T> remote;
    try {
      remote = await adapter.createRemote(local);
    } on FireflyValidation catch (error) {
      final recovered = await adapter.findDuplicate(local, error);
      if (recovered == null) {
        await _reject(creating, local, error);
        return;
      }

      await _db.transaction(() async {
        // Recovering a server copy uses the same server-wins rule as pull.
        final existing = await idMap.byRemote(_type, recovered.id);
        if (existing != null && existing.localPk != local.pk) {
          await _reject(creating, local, error);
          return;
        }
        final current = await adapter.readLocal(local.pk);
        if (current == null) {
          await _markSynced(recovered, local, pendingDelete: true);
          return;
        }
        if (current.hash != recovered.hash) {
          await _recordConflict(creating.copyWith(remoteId: recovered.id),
              current, recovered, 'remoteWins');
        }
        await _applyRemote(recovered, localPk: local.pk, mapping: creating);
      });
      return;
    }
    await _finishPush(remote, local);
  }

  Future<void> _update(
      LocalCollectionRow local, FireflyIdMapping mapping) async {
    RemoteCollectionRow<T> remote;
    try {
      remote = await adapter.updateRemote(mapping, local);
    } on FireflyNotFound {
      await _db.transaction(() => _deleteLocal(mapping));
      return;
    } on FireflyValidation catch (error) {
      await _reject(mapping, local, error);
      return;
    }
    await _finishPush(remote, local, mapping: mapping);
  }

  Future<void> _finishPush(
          RemoteCollectionRow<T> remote, LocalCollectionRow local,
          {FireflyIdMapping? mapping}) =>
      _db.transaction(() async {
        final current = await idMap.byLocal(_type, local.pk);
        final deleted = current?.state == FireflySyncState.pendingDelete ||
            await adapter.readLocal(local.pk) == null;
        await _markSynced(remote, local,
            mapping: mapping, pendingDelete: deleted);
      });

  Future<void> _reject(FireflyIdMapping mapping, LocalCollectionRow local,
          FireflyValidation error) =>
      _db.transaction(() async {
        final current = await idMap.byLocal(_type, local.pk);
        if (current?.state == FireflySyncState.pendingDelete) return;
        await idMap.put(mapping.copyWith(
          state: FireflySyncState.error,
          attempts: mapping.attempts + 1,
          lastError: Value(redactError(error.message)),
          lastAttemptAt: Value(now()),
        ));
        await _meta.write(_rejectedHashKey(local.pk), local.hash);
      });

  Future<void> pushDeletes() async {
    for (final mapping
        in await idMap.list(_type, state: FireflySyncState.pendingDelete)) {
      if (IdMapRepository.isProvisional(mapping)) {
        if (!_completePull) continue;
      } else {
        try {
          await adapter.removeRemote(mapping.remoteId);
        } on FireflyNotFound {
          // A previous attempt may have already deleted it.
        }
      }
      await _db.transaction(() => _forgetMapping(mapping.localPk));
    }
  }
}

// Schema v47 stores Drift DateTime values as Unix seconds.
DateTime? _driftInstant(DateTime? date) => date == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(
        date.millisecondsSinceEpoch ~/ 1000 * 1000);

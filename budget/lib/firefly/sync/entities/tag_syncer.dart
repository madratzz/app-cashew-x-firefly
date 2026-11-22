import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/tag.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';

const _tag = FireflyEntityType.tag;

class TagSyncer extends EntitySyncer {
  const TagSyncer();

  static final _cycles = Expando<CollectionSync<FireflyTag>>();

  @override
  FireflyEntityType get type => _tag;

  // Transaction splits refer to tags by name. Use the same cycle's server
  // names, since a pending local rename has yet to reach Firefly.
  static String? remoteIdForName(SyncContext context, String name) =>
      _adapter(context)?.idsByName[name];

  static String? remoteNameForId(SyncContext context, String id) =>
      _adapter(context)?.namesById[id];

  static _TagAdapter? _adapter(SyncContext context) =>
      _cycles[context]?.adapter as _TagAdapter?;

  CollectionSync<FireflyTag> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _TagAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final pending = await _provisionalDeletes(context);
    try {
      final result = await _cycle(context).pull();
      if (!result.complete && !context.isCancelled()) {
        throw const FireflyInvalidPayload();
      }
    } finally {
      await _clearResolvedDeleteNames(context, pending);
    }
  }

  @override
  Future<void> push(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _cycle(context).push();
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final pending =
        await context.idMap.list(type, state: FireflySyncState.pendingDelete);
    try {
      await _cycle(context).pushDeletes();
    } finally {
      await _clearResolvedDeleteNames(context, pending);
    }
  }

  Future<List<FireflyIdMapping>> _provisionalDeletes(
          SyncContext context) async =>
      (await context.idMap.list(type, state: FireflySyncState.pendingDelete))
          .where(IdMapRepository.isProvisional)
          .toList();

  Future<void> _clearResolvedDeleteNames(
      SyncContext context, List<FireflyIdMapping> pending) async {
    for (final map in pending) {
      final current = await context.idMap.byLocal(type, map.localPk);
      if (current == null || !IdMapRepository.isProvisional(current)) {
        await context.meta.remove(fireflyTagDeleteKey(map.localPk));
      }
    }
  }
}

class _TagAdapter extends CollectionAdapter<FireflyTag> {
  _TagAdapter(this.context);

  final SyncContext context;
  final namesById = <String, String>{};
  final idsByName = <String, String>{};
  FinanceDatabase get _db => context.db;

  @override
  FireflyEntityType get type => _tag;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyTag>>> page(
      int page, int limit) async {
    if (page == 1) {
      namesById.clear();
      idsByName.clear();
    }
    return (await context.api.tags.list(page: page, limit: limit))
        .map(_remember);
  }

  RemoteCollectionRow<FireflyTag> _remember(FireflyTag tag) {
    final name = tag.name!.trim();
    _forgetName(tag.id);
    namesById[tag.id] = name;
    idsByName[name] = tag.id;
    return RemoteCollectionRow(
      id: tag.id,
      value: tag,
      fields: _tagFields(name, tag.description, tag.date),
      updatedAt: tag.updatedAt,
    );
  }

  void _forgetName(String id) {
    final previous = namesById.remove(id);
    if (idsByName[previous] == id) idsByName.remove(previous);
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async =>
      (await _db.fireflyTags()).map(_localRow).toList();

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final tag = await _db.fireflyTag(pk);
    if (tag == null) return null;
    final local = _localRow(tag);
    final mapping = await context.idMap.byLocal(type, pk);
    // Drift truncates timestamps to seconds, so same-second edits need a
    // field comparison even when the saved timestamp matches the mapping.
    if (mapping != null &&
        mapping.localVersionAt == local.modifiedAt &&
        mapping.syncedHash != local.hash) {
      return _localRow(tag, hashOnly: true);
    }
    return local;
  }

  @override
  Future<String?> findNaturalKey(RemoteCollectionRow<FireflyTag> remote) async {
    final name = remote.fields['tag'] as String;
    for (final tag in await _db.fireflyTagsWithNames({name})) {
      final map = await context.idMap.byLocal(type, tag.tagPk);
      if (map == null || IdMapRepository.isProvisional(map)) return tag.tagPk;
    }
    final pending =
        await context.idMap.list(type, state: FireflySyncState.pendingDelete);
    for (final map in pending.where(IdMapRepository.isProvisional)) {
      final pendingName =
          await context.meta.read(fireflyTagDeleteKey(map.localPk));
      if (pendingName == name) return map.localPk;
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
    RemoteCollectionRow<FireflyTag> remote, {
    String? localPk,
  }) async {
    final current = localPk == null ? null : await _db.fireflyTag(localPk);
    final tag = remote.value;
    final fields = TagsCompanion.insert(
      tagPk: localPk == null ? const Value.absent() : Value(localPk),
      name: remote.fields['tag'] as String,
      description: Value(remote.fields['description'] as String?),
      date: Value(tag.date),
      dateCreated:
          Value(current?.dateCreated ?? tag.createdAt ?? context.now()),
      dateTimeModified: Value(remote.updatedAt),
    );
    final stored = await _db.into(_db.tags).insertReturning(
          fields,
          onConflict: DoUpdate((_) => fields),
        );
    return _localRow(stored);
  }

  @override
  Future<void> removeLocal(String pk) => _db.removeFireflyTagLocally(pk);

  @override
  Future<RemoteCollectionRow<FireflyTag>> createRemote(
          LocalCollectionRow local) async =>
      _remember(await context.api.tags.create(local.fields));

  @override
  Future<RemoteCollectionRow<FireflyTag>> updateRemote(
          FireflyIdMapping mapping, LocalCollectionRow local) async =>
      _remember(await context.api.tags.update(mapping.remoteId, local.fields));

  @override
  Future<void> removeRemote(String id) async {
    try {
      await context.api.tags.delete(id);
    } on FireflyNotFound {
      // A delete can have succeeded during a previous cycle.
    }
    _forgetName(id);
  }

  @override
  Future<RemoteCollectionRow<FireflyTag>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate =
        RegExp(r'already (?:in use|exists|been taken)', caseSensitive: false);
    if (!(error.errors['tag'] ?? [error.message]).any(duplicate.hasMatch)) {
      return null;
    }
    for (var requested = 1;; requested++) {
      final page = await context.api.tags
          .list(page: requested, limit: context.config.pageSize);
      for (final tag in page.items) {
        if (tag.name!.trim() == local.fields['tag']) return _remember(tag);
      }
      if (page.currentPage != requested ||
          requested >= page.totalPages ||
          page.items.isEmpty) {
        return null;
      }
    }
  }

  LocalCollectionRow _localRow(Tag tag, {bool hashOnly = false}) =>
      LocalCollectionRow(
        pk: tag.tagPk,
        fields: _tagFields(tag.name, tag.description, tag.date),
        modifiedAt: hashOnly ? null : tag.dateTimeModified,
        snapshot: tag.toJson(),
      );
}

JsonObject _tagFields(String name, String? description, DateTime? date) => {
      'tag': name.trim(),
      'description': description == '' ? null : description,
      'date': date == null ? null : formatFireflyDate(date),
    };

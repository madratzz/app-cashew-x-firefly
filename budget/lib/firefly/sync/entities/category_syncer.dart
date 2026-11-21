import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/category.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';

class CategorySyncer extends EntitySyncer {
  const CategorySyncer();

  static final _cycles = Expando<CollectionSync<FireflyCategory>>();

  @override
  FireflyEntityType get type => FireflyEntityType.category;

  CollectionSync<FireflyCategory> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _CategoryAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    final adapter = cycle.adapter as _CategoryAdapter;
    await adapter.markMissingLocalRows();
    final result = await cycle.pull();
    if (result.complete) await adapter.resolveSubcategories();
  }

  @override
  Future<void> push(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).push();
    }
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await (_cycle(context).adapter as _CategoryAdapter)
          .markMissingLocalRows();
      await _cycle(context).pushDeletes();
    }
  }
}

class _CategoryAdapter extends CollectionAdapter<FireflyCategory> {
  _CategoryAdapter(this.context);

  final SyncContext context;
  final _listed = <String, RemoteCollectionRow<FireflyCategory>>{};

  FinanceDatabase get _db => context.db;
  String get _separator => context.config.subcategorySeparator.isEmpty
      ? ' / '
      : context.config.subcategorySeparator;

  @override
  FireflyEntityType get type => FireflyEntityType.category;

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyCategory>>> page(
      int page, int limit) async {
    if (page == 1) _listed.clear();
    final result = (await context.api.categories.list(page: page, limit: limit))
        .map(_remoteRow);
    for (final row in result.items) {
      _listed[row.id] = row;
    }
    return result;
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async {
    final categories = await _db.fireflySyncableCategories();
    final byPk = {
      for (final category in categories) category.categoryPk: category
    };
    return [
      for (final category in categories)
        _localRow(category, byPk[category.mainCategoryPk]),
    ];
  }

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    if (!isFireflySyncableCategory(pk)) return null;
    final category = await _db.fireflyCategory(pk);
    if (category == null) return null;
    final parent = await _parentOf(category);
    final local = _localRow(category, parent);
    final mapping = await context.idMap.byLocal(type, pk);
    final lastVersion = mapping?.localVersionAt;
    // The projected child name can change without a child write. Drift also
    // stores both category timestamps at second precision.
    if (lastVersion != null &&
        local.modifiedAt != null &&
        local.hash != mapping!.syncedHash &&
        (local.modifiedAt == lastVersion ||
            (parent != null && local.modifiedAt!.isBefore(lastVersion)))) {
      return _localRow(category, parent, hashOnly: true);
    }
    return local;
  }

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyCategory> remote) async {
    final name = (remote.fields['name'] as String).toLowerCase();
    for (final local in await listLocal()) {
      if ((local.fields['name'] as String).toLowerCase() != name) continue;
      final mapping = await context.idMap.byLocal(type, local.pk);
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        return local.pk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
    RemoteCollectionRow<FireflyCategory> remote, {
    String? localPk,
  }) async {
    final fullName = remote.fields['name'] as String;
    final parent = await _findParent(fullName, excluding: localPk);
    final name = parent == null ? fullName : _childName(fullName);
    final existing =
        localPk == null ? null : await _db.fireflyCategory(localPk);
    if (existing != null && (existing.name != name || parent != null)) {
      await _detachChildren(existing);
    }
    final saved = await _db.writeFireflyCategory(
      pk: localPk,
      name: name,
      parentPk: parent?.categoryPk,
      modifiedAt: remote.updatedAt,
      createdAt: remote.value.createdAt ?? context.now(),
    );
    return _localRow(saved, parent);
  }

  // CollectionSync fetches all pages before applying rows, but applies them in
  // server order. Link a child whose parent was written after it, retaining
  // the synchronized name and skipping local edits and pending deletes.
  Future<void> resolveSubcategories() async {
    for (final remote in _listed.values) {
      final fullName = remote.fields['name'] as String;
      if (_splitAt(fullName) < 0) continue;
      await _db.transaction(() async {
        final mapping = await context.idMap.byRemote(type, remote.id);
        if (mapping == null ||
            mapping.state != FireflySyncState.synced ||
            mapping.syncedHash != remote.hash) {
          return;
        }
        final local = await _db.fireflyCategory(mapping.localPk);
        if (local == null ||
            local.mainCategoryPk != null ||
            local.name.trim() != fullName) {
          return;
        }
        final parent = await _findParent(fullName, excluding: local.categoryPk);
        if (parent == null) return;
        await _detachChildren(local);
        await _db.writeFireflyCategory(
          pk: local.categoryPk,
          name: _childName(fullName),
          parentPk: parent.categoryPk,
          modifiedAt: local.dateTimeModified,
          createdAt: local.dateCreated,
        );
      });
    }
  }

  Future<void> markMissingLocalRows() => _db.transaction(() async {
        final localPks = {
          for (final local in await _db.fireflySyncableCategories())
            local.categoryPk,
        };
        for (final mapping in await context.idMap.list(type)) {
          if (!isFireflySyncableCategory(mapping.localPk)) {
            await context.idMap.remove(type, mapping.localPk);
          } else if (!localPks.contains(mapping.localPk) &&
              mapping.state != FireflySyncState.pendingDelete) {
            // Legacy deletion of a parent only logs the parent.
            await context.idMap.markPendingDelete(type, mapping.localPk);
          }
        }
      });

  @override
  Future<void> removeLocal(String pk) async {
    final category = await _db.fireflyCategory(pk);
    if (category == null) return;
    await _detachChildren(category);
    await _db.deleteFireflyCategory(pk);
  }

  @override
  Future<RemoteCollectionRow<FireflyCategory>> createRemote(
          LocalCollectionRow local) async =>
      _remoteRow(await context.api.categories.create(local.fields));

  @override
  Future<RemoteCollectionRow<FireflyCategory>> updateRemote(
          FireflyIdMapping mapping, LocalCollectionRow local) async =>
      _remoteRow(
          await context.api.categories.update(mapping.remoteId, local.fields));

  @override
  Future<void> removeRemote(String id) => context.api.categories.delete(id);

  @override
  Future<RemoteCollectionRow<FireflyCategory>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate = RegExp(r'already (?:in use|exists|been taken|a category)',
        caseSensitive: false);
    if (!(error.errors['name'] ?? [error.message]).any(duplicate.hasMatch)) {
      return null;
    }
    final name = (local.fields['name'] as String).toLowerCase();
    var requested = 1;
    while (true) {
      final page = await context.api.categories
          .list(page: requested, limit: context.config.pageSize);
      for (final category in page.items) {
        if (category.name!.trim().toLowerCase() == name) {
          return _remoteRow(category);
        }
      }
      if (page.currentPage != requested ||
          page.currentPage >= page.totalPages ||
          page.items.isEmpty) {
        return null;
      }
      requested++;
    }
  }

  Future<TransactionCategory?> _parentOf(TransactionCategory category) async {
    final pk = category.mainCategoryPk;
    return pk != null && isFireflySyncableCategory(pk)
        ? _db.fireflyCategory(pk)
        : null;
  }

  int _splitAt(String name) {
    final index = name.indexOf(_separator);
    return index > 0 && index + _separator.length < name.length ? index : -1;
  }

  String _childName(String name) =>
      name.substring(_splitAt(name) + _separator.length);

  Future<TransactionCategory?> _findParent(String name,
      {String? excluding}) async {
    final split = _splitAt(name);
    if (split < 0) return null;
    final prefix = name.substring(0, split);
    for (final category in await _db.fireflySyncableCategories()) {
      if (category.categoryPk != excluding &&
          category.mainCategoryPk == null &&
          category.name.trim() == prefix &&
          (await context.idMap.byLocal(type, category.categoryPk))?.state !=
              FireflySyncState.pendingDelete) {
        return category;
      }
    }
    return null;
  }

  Future<void> _detachChildren(TransactionCategory parent) async {
    for (final child in await _db.fireflyCategoryChildren(parent.categoryPk)) {
      // Firefly categories are independently addressable. Retain the child's
      // qualified name when its parent disappears, even with existing transactions.
      await _db.writeFireflyCategory(
        pk: child.categoryPk,
        name: _qualifiedName(child, parent),
        parentPk: null,
        modifiedAt: child.dateTimeModified,
        createdAt: child.dateCreated,
      );
    }
  }

  String _qualifiedName(
          TransactionCategory category, TransactionCategory? parent) =>
      parent == null
          ? category.name.trim()
          : '${parent.name.trim()}$_separator${category.name.trim()}';

  LocalCollectionRow _localRow(
      TransactionCategory category, TransactionCategory? parent,
      {bool hashOnly = false}) {
    final modifiedAt = category.dateTimeModified;
    final parentModifiedAt = parent?.dateTimeModified;
    return LocalCollectionRow(
      pk: category.categoryPk,
      fields: {'name': _qualifiedName(category, parent)},
      modifiedAt: hashOnly
          ? null
          : parentModifiedAt != null &&
                  (modifiedAt == null || parentModifiedAt.isAfter(modifiedAt))
              ? parentModifiedAt
              : modifiedAt,
      snapshot: category.toJson(),
    );
  }

  RemoteCollectionRow<FireflyCategory> _remoteRow(FireflyCategory category) =>
      RemoteCollectionRow(
        id: category.id,
        value: category,
        fields: {'name': category.name!.trim()},
        updatedAt: category.updatedAt,
      );
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/object_group.dart';
import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';

class ObjectGroupSyncer extends EntitySyncer {
  const ObjectGroupSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.objectGroup;

  @override
  Future<void> pull(SyncContext context) => pullFireflyCachedResources(
        context,
        type,
        (page, limit) =>
            context.api.objectGroups.list(page: page, limit: limit),
        (group) => group.toJson(),
      );
}

extension FireflyObjectGroupQueries on FinanceDatabase {
  Stream<List<FireflyObjectGroup>> watchFireflyObjectGroups() =>
      ResourceCacheRepository(this).watch(FireflyEntityType.objectGroup).map(
          (rows) => rows
              .map((row) => FireflyObjectGroup.fromJson(
                  ResourceCacheRepository.decode(row)))
              .toList()
            ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0)));
}

/// Replace one cache collection only after receiving a complete listing.
Future<void> pullFireflyCachedResources<T extends FireflyResource>(
  SyncContext context,
  FireflyEntityType type,
  Future<FireflyPage<T>> Function(int page, int limit) fetch,
  JsonObject Function(T) toJson, {
  String keyPrefix = '',
  String excludedPrefix = '',
}) async {
  if (!context.config.mode || context.isCancelled()) return;
  final resources = <String, T>{};
  int? total;
  for (var page = 1; !context.isCancelled(); page++) {
    final result = await fetch(page, context.config.pageSize);
    if (context.isCancelled()) return;
    total ??= result.total;
    if (result.currentPage != page ||
        result.total != total ||
        (result.items.isEmpty && page < result.totalPages)) {
      throw const FireflyInvalidPayload();
    }
    for (final resource in result.items) {
      final key = '$keyPrefix${resource.id}';
      if (resources.containsKey(key)) throw const FireflyInvalidPayload();
      resources[key] = resource;
    }
    if (resources.length > total) throw const FireflyInvalidPayload();
    if (page >= result.totalPages) {
      if (resources.length != total) throw const FireflyInvalidPayload();
      break;
    }
  }

  await context.db.transaction(() async {
    if (context.isCancelled()) return;
    final prefix = '${type.name}:';
    final existing = {
      for (final row in await context.cache.list(type))
        row.resourcePk.substring(prefix.length): row,
    };
    for (final entry in resources.entries) {
      final previous = existing.remove(entry.key);
      await writeFireflyCachedResource(
        context,
        type,
        entry.key,
        toJson(entry.value),
        updatedAt: entry.value.updatedAt,
        previous: previous,
      );
    }
    for (final key in existing.keys) {
      if (key.startsWith(keyPrefix) &&
          (excludedPrefix.isEmpty || !key.startsWith(excludedPrefix))) {
        await context.cache.remove(type, key);
      }
    }
  });
}

Future<void> writeFireflyCachedResource(
  SyncContext context,
  FireflyEntityType type,
  String key,
  JsonObject json, {
  DateTime? updatedAt,
  FireflyCachedResource? previous,
}) async {
  if (previous == null ||
      canonicalJson(ResourceCacheRepository.decode(previous)) !=
          canonicalJson(json)) {
    await context.cache.write(type, key, json, modifiedAt: updatedAt);
  }
}

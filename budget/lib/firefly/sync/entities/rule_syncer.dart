import 'dart:async';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/scheduler.dart';

const _rule = FireflyEntityType.rule;
const _group = FireflyEntityType.ruleGroup;

class RuleSyncer extends EntitySyncer {
  const RuleSyncer();

  // The engine refresh and online edits share a queue so a refresh that
  // started before an edit cannot overwrite the edit's response.
  static final _pending = Expando<Future<void>>();

  @override
  FireflyEntityType get type => _rule;

  @override
  Future<void> pull(SyncContext context) => _serialized(context.db, () async {
        if (_inactive(context)) return;
        final api = context.api.rules;
        final groups = await _load(
            context, (page, limit) => api.listGroups(page: page, limit: limit));
        if (groups == null) return;
        final rules = await _load(
            context, (page, limit) => api.list(page: page, limit: limit));
        if (rules == null || _inactive(context)) return;

        await context.db.transaction(() async {
          await _replace(context.cache, _group, groups);
          await _replace(context.cache, _rule, rules);
        });
      });

  Future<FireflyRule> createRule(SyncContext context, JsonObject body) =>
      _save(context, _rule, () => context.api.rules.create(body));

  Future<FireflyRule> updateRule(
          SyncContext context, String id, JsonObject body) =>
      _save(context, _rule, () => context.api.rules.update(id, body));

  Future<void> deleteRule(SyncContext context, String id) =>
      _delete(context, _rule, id, () => context.api.rules.delete(id));

  Future<FireflyRuleGroup> createGroup(SyncContext context, JsonObject body) =>
      _save(context, _group, () => context.api.rules.createGroup(body));

  Future<FireflyRuleGroup> updateGroup(
          SyncContext context, String id, JsonObject body) =>
      _save(context, _group, () => context.api.rules.updateGroup(id, body));

  Future<void> deleteGroup(SyncContext context, String id) =>
      _delete(context, _group, id, () => context.api.rules.deleteGroup(id));

  /// Run a rule or group on the server and reconcile transaction history.
  /// The full pull also sees edits and deletes outside the normal sync window.
  Future<SyncReport> trigger(
    SyncScheduler scheduler,
    String id, {
    bool groups = false,
    DateTime? start,
    DateTime? end,
    List<String> accounts = const [],
  }) async {
    final engine = scheduler.engine;
    final context = engine.context;
    await _serialized(context.db, () async {
      _requireOnline(context);
      final api = context.api.rules;
      final run = groups ? api.triggerGroup : api.trigger;
      await run(id, start: start, end: end, accounts: accounts);
    });
    // syncNow joins an active cycle. Wait for any older cycle before asking
    // for a new one that is guaranteed to start after the server's response.
    while (engine.isRunning) {
      await engine.run();
    }
    return scheduler.syncNow(fullResync: true);
  }

  Future<T> _save<T extends FireflyResource>(SyncContext context,
          FireflyEntityType type, Future<T> Function() send) =>
      _serialized(context.db, () async {
        _requireOnline(context);
        final resource = await send();
        await _write(context.cache, type, resource);
        return resource;
      });

  Future<void> _delete(SyncContext context, FireflyEntityType type, String id,
          Future<void> Function() send) =>
      _serialized(context.db, () async {
        _requireOnline(context);
        try {
          await send();
        } on FireflyNotFound {
          // The resource is already absent on the server.
        }
        await context.db.transaction(() async {
          await context.cache.remove(type, id);
          if (type == _group) {
            for (final row in await context.cache.list(_rule)) {
              final rule =
                  FireflyRule.fromJson(ResourceCacheRepository.decode(row));
              if (rule.ruleGroupId == id) {
                await context.cache.remove(_rule, rule.id);
              }
            }
          }
        });
      });

  static bool _inactive(SyncContext context) =>
      !context.config.mode || context.isCancelled();

  static void _requireOnline(SyncContext context) {
    if (_inactive(context)) throw const FireflyTransportUnavailable();
  }

  static Future<T> _serialized<T>(
      FinanceDatabase db, Future<T> Function() operation) async {
    final previous = _pending[db];
    final done = Completer<void>();
    _pending[db] = done.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      if (identical(_pending[db], done.future)) _pending[db] = null;
      done.complete();
    }
  }

  static Future<Map<String, T>?> _load<T extends FireflyResource>(
      SyncContext context,
      Future<FireflyPage<T>> Function(int, int) fetch) async {
    final items = <String, T>{};
    int? total;
    for (var page = 1; !_inactive(context); page++) {
      final response = await fetch(page, context.config.pageSize);
      if (_inactive(context)) return null;
      total ??= response.total;
      if (response.currentPage != page ||
          response.total != total ||
          response.perPage < 1 ||
          (page > response.totalPages && !(page == 1 && total == 0))) {
        throw const FireflyInvalidPayload();
      }
      for (final item in response.items) {
        if (items.containsKey(item.id)) throw const FireflyInvalidPayload();
        items[item.id] = item;
      }
      if (page >= response.totalPages) {
        if (items.length != total) throw const FireflyInvalidPayload();
        return items;
      }
      if (response.items.length != response.perPage) {
        throw const FireflyInvalidPayload();
      }
    }
    return null;
  }

  static Future<void> _replace(ResourceCacheRepository cache,
      FireflyEntityType type, Map<String, FireflyResource> resources) async {
    final keys = {
      for (final id in resources.keys)
        ResourceCacheRepository.resourcePk(type, id),
    };
    final prefixLength = type.name.length + 1;
    for (final row in await cache.list(type)) {
      if (!keys.contains(row.resourcePk)) {
        await cache.remove(type, row.resourcePk.substring(prefixLength));
      }
    }
    for (final resource in resources.values) {
      await _write(cache, type, resource);
    }
  }

  static Future<void> _write(ResourceCacheRepository cache,
          FireflyEntityType type, FireflyResource resource) =>
      cache.write(
          type,
          resource.id,
          {
            'id': resource.id,
            'attributes': resource.attributes,
          },
          modifiedAt: resource.updatedAt);
}

import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/currency.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';

class CurrencySyncer extends EntitySyncer {
  const CurrencySyncer();

  static final _pending = Expando<Future<void>>();

  @override
  FireflyEntityType get type => FireflyEntityType.currency;

  @override
  Future<void> pull(SyncContext context) => _run(context);

  Future<void> setEnabled(SyncContext context, String code,
          {required bool enabled}) =>
      _run(
        context,
        () => enabled
            ? context.api.currencies.enable(code.trim())
            : context.api.currencies.disable(code.trim()),
      );

  Future<void> setPrimary(SyncContext context, String code) =>
      _run(context, () => context.api.currencies.setPrimary(code.trim()));

  // An automatic pull and currency management actions share the same cache.
  Future<void> _run(SyncContext context, [Future<void> Function()? change]) {
    final previous = _pending[context.db] ?? Future<void>.value();
    final next = previous.then((_) async {
      if (!context.config.mode || context.isCancelled()) return;
      await change?.call();
      if (!context.isCancelled()) await _refresh(context);
    });
    _pending[context.db] =
        next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _refresh(SyncContext context) async {
    final currencies = <String, FireflyCurrency>{};
    var seen = 0;
    int? total;
    for (var page = 1; !context.isCancelled(); page++) {
      final result = await context.api.currencies
          .list(page: page, limit: context.config.pageSize);
      total ??= result.total;
      if (result.currentPage != page ||
          result.total != total ||
          (result.items.isEmpty && page < result.totalPages)) {
        throw const FireflyInvalidPayload();
      }
      for (final currency in result.items) {
        currencies[_code(currency)] = currency;
      }
      seen += result.items.length;
      if (page >= result.totalPages) {
        if (seen != result.total) throw const FireflyInvalidPayload();
        break;
      }
    }
    if (context.isCancelled()) return;

    String? primaryCode;
    if (currencies.isNotEmpty) {
      final primary = await context.api.currencies.primary();
      primaryCode = _code(primary);
      currencies[primaryCode] = primary;
    }
    if (context.isCancelled()) return;

    final cache = context.cache;
    await context.db.transaction(() async {
      if (context.isCancelled()) return;
      final existing = {
        for (final row in await cache.list(type)) row.resourcePk: row,
      };
      for (final MapEntry(key: code, value: currency) in currencies.entries) {
        final attributes = {
          ...currency.attributes,
          'code': code,
          'remote_id': currency.id,
          'primary': code == primaryCode,
        };
        final row =
            existing.remove(ResourceCacheRepository.resourcePk(type, code));
        if (row?.json != jsonEncode(attributes)) {
          await cache.write(type, code, attributes,
              modifiedAt: currency.updatedAt);
        }
      }
      for (final row in existing.values) {
        await cache.remove(
            type, row.resourcePk.substring('${type.name}:'.length));
      }
    });
  }

  String _code(FireflyCurrency currency) {
    final code = currency.code?.trim().toLowerCase();
    if (code == null || code.isEmpty) throw const FireflyInvalidPayload();
    return code;
  }
}

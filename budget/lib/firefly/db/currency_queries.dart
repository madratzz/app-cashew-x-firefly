import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/currency.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:flutter/services.dart';

const _currency = FireflyEntityType.currency;

extension FireflyCurrencyQueries on FinanceDatabase {
  Future<FireflyCachedResource?> fireflyCurrency(String code) =>
      ResourceCacheRepository(this).read(_currency, code.trim().toLowerCase());

  Future<List<FireflyCachedCurrency>> fireflyCurrencies() async =>
      _decodeCurrencies(await ResourceCacheRepository(this).list(_currency));

  Stream<List<FireflyCachedCurrency>> watchFireflyCurrencies() =>
      ResourceCacheRepository(this).watch(_currency).map(_decodeCurrencies);

  /// Server currencies absent from Cashew's bundled catalog.
  Stream<List<FireflyCachedCurrency>> watchFireflyCustomCurrencies() async* {
    final bundled = jsonDecode(await rootBundle
        .loadString('assets/static/generated/currencies.json')) as JsonObject;
    yield* watchFireflyCurrencies().map(
      (currencies) =>
          currencies.where((row) => !bundled.containsKey(row.code)).toList(),
    );
  }

  Future<FireflyCachedCurrency?> fireflyPrimaryCurrency() async {
    for (final currency in await fireflyCurrencies()) {
      if (currency.primary == true) return currency;
    }
    return null;
  }
}

class FireflyCachedCurrency extends FireflyCurrency {
  factory FireflyCachedCurrency.fromCache(FireflyCachedResource row) {
    final attributes = ResourceCacheRepository.decode(row);
    return FireflyCachedCurrency._(
      id: attributes['remote_id'] as String,
      attributes: attributes,
    );
  }

  const FireflyCachedCurrency._({required super.id, required super.attributes});

  String? get symbol => attributes['symbol'] as String?;
}

List<FireflyCachedCurrency> _decodeCurrencies(
        List<FireflyCachedResource> rows) =>
    rows.map(FireflyCachedCurrency.fromCache).toList()
      ..sort((a, b) => a.code!.compareTo(b.code!));

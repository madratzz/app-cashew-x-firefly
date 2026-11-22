import 'package:budget/firefly/api/models/exchange_rate.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class ExchangeRatesApi extends FireflyResourceApi<FireflyExchangeRate> {
  const ExchangeRatesApi(super.transport);

  static const _path = '/exchange-rates';

  String _byId(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyExchangeRate>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async {
    final result = await transport.getPage(_path, query: {
      ...query,
      'page': '$page',
      'limit': '$limit',
    });
    return result.map(FireflyExchangeRate.fromJson);
  }

  @override
  Future<FireflyExchangeRate> get(String id) async =>
      FireflyExchangeRate.fromJson(await transport.get(_byId(id)));

  @override
  Future<FireflyExchangeRate> create(JsonObject body) async =>
      FireflyExchangeRate.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyExchangeRate> update(String id, JsonObject body) async =>
      FireflyExchangeRate.fromJson(await transport.put(_byId(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_byId(id));

  /// Returns units of each lowercase currency code per one unit of baseCode.
  /// Uses the latest applicable date per pair, preferring direct rates on ties.
  Future<Map<String, double>> latestRates(
    String baseCode, {
    required DateTime onOrBefore,
    int limit = 100,
  }) async {
    final base = baseCode.trim().toLowerCase();
    if (base.isEmpty) throw ArgumentError.value(baseCode, 'baseCode');
    final cutoff =
        DateTime.utc(onOrBefore.year, onOrBefore.month, onOrBefore.day);
    final rates = <String, ({DateTime date, double rate, bool direct})>{};
    var seen = 0;
    int? total;
    for (var page = 1;; page++) {
      final result = await list(page: page, limit: limit);
      total ??= result.total;
      if (result.currentPage != page ||
          result.total != total ||
          (result.items.isEmpty && page < result.totalPages)) {
        throw const FireflyInvalidPayload();
      }
      for (final row in result.items) {
        final from = row.fromCurrencyCode!;
        final to = row.toCurrencyCode!;
        final date = row.date!;
        if ((from != base && to != base) ||
            from == to ||
            date.isAfter(cutoff)) {
          continue;
        }
        final direct = from == base;
        final code = direct ? to : from;
        final rate = direct ? row.rate! : 1 / row.rate!;
        if (!rate.isFinite) continue;
        final previous = rates[code];
        if (previous == null ||
            date.isAfter(previous.date) ||
            (date == previous.date && direct && !previous.direct)) {
          rates[code] = (date: date, rate: rate, direct: direct);
        }
      }
      seen += result.items.length;
      if (page >= result.totalPages) {
        if (seen != result.total) throw const FireflyInvalidPayload();
        return {
          base: 1,
          for (final entry in rates.entries) entry.key: entry.value.rate,
        };
      }
    }
  }
}

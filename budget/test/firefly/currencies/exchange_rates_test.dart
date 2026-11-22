import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';

const _path = '/exchange-rates';

void main() {
  test('reads a dated, paginated rate map with direct and inverse pairs',
      () async {
    final transport = FakeFireflyTransport(maxPageSize: 2);
    final rates = FireflyApi(transport).exchangeRates;
    for (final (id, from, to, date, rate) in [
      ('1', 'USD', 'EUR', '2026-04-01', '1.1'),
      ('2', 'EUR', 'USD', '2026-04-02', '2'),
      ('3', 'USD', 'EUR', '2026-04-02', '0.9'),
      ('4', 'USD', 'EUR', '2026-04-03', '1.5'),
      ('5', 'JPY', 'USD', '2026-04-02', '0.01'),
      ('6', 'GBP', 'EUR', '2026-04-02', '1.5'),
    ]) {
      transport.seed(_path, id, _attributes(from, to, date, rate));
    }
    final page = await rates.list();
    expect((page.total, page.perPage, page.totalPages), (6, 2, 3));
    final first = page.items.first;
    expect((first.id, first.fromCurrencyCode, first.toCurrencyCode),
        ('1', 'usd', 'eur'));
    expect((first.date, first.rate), (DateTime.utc(2026, 4, 1), 1.1));
    expect((await rates.get('3')).id, '3');

    expect(
      await rates.latestRates(' USD ', onOrBefore: DateTime(2026, 4, 2)),
      {'usd': 1, 'eur': 0.9, 'jpy': 100},
    );
    expect(
      await rates.latestRates('usd', onOrBefore: DateTime(2026, 4, 1)),
      {'usd': 1, 'eur': 1.1},
    );
  });

  test('writes the Firefly request shape and reads the returned resource',
      () async {
    final transport = _ExchangeRatesServer();
    final rates = FireflyApi(transport).exchangeRates;
    final created = await rates.create(const {
      'from': 'USD',
      'to': 'EUR',
      'date': '2026-04-01',
      'rate': '0.92',
    });
    expect(transport.requests.single.path, _path);
    expect((created.fromCurrencyCode, created.toCurrencyCode, created.rate),
        ('usd', 'eur', 0.92));

    final updated = await rates
        .update(created.id, const {'date': '2026-04-02', 'rate': '0.95'});
    expect(transport.requests.last.path, '$_path/${created.id}');
    expect((updated.date, updated.rate), (DateTime.utc(2026, 4, 2), 0.95));
    await rates.delete(updated.id);
    expect(await rates.list().then((page) => page.items), isEmpty);
  });

  test('rejects invalid rates instead of supplying partial conversions',
      () async {
    final transport = FakeFireflyTransport();
    transport.seed(_path, '1', _attributes('USD', 'EUR', '2026-04-01', 'NaN'));
    final rates = FireflyApi(transport).exchangeRates;
    await expectLater(
      rates.latestRates('USD', onOrBefore: DateTime(2026, 4, 1)),
      throwsA(isA<FireflyInvalidPayload>()),
    );
  });
}

JsonObject _attributes(String from, String to, String date, String rate) => {
      'from_currency_code': from,
      'to_currency_code': to,
      'date': '${date}T00:00:00+10:00',
      'rate': rate,
    };

class _ExchangeRatesServer extends FakeFireflyTransport {
  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final result = await super.post(path, body, query: query);
    return _replaceAttributes(
        result,
        _attributes(body['from']! as String, body['to']! as String,
            body['date']! as String, body['rate']! as String));
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final result = await super.put(path, body, query: query);
    final previous = result['attributes']! as JsonObject;
    return _replaceAttributes(
        result,
        _attributes(
          previous['from_currency_code']! as String,
          previous['to_currency_code']! as String,
          body['date']! as String,
          body['rate']! as String,
        ));
  }

  JsonObject _replaceAttributes(JsonObject resource, JsonObject attributes) {
    seed(_path, resource['id']! as String, attributes);
    return {...resource, 'attributes': attributes};
  }
}

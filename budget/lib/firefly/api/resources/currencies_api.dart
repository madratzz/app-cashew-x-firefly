import 'package:budget/firefly/api/models/currency.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class CurrenciesApi extends FireflyResourceApi<FireflyCurrency> {
  const CurrenciesApi(super.transport);

  static const _path = '/currencies';

  String _byCode(String code) =>
      '$_path/${Uri.encodeComponent(code.toUpperCase())}';

  @override
  Future<FireflyPage<FireflyCurrency>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async {
    final result = await transport.getPage(_path, query: {
      ...query,
      'page': '$page',
      'limit': '$limit',
    });
    return result.map(FireflyCurrency.fromJson);
  }

  @override
  Future<FireflyCurrency> get(String id) async =>
      FireflyCurrency.fromJson(await transport.get(_byCode(id)));

  @override
  Future<FireflyCurrency> create(JsonObject body) async =>
      FireflyCurrency.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyCurrency> update(String id, JsonObject body) async =>
      FireflyCurrency.fromJson(await transport.put(_byCode(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_byCode(id));

  Future<FireflyCurrency> primary() async =>
      FireflyCurrency.fromJson(await transport.get('$_path/primary'));

  Future<void> enable(String code) async {
    await transport.post('${_byCode(code)}/enable', const {});
  }

  Future<void> disable(String code) async {
    await transport.post('${_byCode(code)}/disable', const {});
  }

  Future<void> setPrimary(String code) async {
    await transport.post('${_byCode(code)}/primary', const {});
  }
}

import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class PiggyBanksApi extends FireflyResourceApi<FireflyPiggyBank> {
  const PiggyBanksApi(super.transport);

  static const _path = '/piggy-banks';

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyPiggyBank>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyPiggyBank.fromJson);

  @override
  Future<FireflyPiggyBank> get(String id) async =>
      FireflyPiggyBank.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyPiggyBank> create(JsonObject body) async =>
      FireflyPiggyBank.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyPiggyBank> update(String id, JsonObject body) async =>
      FireflyPiggyBank.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  Future<FireflyPage<JsonObject>> listEvents(String id,
          {int page = 1, int limit = 100}) =>
      transport.getPage('${_item(id)}/events', query: {
        'page': '$page',
        'limit': '$limit',
      });
}

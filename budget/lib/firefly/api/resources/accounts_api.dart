import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class AccountsApi extends FireflyResourceApi<FireflyAccount> {
  const AccountsApi(super.transport);

  static const _path = '/accounts';

  @override
  Future<FireflyPage<FireflyAccount>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
    String? type,
  }) async {
    final result = await transport.getPage(_path, query: {
      ...query,
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
    });
    return result.map(FireflyAccount.fromResource);
  }

  @override
  Future<FireflyAccount> get(String id) async =>
      FireflyAccount.fromResource(await transport.get(_itemPath(id)));

  @override
  Future<FireflyAccount> create(JsonObject body) async =>
      FireflyAccount.fromResource(await transport.post(_path, body));

  @override
  Future<FireflyAccount> update(String id, JsonObject body) async =>
      FireflyAccount.fromResource(await transport.put(_itemPath(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_itemPath(id));

  String _itemPath(String id) => '$_path/${Uri.encodeComponent(id)}';
}

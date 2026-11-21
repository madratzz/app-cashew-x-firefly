import 'package:budget/firefly/api/models/category.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class CategoriesApi extends FireflyResourceApi<FireflyCategory> {
  const CategoriesApi(super.transport);

  static const _path = '/categories';

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyCategory>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyCategory.fromJson);

  @override
  Future<FireflyCategory> get(String id) async =>
      FireflyCategory.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyCategory> create(JsonObject body) async =>
      FireflyCategory.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyCategory> update(String id, JsonObject body) async =>
      FireflyCategory.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));
}

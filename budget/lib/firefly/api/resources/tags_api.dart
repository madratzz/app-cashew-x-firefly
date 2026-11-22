import 'package:budget/firefly/api/models/tag.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class TagsApi extends FireflyResourceApi<FireflyTag> {
  const TagsApi(super.transport);

  static const _path = '/tags';

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyTag>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyTag.fromJson);

  @override
  Future<FireflyTag> get(String id) async =>
      FireflyTag.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyTag> create(JsonObject body) async =>
      FireflyTag.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyTag> update(String id, JsonObject body) async =>
      FireflyTag.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));
}

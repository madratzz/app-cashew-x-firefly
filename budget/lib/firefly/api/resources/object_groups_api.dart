import 'package:budget/firefly/api/models/object_group.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class ObjectGroupsApi extends FireflyResourceApi<FireflyObjectGroup> {
  const ObjectGroupsApi(super.transport);

  static const _path = '/object-groups';

  @override
  Future<FireflyPage<FireflyObjectGroup>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path,
              query: {...query, 'page': '$page', 'limit': '$limit'}))
          .map(FireflyObjectGroup.fromJson);

  @override
  Future<FireflyObjectGroup> get(String id) async =>
      FireflyObjectGroup.fromJson(await transport.get(_item(id)));

  /// Groups are created by assigning a title to a bill or piggy bank.
  @override
  Future<FireflyObjectGroup> create(JsonObject body) async =>
      throw const FireflyValidation(
          'Assign the group to a bill or piggy bank.');

  @override
  Future<FireflyObjectGroup> update(String id, JsonObject body) async =>
      FireflyObjectGroup.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';
}

import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class BillsApi extends FireflyResourceApi<FireflyBill> {
  const BillsApi(super.transport);

  static const _path = '/bills';

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyBill>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyBill.fromJson);

  @override
  Future<FireflyBill> get(String id) async =>
      FireflyBill.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyBill> create(JsonObject body) async =>
      FireflyBill.fromJson(await transport.post(
          _path, FireflyBill(id: '', attributes: body).toWriteJson()));

  @override
  Future<FireflyBill> update(String id, JsonObject body) async =>
      FireflyBill.fromJson(await transport.put(
          _item(id), FireflyBill(id: id, attributes: body).toWriteJson()));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));
}

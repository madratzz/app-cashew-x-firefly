import 'package:budget/firefly/api/models/transaction_link.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class TransactionLinksApi extends FireflyResourceApi<FireflyTransactionLink> {
  const TransactionLinksApi(super.transport);

  static const _path = '/transaction-links';

  @override
  Future<FireflyPage<FireflyTransactionLink>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path,
              query: {...query, 'page': '$page', 'limit': '$limit'}))
          .map(FireflyTransactionLink.fromJson);

  @override
  Future<FireflyTransactionLink> get(String id) async =>
      FireflyTransactionLink.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyTransactionLink> create(JsonObject body) async =>
      FireflyTransactionLink.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyTransactionLink> update(String id, JsonObject body) async =>
      FireflyTransactionLink.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  Future<FireflyPage<JsonObject>> listTypes({int page = 1, int limit = 100}) =>
      transport
          .getPage('/link-types', query: {'page': '$page', 'limit': '$limit'});

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';
}

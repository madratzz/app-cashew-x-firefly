import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class TransactionsApi extends FireflyResourceApi<FireflyTransaction> {
  const TransactionsApi(super.transport);

  static const _path = '/transactions';
  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyTransaction>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
    String type = 'all',
    DateTime? start,
    DateTime? end,
  }) async =>
      (await transport.getPage(_path, query: {
        'type': type,
        ...query,
        'page': '$page',
        'limit': '$limit',
        if (start != null) 'start': formatFireflyDate(start),
        if (end != null) 'end': formatFireflyDate(end),
      }))
          .map(FireflyTransaction.fromJson);

  @override
  Future<FireflyTransaction> get(String id) async =>
      FireflyTransaction.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyTransaction> create(JsonObject body) async =>
      FireflyTransaction.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyTransaction> update(String id, JsonObject body) async =>
      FireflyTransaction.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  Future<void> deleteJournal(String journalId) => transport
      .delete('/transaction-journals/${Uri.encodeComponent(journalId)}');
}

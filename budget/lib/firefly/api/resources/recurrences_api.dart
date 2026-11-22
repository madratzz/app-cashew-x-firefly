import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class RecurrencesApi extends FireflyResourceApi<FireflyRecurrence> {
  const RecurrencesApi(super.transport);

  static const _path = '/recurrences';

  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyRecurrence>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyRecurrence.fromJson);

  @override
  Future<FireflyRecurrence> get(String id) async =>
      FireflyRecurrence.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyRecurrence> create(JsonObject body) async =>
      FireflyRecurrence.fromJson(await transport.post(
          _path, FireflyRecurrence(id: '', attributes: body).toWriteJson()));

  @override
  Future<FireflyRecurrence> update(String id, JsonObject body) async =>
      FireflyRecurrence.fromJson(await transport.put(
          _item(id),
          FireflyRecurrence(id: id, attributes: body)
              .toWriteJson(updating: true)));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  /// Create now for the selected server occurrence.
  Future<FireflyTransaction?> trigger(String id, {DateTime? date}) async {
    final occurrence =
        date ?? (await get(id)).nextOccurrence(from: DateTime.now());
    if (occurrence == null) return null;
    final result = await transport.post(
      '${_item(id)}/trigger',
      const {},
      query: {'date': formatFireflyDate(occurrence)},
    );
    final data = result['data'];
    if (data is! List<Object?>) throw const FireflyInvalidPayload();
    if (data.isEmpty) return null;
    if (data.length != 1 || data.single is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyTransaction.fromJson(data.single as JsonObject);
  }
}

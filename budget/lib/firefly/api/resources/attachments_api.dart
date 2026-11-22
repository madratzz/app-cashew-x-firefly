import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class AttachmentsApi extends FireflyResourceApi<FireflyAttachment> {
  const AttachmentsApi(super.transport);

  static const _path = '/attachments';
  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';

  @override
  Future<FireflyPage<FireflyAttachment>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path,
              query: {...query, 'page': '$page', 'limit': '$limit'}))
          .map(FireflyAttachment.fromJson);

  @override
  Future<FireflyAttachment> get(String id) async =>
      FireflyAttachment.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyAttachment> create(JsonObject body) async {
    final client = transport;
    final resource = client is HttpFireflyTransport
        ? await client.post(_path, body, retry: false)
        : await client.post(_path, body);
    return FireflyAttachment.fromJson(resource);
  }

  @override
  Future<FireflyAttachment> update(String id, JsonObject body) async =>
      FireflyAttachment.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  Future<void> upload(String id, Stream<List<int>> bytes, {int? length}) =>
      transport.upload('${_item(id)}/upload', bytes, length: length);

  Future<Stream<List<int>>> download(String id) =>
      transport.download('${_item(id)}/download');
}

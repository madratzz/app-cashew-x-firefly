import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class AttachmentsApi extends FireflyResourceApi<FireflyAttachment> {
  const AttachmentsApi(super.transport);

  Future<void> upload(String id, Stream<List<int>> bytes,
          {int? length}) async =>
      throw const FireflyTransportUnavailable();

  Future<Stream<List<int>>> download(String id) async =>
      throw const FireflyTransportUnavailable();
}

import 'package:budget/firefly/api/models/transaction_link.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class TransactionLinksApi extends FireflyResourceApi<FireflyTransactionLink> {
  const TransactionLinksApi(super.transport);

  Future<FireflyPage<JsonObject>> listTypes(
          {int page = 1, int limit = 100}) async =>
      throw const FireflyTransportUnavailable();
}

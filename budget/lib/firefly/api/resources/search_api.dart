import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';

class SearchApi {
  const SearchApi(this.transport);
  final FireflyTransport transport;

  Future<FireflyPage<FireflyTransaction>> transactions(String search,
          {int page = 1, int limit = 100}) async =>
      throw const FireflyTransportUnavailable();
}

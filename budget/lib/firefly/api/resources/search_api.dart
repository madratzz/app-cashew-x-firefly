import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';

class SearchApi {
  const SearchApi(this.transport);
  final FireflyTransport transport;

  Future<FireflyPage<FireflyTransaction>> transactions(
    String search, {
    int page = 1,
    int limit = 100,
  }) async =>
      (await transport.getPage('/search/transactions', query: {
        'query': search,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyTransaction.fromJson);
}

import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class TransactionsApi extends FireflyResourceApi<FireflyTransaction> {
  const TransactionsApi(super.transport);

  @override
  Future<FireflyPage<FireflyTransaction>> list(
          {int page = 1,
          int limit = 100,
          FireflyQuery query = const {},
          String type = 'all',
          DateTime? start,
          DateTime? end}) async =>
      throw const FireflyTransportUnavailable();

  Future<void> deleteJournal(String journalId) async =>
      throw const FireflyTransportUnavailable();
}

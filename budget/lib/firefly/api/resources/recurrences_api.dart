import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class RecurrencesApi extends FireflyResourceApi<FireflyRecurrence> {
  const RecurrencesApi(super.transport);

  Future<FireflyTransaction?> trigger(String id, {DateTime? date}) async =>
      throw const FireflyTransportUnavailable();
}

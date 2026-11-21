import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class PiggyBanksApi extends FireflyResourceApi<FireflyPiggyBank> {
  const PiggyBanksApi(super.transport);

  Future<FireflyPage<JsonObject>> listEvents(String id,
          {int page = 1, int limit = 100}) async =>
      throw const FireflyTransportUnavailable();
}

import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class AccountsApi extends FireflyResourceApi<FireflyAccount> {
  const AccountsApi(super.transport);

  @override
  Future<FireflyPage<FireflyAccount>> list(
          {int page = 1,
          int limit = 100,
          FireflyQuery query = const {},
          String? type}) async =>
      throw const FireflyTransportUnavailable();
}

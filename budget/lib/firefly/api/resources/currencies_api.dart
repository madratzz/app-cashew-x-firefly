import 'package:budget/firefly/api/models/currency.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class CurrenciesApi extends FireflyResourceApi<FireflyCurrency> {
  const CurrenciesApi(super.transport);

  Future<FireflyCurrency> primary() async =>
      throw const FireflyTransportUnavailable();

  Future<void> enable(String code) async =>
      throw const FireflyTransportUnavailable();

  Future<void> disable(String code) async =>
      throw const FireflyTransportUnavailable();

  Future<void> setPrimary(String code) async =>
      throw const FireflyTransportUnavailable();
}

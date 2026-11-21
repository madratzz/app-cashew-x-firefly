import 'package:budget/firefly/api/models/available_budget.dart';
import 'package:budget/firefly/api/models/budget.dart';
import 'package:budget/firefly/api/models/budget_limit.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class BudgetsApi extends FireflyResourceApi<FireflyBudget> {
  const BudgetsApi(super.transport);

  Future<FireflyPage<FireflyBudgetLimit>> listLimits(String budgetId,
          {int page = 1, int limit = 100}) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyBudgetLimit> getLimit(String budgetId, String limitId) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyBudgetLimit> createLimit(
          String budgetId, JsonObject body) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyBudgetLimit> updateLimit(
          String budgetId, String limitId, JsonObject body) async =>
      throw const FireflyTransportUnavailable();

  Future<void> deleteLimit(String budgetId, String limitId) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyPage<FireflyAvailableBudget>> listAvailable(
          {int page = 1,
          int limit = 100,
          DateTime? start,
          DateTime? end}) async =>
      throw const FireflyTransportUnavailable();
}

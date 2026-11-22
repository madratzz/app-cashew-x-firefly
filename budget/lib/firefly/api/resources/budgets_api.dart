import 'package:budget/firefly/api/models/available_budget.dart';
import 'package:budget/firefly/api/models/budget.dart';
import 'package:budget/firefly/api/models/budget_limit.dart';
import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class BudgetsApi extends FireflyResourceApi<FireflyBudget> {
  const BudgetsApi(super.transport);

  static const _path = '/budgets';
  String _item(String id) => '$_path/${Uri.encodeComponent(id)}';
  String _limits(String id) => '${_item(id)}/limits';
  String _limit(String budgetId, String limitId) =>
      '${_limits(budgetId)}/${Uri.encodeComponent(limitId)}';

  @override
  Future<FireflyPage<FireflyBudget>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyBudget.fromJson);

  @override
  Future<FireflyBudget> get(String id) async =>
      FireflyBudget.fromJson(await transport.get(_item(id)));

  @override
  Future<FireflyBudget> create(JsonObject body) async =>
      FireflyBudget.fromJson(await transport.post(_path, body));

  @override
  Future<FireflyBudget> update(String id, JsonObject body) async =>
      FireflyBudget.fromJson(await transport.put(_item(id), body));

  @override
  Future<void> delete(String id) => transport.delete(_item(id));

  Future<FireflyPage<FireflyBudgetLimit>> listLimits(String budgetId,
          {int page = 1, int limit = 100}) async =>
      (await transport.getPage(_limits(budgetId),
              query: {'page': '$page', 'limit': '$limit'}))
          .map(FireflyBudgetLimit.fromJson);

  Future<FireflyBudgetLimit> getLimit(String budgetId, String limitId) async =>
      FireflyBudgetLimit.fromJson(
          await transport.get(_limit(budgetId, limitId)));

  Future<FireflyBudgetLimit> createLimit(
          String budgetId, JsonObject body) async =>
      FireflyBudgetLimit.fromJson(
          await transport.post(_limits(budgetId), body));

  Future<FireflyBudgetLimit> updateLimit(
          String budgetId, String limitId, JsonObject body) async =>
      FireflyBudgetLimit.fromJson(
          await transport.put(_limit(budgetId, limitId), body));

  Future<void> deleteLimit(String budgetId, String limitId) =>
      transport.delete(_limit(budgetId, limitId));

  Future<FireflyPage<FireflyAvailableBudget>> listAvailable(
          {int page = 1,
          int limit = 100,
          DateTime? start,
          DateTime? end}) async =>
      (await transport.getPage('/available-budgets', query: {
        'page': '$page',
        'limit': '$limit',
        if (start != null) 'start': formatFireflyDate(start),
        if (end != null) 'end': formatFireflyDate(end),
      }))
          .map(FireflyAvailableBudget.fromJson);
}

/// Collects a nested or read-only listing before using it for delete detection.
Future<({List<T> items, bool complete})>
    readBudgetPages<T extends FireflyResource>(
        Future<FireflyPage<T>> Function(int) fetch) async {
  final seen = <String, T>{};
  int? total;
  for (var page = 1;; page++) {
    final result = await fetch(page);
    total ??= result.total;
    for (final item in result.items) {
      if (seen.containsKey(item.id)) {
        return (items: seen.values.toList(), complete: false);
      }
      seen[item.id] = item;
    }
    if (result.currentPage != page ||
        result.perPage < 1 ||
        result.total != total ||
        result.items.length > result.perPage ||
        (page > result.totalPages && !(page == 1 && total == 0))) {
      return (items: seen.values.toList(), complete: false);
    }
    if (page >= result.totalPages || result.items.isEmpty) {
      return (
        items: seen.values.toList(),
        complete: page >= result.totalPages && seen.length == total,
      );
    }
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';

extension FireflyRuleQueries on FinanceDatabase {
  Future<List<FireflyCachedResource>> fireflyRules(
          {bool groups = false}) async =>
      _inRuleOrder(await ResourceCacheRepository(this).list(_ruleType(groups)));

  Stream<List<FireflyCachedResource>> watchFireflyRules(
          {bool groups = false}) =>
      ResourceCacheRepository(this).watch(_ruleType(groups)).map(_inRuleOrder);
}

FireflyEntityType _ruleType(bool groups) =>
    groups ? FireflyEntityType.ruleGroup : FireflyEntityType.rule;

List<FireflyCachedResource> _inRuleOrder(List<FireflyCachedResource> rows) {
  final ordered = [
    for (final row in rows)
      (
        row: row,
        order: (ResourceCacheRepository.decode(row)['attributes']
                as Map<String, Object?>)['order'] as int? ??
            0
      ),
  ]..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0
          ? byOrder
          : a.row.resourcePk.compareTo(b.row.resourcePk);
    });
  return [for (final item in ordered) item.row];
}

import 'package:budget/database/tables.dart';

extension FireflyRuleQueries on FinanceDatabase {
  Future<List<FireflyCachedResource>> fireflyRules(
          {bool groups = false}) async =>
      const [];
}

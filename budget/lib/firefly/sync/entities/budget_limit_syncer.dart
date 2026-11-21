import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class BudgetLimitSyncer extends EntitySyncer {
  const BudgetLimitSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.budgetLimit;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.budget,
      };
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class BudgetSyncer extends EntitySyncer {
  const BudgetSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.budget;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
      };
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class RuleSyncer extends EntitySyncer {
  const RuleSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.rule;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.transaction,
      };
}

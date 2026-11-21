import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class RecurrenceSyncer extends EntitySyncer {
  const RecurrenceSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.recurrence;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.walletAccount,
        FireflyEntityType.category,
      };
}

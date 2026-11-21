import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class TransactionSyncer extends EntitySyncer {
  const TransactionSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.transaction;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
        FireflyEntityType.walletAccount,
        FireflyEntityType.liabilityAccount,
        FireflyEntityType.payeeAccount,
        FireflyEntityType.category,
        FireflyEntityType.tag,
        FireflyEntityType.budget,
        FireflyEntityType.bill,
        FireflyEntityType.piggyBank,
      };
}

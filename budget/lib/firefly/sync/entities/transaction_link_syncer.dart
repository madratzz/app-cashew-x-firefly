import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class TransactionLinkSyncer extends EntitySyncer {
  const TransactionLinkSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.transactionLink;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.transaction,
      };
}

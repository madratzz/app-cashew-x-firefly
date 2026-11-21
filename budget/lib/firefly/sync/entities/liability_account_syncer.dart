import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class LiabilityAccountSyncer extends EntitySyncer {
  const LiabilityAccountSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.liabilityAccount;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
        FireflyEntityType.walletAccount,
      };
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class WalletAccountSyncer extends EntitySyncer {
  const WalletAccountSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.walletAccount;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
      };
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class PiggyBankSyncer extends EntitySyncer {
  const PiggyBankSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.piggyBank;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.walletAccount,
      };
}

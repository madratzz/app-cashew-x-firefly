import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class PayeeAccountSyncer extends EntitySyncer {
  const PayeeAccountSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.payeeAccount;
}

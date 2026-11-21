import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class BillSyncer extends EntitySyncer {
  const BillSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.bill;
}

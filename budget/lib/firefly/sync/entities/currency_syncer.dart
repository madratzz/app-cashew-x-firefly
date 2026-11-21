import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class CurrencySyncer extends EntitySyncer {
  const CurrencySyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.currency;
}

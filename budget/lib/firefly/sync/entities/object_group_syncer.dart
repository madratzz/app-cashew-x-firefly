import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class ObjectGroupSyncer extends EntitySyncer {
  const ObjectGroupSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.objectGroup;
}

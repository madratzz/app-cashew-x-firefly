import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class TagSyncer extends EntitySyncer {
  const TagSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.tag;
}

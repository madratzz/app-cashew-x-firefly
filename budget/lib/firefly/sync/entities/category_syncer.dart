import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class CategorySyncer extends EntitySyncer {
  const CategorySyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.category;
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/contracts.dart';

class AttachmentSyncer extends EntitySyncer {
  const AttachmentSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.attachment;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.transaction,
      };
}

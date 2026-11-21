import 'package:budget/firefly/sync/contracts.dart';

/// WP-38 supplies optional local attribute roaming.
class FireflyMetaRoaming {
  const FireflyMetaRoaming(this.context);

  final SyncContext context;

  Future<void> pull() async {}
  Future<void> push() async {}
}

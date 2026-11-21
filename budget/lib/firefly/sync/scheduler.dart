import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';

/// WP-04 implements foreground scheduling.
class SyncScheduler {
  const SyncScheduler(this.engine);

  final SyncEngine engine;

  void start() {}
  void resume() {}
  void pause() {}
  void localWrite() {}
  Future<SyncReport> syncNow({bool fullResync = false}) =>
      engine.run(fullResync: fullResync);
  void dispose() {}
}

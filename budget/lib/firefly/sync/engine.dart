import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/registry.dart';

/// WP-04 replaces the no-op engine.
class SyncEngine {
  const SyncEngine(this.context,
      {this.syncers = entitySyncers,
      this.contributors = transactionContributors});

  final SyncContext context;
  final List<EntitySyncer> syncers;
  final List<TransactionContributor> contributors;

  bool get isRunning => false;
  Stream<SyncProgress> get progress => const Stream<SyncProgress>.empty();
  Future<SyncReport> run({bool fullResync = false}) async => const SyncReport();
  void cancel() {}
  Future<void> dispose() async {}
}

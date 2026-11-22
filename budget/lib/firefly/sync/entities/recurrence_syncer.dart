import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/recurrences_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/bill_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';

class RecurrenceSyncer extends BillRecurrenceSyncer<FireflyRecurrence> {
  const RecurrenceSyncer();

  @override
  FireflyEntityType get type => FireflyEntityType.recurrence;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.walletAccount,
        FireflyEntityType.category,
      };

  @override
  RecurrencesApi api(SyncContext context) => context.api.recurrences;

  @override
  JsonObject writable(JsonObject attributes) =>
      FireflyRecurrence(id: '', attributes: attributes)
          .toWriteJson(updating: true);

  @override
  String get keyField => 'title';

  /// Ask Firefly to generate a group, then import that group through the
  /// regular transaction syncer. [pk] is the local cache primary key.
  Future<FireflyTransaction?> trigger(
    SyncContext context,
    String pk, {
    DateTime? date,
  }) async {
    if (!context.config.mode || context.isCancelled()) return null;
    final mapping = await context.idMap.byLocal(type, pk);
    if (mapping == null ||
        IdMapRepository.isProvisional(mapping) ||
        mapping.state == FireflySyncState.pendingDelete ||
        mapping.state == FireflySyncState.localOnly) {
      throw const FireflyNotFound();
    }
    final recurrences = api(context);
    final occurrence = date ??
        (await recurrences.get(mapping.remoteId))
            .nextOccurrence(from: context.now().toLocal());
    if (occurrence == null || context.isCancelled()) return null;
    final created =
        await recurrences.trigger(mapping.remoteId, date: occurrence);
    if (created == null) return null;

    // The reread queue belongs to a sync cycle. Use a private queue so this
    // action doesn't drain an in-flight cycle's transaction writes.
    final import = SyncContext(
      db: context.db,
      api: context.api,
      config: context.config,
      now: context.now,
      isCancelled: context.isCancelled,
    );
    import.pushedTransactionIds.add(created.id);
    await const TransactionSyncer().rereadPushed(import);
    return created;
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';

class BillContributor extends TransactionContributor {
  const BillContributor();

  @override
  String get id => 'bill';

  @override
  int get version => 1;

  @override
  Future<Transaction> projectRemote(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Transaction row,
  ) async {
    if (!context.config.mode) return row;
    final remoteId = split.subscriptionId ?? split.billId;
    final mapping = remoteId == null
        ? null
        : await context.idMap.byRemote(FireflyEntityType.bill, remoteId);
    final pk = mapping?.state == FireflySyncState.pendingDelete ||
            mapping?.state == FireflySyncState.localOnly
        ? null
        : mapping?.localPk;
    return row.copyWith(billFk: Value(pk));
  }

  @override
  Future<void> push(
    SyncContext context,
    Transaction transaction,
    JsonObject split,
  ) async {
    if (!context.config.mode) return;
    final pk = transaction.billFk;
    final mapping = pk == null
        ? null
        : await context.idMap.byLocal(FireflyEntityType.bill, pk);
    if (mapping != null &&
        !IdMapRepository.isProvisional(mapping) &&
        mapping.state != FireflySyncState.pendingDelete &&
        mapping.state != FireflySyncState.localOnly) {
      split['bill_id'] = mapping.remoteId;
    } else if (split.containsKey('date')) {
      // Real writes clear the link explicitly. Hash projections have no
      // date field and keep the old hash for an unlinked transaction.
      split['bill_id'] = null;
    }
  }
}

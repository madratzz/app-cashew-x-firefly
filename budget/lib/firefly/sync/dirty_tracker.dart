import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';

enum LocalChange { clean, created, updated, deleted }

LocalChange detectLocalChange({
  required FireflyIdMapping? mapping,
  required DateTime? modifiedAt,
  required String hash,
}) {
  if (mapping == null) return LocalChange.created;
  if (mapping.state == FireflySyncState.pendingDelete) {
    return LocalChange.deleted;
  }
  if (mapping.state == FireflySyncState.localOnly) return LocalChange.clean;
  // An interrupted create is retried after pull has had a chance to recover it.
  if (mapping.state == FireflySyncState.creating) return LocalChange.created;
  final syncedAt = mapping.localVersionAt;
  if ((modifiedAt == null ||
          syncedAt == null ||
          modifiedAt.isAfter(syncedAt)) &&
      hash != mapping.syncedHash) {
    return LocalChange.updated;
  }
  return LocalChange.clean;
}

class DirtyTracker {
  const DirtyTracker(this.idMap);

  final IdMapRepository idMap;

  /// Call in the same transaction as advancing the delete-log cursor.
  Future<int> collectDeletes(Iterable<DeleteLog> logs, {DateTime? after}) =>
      idMap.db.transaction(() async {
        var marked = 0;
        for (final log in logs) {
          final modifiedAt = log.dateTimeModified;
          if (after != null && !modifiedAt.isAfter(after)) {
            continue;
          }
          final type = switch (log.type) {
            DeleteLogType.TransactionWallet => FireflyEntityType.walletAccount,
            DeleteLogType.TransactionCategory => FireflyEntityType.category,
            DeleteLogType.Budget => FireflyEntityType.budget,
            DeleteLogType.CategoryBudgetLimit => null,
            DeleteLogType.Transaction => FireflyEntityType.transaction,
            DeleteLogType.Objective => FireflyEntityType.piggyBank,
            _ => null,
          };
          if (type == null) continue;
          var found = await idMap.markPendingDelete(type, log.entryPk);
          if (type == FireflyEntityType.walletAccount) {
            final liability = await idMap.markPendingDelete(
                FireflyEntityType.liabilityAccount, log.entryPk);
            found = found || liability;
          }
          if (found) marked++;
        }
        return marked;
      });
}

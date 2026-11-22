import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';

extension FireflyResetQueries on FinanceDatabase {
  /// Clears finance data and sync state before a replace-from-server import.
  /// Keeps app settings, scanner templates and the primary wallet row "0",
  /// which the rest of the app expects to exist. Writes no delete logs.
  Future<void> clearFireflyFinanceData() => transaction(() async {
        final tables = <TableInfo<Table, Object?>>[
          transactionTags,
          attachments,
          accountDetails,
          budgetLimits,
          categoryBudgetLimits,
          transactions,
          transactionGroups,
          associatedTitles,
          objectives,
          budgets,
          categories,
          payees,
          tags,
          deleteLogs,
          fireflyIdMap,
          fireflySyncMeta,
          fireflyConflicts,
          fireflyResourceCache,
        ];
        for (final table in tables) {
          await delete(table).go();
        }
        await (delete(wallets)..where((w) => w.walletPk.isNotValue('0'))).go();
      });
}

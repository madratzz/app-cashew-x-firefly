import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';

extension FireflyTransactionQueries on FinanceDatabase {
  Future<Transaction?> fireflyTransaction(String pk) =>
      (select(transactions)..where((row) => row.transactionPk.equals(pk)))
          .getSingleOrNull();

  Future<List<Transaction>> fireflyTransactions() => select(transactions).get();

  /// Break the self-references before deleting either side of a pair. Pulls
  /// bypass the legacy delete path to avoid generating outgoing delete logs.
  Future<void> removeFireflyTransactions(Iterable<String> pks) async {
    final keys = pks.toSet();
    if (keys.isEmpty) return;
    await (update(transactions)
          ..where((row) => row.pairedTransactionFk.isIn(keys)))
        .write(const TransactionsCompanion(pairedTransactionFk: Value(null)));
    await (delete(transactions)..where((row) => row.transactionPk.isIn(keys)))
        .go();
  }

  Future<TransactionGroup?> fireflyTransactionGroup(String pk) =>
      (select(transactionGroups)..where((row) => row.groupPk.equals(pk)))
          .getSingleOrNull();
}

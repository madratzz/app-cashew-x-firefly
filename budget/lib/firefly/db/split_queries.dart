import 'package:budget/database/tables.dart';

/// WP-32a supplies split draft queries and writes.
extension FireflySplitQueries on FinanceDatabase {
  Future<List<Transaction>> fireflyGroupSplits(String groupPk) async =>
      const [];
  Future<String?> fireflyGroupTitle(String groupPk) async => null;
  Future<void> persistFireflyGroupDraft(
      String transactionPk, List<Transaction> splits, String? title) async {}
}

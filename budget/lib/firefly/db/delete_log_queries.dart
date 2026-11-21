import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';

extension FireflyDeleteLogQueries on FinanceDatabase {
  Future<List<DeleteLog>> fireflyDeleteLogs({
    DateTime? after,
    bool includeAfter = false,
  }) {
    final query = select(deleteLogs)
      ..orderBy([
        (row) => OrderingTerm.asc(row.dateTimeModified),
        (row) => OrderingTerm.asc(row.deleteLogPk),
      ]);
    if (after != null) {
      query.where((row) => includeAfter
          ? row.dateTimeModified.isBiggerOrEqualValue(after)
          : row.dateTimeModified.isBiggerThanValue(after));
    }
    return query.get();
  }
}

import 'package:budget/database/tables.dart';

extension FireflyDeleteLogQueries on FinanceDatabase {
  Future<List<DeleteLog>> fireflyDeleteLogs({DateTime? after}) async =>
      const [];
}

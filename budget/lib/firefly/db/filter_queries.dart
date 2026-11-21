import 'package:budget/database/tables.dart';

extension FireflyFilterQueries on FinanceDatabase {
  Future<List<String>> fireflyFilteredTransactionPks(
          {String? payeePk,
          List<String> tagPks = const [],
          bool matchAllTags = false,
          String? billPk,
          bool? reconciled,
          bool? hasAttachment}) async =>
      const [];
}

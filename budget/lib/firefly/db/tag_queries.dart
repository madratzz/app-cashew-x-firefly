import 'package:budget/database/tables.dart';

extension FireflyTagQueries on FinanceDatabase {
  Future<List<Tag>> fireflyTransactionTags(String transactionPk) async =>
      const [];

  Future<List<Tag>> fireflyTags({String? search}) async => const [];
}

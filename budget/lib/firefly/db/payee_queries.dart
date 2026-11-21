import 'package:budget/database/tables.dart';

extension FireflyPayeeQueries on FinanceDatabase {
  Future<Payee?> fireflyPayee(String pk) async => null;

  Future<List<Payee>> fireflyPayees({String? search}) async => const [];
}

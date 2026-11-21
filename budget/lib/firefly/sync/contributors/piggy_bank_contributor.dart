import 'package:budget/firefly/sync/contracts.dart';

class PiggyBankContributor extends TransactionContributor {
  const PiggyBankContributor();

  @override
  String get id => 'piggyBank';
}

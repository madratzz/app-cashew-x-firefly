import 'package:budget/firefly/sync/contracts.dart';

class BudgetContributor extends TransactionContributor {
  const BudgetContributor();

  @override
  String get id => 'budget';
}

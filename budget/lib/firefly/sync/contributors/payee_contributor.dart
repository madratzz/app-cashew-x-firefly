import 'package:budget/firefly/sync/contracts.dart';

class PayeeContributor extends TransactionContributor {
  const PayeeContributor();

  @override
  String get id => 'payee';
}

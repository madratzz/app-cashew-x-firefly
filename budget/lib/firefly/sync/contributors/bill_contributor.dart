import 'package:budget/firefly/sync/contracts.dart';

class BillContributor extends TransactionContributor {
  const BillContributor();

  @override
  String get id => 'bill';
}

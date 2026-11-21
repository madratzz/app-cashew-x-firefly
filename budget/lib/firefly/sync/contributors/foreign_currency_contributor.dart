import 'package:budget/firefly/sync/contracts.dart';

class ForeignCurrencyContributor extends TransactionContributor {
  const ForeignCurrencyContributor();

  @override
  String get id => 'foreignCurrency';
}

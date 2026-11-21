import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyAccount extends FireflyResource {
  const FireflyAccount({required super.id, super.attributes});

  factory FireflyAccount.fromResource(JsonObject data) {
    final id = data['id'];
    final attributes = data['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyAccount(id: id, attributes: attributes);
  }

  DateTime? get createdAt => _date('created_at');
  String? get type => attributes['type'] as String?;
  String? get accountRole => attributes['account_role'] as String?;
  int? get order => attributes['order'] as int?;
  bool? get active => attributes['active'] as bool?;
  String? get objectGroupId => attributes['object_group_id'] as String?;
  int? get objectGroupOrder => attributes['object_group_order'] as int?;
  String? get objectGroupTitle => attributes['object_group_title'] as String?;
  bool? get objectHasCurrencySetting =>
      attributes['object_has_currency_setting'] as bool?;
  String? get currencyId => attributes['currency_id'] as String?;
  String? get currencyName => attributes['currency_name'] as String?;
  String? get currencyCode => attributes['currency_code'] as String?;
  String? get currencySymbol => attributes['currency_symbol'] as String?;
  int? get currencyDecimalPlaces =>
      attributes['currency_decimal_places'] as int?;
  String? get primaryCurrencyId => attributes['primary_currency_id'] as String?;
  String? get primaryCurrencyName =>
      attributes['primary_currency_name'] as String?;
  String? get primaryCurrencyCode =>
      attributes['primary_currency_code'] as String?;
  String? get primaryCurrencySymbol =>
      attributes['primary_currency_symbol'] as String?;
  int? get primaryCurrencyDecimalPlaces =>
      attributes['primary_currency_decimal_places'] as int?;
  double? get currentBalance => _amount('current_balance');
  double? get primaryCurrentBalance => _amount('pc_current_balance');
  double? get openingBalance => _amount('opening_balance');
  double? get primaryOpeningBalance => _amount('pc_opening_balance');
  double? get virtualBalance => _amount('virtual_balance');
  double? get primaryVirtualBalance => _amount('pc_virtual_balance');
  double? get debtAmount => _amount('debt_amount');
  double? get primaryDebtAmount => _amount('pc_debt_amount');
  double? get balanceDifference => _amount('balance_difference');
  double? get primaryBalanceDifference => _amount('pc_balance_difference');
  DateTime? get currentBalanceDate => _date('current_balance_date');
  DateTime? get openingBalanceDate => _date('opening_balance_date');
  DateTime? get monthlyPaymentDate => _date('monthly_payment_date');
  DateTime? get lastActivity => _date('last_activity');
  String? get creditCardType => attributes['credit_card_type'] as String?;
  String? get accountNumber => attributes['account_number'] as String?;
  String? get iban => attributes['iban'] as String?;
  String? get bic => attributes['bic'] as String?;
  String? get notes => attributes['notes'] as String?;
  String? get liabilityType => attributes['liability_type'] as String?;
  String? get liabilityDirection =>
      attributes['liability_direction'] as String?;
  double? get interest => _amount('interest');
  String? get interestPeriod => attributes['interest_period'] as String?;
  bool? get includeNetWorth => attributes['include_net_worth'] as bool?;
  double? get latitude => (attributes['latitude'] as num?)?.toDouble();
  double? get longitude => (attributes['longitude'] as num?)?.toDouble();
  int? get zoomLevel => attributes['zoom_level'] as int?;

  DateTime? _date(String key) {
    final value = attributes[key] as String?;
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  double? _amount(String key) {
    final value = attributes[key] as String?;
    return value == null || value.isEmpty ? null : parseFireflyAmount(value);
  }
}

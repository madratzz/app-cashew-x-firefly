import 'package:budget/firefly/api/models/resource.dart';

class FireflyAccount extends FireflyResource {
  const FireflyAccount({required super.id, super.attributes});

  String? get type => attributes['type'] as String?;
  String? get currencyCode => attributes['currency_code'] as String?;
  int? get currencyDecimalPlaces =>
      attributes['currency_decimal_places'] as int?;
  bool? get active => attributes['active'] as bool?;
}

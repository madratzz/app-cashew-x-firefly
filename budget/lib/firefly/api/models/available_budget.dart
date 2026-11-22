import 'package:budget/firefly/api/models/budget_limit.dart';
import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyAvailableBudget extends FireflyResource {
  const FireflyAvailableBudget({required super.id, super.attributes});

  factory FireflyAvailableBudget.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyAvailableBudget(id: id, attributes: attributes);
  }

  DateTime get start => parseBudgetDate(attributes['start']);
  DateTime get end => parseBudgetDate(attributes['end']);
  double get amount => parseFireflyAmount('${attributes['amount']}');
  String? get currencyCode => attributes['currency_code'] as String?;
}

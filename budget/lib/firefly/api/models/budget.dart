import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyBudget extends FireflyResource {
  const FireflyBudget({required super.id, super.attributes});

  factory FireflyBudget.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    final name = attributes is JsonObject ? attributes['name'] : null;
    if (id is! String ||
        id.isEmpty ||
        attributes is! JsonObject ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FireflyInvalidPayload();
    }
    return FireflyBudget(id: id, attributes: attributes);
  }

  bool get active => attributes['active'] as bool? ?? true;
  String get autoBudgetType =>
      attributes['auto_budget_type'] as String? ?? 'none';
  String? get autoBudgetPeriod => attributes['auto_budget_period'] as String?;
  double get autoBudgetAmount {
    final value = attributes['auto_budget_amount'];
    return value == null ? 0 : parseFireflyAmount('$value');
  }

  String? get currencyCode =>
      (attributes['currency_code'] ?? attributes['auto_budget_currency_code'])
          as String?;
  int? get decimalPlaces => attributes['currency_decimal_places'] as int?;

  DateTime? get createdAt {
    final value = attributes['created_at'];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}

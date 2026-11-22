import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyBudgetLimit extends FireflyResource {
  const FireflyBudgetLimit({required super.id, super.attributes});

  factory FireflyBudgetLimit.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyBudgetLimit(id: id, attributes: attributes);
  }

  DateTime get start => parseBudgetDate(attributes['start']);
  DateTime get end => parseBudgetDate(attributes['end']);
  double get amount => parseFireflyAmount('${attributes['amount']}');
  String get currencyCode {
    final code = attributes['currency_code'];
    if (code is! String || code.isEmpty) throw const FireflyInvalidPayload();
    return code;
  }

  int? get decimalPlaces => attributes['currency_decimal_places'] as int?;
  String? get notes => attributes['notes'] as String?;
}

/// Budget periods are calendar dates in Firefly, even when read with offsets.
DateTime parseBudgetDate(Object? value) {
  if (value is! String || value.length < 10) {
    throw const FireflyInvalidPayload();
  }
  final day = value.substring(0, 10);
  final parsed = DateTime.tryParse(day);
  if (parsed == null || formatFireflyDate(parsed) != day) {
    throw const FireflyInvalidPayload();
  }
  return parsed;
}

import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

enum FireflyBillFrequency {
  weekly('weekly'),
  monthly('monthly'),
  quarterly('quarterly'),
  halfYear('half-year'),
  yearly('yearly');

  const FireflyBillFrequency(this.wireValue);

  final String wireValue;

  static FireflyBillFrequency? fromWire(Object? value) {
    for (final frequency in values) {
      if (frequency.wireValue == value) return frequency;
    }
    return null;
  }
}

class FireflyBill extends FireflyResource {
  const FireflyBill({required super.id, super.attributes});

  factory FireflyBill.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if ((id is! int && id is! String) ||
        id == '' ||
        attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyBill(id: id.toString(), attributes: attributes);
  }

  static const writableKeys = {
    'name',
    'currency_id',
    'currency_code',
    'amount_min',
    'amount_max',
    'date',
    'end_date',
    'extension_date',
    'repeat_freq',
    'skip',
    'active',
    'notes',
    'object_group_id',
    'object_group_title',
  };

  String? get currencyCode => attributes['currency_code'] as String?;
  double? get amountMin => _amount(attributes['amount_min']);
  double? get amountMax => _amount(attributes['amount_max']);
  DateTime? get date => _date(attributes['date']);
  DateTime? get endDate => _date(attributes['end_date']);
  DateTime? get extensionDate => _date(attributes['extension_date']);
  FireflyBillFrequency? get frequency =>
      FireflyBillFrequency.fromWire(attributes['repeat_freq']);
  int? get skip => attributes['skip'] as int?;
  bool? get active => attributes['active'] as bool?;
  String? get notes => attributes['notes'] as String?;
  DateTime? get nextExpectedMatch => _date(attributes['next_expected_match']);

  List<DateTime> get payDates => [
        for (final value in attributes['pay_dates'] as List<Object?>? ?? [])
          if (_date(value) case final date?) date,
      ];

  List<DateTime> get paidDates => [
        for (final payment in attributes['paid_dates'] as List<Object?>? ?? [])
          if (payment is JsonObject)
            if (_date(payment['date']) case final date?) date,
      ];

  JsonObject toWriteJson() => {
        for (final key in writableKeys)
          if (attributes.containsKey(key))
            key: key == 'name' ? name?.trim() : attributes[key],
      };
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

double? _amount(Object? value) =>
    value == null ? null : parseFireflyAmount(value.toString());

import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyPiggyBank extends FireflyResource {
  const FireflyPiggyBank({required super.id, super.attributes});

  factory FireflyPiggyBank.fromJson(JsonObject data) {
    final id = _id(data['id']);
    final attributes = data['attributes'];
    if (id == null || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyPiggyBank(id: id, attributes: attributes);
  }

  DateTime? get createdAt => _date(attributes['created_at']);
  DateTime? get startDate => _date(attributes['start_date']);
  DateTime? get targetDate => _date(attributes['target_date']);
  double? get targetAmount => _amount(attributes['target_amount']);
  double get currentAmount => _amount(attributes['current_amount']) ?? 0;
  int? get currencyDecimalPlaces =>
      attributes['currency_decimal_places'] as int?;

  List<FireflyPiggyBankAccount> get accounts {
    final value = attributes['accounts'];
    if (value is! List) throw const FireflyInvalidPayload();
    return [
      for (final account in value)
        if (account is JsonObject)
          FireflyPiggyBankAccount(
            id: _id(account['id'] ?? account['account_id']) ??
                (throw const FireflyInvalidPayload()),
            currentAmount: _amount(account['current_amount']) ?? 0,
          )
        else
          throw const FireflyInvalidPayload(),
    ];
  }
}

class FireflyPiggyBankAccount {
  const FireflyPiggyBankAccount(
      {required this.id, required this.currentAmount});

  final String id;
  final double currentAmount;
}

class FireflyPiggyBankEvent extends FireflyResource {
  const FireflyPiggyBankEvent._({required super.id, required super.attributes});

  factory FireflyPiggyBankEvent.fromJson(JsonObject data) {
    final id = _id(data['id']);
    final attributes = data['attributes'];
    if (id == null || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyPiggyBankEvent._(id: id, attributes: attributes);
  }

  DateTime? get createdAt => _date(attributes['created_at']);
  double? get amount => _amount(attributes['amount']);
  String? get journalId => _id(attributes['transaction_journal_id']);
  String? get groupId => _id(attributes['transaction_group_id']);
}

String? _id(Object? value) => switch (value) {
      String() when value.isNotEmpty => value,
      int() => value.toString(),
      _ => null,
    };

DateTime? _date(Object? value) {
  if (value == null) return null;
  return (value is String ? DateTime.tryParse(value)?.toLocal() : null) ??
      (throw const FireflyInvalidPayload());
}

double? _amount(Object? value) {
  if (value == null) return null;
  return parseFireflyAmount(value.toString());
}

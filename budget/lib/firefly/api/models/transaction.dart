import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyTransaction extends FireflyResource {
  const FireflyTransaction({required super.id, super.attributes});

  factory FireflyTransaction.fromJson(JsonObject json) {
    final id = _id(json['id']);
    final attributes = json['attributes'];
    if (id == null || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyTransaction(id: id, attributes: attributes);
  }

  DateTime? get createdAt => _date(attributes['created_at']);
  String? get groupTitle => attributes['group_title'] as String?;

  List<FireflyTransactionSplit> get splits {
    final values = attributes['transactions'];
    if (values == null) return const [];
    if (values is! List<Object?>) throw const FireflyInvalidPayload();
    return [
      for (final value in values)
        if (value is JsonObject)
          FireflyTransactionSplit(value)
        else
          throw const FireflyInvalidPayload(),
    ];
  }
}

/// Retains extension fields so contributors can read fields introduced by
/// newer servers without changing the transport or the core mapping.
class FireflyTransactionSplit {
  const FireflyTransactionSplit(this.fields);

  final JsonObject fields;

  String? get journalId => _id(fields['transaction_journal_id']);
  String? get type => fields['type'] as String?;
  DateTime? get date => _date(fields['date']);
  int? get order => _integer(fields['order']);
  String? get description => fields['description'] as String?;
  String? get notes => fields['notes'] as String?;
  bool? get reconciled => fields['reconciled'] as bool?;

  String? get currencyId => _id(fields['currency_id']);
  String? get currencyCode => fields['currency_code'] as String?;
  String? get currencyName => fields['currency_name'] as String?;
  String? get currencySymbol => fields['currency_symbol'] as String?;
  int? get currencyDecimalPlaces => _integer(fields['currency_decimal_places']);
  double? get amount => _amount(fields['amount']);
  String? get foreignCurrencyId => _id(fields['foreign_currency_id']);
  String? get foreignCurrencyCode => fields['foreign_currency_code'] as String?;
  String? get foreignCurrencyName => fields['foreign_currency_name'] as String?;
  String? get foreignCurrencySymbol =>
      fields['foreign_currency_symbol'] as String?;
  int? get foreignCurrencyDecimalPlaces =>
      _integer(fields['foreign_currency_decimal_places']);
  double? get foreignAmount => _amount(fields['foreign_amount']);
  String? get primaryCurrencyId => _id(fields['primary_currency_id']);
  String? get primaryCurrencyCode => fields['primary_currency_code'] as String?;
  String? get primaryCurrencyName => fields['primary_currency_name'] as String?;
  String? get primaryCurrencySymbol =>
      fields['primary_currency_symbol'] as String?;
  int? get primaryCurrencyDecimalPlaces =>
      _integer(fields['primary_currency_decimal_places']);
  double? get primaryCurrencyAmount => _amount(fields['pc_amount']);
  double? get primaryCurrencyForeignAmount =>
      _amount(fields['pc_foreign_amount']);

  String? get sourceId => _id(fields['source_id']);
  String? get sourceName => fields['source_name'] as String?;
  String? get sourceType => fields['source_type'] as String?;
  String? get destinationId => _id(fields['destination_id']);
  String? get destinationName => fields['destination_name'] as String?;
  String? get destinationType => fields['destination_type'] as String?;
  String? get categoryId => _id(fields['category_id']);
  String? get categoryName => fields['category_name'] as String?;
  String? get budgetId => _id(fields['budget_id']);
  String? get budgetName => fields['budget_name'] as String?;
  String? get billId => _id(fields['bill_id']);
  String? get subscriptionId => _id(fields['subscription_id']);
  String? get piggyBankId => _id(fields['piggy_bank_id']);
  List<String> get tags =>
      (fields['tags'] as List<Object?>? ?? const []).cast<String>();
  String? get internalReference => fields['internal_reference'] as String?;
  String? get externalId => fields['external_id'] as String?;
  String? get externalUrl => fields['external_url'] as String?;
  bool? get hasAttachments => fields['has_attachments'] as bool?;
}

String? _id(Object? value) => switch (value) {
      String() when value.isNotEmpty => value,
      int() => value.toString(),
      _ => null,
    };

int? _integer(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

double? _amount(Object? value) =>
    value == null || value == '' ? null : parseFireflyAmount(value.toString());

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

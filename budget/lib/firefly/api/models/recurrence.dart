import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

enum FireflyRepetitionType {
  daily,
  weekly,
  ndom,
  monthly,
  yearly;

  static FireflyRepetitionType? fromWire(Object? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

class FireflyRepetition {
  const FireflyRepetition(this.fields);

  final JsonObject fields;

  FireflyRepetitionType? get type =>
      FireflyRepetitionType.fromWire(fields['type']);
  String? get moment => fields['moment']?.toString();
  int? get skip => fields['skip'] as int?;
  int? get weekend => fields['weekend'] as int?;
  String? get description => fields['description'] as String?;

  List<DateTime> get occurrences => [
        for (final value in fields['occurrences'] as List<Object?>? ?? [])
          if (_calendarDate(value) case final date?) date,
      ];

  JsonObject toWriteJson() =>
      _selectFields(fields, const {'type', 'moment', 'skip', 'weekend'});
}

class FireflyRecurrence extends FireflyResource {
  const FireflyRecurrence({required super.id, super.attributes});

  factory FireflyRecurrence.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if ((id is! int && id is! String) ||
        id == '' ||
        attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyRecurrence(id: id.toString(), attributes: attributes);
  }

  static const writableKeys = {
    'type',
    'title',
    'description',
    'first_date',
    'repeat_until',
    'nr_of_repetitions',
    'apply_rules',
    'active',
    'notes',
    'repetitions',
    'transactions',
  };

  String? get title => attributes['title'] as String?;
  String? get type => attributes['type'] as String?;
  String? get description => attributes['description'] as String?;
  DateTime? get firstDate => _calendarDate(attributes['first_date']);
  DateTime? get repeatUntil => _calendarDate(attributes['repeat_until']);
  DateTime? get latestDate => _calendarDate(attributes['latest_date']);
  int? get numberOfRepetitions => attributes['nr_of_repetitions'] as int?;
  bool? get applyRules => attributes['apply_rules'] as bool?;
  bool? get active => attributes['active'] as bool?;
  String? get notes => attributes['notes'] as String?;

  List<FireflyRepetition> get repetitions =>
      _objects(attributes['repetitions']).map(FireflyRepetition.new).toList();

  /// Template references are Firefly IDs, as returned by the API.
  List<JsonObject> get transactions => _objects(attributes['transactions']);

  /// Dates use the server's calendar day, including when its timezone
  /// differs from the device's. Multiple repetitions can share a date.
  List<DateTime> upcomingOccurrences({required DateTime from}) {
    if (active == false) return const [];
    final day = DateTime(from.year, from.month, from.day);
    return {
      for (final repetition in repetitions)
        for (final date in repetition.occurrences)
          if (!date.isBefore(day)) date,
    }.toList()
      ..sort();
  }

  DateTime? nextOccurrence({required DateTime from}) =>
      upcomingOccurrences(from: from).firstOrNull;

  JsonObject toWriteJson({bool updating = false}) {
    final fields = _selectFields(attributes, writableKeys);
    if (fields.containsKey('title')) fields['title'] = title?.trim();
    if (updating) fields.remove('type');
    if (fields.containsKey('repetitions')) {
      fields['repetitions'] = [
        for (final repetition in repetitions) repetition.toWriteJson(),
      ];
    }
    if (fields.containsKey('transactions')) {
      fields['transactions'] = [
        for (final transaction in transactions)
          {
            ..._selectFields(transaction, const {
              'description',
              'amount',
              'foreign_amount',
              'currency_id',
              'currency_code',
              'foreign_currency_id',
              'foreign_currency_code',
              'budget_id',
              'category_id',
              'source_id',
              'destination_id',
              'tags',
              'piggy_bank_id',
              'bill_id',
            }),
            if (updating && transaction['id'] != null) 'id': transaction['id'],
            if (transaction.containsKey('subscription_id'))
              'bill_id':
                  transaction['subscription_id'] ?? transaction['bill_id'],
          }
            // 6.6.2 reads back `tags: []` but rejects it on write.
            ..removeWhere((key, value) =>
                key == 'tags' && value is List && value.isEmpty),
      ];
    }
    return fields;
  }
}

List<JsonObject> _objects(Object? value) {
  if (value == null) return const [];
  if (value is! List<Object?>) throw const FireflyInvalidPayload();
  return [
    for (final item in value)
      if (item is JsonObject) item else throw const FireflyInvalidPayload(),
  ];
}

JsonObject _selectFields(JsonObject fields, Set<String> keys) => {
      for (final key in keys)
        if (fields.containsKey(key)) key: fields[key],
    };

DateTime? _calendarDate(Object? value) {
  if (value is! String || value.length < 10) return null;
  return DateTime.tryParse(value.substring(0, 10));
}

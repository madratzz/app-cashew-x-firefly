import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyExchangeRate extends FireflyResource {
  const FireflyExchangeRate({required super.id, super.attributes});

  factory FireflyExchangeRate.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    final result = FireflyExchangeRate(id: id, attributes: attributes);
    if (result.fromCurrencyCode == null ||
        result.toCurrencyCode == null ||
        result.date == null ||
        result.rate == null) {
      throw const FireflyInvalidPayload();
    }
    return result;
  }

  String? get fromCurrencyCode => _code('from_currency_code');
  String? get toCurrencyCode => _code('to_currency_code');

  /// The rate applies on this calendar date in Firefly's timezone.
  DateTime? get date {
    final value = attributes['date'];
    if (value is! String || value.length < 10) return null;
    final day = value.substring(0, 10);
    final date = DateTime.tryParse('${day}T00:00:00Z');
    return date != null && formatFireflyDate(date) == day ? date : null;
  }

  double? get rate {
    final value = double.tryParse(attributes['rate']?.toString() ?? '');
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  String? _code(String key) {
    final value = attributes[key];
    return value is String && value.trim().isNotEmpty
        ? value.trim().toLowerCase()
        : null;
  }
}

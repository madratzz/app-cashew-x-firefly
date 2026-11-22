import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyTag extends FireflyResource {
  const FireflyTag({required super.id, super.attributes});

  factory FireflyTag.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    final name = attributes['tag'];
    final description = attributes['description'];
    final date = attributes['date'];
    if (name is! String ||
        name.trim().isEmpty ||
        (description != null && description is! String) ||
        (date != null &&
            (date is! String || DateTime.tryParse(date) == null))) {
      throw const FireflyInvalidPayload();
    }
    return FireflyTag(id: id, attributes: attributes);
  }

  @override
  String? get name => attributes['tag'] as String?;
  String? get description => attributes['description'] as String?;
  DateTime? get date => _date('date');
  DateTime? get createdAt => _date('created_at')?.toLocal();

  DateTime? _date(String field) {
    final value = attributes[field];
    return value is String ? DateTime.tryParse(value) : null;
  }
}

import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyCategory extends FireflyResource {
  const FireflyCategory({required super.id, super.attributes});

  factory FireflyCategory.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String ||
        id.isEmpty ||
        attributes is! JsonObject ||
        attributes['name'] is! String ||
        (attributes['name'] as String).trim().isEmpty) {
      throw const FireflyInvalidPayload();
    }
    return FireflyCategory(id: id, attributes: attributes);
  }

  String? get notes => attributes['notes'] as String?;

  DateTime? get createdAt {
    final value = attributes['created_at'];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}

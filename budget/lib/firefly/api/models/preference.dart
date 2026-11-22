import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyPreference extends FireflyResource {
  const FireflyPreference({required super.id, super.attributes});

  factory FireflyPreference.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String ||
        id.isEmpty ||
        attributes is! JsonObject ||
        attributes['name'] is! String ||
        (attributes['name'] as String).isEmpty ||
        !attributes.containsKey('data')) {
      throw const FireflyInvalidPayload();
    }
    return FireflyPreference(id: id, attributes: attributes);
  }

  Object? get data => attributes['data'];
}

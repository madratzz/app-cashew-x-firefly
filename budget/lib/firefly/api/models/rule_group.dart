import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyRuleGroup extends FireflyResource {
  const FireflyRuleGroup({required super.id, super.attributes});

  factory FireflyRuleGroup.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyRuleGroup(id: id, attributes: attributes);
  }

  String? get title => attributes['title'] as String?;
  String? get description => attributes['description'] as String?;
  int? get order => attributes['order'] as int?;
  bool? get active => attributes['active'] as bool?;

  JsonObject toWriteJson() => {
        for (final key in const ['title', 'description', 'order', 'active'])
          if (attributes.containsKey(key)) key: attributes[key],
      };
}

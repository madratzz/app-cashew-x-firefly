import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyObjectGroup extends FireflyResource {
  const FireflyObjectGroup({required super.id, super.attributes})
      : _resource = null;

  const FireflyObjectGroup._({
    required super.id,
    required super.attributes,
    required JsonObject resource,
  }) : _resource = resource;

  final JsonObject? _resource;

  JsonObject toJson() => _resource ?? {'id': id, 'attributes': attributes};

  factory FireflyObjectGroup.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if ((id is! String && id is! int) ||
        id == '' ||
        attributes is! JsonObject ||
        attributes['title'] is! String) {
      throw const FireflyInvalidPayload();
    }
    return FireflyObjectGroup._(
      id: id.toString(),
      attributes: attributes,
      resource: json,
    );
  }

  String? get title => attributes['title'] as String?;
  int? get order => attributes['order'] as int?;

  @override
  String? get name => title;
}

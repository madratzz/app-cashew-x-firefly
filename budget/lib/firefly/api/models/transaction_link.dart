import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyTransactionLink extends FireflyResource {
  const FireflyTransactionLink({required super.id, super.attributes})
      : _resource = null;

  const FireflyTransactionLink._({
    required super.id,
    required super.attributes,
    required JsonObject resource,
  }) : _resource = resource;

  final JsonObject? _resource;

  JsonObject toJson() => _resource ?? {'id': id, 'attributes': attributes};

  factory FireflyTransactionLink.fromJson(JsonObject json) {
    final attributes = _attributes(json);
    _id(attributes['inward_id']);
    _id(attributes['outward_id']);
    _id(attributes['link_type_id']);
    return FireflyTransactionLink._(
      id: _id(json['id']),
      attributes: attributes,
      resource: json,
    );
  }

  String get inwardJournalId => _id(attributes['inward_id']);
  String get outwardJournalId => _id(attributes['outward_id']);
  String get linkTypeId => _id(attributes['link_type_id']);
  String? get notes => attributes['notes'] as String?;
}

class FireflyLinkType extends FireflyResource {
  const FireflyLinkType({required super.id, super.attributes})
      : _resource = null;

  const FireflyLinkType._({
    required super.id,
    required super.attributes,
    required JsonObject resource,
  }) : _resource = resource;

  final JsonObject? _resource;

  JsonObject toJson() => _resource ?? {'id': id, 'attributes': attributes};

  factory FireflyLinkType.fromJson(JsonObject json) {
    final attributes = _attributes(json);
    if (attributes['name'] is! String ||
        attributes['inward'] is! String ||
        attributes['outward'] is! String) {
      throw const FireflyInvalidPayload();
    }
    return FireflyLinkType._(
      id: _id(json['id']),
      attributes: attributes,
      resource: json,
    );
  }

  String get inward => attributes['inward'] as String;
  String get outward => attributes['outward'] as String;
}

JsonObject _attributes(JsonObject resource) {
  final attributes = resource['attributes'];
  if (attributes is! JsonObject) throw const FireflyInvalidPayload();
  return attributes;
}

String _id(Object? value) => switch (value) {
      String() when value.isNotEmpty => value,
      int() => value.toString(),
      _ => throw const FireflyInvalidPayload(),
    };

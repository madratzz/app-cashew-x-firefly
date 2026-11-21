import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyCurrency extends FireflyResource {
  const FireflyCurrency({required super.id, super.attributes});

  factory FireflyCurrency.fromJson(JsonObject data) {
    final id = data['id'];
    final attributes = data['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    return FireflyCurrency(id: id, attributes: attributes);
  }

  String? get code => attributes['code'] as String?;
  int? get decimalPlaces => attributes['decimal_places'] as int?;
  bool? get enabled => attributes['enabled'] as bool?;
  bool? get primary => attributes['primary'] as bool?;
}

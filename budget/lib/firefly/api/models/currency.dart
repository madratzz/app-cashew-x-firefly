import 'package:budget/firefly/api/models/resource.dart';

class FireflyCurrency extends FireflyResource {
  const FireflyCurrency({required super.id, super.attributes});

  String? get code => attributes['code'] as String?;
  int? get decimalPlaces => attributes['decimal_places'] as int?;
  bool? get enabled => attributes['enabled'] as bool?;
  bool? get primary => attributes['primary'] as bool?;
}

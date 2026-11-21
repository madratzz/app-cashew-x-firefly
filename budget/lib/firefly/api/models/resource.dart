import 'package:budget/firefly/api/transport.dart';

/// Stable DTO surface for a decoded JSON:API resource. Feature packages add
/// resource-specific fields and parsing in their respective model files.
class FireflyResource {
  const FireflyResource({required this.id, this.attributes = const {}});

  final String id;
  final JsonObject attributes;
  String? get name => attributes['name'] as String?;
  DateTime? get updatedAt {
    final value = attributes['updated_at'];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}

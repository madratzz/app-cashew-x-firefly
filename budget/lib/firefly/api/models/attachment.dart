import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyAttachment extends FireflyResource {
  const FireflyAttachment({required super.id, super.attributes});

  factory FireflyAttachment.fromJson(JsonObject resource) {
    final id = resource['id'];
    final attributes = resource['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    final result = FireflyAttachment(id: id, attributes: attributes);
    // Validate the parent and name before using the listing for reconciliation.
    result.attachableType;
    result.attachableId;
    result.filename;
    return result;
  }

  static const transactionJournal = 'TransactionJournal';

  String get attachableType =>
      _requiredString('attachable_type').split(r'\').last;
  String get attachableId => _requiredString('attachable_id');
  String get filename => _requiredString('filename');
  String? get title => _optionalString('title');
  String? get mime => _optionalString('mime');
  String? get hash => _optionalString('hash')?.toLowerCase();
  int? get size => attributes['size'] as int?;
  DateTime? get createdAt =>
      DateTime.tryParse(attributes['created_at'] as String? ?? '')?.toLocal();

  String _requiredString(String key) =>
      _optionalString(key) ?? (throw const FireflyInvalidPayload());

  String? _optionalString(String key) {
    final value = attributes[key];
    if (value == null || value == '') return null;
    if (value is String) return value;
    throw const FireflyInvalidPayload();
  }
}

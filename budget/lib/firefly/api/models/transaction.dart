import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyTransaction extends FireflyResource {
  const FireflyTransaction({required super.id, super.attributes});

  String? get groupTitle => attributes['group_title'] as String?;

  List<FireflyTransactionSplit> get splits =>
      ((attributes['transactions'] as List<Object?>?) ?? const [])
          .map((value) => FireflyTransactionSplit(value as JsonObject))
          .toList();
}

class FireflyTransactionSplit {
  const FireflyTransactionSplit(this.fields);

  final JsonObject fields;
  String? get journalId => fields['transaction_journal_id'] as String?;
  String? get type => fields['type'] as String?;
  String? get sourceId => fields['source_id'] as String?;
  String? get destinationId => fields['destination_id'] as String?;
  String? get internalReference => fields['internal_reference'] as String?;
}

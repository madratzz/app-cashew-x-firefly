import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/sync/contracts.dart';

class AttachmentsContributor extends TransactionContributor {
  const AttachmentsContributor();

  @override
  String get id => 'attachments';

  // Firefly derives has_attachments from the attachment collection. There is
  // no writable split field or local transaction column to project or clear.
  @override
  Future<Transaction> projectRemote(
          SyncContext context,
          FireflyTransaction group,
          FireflyTransactionSplit split,
          Transaction row) async =>
      row;
}

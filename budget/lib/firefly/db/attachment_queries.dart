import 'package:budget/database/tables.dart';

/// WP-35a supplies attachment draft queries and writes.
extension FireflyAttachmentQueries on FinanceDatabase {
  Future<List<Attachment>> fireflyTransactionAttachments(
          String transactionPk) async =>
      const [];

  Future<void> persistFireflyAttachmentDraft(
      String transactionPk, List<Attachment> attachments) async {}
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/pages/attachments/attachment_actions.dart';
import 'package:budget/firefly/ui/transaction/attachments_section.dart';
import 'package:budget/struct/databaseGlobal.dart' as global_db;
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Lists the files of one transaction, or every file when [transactionPk]
/// is null. Deleting here is saved immediately.
class FireflyAttachmentsPage extends StatelessWidget {
  const FireflyAttachmentsPage({this.transactionPk, this.db, super.key});

  final String? transactionPk;
  final FinanceDatabase? db;

  FinanceDatabase get _db => db ?? global_db.database;

  Future<void> _delete(BuildContext context, Attachment row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('firefly-attachments-delete-confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('firefly-attachments-remove'.tr())),
        ],
      ),
    );
    if (confirmed != true) return;
    final owner = row.attachableFk;
    final baseline = await _db.fireflyTransactionAttachments(owner);
    await _db.persistFireflyAttachmentDraft(
      owner,
      [
        for (final item in baseline)
          if (item.attachmentPk != row.attachmentPk) item
      ],
      baseline: baseline,
      supportDirectory: FireflyAttachmentActions.supportDirectory,
    );
    fireflyLocalWrite();
  }

  Future<void> _open(BuildContext context, Attachment row) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await openFireflyAttachmentFile(_db, row);
    if (error != null) messenger?.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final pk = transactionPk;
    return Scaffold(
      appBar: AppBar(title: Text('firefly-attachments-title'.tr())),
      body: StreamBuilder<List<Attachment>>(
        stream: pk == null
            ? _db.watchFireflyAttachments()
            : _db.watchFireflyTransactionAttachments(pk),
        builder: (context, snapshot) {
          final rows = snapshot.data;
          if (rows == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rows.isEmpty) {
            return Center(child: Text('firefly-attachments-empty'.tr()));
          }
          return ListView(children: [
            for (final row in rows)
              FireflyAttachmentTile(
                row: row,
                onOpen: () => _open(context, row),
                onRemove: () => _delete(context, row),
              ),
          ]);
        },
      ),
    );
  }
}

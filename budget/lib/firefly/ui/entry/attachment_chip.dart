import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/pages/attachments/attachments_page.dart';
import 'package:budget/struct/databaseGlobal.dart' as global_db;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyAttachmentChip(BuildContext context, Transaction transaction) =>
    FireflyAttachmentChip(transactionPk: transaction.transactionPk);

/// Row indicator: a paperclip with the file count, opening the file list.
class FireflyAttachmentChip extends StatefulWidget {
  const FireflyAttachmentChip(
      {required this.transactionPk, this.db, super.key});

  final String transactionPk;
  final FinanceDatabase? db;

  @override
  State<FireflyAttachmentChip> createState() => _FireflyAttachmentChipState();
}

class _FireflyAttachmentChipState extends State<FireflyAttachmentChip> {
  late FinanceDatabase database;
  late Stream<List<Attachment>> rows;

  void _watch() {
    database = widget.db ?? global_db.database;
    rows = database.watchFireflyTransactionAttachments(widget.transactionPk);
  }

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(FireflyAttachmentChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactionPk != widget.transactionPk ||
        oldWidget.db != widget.db) {
      _watch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionPk = widget.transactionPk;
    return StreamBuilder<List<Attachment>>(
      stream: rows,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Tooltip(
          message:
              'firefly-attachments-count'.tr(namedArgs: {'count': '$count'}),
          child: InkWell(
            key: const ValueKey('firefly-attachment-chip'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => FireflyAttachmentsPage(
                    transactionPk: transactionPk, db: database))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.attach_file_rounded, size: 16),
                Text('$count'),
              ]),
            ),
          ),
        );
      },
    );
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/ui/pages/splits/splits_page.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflySplitChip(BuildContext context, Transaction transaction) =>
    transaction.splitGroupFk == null
        ? const SizedBox.shrink()
        : FireflySplitChip(transaction: transaction);

/// Marks a row that belongs to a split group and opens the whole group.
class FireflySplitChip extends StatelessWidget {
  const FireflySplitChip({super.key, required this.transaction, this.db});

  final Transaction transaction;
  final FinanceDatabase? db;

  @override
  Widget build(BuildContext context) {
    final finance = db ?? database;
    final groupPk = transaction.splitGroupFk!;
    return FutureBuilder<List<Transaction>>(
      future: finance.fireflyGroupSplits(groupPk),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Transaction>[];
        final journals = fireflyJournals(rows);
        final index = journals.indexWhere((row) =>
                row.transactionPk == transaction.transactionPk ||
                row.pairedTransactionFk == transaction.transactionPk) +
            1;
        return ActionChip(
          avatar: const Icon(Icons.call_split_rounded, size: 16),
          visualDensity: VisualDensity.compact,
          label: Text(journals.isEmpty
              ? 'firefly-splits-chip'.tr()
              : 'firefly-splits-chip-position'.tr(namedArgs: {
                  'index': '$index',
                  'count': '${journals.length}',
                })),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => FireflySplitsPage(groupPk: groupPk, db: finance),
          )),
        );
      },
    );
  }
}

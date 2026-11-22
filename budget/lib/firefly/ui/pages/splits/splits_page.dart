import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One row per journal; a transfer keeps only its outgoing side.
List<Transaction> fireflyJournals(List<Transaction> rows) {
  final seen = <String>{};
  return [
    for (final row in rows)
      if (seen.add(row.transactionPk) &&
          (row.pairedTransactionFk == null ||
              seen.add(row.pairedTransactionFk!)))
        row,
  ];
}

/// Shows every split of a Firefly transaction group together.
class FireflySplitsPage extends StatefulWidget {
  const FireflySplitsPage({super.key, this.groupPk, this.db});

  final String? groupPk;
  final FinanceDatabase? db;

  @override
  State<FireflySplitsPage> createState() => _FireflySplitsPageState();
}

class _FireflySplitsPageState extends State<FireflySplitsPage> {
  late final FinanceDatabase _db = widget.db ?? database;
  late final Future<(String?, List<Transaction>)> _group = _load();

  Future<(String?, List<Transaction>)> _load() async {
    final groupPk = widget.groupPk;
    if (groupPk == null) return (null, const <Transaction>[]);
    return (
      await _db.fireflyGroupTitle(groupPk),
      await _db.fireflyGroupSplits(groupPk),
    );
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(String?, List<Transaction>)>(
        future: _group,
        builder: (context, snapshot) {
          final (title, rows) = snapshot.data ?? (null, const <Transaction>[]);
          final journals = fireflyJournals(rows);
          final total = journals.fold<double>(0, (sum, row) => sum + row.amount);
          final heading = (title?.trim().isNotEmpty ?? false)
              ? title!.trim()
              : journals.isEmpty
                  ? 'firefly-splits-title'.tr()
                  : journals.first.name;
          return Scaffold(
            appBar: AppBar(title: Text(heading)),
            body: ListView(
              children: [
                for (final row in journals)
                  ListTile(
                    key: ValueKey('firefly-split-page-${row.transactionPk}'),
                    leading: Icon(row.pairedTransactionFk != null
                        ? Icons.swap_horiz_rounded
                        : Icons.call_split_rounded),
                    title: Text(row.name),
                    trailing: Text(row.amount.toStringAsFixed(2)),
                  ),
                ListTile(
                  key: const ValueKey('firefly-split-page-total'),
                  title: Text('firefly-splits-page-total'.tr(namedArgs: {
                    'count': '${journals.length}',
                  })),
                  trailing: Text(total.toStringAsFixed(2)),
                ),
              ],
            ),
          );
        },
      );
}

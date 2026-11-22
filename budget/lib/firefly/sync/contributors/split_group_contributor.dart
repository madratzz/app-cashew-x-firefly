import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';
import 'package:easy_localization/easy_localization.dart';

class SplitGroupContributor extends TransactionContributor {
  const SplitGroupContributor();

  @override
  String get id => 'splitGroup';

  @override
  Future<Transaction> projectRemote(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Transaction row,
  ) async =>
      row.copyWith(
        splitOrder: Value(row.splitGroupFk == null ? null : split.order),
      );

  @override
  Future<bool> pushSplitWrite(
    SyncContext context,
    Transaction row,
    JsonObject fields, {
    FireflyTransactionSplit? prior,
  }) async {
    final order = row.splitOrder;
    if (order != null && order != prior?.order) fields['order'] = order;
    return true;
  }

  @override
  Future<void> pushGroup(
    SyncContext context,
    TransactionGroup group,
    JsonObject fields,
  ) async {
    var title = group.title;
    final journals = fields['transactions'];
    // Firefly 6.6.2 requires a title on any write with multiple journals,
    // including PUTs where the existing title has not changed.
    if ((title == null || title.isEmpty) &&
        journals is List<Object?> &&
        journals.length > 1) {
      final rows = await context.db.fireflyGroupSplits(group.groupPk);
      final name = rows.map((row) => row.name.trim()).firstWhere(
            (name) => name.isNotEmpty,
            orElse: () => 'transaction'.tr(),
          );
      title = name;
    }
    fields['group_title'] = title;
  }
}

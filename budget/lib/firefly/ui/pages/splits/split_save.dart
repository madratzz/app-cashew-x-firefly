import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:drift/drift.dart';

/// Copies the schema 47 columns the legacy form does not edit from the stored
/// row, so an edit keeps payee, currency, split and bill links.
Transaction fireflyKeepStoredFields(Transaction form, Transaction? stored) {
  if (stored == null) return form;
  return form.copyWith(
    payeeFk: Value(stored.payeeFk),
    foreignAmount: Value(stored.foreignAmount),
    foreignCurrency: Value(stored.foreignCurrency),
    splitGroupFk: Value(stored.splitGroupFk),
    splitOrder: Value(stored.splitOrder),
    fireflyType: Value(stored.fireflyType),
    billFk: Value(stored.billFk),
    reconciled: stored.reconciled,
  );
}

/// Runs the legacy save and keeps the junction rows a replacing insert
/// cascades away. Returns the legacy row id.
Future<int?> fireflySaveTransaction(
  FinanceDatabase db,
  Transaction form,
  Transaction? stored,
  Future<int?> Function(Transaction transaction) legacySave,
) =>
    db.transaction(() async {
      final row = fireflyKeepStoredFields(form, stored);
      if (stored == null) return legacySave(row);
      final tags = await (db.select(db.transactionTags)
            ..where((tag) => tag.transactionFk.equals(stored.transactionPk)))
          .get();
      final rowId = await legacySave(row);
      if (tags.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.transactionTags, tags,
            mode: InsertMode.insertOrIgnore));
      }
      return rowId;
    });

/// Rebases the draft on the just-saved anchor. The anchor row takes every
/// field from the saved transaction, and new split rows inherit its wallet,
/// date and type, so a draft loaded when the form opened cannot overwrite
/// later form edits.
void fireflyRebaseSplitDraft(
    FireflyTransactionDraft draft, Transaction saved, Set<String> newSplitPks) {
  if (draft.splits.isEmpty) return;
  draft.splits = [
    for (final row in draft.splits)
      if (row.transactionPk == '-1' || row.transactionPk == saved.transactionPk)
        saved
      else if (newSplitPks.contains(row.transactionPk))
        saved.copyWith(
          transactionPk: row.transactionPk,
          pairedTransactionFk: const Value(null),
          name: row.name,
          amount: row.amount,
          categoryFk: row.categoryFk,
          subCategoryFk: Value(row.subCategoryFk),
          note: '',
          dateTimeModified: const Value(null),
          payeeFk: const Value(null),
          foreignAmount: const Value(null),
          foreignCurrency: const Value(null),
          splitOrder: const Value(null),
          billFk: const Value(null),
          sharedKey: const Value(null),
          sharedOldKey: const Value(null),
          sharedStatus: const Value(null),
          sharedDateUpdated: const Value(null),
        )
      else
        row,
  ];
}

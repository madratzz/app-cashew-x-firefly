import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:drift/drift.dart';

class FireflyTransactionDraft {
  FireflyTransactionDraft(this.db);

  final FinanceDatabase db;
  String? payeePk;
  Set<String> tagPks = {};
  double? foreignAmount;
  String? foreignCurrency;
  List<Transaction> splits = [];
  String? splitTitle;
  String? billPk;
  String? piggyBankPk;
  String? budgetPk;
  List<Attachment> attachments = [];

  TransactionsCompanion _loaded = const TransactionsCompanion(
    payeeFk: Value(null),
    foreignAmount: Value(null),
    foreignCurrency: Value(null),
    billFk: Value(null),
    objectiveFk: Value(null),
    sharedReferenceBudgetPk: Value(null),
  );
  Set<String> _loadedTags = {};

  Future<void> load(String transactionPk) async {
    final row = await _transaction(transactionPk).getSingleOrNull();
    payeePk = row?.payeeFk;
    foreignAmount = row?.foreignAmount;
    foreignCurrency = row?.foreignCurrency;
    billPk = row?.billFk;
    piggyBankPk = row?.objectiveFk;
    budgetPk = row?.sharedReferenceBudgetPk;
    _loaded = _fields;
    final tags = await (db.select(db.transactionTags)
          ..where((tag) => tag.transactionFk.equals(transactionPk)))
        .get();
    tagPks = tags.map((tag) => tag.tagFk).toSet();
    _loadedTags = {...tagPks};

    final groupPk = row?.splitGroupFk;
    splits = groupPk == null ? [] : await db.fireflyGroupSplits(groupPk);
    splitTitle = groupPk == null ? null : await db.fireflyGroupTitle(groupPk);
    attachments = await db.fireflyTransactionAttachments(transactionPk);
  }

  /// Runs after the legacy transaction save. Untouched fields stay as stored.
  Future<void> persist(String transactionPk) async {
    await db.transaction(() async {
      final fields = _fields.toColumns(false);
      final loaded = _loaded.toColumns(false);
      fields.removeWhere((column, value) => value == loaded[column]);
      final editedTags = tagPks.difference(_loadedTags).isNotEmpty ||
          _loadedTags.difference(tagPks).isNotEmpty;

      if (fields.isNotEmpty || editedTags) {
        fields['date_time_modified'] = Variable(DateTime.now());
        await (db.update(db.transactions)
              ..where((row) => row.transactionPk.equals(transactionPk)))
            .write(RawValuesInsertable(fields));
      }
      if (editedTags) {
        final removed = _loadedTags.difference(tagPks);
        await (db.delete(db.transactionTags)
              ..where((row) =>
                  row.transactionFk.equals(transactionPk) &
                  row.tagFk.isIn(removed)))
            .go();
        await db.batch((batch) {
          batch.insertAll(
            db.transactionTags,
            [
              for (final tag in tagPks.difference(_loadedTags))
                TransactionTagLink(transactionFk: transactionPk, tagFk: tag),
            ],
            mode: InsertMode.insertOrIgnore,
          );
        });
      }
      await db.persistFireflyGroupDraft(transactionPk, splits, splitTitle);
      await db.persistFireflyAttachmentDraft(transactionPk, attachments);
    });
    _loaded = _fields;
    _loadedTags = {...tagPks};
  }

  TransactionsCompanion get _fields => TransactionsCompanion(
        payeeFk: Value(payeePk),
        foreignAmount: Value(foreignAmount),
        foreignCurrency: Value(foreignCurrency?.trim().toLowerCase()),
        billFk: Value(billPk),
        objectiveFk: Value(piggyBankPk),
        sharedReferenceBudgetPk: Value(budgetPk),
      );

  SimpleSelectStatement<$TransactionsTable, Transaction> _transaction(
          String pk) =>
      db.select(db.transactions)..where((row) => row.transactionPk.equals(pk));
}

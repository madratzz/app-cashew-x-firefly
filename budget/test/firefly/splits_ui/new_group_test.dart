import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/splits/split_save.dart';
import 'package:budget/firefly/ui/transaction/split_section.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

void main() {
  late FinanceDatabase db;

  // Drift's close never completes after a widget test, so the file shares one
  // in-memory database and clears it before each test.
  setUpAll(() async {
    appStateSettings = await getDefaultPreferences();
    db = await seededDatabase();
  });

  tearDownAll(() => db.close());

  setUp(() async {
    await db.delete(db.transactionTags).go();
    await db.delete(db.tags).go();
    await db.delete(db.transactions).go();
    await db.delete(db.transactionGroups).go();
    await seedGroup(db);
  });

  test('a new transaction with split rows becomes a group', () async {
    final draft = FireflyTransactionDraft(db);
    final anchor = Transaction(
      transactionPk: '-1',
      name: '',
      amount: 0,
      note: '',
      categoryFk: '-1',
      walletFk: '0',
      dateCreated: DateTime(2026, 1, 1),
      income: false,
      paid: true,
      skipPaid: false,
    );
    fireflyNewSplitPks(draft).add('extra');
    draft.splits = [
      anchor,
      anchor.copyWith(
          transactionPk: 'extra', name: 'Tip', amount: -1, categoryFk: 'food'),
    ];
    final rowId = await fireflySaveTransaction(
      db,
      anchor.copyWith(name: 'Dinner', amount: -20, categoryFk: 'food'),
      null,
      (row) async => await db.createOrUpdateTransaction(row, insert: true),
    );
    final saved = await db.getTransactionFromRowId(rowId!);
    fireflyRebaseSplitDraft(draft, saved, fireflyNewSplitPks(draft));
    await draft.persist(saved.transactionPk);

    final stored = await db.getTransactionFromPk(saved.transactionPk);
    final rows = await db.fireflyGroupSplits(stored.splitGroupFk!);
    expect(rows.map((row) => (row.name, row.amount, row.walletFk)), [
      ('Dinner', -20.0, '0'),
      ('Tip', -1.0, '0'),
    ]);
    expect(rows.last.dateCreated, saved.dateCreated);
  });
}

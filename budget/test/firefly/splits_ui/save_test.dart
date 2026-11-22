import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/db/split_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/splits/split_save.dart';
import 'package:budget/firefly/ui/transaction/split_section.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

class _FakeTokens extends TokenStore {
  @override
  Future<String?> read() async => 'REDACTED';
}

void main() {
  late FinanceDatabase db;
  late Transaction bread;
  late Transaction milk;

  // Drift's close never completes after a widget test, so the file shares one
  // in-memory database and clears it before each test.
  setUpAll(() async {
    appStateSettings = await getDefaultPreferences();
    // The edit keeps child rows because Firefly mode saves update in place.
    appStateSettings['fireflyMode'] = true;
    await FireflyMode.init(() => appStateSettings, tokenStore: _FakeTokens());
    db = await seededDatabase();
  });

  tearDownAll(() => db.close());

  setUp(() async {
    await db.delete(db.transactionTags).go();
    await db.delete(db.tags).go();
    await db.delete(db.transactions).go();
    await db.delete(db.transactionGroups).go();
    (bread, milk) = await seedGroup(db);
  });

  test('editing a tagged split keeps its tags and split membership', () async {
    await db.into(db.tags).insert(TagsCompanion.insert(
        tagPk: const Value('tag'), name: 'Groceries'));
    await db.into(db.transactionTags).insert(TransactionTagsCompanion.insert(
        transactionFk: milk.transactionPk, tagFk: 'tag'));

    // The form opened earlier, so its draft holds the old anchor row.
    final draft = FireflyTransactionDraft(db);
    await draft.load(milk.transactionPk);
    expect(draft.tagPks, {'tag'});

    // The legacy form rebuilds the row without schema 47 fields.
    final form = Transaction(
      transactionPk: milk.transactionPk,
      name: 'Oat milk',
      amount: -4,
      note: '',
      categoryFk: 'food',
      walletFk: '0',
      dateCreated: milk.dateCreated,
      income: false,
      paid: true,
      skipPaid: false,
    );
    final rowId = await fireflySaveTransaction(
      db,
      form,
      milk,
      (row) async =>
          await db.createOrUpdateTransaction(row, originalTransaction: milk),
    );
    final saved = await db.getTransactionFromRowId(rowId!);
    fireflyRebaseSplitDraft(draft, saved, fireflyNewSplitPks(draft));
    await draft.persist(saved.transactionPk);

    final tags = await db.select(db.transactionTags).get();
    expect(tags.map((tag) => (tag.transactionFk, tag.tagFk)),
        [(milk.transactionPk, 'tag')]);
    final rows = await db.fireflyGroupSplits(milk.splitGroupFk!);
    expect(rows.map((row) => (row.transactionPk, row.name, row.amount)), [
      (bread.transactionPk, 'Bread', -3.0),
      (milk.transactionPk, 'Oat milk', -4.0),
    ]);
    expect(rows.map((row) => row.splitOrder), [0, 1]);
    expect(await db.fireflyGroupTitle(milk.splitGroupFk!), 'Shop');
  });
}

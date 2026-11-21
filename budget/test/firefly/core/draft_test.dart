import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  test('draft loads, edits, clears selected fields and preserves legacy fields',
      () async {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('0'),
          name: 'Default',
          order: 0,
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('0'),
          name: 'Default',
          order: 0,
        ));
    final group = await db.into(db.transactionGroups).insertReturning(
          const TransactionGroupsCompanion(),
        );
    final row = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            name: 'Purchase',
            amount: -1,
            note: 'Legacy note',
            categoryFk: '0',
            foreignAmount: const Value(15),
            foreignCurrency: const Value('eur'),
            billFk: const Value('former-bill'),
            splitGroupFk: Value(group.groupPk),
            dateTimeModified: Value(fixtureTime),
          ),
        );

    final draft = FireflyTransactionDraft(db);
    await draft.load(row.transactionPk);
    expect(draft.foreignAmount, 15);
    expect(draft.billPk, 'former-bill');
    expect(draft.splits, isEmpty);
    expect(draft.attachments, isEmpty);
    await draft.persist(row.transactionPk);
    expect(await db.select(db.transactions).getSingle(), row);

    final tag = await db.into(db.tags).insertReturning(
          TagsCompanion.insert(name: 'Example'),
        );
    draft
      ..foreignCurrency = ' USD '
      ..foreignAmount = 20
      ..billPk = null
      ..tagPks = {tag.tagPk};
    await draft.persist(row.transactionPk);
    final saved = await db.select(db.transactions).getSingle();
    expect(saved.note, 'Legacy note');
    expect(saved.foreignCurrency, 'usd');
    expect(saved.foreignAmount, 20);
    expect(saved.billFk, isNull);
    expect(saved.dateTimeModified!.isAfter(fixtureTime), isTrue);
    expect((await db.select(db.transactionTags).getSingle()).tagFk, tag.tagPk);

    await draft.load(row.transactionPk);
    expect(draft.tagPks, {tag.tagPk});
    draft.tagPks.clear();
    await draft.persist(row.transactionPk);
    expect(await db.select(db.transactionTags).get(), isEmpty);
  });
}

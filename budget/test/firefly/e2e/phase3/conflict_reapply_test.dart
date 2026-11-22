import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/ui/pages/connection/conflicts_page.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  final at = DateTime(2026, 3, 1, 12);

  setUp(() async {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Default', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('food'), name: 'Food', order: 0));
    for (final pk in ['a', 'b']) {
      await db.into(db.tags).insert(TagsCompanion.insert(
          tagPk: Value(pk), name: 'Tag ${pk.toUpperCase()}'));
    }
  });

  Future<FireflyConflict> record(FireflyEntityType type, String pk,
          Map<String, Object?> local) =>
      ConflictRepository(db).record(
          type: type,
          localPk: pk,
          remoteId: '7',
          local: local,
          resolution: 'remoteWins');

  test('a tag-only transaction conflict restores the local tags and group',
      () async {
    await db.into(db.transactionGroups).insert(const TransactionGroupsCompanion(
        groupPk: Value('g'), title: Value('Shop')));
    final row = await db.into(db.transactions).insertReturning(
        TransactionsCompanion.insert(
            transactionPk: const Value('t'),
            name: 'Milk',
            amount: -2,
            note: '',
            categoryFk: 'food',
            splitGroupFk: const Value('g'),
            splitOrder: const Value(0)));
    await db.into(db.transactionTags).insert(
        TransactionTagsCompanion.insert(transactionFk: 't', tagFk: 'a'));
    final snapshot = await db.fireflyTransactionSnapshot(row);
    expect(snapshot[fireflySnapshotTagPks], ['a']);
    final conflict =
        await record(FireflyEntityType.transaction, 't', snapshot);

    // The server version replaced the local tags and the group title.
    await db.delete(db.transactionTags).go();
    await db.into(db.transactionTags).insert(
        TransactionTagsCompanion.insert(transactionFk: 't', tagFk: 'b'));
    await (db.update(db.transactionGroups)
          ..where((group) => group.groupPk.equals('g')))
        .write(const TransactionGroupsCompanion(title: Value('Market')));

    expect(await reapplyFireflyConflict(db, conflict, now: () => at), isTrue);
    final links = await db.select(db.transactionTags).get();
    expect(links.map((link) => link.tagFk), ['a']);
    final saved = await db.fireflyTransaction('t');
    expect((saved!.splitGroupFk, saved.dateTimeModified), ('g', at));
    expect((await db.fireflyTransactionGroup('g'))!.title, 'Shop');
  });

  test('a payee conflict reapplies the local payee', () async {
    final payee = await db.into(db.payees).insertReturning(
        PayeesCompanion.insert(
            payeePk: const Value('p'),
            name: 'Corner shop',
            kind: PayeeKind.expense));
    final conflict =
        await record(FireflyEntityType.payeeAccount, 'p', payee.toJson());
    await (db.update(db.payees)..where((row) => row.payeePk.equals('p')))
        .write(const PayeesCompanion(name: Value('Server name')));

    expect(await reapplyFireflyConflict(db, conflict, now: () => at), isTrue);
    final saved = await db.select(db.payees).getSingle();
    expect((saved.name, saved.dateTimeModified), ('Corner shop', at));
  });
}

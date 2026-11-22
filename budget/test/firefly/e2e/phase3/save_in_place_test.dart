import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_database.dart';

class _FakeTokens extends TokenStore {
  _FakeTokens(this.token);

  final String? token;

  @override
  Future<String?> read() async => token;
}

Future<void> _setMode(bool on) async {
  appStateSettings['fireflyMode'] = on;
  await FireflyMode.init(() => appStateSettings,
      tokenStore: _FakeTokens(on ? 'REDACTED' : null));
}

Future<int> _rowId(FinanceDatabase db, String pk) async =>
    (await db.customSelect('SELECT rowid FROM transactions '
            'WHERE transaction_pk = ?',
            variables: [Variable.withString(pk)]).getSingle())
        .read<int>('rowid');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late Transaction milk;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    db = inMemoryFinanceDatabase();
    database = db;
    addTearDown(db.close);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Default', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('food'), name: 'Food', order: 0));
    final group = await db.into(db.transactionGroups).insertReturning(
        const TransactionGroupsCompanion(title: Value('Shop')));
    milk = await db.into(db.transactions).insertReturning(
        TransactionsCompanion.insert(
            name: 'Milk',
            amount: -2,
            note: '',
            categoryFk: 'food',
            splitGroupFk: Value(group.groupPk),
            splitOrder: const Value(1)));
    await db.into(db.tags).insert(
        TagsCompanion.insert(tagPk: const Value('tag'), name: 'Groceries'));
    await db.into(db.transactionTags).insert(TransactionTagsCompanion.insert(
        transactionFk: milk.transactionPk, tagFk: 'tag'));
    await db.into(db.attachments).insert(AttachmentsCompanion.insert(
        attachmentPk: const Value('att'),
        attachableType: 'TransactionJournal',
        attachableFk: milk.transactionPk,
        filename: 'receipt.jpg',
        uploadState: 'synced'));
    await db.into(db.fireflyIdMap).insert(FireflyIdMapCompanion.insert(
        entityType: FireflyEntityType.transaction,
        localPk: milk.transactionPk,
        remoteId: '42',
        state: FireflySyncState.synced));
  });

  tearDown(() => _setMode(false));

  test('Firefly mode edits a transaction in place and keeps its child rows',
      () async {
    await _setMode(true);
    final before = await _rowId(db, milk.transactionPk);
    final rowId = await db.createOrUpdateTransaction(
        milk.copyWith(name: 'Oat milk', amount: -4),
        originalTransaction: milk);

    expect(rowId, before);
    final saved = await db.getTransactionFromPk(milk.transactionPk);
    expect((saved.name, saved.amount), ('Oat milk', -4.0));
    expect((saved.splitGroupFk, saved.splitOrder),
        (milk.splitGroupFk, milk.splitOrder));
    expect((await db.select(db.transactionTags).get()).single.transactionFk,
        milk.transactionPk);
    expect((await db.select(db.attachments).get()).single.attachableFk,
        milk.transactionPk);
    final mapping = (await db.select(db.fireflyIdMap).get()).single;
    expect((mapping.localPk, mapping.remoteId), (milk.transactionPk, '42'));
  });

  test('Firefly mode off keeps the legacy replacing save', () async {
    final before = await _rowId(db, milk.transactionPk);
    await db.createOrUpdateTransaction(milk.copyWith(name: 'Oat milk'),
        originalTransaction: milk);
    expect(await _rowId(db, milk.transactionPk), isNot(before));
  });

  test('every transaction delete path removes its tag links', () async {
    // Native SQLite runs without foreign keys, so the cascade must not be
    // relied on.
    await db.customStatement('PRAGMA foreign_keys = OFF');
    Future<void> tagged(String pk) async {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: Value(pk),
          name: pk,
          amount: -1,
          note: '',
          categoryFk: 'food'));
      await db.into(db.transactionTags).insert(
          TransactionTagsCompanion.insert(transactionFk: pk, tagFk: 'tag'));
    }

    Future<Set<String>> linked() async => {
          for (final link in await db.select(db.transactionTags).get())
            link.transactionFk
        };

    await tagged('a');
    await tagged('b');
    await tagged('c');
    await db.deleteTransaction('a');
    expect(await linked(), {milk.transactionPk, 'b', 'c'});
    await db.deleteTransactions(['b']);
    expect(await linked(), {milk.transactionPk, 'c'});
    await db.removeFireflyTransactions(['c']);
    expect(await linked(), {milk.transactionPk});
    await db.deleteCategoryTransactions('food');
    expect(await linked(), isEmpty);
  });
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/filter_queries.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => 'REDACTED';

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> delete() async {}
}

void main() {
  late FinanceDatabase db;
  late Payee shop;
  late Tag food, travel;
  late String bill;
  var keepOpen = false;

  Future<void> seed(String pk, int day,
      {String name = 'Row',
      String? payeePk,
      String? billPk,
      bool reconciled = false,
      String? paired,
      Set<Tag> tagged = const {}}) async {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: Value(pk),
          name: name,
          amount: -1,
          note: '',
          categoryFk: '0',
          payeeFk: Value(payeePk),
          billFk: Value(billPk),
          reconciled: Value(reconciled),
          pairedTransactionFk: Value(paired),
          dateCreated: Value(DateTime(2026, 1, day)),
        ));
    await db.replaceFireflyTransactionTagLinks(
        pk, {for (final tag in tagged) tag.tagPk});
  }

  Future<void> attach(String pk, {String state = 'uploaded'}) =>
      db.into(db.attachments).insert(AttachmentsCompanion.insert(
            attachableType: FireflyAttachment.transactionJournal,
            attachableFk: pk,
            filename: 'receipt.pdf',
            uploadState: state,
          ));

  setUp(() async {
    db = inMemoryFinanceDatabase();
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Wallet', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Balance', order: 0));
    shop = await db.fireflyCreatePayee(
        name: 'Corner shop', kind: PayeeKind.expense);
    food = await db.saveFireflyTag(name: 'food');
    travel = await db.saveFireflyTag(name: 'travel');
    await db.writeFireflySchedule(
        FireflyEntityType.bill, '7', {'name': 'Internet', 'active': true});
    bill = ResourceCacheRepository.resourcePk(FireflyEntityType.bill, '7');

    await seed('a', 1, payeePk: shop.payeePk, tagged: {food});
    await seed('b', 2, tagged: {food, travel}, reconciled: true);
    await seed('c', 3, billPk: bill, tagged: {travel});
    await seed('d', 4, name: 'Plain');
    await seed('e', 5, paired: 'd');
    await attach('b');
    await attach('d');
    await attach('c', state: 'deleted');
  });

  tearDown(() async {
    if (!keepOpen) await db.close();
    keepOpen = false;
  });

  test('no filter returns every transaction, newest first', () async {
    expect(await db.fireflyFilteredTransactionPks(), ['e', 'd', 'c', 'b', 'a']);
  });

  test('payee', () async {
    expect(
        await db.fireflyFilteredTransactionPks(payeePk: shop.payeePk), ['a']);
  });

  test('tags match any or all', () async {
    final both = [food.tagPk, travel.tagPk];
    expect(
        await db.fireflyFilteredTransactionPks(tagPks: both), ['c', 'b', 'a']);
    expect(
        await db.fireflyFilteredTransactionPks(
            tagPks: both, matchAllTags: true),
        ['b']);
    expect(
        await db.fireflyFilteredTransactionPks(
            tagPks: [food.tagPk], matchAllTags: true),
        ['b', 'a']);
  });

  test('bill', () async {
    expect(await db.fireflyFilteredTransactionPks(billPk: bill), ['c']);
  });

  test('reconciled', () async {
    expect(await db.fireflyFilteredTransactionPks(reconciled: true), ['b']);
    expect(await db.fireflyFilteredTransactionPks(reconciled: false),
        ['e', 'd', 'c', 'a']);
  });

  test('has attachment includes the paired side and skips deleted files',
      () async {
    expect(await db.fireflyFilteredTransactionPks(hasAttachment: true),
        ['e', 'd', 'b']);
    expect(await db.fireflyFilteredTransactionPks(hasAttachment: false),
        ['c', 'a']);
  });

  test('filters combine', () async {
    expect(
        await db.fireflyFilteredTransactionPks(
            tagPks: [travel.tagPk], hasAttachment: true),
        ['b']);
  });

  test('offline search matches payee and tag names with legacy filters',
      () async {
    final filters = SearchFilters(searchQuery: 'corner');
    final rows = await db
        .watchFireflyFilteredTransactions(FireflySearchFilters(),
            searchFilters: filters)
        .first;
    expect(rows.map((row) => row.transactionPk), ['a']);

    final byTag = await db
        .watchFireflyFilteredTransactions(
            FireflySearchFilters(reconciled: true),
            searchFilters: SearchFilters(searchQuery: 'TRAVEL'))
        .first;
    expect(byTag.map((row) => row.transactionPk), ['b']);

    final extra = await db.watchFireflyPayeeTagMatches('food').first;
    expect(extra.map((row) => row.transactionPk), ['b', 'a']);
    expect(await db.watchFireflyPayeeTagMatches('plain').first, isEmpty);
    expect(await db.watchFireflyPayeeTagMatches(' ').first, isEmpty);
  });

  test('filter string round trip keeps Firefly filters', () {
    final filters = SearchFilters(
        firefly: FireflySearchFilters(
      payeePk: 'p',
      tagPks: ['t1', 't2'],
      matchAllTags: true,
      billPk: 'b',
      reconciled: false,
      hasAttachment: true,
    ));
    expect(filters.isClear(), isFalse);
    final loaded = SearchFilters()..loadFilterString(filters.getFilterString());
    expect(loaded.firefly.payeePk, 'p');
    expect(loaded.firefly.tagPks, ['t1', 't2']);
    expect(loaded.firefly.matchAllTags, isTrue);
    expect(loaded.firefly.billPk, 'b');
    expect(loaded.firefly.reconciled, isFalse);
    expect(loaded.firefly.hasAttachment, isTrue);
    expect(loaded.copyWith().firefly.tagPks, ['t1', 't2']);
    loaded.clearSearchFilters();
    expect(loaded.firefly.isClear, isTrue);
    expect(loaded.isClear(), isTrue);
    expect(SearchFilters().getFilterString(), isNot(contains('firefly')));
  });

  testWidgets('filters are hidden with Firefly mode off', (tester) async {
    await tester.runAsync(() => FireflyMode.init(
        () => {FireflyConfig.modeKey: false},
        tokenStore: _Tokens()));
    expect(showFireflySearchFilters(true), isFalse);

    await tester.runAsync(() => FireflyMode.init(
        () => {
              FireflyConfig.modeKey: true,
              FireflyConfig.baseUrlKey: 'https://firefly.example',
            },
        tokenStore: _Tokens()));
    expect(showFireflySearchFilters(true), isTrue);
    expect(showFireflySearchFilters(false), isFalse);
    await tester.runAsync(() => FireflyMode.init(
        () => {FireflyConfig.modeKey: false},
        tokenStore: _Tokens()));
  });

  testWidgets('section toggles payee, tags, bill and status filters',
      (tester) async {
    final previous = appStateSettings;
    appStateSettings = {...previous, 'materialYou': false};
    addTearDown(() => appStateSettings = previous);
    final filters = FireflySearchFilters();
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FireflyFiltersSection(
            db: db,
            filters: filters,
            onChanged: () => changes++,
          ),
        ),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('Corner shop').last);
    await tester.tap(find.text('food').last);
    await tester.tap(find.text('travel').last);
    await tester.tap(find.text('firefly-filters-match-all-tags').last);
    await tester.tap(find.text('Internet').last);
    await tester.tap(find.text('firefly-filters-reconciled').last);
    await tester.tap(find.text('firefly-filters-has-attachment').last);
    await tester.pump();
    expect(changes, 7);
    expect(filters.payeePk, shop.payeePk);
    expect(filters.tagPks, [food.tagPk, travel.tagPk]);
    expect(filters.matchAllTags, isTrue);
    expect(filters.billPk, bill);
    expect(filters.reconciled, isTrue);
    expect(filters.hasAttachment, isTrue);

    await tester.tap(find.text('food').last);
    await tester.tap(find.text('Corner shop').last);
    await tester.pump();
    expect(filters.tagPks, [travel.tagPk]);
    expect(filters.payeePk, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    // Drift's close waits on stream timers owned by the fake-async zone;
    // the in-memory database is dropped instead.
    keepOpen = true;
  });
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/entry/tags_chip.dart';
import 'package:budget/firefly/ui/pages/tags/tags_page.dart';
import 'package:budget/firefly/ui/transaction/tags_section.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  late Transaction row;
  late Tag food;
  late Tag travel;

  setUp(() async {
    db = inMemoryFinanceDatabase();
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Wallet', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Balance', order: 0));
    row = await db.into(db.transactions).insertReturning(
        TransactionsCompanion.insert(
            name: 'Lunch', amount: -10, note: '', categoryFk: '0'));
    food = await db.saveFireflyTag(name: 'Food');
    travel = await db.saveFireflyTag(name: 'Reise ✈');
  });

  // Closing Drift after its stream widgets hangs under the fake clock, so
  // each test unmounts and leaves the in-memory database to be collected
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<T> io<T>(WidgetTester tester, Future<T> Function() run) async =>
      (await tester.runAsync(run)) as T;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('tags section', () {
    Future<FireflyTransactionDraft> pump(WidgetTester tester) async {
      final draft = FireflyTransactionDraft(db)..tagPks = {food.tagPk};
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: FireflyTagsSection(draft: draft))));
      await settle(tester);
      return draft;
    }

    testWidgets('adds and removes existing tags', (tester) async {
      final draft = await pump(tester);
      expect(
          find.byKey(ValueKey('firefly-tag-selected-${food.tagPk}')), findsOne);
      await tester
          .tap(find.byKey(ValueKey('firefly-tag-option-${travel.tagPk}')));
      await tester.pump();
      expect(draft.tagPks, {food.tagPk, travel.tagPk});
      await tester
          .tap(find.byKey(ValueKey('firefly-tag-selected-${food.tagPk}')));
      await tester.pump();
      expect(draft.tagPks, {travel.tagPk});
      await finish(tester);
    });

    testWidgets('creates a new tag from search', (tester) async {
      final draft = await pump(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-tags-search')), 'Gifts');
      await tester.pump();
      expect(find.byKey(const ValueKey('firefly-tag-create')), findsOne);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('firefly-tag-create')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await settle(tester);
      final gifts = (await io(tester, db.fireflyTags))
          .singleWhere((t) => t.name == 'Gifts');
      expect(draft.tagPks, contains(gifts.tagPk));
      await finish(tester);
    });

    testWidgets('no create option for an existing name', (tester) async {
      await pump(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-tags-search')), 'food');
      await tester.pump();
      expect(find.byKey(const ValueKey('firefly-tag-create')), findsNothing);
      await finish(tester);
    });
  });

  group('tags chip', () {
    testWidgets('shows linked tags and hides when none', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: FireflyTagsChip(transaction: row, db: db))));
      await settle(tester);
      expect(find.byKey(const ValueKey('firefly-tags-chip')), findsNothing);
      await io(
          tester,
          () => db.replaceFireflyTransactionTagLinks(
              row.transactionPk, {food.tagPk, travel.tagPk}));
      await settle(tester);
      expect(find.text('#Food'), findsOne);
      expect(find.text('#Reise ✈'), findsOne);
      await finish(tester);
    });
  });

  group('tags page', () {
    late int writes;

    Future<void> pump(WidgetTester tester) async {
      writes = 0;
      await tester.pumpWidget(MaterialApp(
          home: FireflyTagsPage(db: db, onLocalWrite: () => writes++)));
      await settle(tester);
    }

    Future<void> tapAsync(WidgetTester tester, Finder finder) async {
      await tester.runAsync(() async {
        await tester.tap(finder);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await settle(tester);
    }

    testWidgets('lists, creates, renames and deletes', (tester) async {
      await pump(tester);
      expect(find.text('Food'), findsOne);

      await tester.tap(find.byKey(const ValueKey('firefly-tags-add')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
          find.byKey(const ValueKey('firefly-tag-name-field')), 'Rent');
      await tapAsync(tester, find.byKey(const ValueKey('firefly-tag-save')));
      expect(find.text('Rent'), findsOne);
      expect(writes, 1);

      await tester.tap(find.byKey(ValueKey('firefly-tag-${food.tagPk}')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
          find.byKey(const ValueKey('firefly-tag-name-field')), 'Groceries');
      await tapAsync(tester, find.byKey(const ValueKey('firefly-tag-save')));
      expect((await io(tester, () => db.fireflyTag(food.tagPk)))!.name,
          'Groceries');
      expect(writes, 2);

      await io(
          tester,
          () => db.replaceFireflyTransactionTagLinks(
              row.transactionPk, {food.tagPk}));
      await tester
          .tap(find.byKey(ValueKey('firefly-tag-delete-${food.tagPk}')));
      await tester.pump(const Duration(milliseconds: 500));
      await tapAsync(
          tester, find.byKey(const ValueKey('firefly-tag-delete-confirm')));
      expect(await io(tester, () => db.fireflyTag(food.tagPk)), isNull);
      expect(
          await io(tester, () => db.fireflyTransactionTags(row.transactionPk)),
          isEmpty);
      expect(writes, 3);
      await finish(tester);
    });

    testWidgets('rejects duplicate names', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('firefly-tags-add')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
          find.byKey(const ValueKey('firefly-tag-name-field')), 'FOOD');
      await tapAsync(tester, find.byKey(const ValueKey('firefly-tag-save')));
      expect(find.byKey(const ValueKey('firefly-tag-name-field')), findsOne);
      expect(writes, 0);
      expect((await io(tester, db.fireflyTags)).length, 2);
      await finish(tester);
    });
  });
}

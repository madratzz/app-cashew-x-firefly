import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/transaction/split_section.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
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

  setUp(() async {
    await db.delete(db.transactionTags).go();
    await db.delete(db.tags).go();
    await db.delete(db.transactions).go();
    await db.delete(db.transactionGroups).go();
    await seedGroup(db);
  });

  testWidgets('split editor adds rows, totals them and validates',
      (tester) async {
    final draft = FireflyTransactionDraft(db);
    await pumpSplitWidget(tester, FireflySplitEditor(draft: draft));

    await tester.tap(find.byKey(const ValueKey('firefly-split-start')));
    await tester.pump();
    expect(draft.splits, hasLength(2));
    expect(find.byKey(const ValueKey('firefly-split-anchor')), findsOneWidget);
    expect(find.text('firefly-splits-group-title-default-main'),
        findsOneWidget);
    expect(fireflySplitDraftError(draft), 'firefly-splits-error-description');
    expect(find.byKey(const ValueKey('firefly-split-error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('firefly-split-add')));
    await tester.pump();
    expect(draft.splits, hasLength(3));
    final rows = draft.splits.skip(1).toList();
    for (final (index, row) in rows.indexed) {
      final editor = find.byKey(ValueKey('firefly-split-${row.transactionPk}'));
      await tester.enterText(
          find.descendant(
              of: editor, matching: find.byKey(const ValueKey('description'))),
          'Part $index');
      await tester.enterText(
          find.descendant(
              of: editor, matching: find.byKey(const ValueKey('amount'))),
          '${index + 1}.5');
    }
    await tester.pump();
    expect(fireflySplitDraftError(draft), isNull);
    expect(find.byKey(const ValueKey('firefly-split-error')), findsNothing);
    expect(draft.splits.skip(1).map((row) => row.amount), [-1.5, -2.5]);
    final total = tester.widget<Text>(
        find.byKey(const ValueKey('firefly-split-total')));
    expect(total.data, 'firefly-splits-total');
    expect(fireflyNewSplitPks(draft), rows.map((row) => row.transactionPk));

    await tester.enterText(
        find.descendant(
            of: find.byKey(ValueKey('firefly-split-${rows[0].transactionPk}')),
            matching: find.byKey(const ValueKey('amount'))),
        '0');
    await tester.pump();
    expect(fireflySplitDraftError(draft), 'firefly-splits-error-amount');

    // Removing down to one journal turns the draft into a normal transaction.
    for (final row in rows) {
      await tester.tap(find.descendant(
          of: find.byKey(ValueKey('firefly-split-${row.transactionPk}')),
          matching: find.byKey(const ValueKey('remove'))));
      await tester.pump();
    }
    expect(draft.splits, isEmpty);
    expect(find.byKey(const ValueKey('firefly-split-start')), findsOneWidget);
  });
}

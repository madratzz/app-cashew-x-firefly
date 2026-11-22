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
  late Transaction bread;
  late Transaction milk;

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
    (bread, milk) = await seedGroup(db);
  });

  testWidgets('a stored group shows the edited row as the main split',
      (tester) async {
    final draft = FireflyTransactionDraft(db);
    await tester.runAsync(() => draft.load(milk.transactionPk));
    fireflySetSplitAnchor(draft, milk.transactionPk);
    await pumpSplitWidget(tester, FireflySplitEditor(draft: draft));

    expect(find.byKey(const ValueKey('firefly-split-anchor')), findsOneWidget);
    expect(find.byKey(ValueKey('firefly-split-${bread.transactionPk}')),
        findsOneWidget);
    expect(find.text('firefly-splits-group-title-default'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });
}

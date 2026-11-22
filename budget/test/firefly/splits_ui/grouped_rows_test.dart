import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/entry/split_chip.dart';
import 'package:budget/firefly/ui/pages/splits/splits_page.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
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

  testWidgets('grouped rows show their position and open the group',
      (tester) async {
    await pumpSplitWidget(
        tester,
        Builder(
            builder: (context) => fireflySplitChip(
                context, bread.copyWith(splitGroupFk: const Value(null)))));
    expect(find.byType(FireflySplitChip), findsNothing);
    await pumpSplitWidget(tester, FireflySplitChip(transaction: milk, db: db));
    expect(find.text('firefly-splits-chip-position'), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.runAsync(() => tester.pump());
    await tester.pump(const Duration(milliseconds: 500));
    await settleDb(tester);
    await tester.pump();
    expect(find.byType(FireflySplitsPage), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('-5.00'), findsOneWidget);
  });
}

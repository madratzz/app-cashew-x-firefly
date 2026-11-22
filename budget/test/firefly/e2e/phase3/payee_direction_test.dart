import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/transaction/payee_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  for (final (income, shown, hidden) in [
    (true, 'Employer', 'Shop'),
    (false, 'Shop', 'Employer'),
  ]) {
    testWidgets('a draft with income $income opens the picker on $shown',
        (tester) async {
      final db = inMemoryFinanceDatabase();
      await tester.runAsync(() async {
        await db.fireflyCreatePayee(name: 'Shop', kind: PayeeKind.expense);
        await db.fireflyCreatePayee(name: 'Employer', kind: PayeeKind.revenue);
      });
      final draft = FireflyTransactionDraft(db)..income = income;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: FireflyPayeePicker(draft: draft))));
      Future<void> settle() async {
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
      }

      await settle();
      await tester.tap(find.byKey(const ValueKey('firefly-payee-picker')));
      await settle();
      expect(find.text(shown), findsOneWidget);
      expect(find.text(hidden), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      db.close();
    });
  }
}

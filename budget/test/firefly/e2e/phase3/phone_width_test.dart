import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/slots.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_database.dart';

class _FakeTokens extends TokenStore {
  @override
  Future<String?> read() async => 'REDACTED';
}

void main() {
  late FinanceDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['fireflyMode'] = true;
    await FireflyMode.init(() => appStateSettings, tokenStore: _FakeTokens());
    db = inMemoryFinanceDatabase();
    database = db;
  });

  tearDown(() async {
    appStateSettings['fireflyMode'] = false;
    await FireflyMode.init(() => appStateSettings);
    // Awaiting close inside a fake-async widget test never completes.
    db.close();
  });

  testWidgets('every add-transaction section fits a phone screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final draft = FireflyTransactionDraft(db)..income = false;
    final types = <Type>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(builder: (context) {
            types
              ..clear()
              ..addAll([
                for (final build in fireflyTransactionSections)
                  build(context, draft).runtimeType,
              ]);
            return FireflyTransactionExtras(draft: draft);
          }),
        ),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(types, hasLength(fireflyTransactionSections.length));
    for (final type in types) {
      final section = find.byWidgetPredicate((w) => w.runtimeType == type);
      expect(section, findsWidgets, reason: '$type');
      expect(tester.getSize(section.first).width, lessThanOrEqualTo(390),
          reason: '$type');
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/pages/links/links_page.dart';
import 'package:budget/firefly/ui/pages/links/object_group_label.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/e2e_harness.dart';
import 'links_test.dart' show seedLocalTargets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('creates and removes a directed link from the links page',
      (tester) async {
    final db = inMemoryFinanceDatabase();
    final transport = FakeFireflyTransport()
      ..seed('/link-types', '1', {
        'name': 'Paid',
        'inward': 'is paid by',
        'outward': 'pays for',
      });
    final context =
        SyncContext(db: db, api: FireflyApi(transport), config: e2eConfig);
    await tester.runAsync(() => seedLocalTargets(context));
    await tester.pumpWidget(_localized(
      home: FireflyLinksPage(db: db, syncContext: () async => context),
    ));
    await _settle(tester);

    await tester.tap(find.text('Create transaction link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'internet');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Internet bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Internet bill').hitTestable(), findsNothing);
    await tester.tap(find.text('Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relationship'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('is paid by').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create link'));
    await _settle(tester);
    expect(find.text('Internet bill is paid by Payment'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove link'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove link'));
    await _settle(tester);
    expect(find.text('No transaction links'), findsOneWidget);
    expect(
        transport.requests
            .where((request) => request.method != 'GET')
            .map((request) => (request.method, request.path)),
        [
          ('POST', '/transaction-links'),
          ('DELETE', '/transaction-links/1'),
        ]);
    await _close(tester, db);
  });

  testWidgets('renders group labels using cached bills and piggy banks',
      (tester) async {
    final db = inMemoryFinanceDatabase();
    final context = SyncContext(
        db: db, api: FireflyApi(FakeFireflyTransport()), config: e2eConfig);
    await tester.runAsync(() async {
      await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value("0"), name: "Default", order: 0));
      await db.into(db.objectives).insert(ObjectivesCompanion.insert(
            objectivePk: const Value('goal'),
            name: 'Savings',
            amount: 10,
            type: const Value(ObjectiveType.goal),
            order: 0,
          ));
      await context.idMap.put(fixtureMapping(
          type: FireflyEntityType.piggyBank, localPk: 'goal', remoteId: '10'));
      await context.cache.write(FireflyEntityType.piggyBank, '10', {
        'id': '10',
        'attributes': {'name': 'Savings', 'object_group_title': 'Household'},
      });
    });
    await tester.pumpWidget(_localized(
      home: Scaffold(
        body: Column(children: [
          const FireflyObjectGroupLabel(
              attributes: {'object_group_title': 'Utilities'}),
          FireflyPiggyBankObjectGroupLabel(db: db, objectivePk: 'goal'),
          const FireflyObjectGroupLabel(attributes: {}),
        ]),
      ),
    ));
    await _settle(tester);
    expect(find.text('Object group: Household'), findsOneWidget);
    expect(find.text('Object group: Utilities'), findsOneWidget);
    await _close(tester, db);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester, FinanceDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  db.close();
}

Widget _localized({required Widget home}) => EasyLocalization(
      startLocale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      path: 'assets/translations/firefly/en/links.json',
      assetLoader: const _LinksTranslations(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: home,
        ),
      ),
    );

class _LinksTranslations extends AssetLoader {
  const _LinksTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

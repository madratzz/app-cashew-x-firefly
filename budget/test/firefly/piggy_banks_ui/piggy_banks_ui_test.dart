import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/piggy_banks/piggy_bank_events_page.dart';
import 'package:budget/firefly/ui/pages/piggy_banks/piggy_bank_ui.dart';
import 'package:budget/firefly/ui/transaction/piggy_section.dart';
import 'package:budget/pages/addObjectivePage.dart';
import 'package:budget/pages/objectivesListPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

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

const _bank = {
  'name': 'Trip',
  'target_amount': '100.00',
  'current_amount': '40.00',
  'currency_decimal_places': 2,
  'accounts': [
    {'id': '21', 'current_amount': '40.00'}
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late Objective goal;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    db = inMemoryFinanceDatabase();
    database = db;
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Default', order: 0));
    goal = await db.into(db.objectives).insertReturning(
        ObjectivesCompanion.insert(
            name: 'Trip', amount: 100, order: 0, walletFk: const Value('0')));
    await IdMapRepository(db).put(fixtureMapping(
        type: FireflyEntityType.piggyBank,
        localPk: goal.objectivePk,
        remoteId: '31'));
    await ResourceCacheRepository(db).write(FireflyEntityType.piggyBank, '31', {
      'id': '31',
      'attributes': _bank,
      'events': [
        {
          'id': '1',
          'attributes': {
            'created_at': '2024-01-02T00:00:00Z',
            'amount': '40.00',
            'transaction_journal_id': '7',
          }
        }
      ],
    });
  });

  tearDown(() => _setMode(false));

  // Closing Drift after its stream widgets hangs under the fake clock, so
  // each test unmounts and leaves the in-memory database to be collected
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpProgress(WidgetTester tester) async {
    await tester.pumpWidget(Provider<AllWallets>.value(
      value: AllWallets(list: [], indexedByPk: {}),
      child: MaterialApp(
        home: WatchTotalAndAmountOfObjective(
          objective: goal,
          builder: (amount, total, percentage) =>
              Text('$total of $amount', textDirection: TextDirection.ltr),
        ),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  testWidgets('Firefly mode shows the server saved amount as progress',
      (tester) async {
    await _setMode(true);
    await pumpProgress(tester);
    expect(find.text('40.0 of 100.0'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('legacy mode keeps the local transaction total', (tester) async {
    await _setMode(false);
    await pumpProgress(tester);
    expect(find.textContaining('0.0 of 100.0'), findsOneWidget);
    expect(find.text('40.0 of 100.0'), findsNothing);
    expect(find.byType(FireflyPiggyBankActions), findsNothing);
    await finish(tester);
  });

  testWidgets('add money sends the new total to Firefly', (tester) async {
    await _setMode(true);
    final transport = FakeFireflyTransport();
    transport.seed('/piggy-banks', '31', _bank);
    fireflyPiggySyncContext = () async => SyncContext(
          db: db,
          api: FireflyApi(transport),
          config: const FireflyConfig(
              mode: true, baseUrl: 'https://piggy.test.invalid'),
        );
    addTearDown(() => fireflyPiggySyncContext = () async => null);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: FireflyPiggyBankActions(db: db, objective: goal)),
    ));
    await tester.tap(find.text('firefly-piggy-add-money'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('firefly-piggy-amount')), '12.5');
    await tester.tap(find.text('firefly-piggy-save'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    final put = transport.requests.singleWhere((r) => r.method == 'PUT');
    expect(put.path, '/piggy-banks/31');
    expect(put.body!['accounts'], [
      {'account_id': '21', 'current_amount': '52.50'}
    ]);
    await finish(tester);
  });

  testWidgets('history lists cached events', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: FireflyPiggyBankEventsPage(db: db, objective: goal)));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('+40.00'), findsOneWidget);
    expect(find.textContaining('firefly-piggy-linked-transaction'),
        findsOneWidget);
    await finish(tester);
  });

  testWidgets('transaction section offers synced goals', (tester) async {
    final draft = FireflyTransactionDraft(db);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => fireflyPiggySection(context, draft))),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('firefly-piggy-section')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trip').last);
    await tester.pumpAndSettle();
    expect(draft.piggyBankPk, goal.objectivePk);
    await finish(tester);
  });

  testWidgets('loan creation is hidden in Firefly mode only', (tester) async {
    await _setMode(true);
    expect(fireflyHidesLoanCreation(ObjectiveType.loan), isTrue);
    expect(fireflyHidesLoanCreation(ObjectiveType.goal), isFalse);
    await tester.pumpWidget(MaterialApp(
      home: AddObjectivePage(
        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
        objectiveType: ObjectiveType.loan,
      ),
    ));
    await tester.pump();
    expect(find.text('firefly-piggy-loans-unavailable'), findsOneWidget);
    await finish(tester);

    await _setMode(false);
    expect(fireflyHidesLoanCreation(ObjectiveType.loan), isFalse);
    await finish(tester);
  });
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/firefly/ui/pages/rules/common.dart';
import 'package:budget/firefly/ui/pages/rules/rule_run_page.dart';
import 'package:budget/firefly/ui/pages/rules/rules_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _config = FireflyConfig(mode: true, baseUrl: 'https://firefly.example');

/// Unmounts inside the test body: Drift stream queries leave a zero-length
/// timer that must fire before the binding checks for pending timers.
WidgetTester? _tester;

void widgetTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      _tester = tester;
      addTearDown(() => _tester = null);
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

/// Drift I/O awaited outside a pump never completes under fake async.
Future<T> io<T>(Future<T> Function() run) async {
  final tester = _tester;
  if (tester == null) return run();
  return (await tester.runAsync(run)) as T;
}

/// Alternates real and fake time so Drift queries and streams complete.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

ValueKey<String> _key(String value) => ValueKey(value);

JsonObject _rule(String group, String title, {bool active = true}) => {
      'title': title,
      'rule_group_id': group,
      'order': 1,
      'trigger': 'store-journal',
      'active': active,
      'strict': true,
      'stop_processing': false,
      'triggers': [
        {'type': 'description_contains', 'value': 'Market'}
      ],
      'actions': [
        {'type': 'append_notes', 'value': 'seen'}
      ],
    };

void main() {
  late FinanceDatabase db;
  late FakeFireflyTransport transport;
  late SyncScheduler scheduler;
  late SyncEngine engine;

  setUp(() {
    db = inMemoryFinanceDatabase();
    transport = FakeFireflyTransport();
    engine = SyncEngine(
        SyncContext(db: db, api: FireflyApi(transport), config: _config));
    scheduler = SyncScheduler(engine);
  });

  // Awaiting close inside a fake-async widget test never completes.
  tearDown(() {
    scheduler.dispose();
    engine.dispose();
    db.close();
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await settle(tester);
  }

  Future<void> seedRules() async {
    transport.seed('/rule-groups', '1',
        {'title': 'Groceries', 'order': 1, 'active': true});
    transport.seed(
        '/rule-groups', '2', {'title': 'Empty', 'order': 2, 'active': false});
    transport.seed('/rules', '10', _rule('1', 'Tag market'));
    transport.seed('/rules', '11', _rule('1', 'Old rule', active: false));
    await io(() => fireflyRuleSyncer.pull(engine.context));
    transport.requests.clear();
  }

  Widget page() => FireflyRulesPage(db: db, scheduler: () async => scheduler);

  void goOffline() => transport.onRequest =
      (_) => throw const FireflyNetworkError();

  widgetTest('list shows groups and rules from the cache and adds a group',
      (tester) async {
    await seedRules();
    await pump(tester, page());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Tag market'), findsOneWidget);
    expect(find.text('Old rule'), findsOneWidget);
    expect(find.text('firefly-rules-group-empty'), findsOneWidget);
    expect(find.byKey(_key('firefly-rules-offline')), findsNothing);

    await tester.tap(find.byKey(_key('firefly-rule-group-add')));
    await settle(tester);
    await tester.tap(find.byKey(_key('firefly-rule-group-save')));
    await settle(tester);
    expect(find.text('firefly-rules-name-required'), findsOneWidget);
    await tester.enterText(
        find.byKey(_key('firefly-rule-group-title')), 'Bills');
    await tester.tap(find.byKey(_key('firefly-rule-group-save')));
    await settle(tester);

    final post = transport.requests.singleWhere((r) => r.method == 'POST');
    expect(post.path, '/rule-groups');
    expect(post.body?['title'], 'Bills');
    expect(find.text('Bills'), findsOneWidget);
  });

  widgetTest('editor validates and writes triggers and actions',
      (tester) async {
    await seedRules();
    await pump(tester, page());
    await tester.tap(find.byKey(_key('firefly-rule-group-menu-1')));
    await settle(tester);
    await tester.tap(find.byKey(_key('firefly-rule-group-add-rule')));
    await settle(tester);

    await tester.tap(find.byKey(_key('firefly-rule-save')));
    await settle(tester);
    expect(find.text('firefly-rules-name-required'), findsOneWidget);
    expect(find.text('firefly-rules-triggers-required'), findsOneWidget);

    await tester.enterText(find.byKey(_key('firefly-rule-title')), 'Coffee');
    await tester.tap(find.byKey(_key('firefly-rule-add-trigger')));
    await settle(tester);
    await tester.tap(find.byKey(_key('firefly-rule-save')));
    await settle(tester);
    expect(find.text('firefly-rules-value-required'), findsOneWidget);
    expect(find.text('firefly-rules-actions-required'), findsOneWidget);

    await tester.enterText(
        find.byKey(_key('firefly-rule-trigger-0-value')), 'Cafe');
    await tester.tap(find.byKey(_key('firefly-rule-trigger-0-prohibited')));
    await tester.tap(find.byKey(_key('firefly-rule-add-action')));
    await settle(tester);

    // Stock 6.6.2 rejects these on write, so they are not offered.
    await tester.tap(find.byKey(_key('firefly-rule-action-0-type')));
    await settle(tester);
    for (final keyword in fireflyUnwritableActions) {
      expect(find.text('firefly-rules-action-$keyword'), findsNothing);
    }
    await tester.tap(find.text('firefly-rules-action-clear_notes').last);
    await settle(tester);
    expect(find.byKey(_key('firefly-rule-action-0-value')), findsNothing);
    await tester.tap(find.byKey(_key('firefly-rule-strict')));
    await tester.tap(find.byKey(_key('firefly-rule-save')));
    await settle(tester);

    final post = transport.requests.singleWhere((r) => r.method == 'POST');
    expect(post.path, '/rules');
    expect(post.body?['title'], 'Coffee');
    expect(post.body?['rule_group_id'], '1');
    expect(post.body?['strict'], isFalse);
    expect(post.body?['triggers'], [
      {
        'type': FireflyRule.triggerKeywords.first,
        'value': 'Cafe',
        'active': true,
        'prohibited': true,
      }
    ]);
    expect(post.body?['actions'], [
      {'type': 'clear_notes', 'value': null, 'active': true}
    ]);
    expect(find.text('Coffee'), findsOneWidget);
  });

  widgetTest('an existing rule keeps a read-only server action',
      (tester) async {
    await seedRules();
    await pump(tester, page());
    await tester.tap(find.byKey(_key('firefly-rule-10')));
    await settle(tester);
    expect(find.text('firefly-rules-action-append_notes'), findsOneWidget);
    await tester.enterText(find.byKey(_key('firefly-rule-title')), 'Renamed');
    await tester.tap(find.byKey(_key('firefly-rule-save')));
    await settle(tester);
    final put = transport.requests.singleWhere((r) => r.method == 'PUT');
    expect(put.path, '/rules/10');
    expect((put.body?['actions'] as List).single['type'], 'append_notes');
    expect(find.text('Renamed'), findsOneWidget);
  });

  widgetTest('test lists matching transactions with the filters',
      (tester) async {
    await io(() async {
      await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('w1'), name: 'Checking', order: 0));
      await IdMapRepository(db).put(fixtureMapping(
          type: FireflyEntityType.walletAccount, localPk: 'w1', remoteId: '7'));
    });
    transport.seed('/rules/10/test', '5', {
      'transactions': [
        {
          'transaction_journal_id': '9',
          'type': 'withdrawal',
          'description': 'Market run',
          'date': '2026-11-01T00:00:00+00:00',
          'amount': '12.50',
          'currency_code': 'USD',
        }
      ],
    });
    await pump(
        tester,
        FireflyRuleRunPage(
          id: '10',
          title: 'Tag market',
          scheduler: scheduler,
          db: db,
          today: () => DateTime(2026, 11, 22),
        ));
    await tester.tap(find.byKey(_key('firefly-rule-run-account-7')));
    await tester.tap(find.byKey(_key('firefly-rule-test')));
    await settle(tester);

    expect(find.text('Market run'), findsOneWidget);
    expect(find.text('12.50 USD'), findsOneWidget);
    expect(find.text('firefly-rules-matches'), findsOneWidget);
    final request = transport.requests.single;
    expect(request.path, '/rules/10/test');
    expect(request.query['start'], '2026-10-23');
    expect(request.query['end'], '2026-11-22');
    expect(request.query['accounts[0]'], '7');
  });

  widgetTest('run triggers the group and then syncs', (tester) async {
    await pump(
        tester,
        FireflyRuleRunPage(
          id: '1',
          title: 'Groceries',
          groups: true,
          scheduler: scheduler,
          db: db,
        ));
    await tester.tap(find.byKey(_key('firefly-rule-run')));
    for (var i = 0; i < 4; i++) {
      await settle(tester);
    }
    expect(transport.requests.first.method, 'POST');
    expect(transport.requests.first.path, '/rule-groups/1/trigger');
    expect(
        transport.requests.any(
            (r) => r.method == 'GET' && r.path.startsWith('/transactions')),
        isTrue);
    expect(find.text('firefly-rules-run-done'), findsOneWidget);
  });

  widgetTest('offline keeps rules readable and disables run with a reason',
      (tester) async {
    await seedRules();
    goOffline();
    await pump(tester, page());
    expect(find.text('Tag market'), findsOneWidget);
    expect(find.text('firefly-rules-offline-view'), findsOneWidget);
    expect(
        tester
            .widget<FloatingActionButton>(
                find.byKey(_key('firefly-rule-group-add')))
            .onPressed,
        isNull);

    await tester.tap(find.byKey(_key('firefly-rule-menu-10')));
    await settle(tester);
    await tester.tap(find.byKey(_key('firefly-rule-run-open')));
    await settle(tester);
    expect(find.text('firefly-rules-offline-run'), findsOneWidget);
    final run = find.ancestor(
        of: find.text('firefly-rules-run'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.widget<ButtonStyleButton>(run).onPressed, isNull);
    final test = find.ancestor(
        of: find.text('firefly-rules-test'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.widget<ButtonStyleButton>(test).onPressed, isNull);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byKey(_key('firefly-rule-10')));
    await settle(tester);
    expect(find.text('firefly-rules-offline-edit'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(_key('firefly-rule-save')))
            .onPressed,
        isNull);
    // Only the failed reachability probe was sent.
    expect(transport.requests.where((r) => r.method != 'GET'), isEmpty);
  });

  widgetTest('mode off shows the offline state without any request',
      (tester) async {
    await pump(tester, FireflyRulesPage(db: db, scheduler: () async => null));
    expect(find.text('firefly-rules-empty'), findsOneWidget);
    expect(find.text('firefly-rules-offline-view'), findsOneWidget);
    expect(transport.requests, isEmpty);
  });
}

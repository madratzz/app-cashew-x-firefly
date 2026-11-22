import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/bills/bills_page.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/pages/bills/recurrences_page.dart';
import 'package:budget/firefly/ui/pages/bills/upcoming_recurrences.dart';
import 'package:budget/firefly/ui/slots.dart';
import 'package:budget/firefly/ui/transaction/bill_section.dart';
import 'package:budget/struct/databaseGlobal.dart' as global;
import 'package:budget/struct/upcomingTransactionsFunctions.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/test_database.dart';

class _Tokens extends TokenStore {
  String? token = 'REDACTED';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

/// Answers the trigger endpoint the way Firefly does when nothing is due.
class _TriggerTransport extends FakeFireflyTransport {
  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    if (path.endsWith('/trigger')) {
      requests.add((method: 'POST', path: path, query: query, body: body));
      return {'data': <Object?>[]};
    }
    return super.post(path, body, query: query);
  }
}

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
  for (var i = 0; i < 5; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

const _bill = FireflyEntityType.bill;
const _recurrence = FireflyEntityType.recurrence;

void main() {
  late FinanceDatabase db;
  late Map<String, Object?> settings;
  final today = DateTime(2026, 11, 22);

  Future<void> setMode(bool on) async {
    settings = {
      FireflyConfig.modeKey: on,
      FireflyConfig.baseUrlKey: 'https://firefly.example',
    };
    await FireflyMode.init(() => settings, tokenStore: _Tokens());
  }

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await settle(tester);
  }

  Future<String> seedBill(String id, JsonObject fields) async {
    await io(() => db.writeFireflySchedule(_bill, id, fields));
    return ResourceCacheRepository.resourcePk(_bill, id);
  }

  Future<String> seedRecurrence(String id, {String remoteId = '30'}) async {
    await io(() => db.writeFireflySchedule(_recurrence, id, {
          'title': 'Rent',
          'type': 'withdrawal',
          'active': true,
          'repetitions': [
            {
              'type': 'monthly',
              'moment': '1',
              'skip': 0,
              'weekend': 1,
              'occurrences': [
                '2026-12-01T00:00:00+01:00',
                '2027-01-01T00:00:00+01:00'
              ],
            },
          ],
        }));
    final pk = ResourceCacheRepository.resourcePk(_recurrence, id);
    await io(() => IdMapRepository(db).put(FireflyIdMapping(
          entityType: _recurrence,
          localPk: pk,
          remoteId: remoteId,
          remoteSubId: '',
          remoteRole: 0,
          state: FireflySyncState.synced,
          attempts: 0,
        )));
    return pk;
  }

  setUp(() async {
    db = inMemoryFinanceDatabase();
    await setMode(true);
  });

  tearDown(() async {
    await setMode(false);
    // Awaiting close inside a fake-async widget test never completes.
    db.close();
  });

  group('bills', () {
    widgetTest('list shows paid and expected dates', (tester) async {
      await seedBill('a', {
        'name': 'Internet',
        'amount_min': '30.00',
        'amount_max': '30.00',
        'currency_code': 'EUR',
        'active': true,
        'next_expected_match': '2026-12-05T00:00:00Z',
        'paid_dates': [
          {'date': '2026-11-05T00:00:00Z'},
        ],
      });
      await pump(tester, FireflyBillsPage(db: db));

      expect(find.text('Internet'), findsOneWidget);
      expect(find.text('30.00 EUR'), findsOneWidget);
      expect(find.textContaining('firefly-bills-expected'), findsOneWidget);
      expect(find.textContaining('firefly-bills-paid'), findsOneWidget);
    });

    widgetTest('editor creates a bill and pushes it', (tester) async {
      var pushes = 0;
      await pump(
          tester, FireflyBillsPage(db: db, pushNow: () async => pushes++));
      expect(find.text('firefly-bills-empty'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('firefly-bill-add')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('firefly-bill-save')));
      await settle(tester);
      expect(find.text('firefly-bills-name-required'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-bill-name')), 'Streaming');
      await tester.enterText(
          find.byKey(const ValueKey('firefly-bill-min')), '9.99');
      await tester.tap(find.byKey(const ValueKey('firefly-bill-save')));
      await settle(tester);

      expect(pushes, 1);
      final rows = await io(() => ResourceCacheRepository(db).list(_bill));
      final saved = ResourceCacheRepository.decode(rows.single);
      expect(saved['name'], 'Streaming');
      expect(saved['amount_min'], '9.99');
      expect(saved['amount_max'], '9.99');
      expect(saved['repeat_freq'], 'monthly');
      expect(find.text('Streaming'), findsOneWidget);
    });

    widgetTest('editor sends only changed fields', (tester) async {
      await seedBill('b', {
        'name': 'Gym',
        'amount_min': '20.00',
        'amount_max': '25.00',
        'date': '2026-01-01',
        'repeat_freq': 'monthly',
        'active': true,
      });
      await pump(tester, FireflyBillsPage(db: db, pushNow: () async {}));
      await tester.tap(find.text('Gym'));
      await settle(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-bill-name')), 'Gym club');
      await tester.tap(find.byKey(const ValueKey('firefly-bill-save')));
      await settle(tester);

      final row = await io(() => db.fireflyBill('bill:b'));
      final saved = ResourceCacheRepository.decode(row!);
      expect(saved['name'], 'Gym club');
      expect(saved['amount_max'], '25.00');
    });

    widgetTest('picker sets the draft bill', (tester) async {
      final pk = await seedBill('c', {'name': 'Water'});
      final draft = FireflyTransactionDraft(db);
      await pump(tester, Scaffold(body: Builder(builder: (context) {
        return fireflyBillSection(context, draft);
      })));
      await tester.tap(find.byKey(const ValueKey('firefly-bill-picker')));
      await settle(tester);
      await tester.tap(find.text('Water').last);
      await settle(tester);
      expect(draft.billPk, pk);
    });
  });

  group('recurrences', () {
    widgetTest('list shows the next occurrence', (tester) async {
      await seedRecurrence('r1');
      await pump(tester, FireflyRecurrencesPage(db: db, now: () => today));
      expect(find.text('Rent'), findsOneWidget);
      expect(find.textContaining('firefly-recurrences-next'), findsOneWidget);
    });

    widgetTest('editor saves a changed repetition', (tester) async {
      final pk = await seedRecurrence('r2');
      await pump(
          tester,
          FireflyRecurrencesPage(
              db: db, now: () => today, pushNow: () async {}));
      await tester.tap(find.text('Rent'));
      await settle(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-recurrence-moment')), '15');
      await tester.tap(find.byKey(const ValueKey('firefly-recurrence-save')));
      await settle(tester);

      final saved = ResourceCacheRepository.decode(
          (await io(() => db.fireflyRecurrence(pk)))!);
      final repetition = (saved['repetitions'] as List).single as Map;
      expect(repetition['moment'], '15');
      expect(saved['title'], 'Rent');
      expect(
          find.byKey(const ValueKey('firefly-recurrence-save')), findsNothing);
    });

    widgetTest('server rejection of a moment is shown, not dropped',
        (tester) async {
      final pk = await seedRecurrence('r3');
      Future<void> reject() async {
        final mapping = await IdMapRepository(db).byLocal(_recurrence, pk);
        await IdMapRepository(db).put(mapping!.copyWith(
          state: FireflySyncState.error,
          lastError: const Value('The moment field is invalid.'),
        ));
      }

      await pump(tester,
          FireflyRecurrencesPage(db: db, now: () => today, pushNow: reject));
      await tester.tap(find.text('Rent'));
      await settle(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-recurrence-moment')), '0');
      await tester.tap(find.byKey(const ValueKey('firefly-recurrence-save')));
      await settle(tester);

      expect(find.byType(FireflyErrorBanner), findsOneWidget);
      expect(find.byKey(const ValueKey('firefly-recurrence-save')),
          findsOneWidget);
    });

    widgetTest('create now triggers the server occurrence', (tester) async {
      await seedRecurrence('r4', remoteId: '30');
      final transport = _TriggerTransport();
      transport.seed('/recurrences', '30', {
        'title': 'Rent',
        'repetitions': [
          {
            'type': 'monthly',
            'occurrences': ['2026-12-01T00:00:00+01:00'],
          },
        ],
      });
      final context = SyncContext(
        db: db,
        api: FireflyApi(transport),
        config: FireflyMode.config,
        now: () => today,
      );
      await pump(
          tester,
          FireflyRecurrencesPage(
              db: db, now: () => today, syncContext: () async => context));
      await tester.tap(
          find.byKey(const ValueKey('firefly-recurrence-now-recurrence:r4')));
      await settle(tester);

      final trigger =
          transport.requests.where((r) => r.path.endsWith('/trigger')).single;
      expect(trigger.path, contains('/30/'));
      expect(trigger.query['date'], '2026-12-01');
      expect(find.text('firefly-recurrences-create-none'), findsOneWidget);
    });

    widgetTest('create now reports a failure', (tester) async {
      await seedRecurrence('r5');
      await pump(
          tester,
          FireflyRecurrencesPage(
              db: db,
              now: () => today,
              syncContext: () async => throw const FireflyNetworkError()));
      await tester.tap(
          find.byKey(const ValueKey('firefly-recurrence-now-recurrence:r5')));
      await settle(tester);
      expect(find.text('firefly-recurrences-create-failed'), findsOneWidget);
    });

    widgetTest('upcoming list is fed by recurrence occurrences',
        (tester) async {
      await seedRecurrence('r6');
      await pump(
          tester,
          Scaffold(
              body: SingleChildScrollView(
                  child:
                      FireflyUpcomingRecurrences(db: db, now: () => today))));
      expect(find.text('Rent'), findsNWidgets(2));
    });
  });

  group('no local duplicate for a server recurrence', () {
    Transaction repeating(String pk) => Transaction(
          transactionPk: pk,
          name: 'Rent',
          amount: -500,
          note: '',
          categoryFk: '0',
          walletFk: '0',
          dateCreated: DateTime(2026, 11, 1),
          income: false,
          paid: true,
          skipPaid: false,
          createdAnotherFutureTransaction: false,
          type: TransactionSpecialType.repetitive,
          reoccurrence: BudgetReoccurence.monthly,
          periodLength: 1,
          methodAdded: MethodAdded.csv,
        );

    widgetTest('Cashew does not create the next occurrence', (tester) async {
      global.database = db;
      final row = repeating('server-row');
      await io(() => IdMapRepository(db).put(FireflyIdMapping(
            entityType: FireflyEntityType.transaction,
            localPk: row.transactionPk,
            remoteId: '77',
            remoteSubId: '',
            remoteRole: 0,
            state: FireflySyncState.synced,
            attempts: 0,
          )));
      late BuildContext context;
      await pump(tester, Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }));

      await io(() => createNewSubscriptionTransaction(context, row));
      expect(await io(() => db.select(db.transactions).get()), isEmpty);
    });

    test('guard is off in legacy mode', () async {
      final row = repeating('server-row');
      await IdMapRepository(db).put(FireflyIdMapping(
        entityType: FireflyEntityType.transaction,
        localPk: row.transactionPk,
        remoteId: '77',
        remoteSubId: '',
        remoteRole: 0,
        state: FireflySyncState.synced,
        attempts: 0,
      ));
      expect(await fireflyOwnsSchedule(db, row), isTrue);
      await setMode(false);
      expect(await fireflyOwnsSchedule(db, row), isFalse);
    });

    test('unmapped local rows keep legacy auto-creation', () async {
      expect(await fireflyOwnsSchedule(db, repeating('local')), isFalse);
    });
  });

  widgetTest('legacy mode renders no bill hub entries', (tester) async {
    await setMode(false);
    await pump(tester, const Scaffold(body: FireflyHubSection()));
    expect(find.text('firefly-bills-title'), findsNothing);
    expect(find.text('firefly-recurrences-title'), findsNothing);
  });
}

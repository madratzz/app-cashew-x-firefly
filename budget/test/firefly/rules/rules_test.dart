import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/rule_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/entities/rule_syncer.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/firefly_emulator.dart';

const _syncer = RuleSyncer();
const _config = FireflyConfig(mode: true, baseUrl: 'https://firefly.example');
const _rules = '/rules';
const _groups = '/rule-groups';

JsonObject _ruleBody(String groupId) => {
      'rule_group_id': groupId,
      'title': 'Example rule',
      'order': 1,
      'trigger': 'manual-activation',
      'active': true,
      'strict': false,
      'stop_processing': true,
      'triggers': [
        {
          'type': 'description_contains',
          'value': 'Market',
          'prohibited': true,
          'stop_processing': true,
        }
      ],
      'actions': [
        {'type': 'clear_notes', 'value': null}
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FinanceDatabase db;
  late FakeFireflyTransport transport;
  late SyncContext context;

  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    transport = FakeFireflyTransport(maxPageSize: 1);
    context = SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: _config,
    );
  });

  Future<List<FireflyRule>> cachedRules() async => [
        for (final row in await db.fireflyRules())
          FireflyRule.fromJson(ResourceCacheRepository.decode(row)),
      ];

  Future<List<FireflyRuleGroup>> cachedGroups() async => [
        for (final row in await db.fireflyRules(groups: true))
          FireflyRuleGroup.fromJson(ResourceCacheRepository.decode(row)),
      ];

  test('online CRUD updates both caches and round trips reorder fields',
      () async {
    final group = await _syncer.createGroup(
        context, {'title': 'Example group', 'order': 1, 'active': true});
    final otherGroup = await _syncer
        .createGroup(context, {'title': 'Second group', 'order': 2});
    final rule = await _syncer.createRule(context, _ruleBody(group.id));
    final otherRule = await _syncer.createRule(
        context, {..._ruleBody(group.id), 'title': 'Second rule', 'order': 2});
    expect(
        (await cachedRules()).map((item) => item.id), [rule.id, otherRule.id]);
    await expectLater(_streamIds(db.watchFireflyRules(groups: true)),
        emits([group.id, otherGroup.id]));

    final savedGroup = await _syncer.updateGroup(context, group.id, {
      ...group.attributes,
      'title': 'Renamed group',
      'order': 3,
      'active': false,
    });
    final saved = await _syncer.updateRule(context, rule.id, {
      ...rule.attributes,
      'rule_group_title': group.title,
      'title': 'Renamed rule',
      'order': 3,
      'actions': [
        {'id': '8', 'type': 'set_notes', 'value': 'Edited'}
      ],
    });

    expect(saved.title, 'Renamed rule');
    expect(saved.ruleGroupId, group.id);
    expect(saved.order, 3);
    expect(saved.strict, isFalse);
    expect(saved.stopProcessing, isTrue);
    expect(saved.triggers.single['prohibited'], isTrue);
    expect(saved.actions.single, {
      'type': 'set_notes',
      'value': 'Edited',
      'active': true,
    });
    expect(savedGroup.title, 'Renamed group');
    expect(savedGroup.order, 3);
    expect(savedGroup.active, isFalse);
    final rulePut = transport.requests.last.body!;
    expect(rulePut, isNot(contains('updated_at')));
    expect(rulePut, isNot(contains('rule_group_title')));
    expect((await context.api.rules.get(rule.id)).attributes, saved.attributes);
    expect((await context.api.rules.getGroup(group.id)).attributes,
        savedGroup.attributes);

    await _syncer.pull(context);
    expect(
        (await cachedRules()).map((item) => item.id), [otherRule.id, rule.id]);
    expect((await cachedGroups()).map((item) => item.id),
        [otherGroup.id, group.id]);

    await _syncer.deleteRule(context, rule.id);
    await expectLater(
        context.api.rules.get(rule.id), throwsA(isA<FireflyNotFound>()));
    transport.onRequest = (request) {
      if (request.method == 'DELETE' &&
          request.path == '$_groups/${group.id}') {
        transport.removeSeed(_rules, otherRule.id);
      }
    };
    await _syncer.deleteGroup(context, group.id);
    await expectLater(
        context.api.rules.getGroup(group.id), throwsA(isA<FireflyNotFound>()));
    expect(await cachedRules(), isEmpty);
    expect((await cachedGroups()).single.id, otherGroup.id);
    await _syncer.pull(context);
    expect(await cachedRules(), isEmpty);
  });

  test('partial or cancelled pulls preserve the offline snapshot', () async {
    transport.seed(_groups, '1', {'title': 'First'});
    transport.seed(_rules, '1', _ruleBody('1'));
    await _syncer.pull(context);
    transport.removeSeed(_groups, '1');
    transport.seed(_groups, '2', {'title': 'Second'});
    transport.seed(_rules, '2', _ruleBody('2'));

    transport.onRequest = (request) {
      if (request.path == _rules && request.query['page'] == '2') {
        throw const FireflyNetworkError();
      }
    };
    await expectLater(
        _syncer.pull(context), throwsA(isA<FireflyNetworkError>()));
    final writesBefore = transport.requests.length;
    expect((await cachedRules()).single.id, '1');
    expect((await cachedGroups()).single.id, '1');
    expect(transport.requests, hasLength(writesBefore));

    var cancelled = false;
    transport.onRequest = (request) {
      if (request.path == _rules) cancelled = true;
    };
    await _syncer.pull(SyncContext(
      db: db,
      api: context.api,
      config: _config,
      isCancelled: () => cancelled,
    ));
    expect((await cachedGroups()).single.id, '1');

    transport.onRequest = null;
    transport.removeSeed(_rules, '1');
    await _syncer.pull(context);
    expect((await cachedRules()).single.id, '2');
    expect((await cachedGroups()).single.id, '2');
    expect(
        transport.requests.every((request) => request.method == 'GET'), isTrue);
  });

  test('mode off skips rule pulls and rejects online edits before I/O',
      () async {
    final disabled = SyncContext(
      db: db,
      api: context.api,
      config: const FireflyConfig(),
    );
    await _syncer.pull(disabled);
    await expectLater(
      _syncer.createGroup(disabled, {'title': 'Offline'}),
      throwsA(isA<FireflyTransportUnavailable>()),
    );
    expect(transport.requests, isEmpty);
    expect(await cachedGroups(), isEmpty);
  });

  test('all documented clause keywords and unknown keywords round trip', () {
    expect(FireflyRule.triggerKeywords.toSet(), hasLength(36));
    expect(FireflyRule.actionKeywords.toSet(), hasLength(22));
    for (final triggerType in FireflyRule.triggerTypes) {
      final triggers = [
        for (final keyword in [
          ...FireflyRule.triggerKeywords,
          'future_keyword'
        ])
          {
            'type': keyword,
            'value': 'true',
            'active': true,
            'prohibited': true
          },
      ];
      final actions = [
        for (final keyword in [...FireflyRule.actionKeywords, 'future_keyword'])
          {'type': keyword, 'value': 'example', 'active': true},
      ];
      final rule = FireflyRule.fromJson(fireflyResource('rules', '1', {
        ..._ruleBody('1'),
        'trigger': triggerType,
        'triggers': triggers,
        'actions': actions,
      }));
      expect(rule.trigger, triggerType);
      expect(rule.triggers, triggers);
      expect(rule.actions, actions);
      final write = rule.toWriteJson();
      expect(write['triggers'], triggers);
      expect(write['actions'], actions);
    }
  });

  test('rule and group tests and runs send indexed account and date filters',
      () async {
    final match = fireflyResource('transactions', '21', {
      'transactions': [
        {'transaction_journal_id': '22', 'description': 'Match'}
      ],
    });
    final seen = <http.Request>[];
    final client = HttpFireflyTransport(
      baseUrl: Uri.parse(_config.baseUrl),
      readToken: () async => 'REDACTED-fixture',
      client: MockClient((request) async {
        seen.add(request);
        if (request.method == 'POST') return http.Response('', 204);
        return http.Response(
            jsonEncode({
              'data': [match],
              'meta': {
                'pagination': {
                  'total': 3,
                  'per_page': 1,
                  'current_page': 2,
                  'total_pages': 3,
                },
              },
            }),
            200);
      }),
    );
    addTearDown(client.close);
    final api = FireflyApi(client).rules;
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    const accounts = ['31', '32'];
    final filters = {
      'start': '2026-01-01',
      'end': '2026-01-31',
      'accounts[0]': '31',
      'accounts[1]': '32',
    };
    for (final groups in [false, true]) {
      final testRule = groups ? api.testGroup : api.test;
      final trigger = groups ? api.triggerGroup : api.trigger;
      final path = '/api/v1${groups ? _groups : _rules}/1';
      final matches = await testRule('1',
          start: start, end: end, accounts: accounts, page: 2, limit: 1);
      expect(matches.currentPage, 2);
      expect(matches.total, 3);
      expect(matches.items.single.id, '21');
      expect(matches.items.single.splits.single.description, 'Match');
      expect(seen.last.url.path, '$path/test');
      expect(seen.last.method, 'GET');
      expect(seen.last.url.queryParameters,
          {...filters, 'page': '2', 'limit': '1'});
      await trigger('1', start: start, end: end, accounts: accounts);
      expect(seen.last.url.path, '$path/trigger');
      expect(seen.last.method, 'POST');
      expect(seen.last.url.queryParameters, filters);
      expect(jsonDecode(seen.last.body), isEmpty);
    }
  });

  test('a successful run fetches edits to transactions outside the sync window',
      () async {
    var now = fixtureTime;
    final emulator = FireflyEmulator(clock: () => now);
    final api = FireflyApi(emulator);
    final engine = SyncEngine(SyncContext(
      db: db,
      api: api,
      config: _config,
      now: () => now,
    ));
    final scheduler = SyncScheduler(engine);
    addTearDown(() async {
      scheduler.dispose();
      await engine.dispose();
    });
    final asset = await api.accounts.create({
      'name': 'Example wallet',
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
    });
    final old = await api.transactions.create({
      'transactions': [
        {
          'type': 'withdrawal',
          'date': formatFireflyDate(now.subtract(const Duration(days: 200))),
          'amount': '5.00',
          'description': 'Before rule',
          'source_id': asset.id,
          'destination_name': 'Example store',
        }
      ],
    });
    expect((await scheduler.syncNow()).succeeded, isTrue);
    expect((await db.select(db.transactions).getSingle()).name, 'Before rule');
    now = now.add(const Duration(seconds: 2));
    emulator.requests.clear();
    emulator.onRequest = (request) {
      if (request.path == '/rule-groups/1/trigger') {
        emulator.seed('/transactions', old.id, {
          ...old.attributes,
          'updated_at': now.toIso8601String(),
          'transactions': [
            {...old.splits.single.fields, 'description': 'After rule'}
          ],
        });
      }
    };
    final report = await _syncer.trigger(scheduler, '1', groups: true);
    expect(report.issues, isEmpty);
    expect(report.succeeded, isTrue);
    expect((await db.select(db.transactions).getSingle()).name, 'After rule');
    expect(emulator.requests.first.path, '/rule-groups/1/trigger');
    expect(
      emulator.requests.any((request) =>
          request.method == 'GET' &&
          request.path == '/transactions' &&
          !request.query.containsKey('start')),
      isTrue,
    );
  });
}

Stream<List<String>> _streamIds(Stream<List<FireflyCachedResource>> source) =>
    source.map((rows) => [
          for (final row in rows)
            ResourceCacheRepository.decode(row)['id']! as String,
        ]);

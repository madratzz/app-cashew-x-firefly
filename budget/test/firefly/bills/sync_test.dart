import 'dart:convert';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/entities/recurrence_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_firefly_server.dart';
import '../../support/test_database.dart';
import '../e2e/support/e2e_harness.dart';
import '../e2e/support/firefly_emulator.dart';

const _bill = FireflyEntityType.bill;
const _recurrence = FireflyEntityType.recurrence;

const _billFields = {
  'name': 'Network service',
  'amount_min': '12.00',
  'amount_max': '18.00',
  'currency_code': 'USD',
  'date': '2026-11-22',
  'repeat_freq': 'half-year',
  'skip': 0,
  'active': true,
};

const _recurrenceFields = {
  'type': 'withdrawal',
  'title': 'Metered service',
  'first_date': '2026-11-22',
  'repeat_until': null,
  'active': true,
  'repetitions': [
    {'type': 'weekly', 'moment': '7', 'skip': 0, 'weekend': 1},
  ],
  'transactions': [
    {
      'description': 'Metered service',
      'amount': '7.50',
      'currency_code': 'USD',
      'source_id': '1',
      'destination_id': '2',
    }
  ],
};

void main() {
  late _Fixture fixture;

  setUp(() async {
    fixture = await _Fixture.start();
  });

  for (final type in [_bill, _recurrence]) {
    final isBill = type == _bill;
    final path = isBill ? '/bills' : '/recurrences';
    final name = isBill ? 'name' : 'title';
    final fields = isBill ? _billFields : _recurrenceFields;

    test('${type.name} creates, edits and deletes offline and remotely',
        () async {
      final db = fixture.db;
      final save = isBill ? db.saveFireflyBill : db.saveFireflyRecurrence;
      final read = isBill ? db.fireflyBill : db.fireflyRecurrence;
      final delete = isBill ? db.deleteFireflyBill : db.deleteFireflyRecurrence;
      final start = fixture.server.requests.length;
      final pk = await save(fields);
      expect(ResourceCacheRepository.decode((await read(pk))!), fields);
      expect(fixture.server.requests, hasLength(start));

      await fixture.sync();
      final mapping = (await fixture.context.idMap.byLocal(type, pk))!;
      final id = mapping.remoteId;
      final endpoint = '$path/$id';
      final created = await fixture.api.transport.get(endpoint);
      expect(created['attributes'], containsPair(name, fields[name]));
      expect(
          fixture.writes.where((request) => request.path == path).single.body,
          fields);
      await fixture.expectNoWrites();

      final editStart = fixture.server.requests.length;
      await save({name: 'Device edit', 'notes': 'Offline note'}, pk: pk);
      expect(fixture.server.requests, hasLength(editStart));
      await fixture.sync();
      final edited = await fixture.api.transport.get(endpoint);
      expect(edited['attributes'], containsPair(name, 'Device edit'));
      expect(edited['attributes'], containsPair('notes', 'Offline note'));
      final update = fixture.writes.lastWhere((r) => r.path == endpoint);
      expect(update.body, {name: 'Device edit', 'notes': 'Offline note'});
      await fixture.expectNoWrites();

      await fixture.api.transport.put(endpoint, {name: 'Server edit'});
      await fixture.sync();
      expect(ResourceCacheRepository.decode((await read(pk))!)[name],
          'Server edit');

      await delete(pk);
      expect(await read(pk), isNull);
      expect((await fixture.context.idMap.byLocal(type, pk))!.state,
          FireflySyncState.pendingDelete);
      await fixture.sync();
      await expectLater(
          fixture.api.transport.get(endpoint), throwsA(isA<FireflyNotFound>()));
      expect(await fixture.context.idMap.byLocal(type, pk), isNull);

      final remote = await fixture.api.transport.post(path, fields);
      final remoteId = remote['id']! as String;
      await fixture.sync();
      final pulled =
          (await fixture.context.idMap.byRemote(type, remoteId))!.localPk;
      expect(ResourceCacheRepository.decode((await read(pulled))!)[name],
          fields[name]);
      await fixture.api.transport.delete('$path/$remoteId');
      await fixture.sync();
      expect(await read(pulled), isNull);
      expect(await fixture.context.idMap.byRemote(type, remoteId), isNull);
    });

    test('${type.name} deletes a draft after an interrupted remote create',
        () async {
      final db = fixture.db;
      final save = isBill ? db.saveFireflyBill : db.saveFireflyRecurrence;
      final delete = isBill ? db.deleteFireflyBill : db.deleteFireflyRecurrence;
      final pk = await save(fields);
      fixture.server.onRequest = (request) {
        if (request.method != 'POST' || request.path != path) return;
        // The server committed the POST, but the device missed its response.
        fixture.server.seed(path, '30', request.body!);
        throw const FireflyUnauthorized();
      };
      expect((await fixture.engine.run()).succeeded, isFalse);
      fixture.server.onRequest = null;

      await delete(pk);
      await fixture.sync();
      expect(await fixture.context.idMap.byLocal(type, pk), isNull);
      expect(await fixture.context.idMap.byRemote(type, '30'), isNull);
      expect((await fixture.api.transport.getPage(path)).items, isEmpty);
    });
  }

  test('refreshes server occurrences without discarding an offline edit',
      () async {
    fixture.server.seed('/recurrences', '30', _withOccurrences('2026-11-29'));
    await fixture.sync();
    final pk =
        (await fixture.context.idMap.byRemote(_recurrence, '30'))!.localPk;
    fixture.server.seed('/recurrences', '30', _withOccurrences('2026-12-06'));
    await fixture.expectNoWrites();
    final cached = (await fixture.db.fireflyRecurrence(pk))!;
    expect(
        FireflyRecurrence(
                id: '30', attributes: ResourceCacheRepository.decode(cached))
            .nextOccurrence(from: fixture.now()),
        DateTime(2026, 12, 6));

    await fixture.db.saveFireflyRecurrence({'notes': 'Device edit'}, pk: pk);
    fixture.server.seed('/recurrences', '30', _withOccurrences('2026-12-13'));
    await fixture.sync();
    expect((await fixture.api.recurrences.get('30')).notes, 'Device edit');
    expect(await fixture.context.conflicts.list(), isEmpty);
  });

  test('pulls subscription_id before bill_id and pushes links and unlinks',
      () async {
    fixture.server.seed('/bills', '30', _billFields);
    fixture.server.seed('/bills', '31', {..._billFields, 'name': 'Other bill'});
    await fixture.seedAccounts();
    final serverLinked = await fixture.api.transactions.create({
      'transactions': [
        {
          ...fixture.transactionFields,
          'subscription_id': '30',
          'bill_id': '31'
        },
      ],
    });
    final legacyLinked = await fixture.api.transactions.create({
      'transactions': [
        {...fixture.transactionFields, 'bill_id': '31'},
      ],
    });
    final unlinked = await fixture.api.transactions.create({
      'transactions': [fixture.transactionFields],
    });

    await fixture.sync();
    final billPk = (await fixture.context.idMap.byRemote(_bill, '30'))!.localPk;
    final otherBillPk =
        (await fixture.context.idMap.byRemote(_bill, '31'))!.localPk;
    expect((await fixture.localTransaction(serverLinked.id)).billFk, billPk);
    expect(
        (await fixture.localTransaction(legacyLinked.id)).billFk, otherBillPk);
    final existing = await fixture.localTransaction(unlinked.id);
    expect(existing.billFk, isNull);

    final edit = fixture.db.update(fixture.db.transactions)
      ..where((row) => row.transactionPk.equals(existing.transactionPk));
    await edit.write(TransactionsCompanion(billFk: Value(billPk)));
    await fixture.sync();
    expect(
        (await fixture.api.transactions.get(unlinked.id)).splits.single.billId,
        '30');
    final update = fixture.writes.lastWhere(
        (r) => r.method == 'PUT' && r.path == '/transactions/${unlinked.id}');
    final payload = FireflyEmulator.splitsOf(update.body!).single;
    expect(payload['bill_id'], '30');
    expect(payload, isNot(contains('subscription_id')));

    await edit.write(const TransactionsCompanion(billFk: Value(null)));
    await fixture.sync();
    expect(
        (await fixture.api.transactions.get(unlinked.id)).splits.single.billId,
        isNull);
    await fixture.expectNoWrites();

    final journalId = unlinked.splits.single.journalId;
    await fixture.api.transactions.update(unlinked.id, {
      'transactions': [
        {'transaction_journal_id': journalId, 'subscription_id': '31'},
      ],
    });
    await fixture.sync();
    expect((await fixture.localTransaction(unlinked.id)).billFk, otherBillPk);

    await fixture.api.transactions.update(unlinked.id, {
      'transactions': [
        {'transaction_journal_id': journalId, 'subscription_id': null},
      ],
    });
    await fixture.sync();
    expect((await fixture.localTransaction(unlinked.id)).billFk, isNull);
    expect(await fixture.context.conflicts.list(), isEmpty);
  });

  test('trigger sends the server date, returns a group and imports it',
      () async {
    await fixture.seedAccounts();
    fixture.server.seed('/recurrences', '30', _withOccurrences('2026-11-29'));
    await fixture.sync();
    final pk =
        (await fixture.context.idMap.byRemote(_recurrence, '30'))!.localPk;

    final created = await const RecurrenceSyncer().trigger(fixture.context, pk);
    expect(created, isNotNull);
    expect(created!.splits.single.date!.day, fixture.now().day);
    expect(fixture.triggerDates, ['2026-11-29']);
    expect((await fixture.localTransaction(created.id)).name, 'Triggered item');

    final again = await const RecurrenceSyncer().trigger(
      fixture.context,
      pk,
      date: DateTime(2026, 11, 29),
    );
    expect(again, isNull);
    expect(
        await fixture.db.select(fixture.db.transactions).get(), hasLength(1));
    await fixture.expectNoWrites();
  });
}

JsonObject _withOccurrences(String date) => {
      ..._recurrenceFields,
      'updated_at': '2026-11-22T00:00:00Z',
      'repetitions': [
        {
          'type': 'weekly',
          'moment': '7',
          'skip': 0,
          'weekend': 1,
          'occurrences': ['${date}T00:00:00+14:00']
        },
      ],
    };

class _Fixture {
  _Fixture(this.db, this.server, this.api, this.engine, this.triggerDates);

  final FinanceDatabase db;
  final FireflyEmulator server;
  final FireflyApi api;
  final SyncEngine engine;
  final List<String?> triggerDates;

  static DateTime _clock() => DateTime(2026, 11, 22, 12);
  DateTime now() => _clock();
  SyncContext get context => engine.context;

  JsonObject get transactionFields => {
        'type': 'withdrawal',
        'description': 'Example service',
        'amount': '7.50',
        'date': formatFireflyDateTime(now()),
        'source_id': '1',
        'destination_id': '2',
      };

  static Future<_Fixture> start() async {
    final emulator = FireflyEmulator(clock: _clock);
    final dates = <String?>[];
    final server = await FakeFireflyServer.start(
      transport: emulator,
      intercept: (request) async {
        if (request.method != 'POST' ||
            request.uri.path != '/api/v1/recurrences/30/trigger') {
          return false;
        }
        await request.drain<void>();
        dates.add(request.uri.queryParameters['date']);
        final groups = [
          if (dates.length == 1)
            await emulator.post('/transactions', {
              'transactions': [
                {
                  'type': 'withdrawal',
                  'description': 'Triggered item',
                  'amount': '7.50',
                  'date': formatFireflyDateTime(_clock()),
                  'source_id': '1',
                  'destination_id': '2',
                },
              ],
            }),
        ];
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'data': groups}));
        return true;
      },
    );
    addTearDown(server.close);
    final transport = HttpFireflyTransport(
      baseUrl: Uri.parse(e2eConfig.baseUrl),
      readToken: () async => 'REDACTED',
      client: _LoopbackClient(server.baseUrl),
    );
    addTearDown(transport.close);
    final api = FireflyApi(transport);
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final engine = SyncEngine(SyncContext(
      db: db,
      api: api,
      config: e2eConfig,
      now: _clock,
    ));
    addTearDown(engine.dispose);
    return _Fixture(db, emulator, api, engine, dates);
  }

  Future<void> seedAccounts() async {
    await api.accounts.create({'name': 'Wallet', 'type': 'asset'});
    await api.accounts.create({'name': 'Merchant', 'type': 'expense'});
  }

  Future<Transaction> localTransaction(String id) async {
    final maps =
        await context.idMap.forRemoteGroup(FireflyEntityType.transaction, id);
    final query = db.select(db.transactions)
      ..where((row) => row.transactionPk.equals(maps.single.localPk));
    return query.getSingle();
  }

  Future<void> sync() async {
    final report = await engine.run();
    expect(report.succeeded, isTrue,
        reason: report.issues.map((issue) => issue.message).join(', '));
  }

  Iterable<({String method, String path, FireflyQuery query, JsonObject? body})>
      get writes => server.requests.where((request) => request.method != 'GET');

  Future<void> expectNoWrites() async {
    final count = writes.length;
    await sync();
    expect(writes, hasLength(count));
  }
}

class _LoopbackClient extends http.BaseClient {
  _LoopbackClient(this.target);

  final Uri target;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url
        .replace(scheme: target.scheme, host: target.host, port: target.port);
    final copy = http.StreamedRequest(request.method, url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects;
    request.finalize().listen(copy.sink.add,
        onError: copy.sink.addError, onDone: copy.sink.close);
    return _inner.send(copy);
  }

  @override
  void close() => _inner.close();
}

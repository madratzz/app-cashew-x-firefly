import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/piggy_bank_contributor.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/entities/piggy_bank_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_firefly_server.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/firefly_emulator.dart';

const _path = '/piggy-banks';
const _piggyBank = FireflyEntityType.piggyBank;
const _transaction = FireflyEntityType.transaction;

void main() {
  late FinanceDatabase db;
  late _PiggyBankEmulator emulator;
  late FireflyApi api;
  late SyncEngine engine;
  late SyncContext context;
  late DateTime now;

  setUp(() async {
    now = fixtureTime;
    emulator = _PiggyBankEmulator(() => now);
    final server = await FakeFireflyServer.start(transport: emulator);
    addTearDown(server.close);
    final transport = HttpFireflyTransport(
      baseUrl: Uri.parse('https://piggy-bank.test.invalid'),
      readToken: () async => 'REDACTED',
      client: _LoopbackClient(server.baseUrl),
    );
    addTearDown(transport.close);
    api = FireflyApi(transport);
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    context = SyncContext(
      db: db,
      api: api,
      config: const FireflyConfig(
        mode: true,
        baseUrl: 'https://piggy-bank.test.invalid',
        pageSize: 1,
      ),
      now: () => now,
    );
    engine = SyncEngine(context);
    addTearDown(engine.dispose);
    for (final id in ['21', '22']) {
      emulator.seed('/accounts', id, {
        'type': 'asset',
        'name': 'Asset $id',
        'account_role': 'defaultAsset',
        'currency_code': 'USD',
        'currency_decimal_places': 2,
        'active': true,
        'order': int.parse(id),
        'updated_at': fixtureTime.toIso8601String(),
      });
    }
  });

  Future<void> sync({bool full = false}) async {
    final report = await engine.run(fullResync: full);
    expect(report.issues.map((issue) => issue.message), isEmpty);
    expect(report.succeeded, isTrue);
  }

  Future<Objective> addObjective(String name,
          {ObjectiveType type = ObjectiveType.goal}) =>
      db.into(db.objectives).insertReturning(ObjectivesCompanion.insert(
            name: name,
            amount: 125.5,
            order: 13,
            type: Value(type),
            colour: const Value('#112233'),
            iconName: const Value('wallet'),
            emojiIconName: const Value('★'),
            income: const Value(true),
            pinned: const Value(false),
            archived: const Value(true),
            dateCreated: Value(now.toLocal()),
            endDate: Value(now.toLocal().add(const Duration(days: 90))),
            dateTimeModified: Value(now),
          ));

  test('round trips creates, local edits, server edits and local deletes',
      () async {
    await sync();
    final goal = await addObjective('  New goal  ');
    await sync();
    final mapping =
        (await context.idMap.byLocal(_piggyBank, goal.objectivePk))!;
    final id = mapping.remoteId;
    final created = await api.piggyBanks.get(id);
    expect(created.name, 'New goal');
    expect(created.startDate, goal.dateCreated);
    expect(created.targetDate, goal.endDate);
    expect(created.targetAmount, 125.5);
    expect(created.accounts.single.id, '21');
    final post = emulator.requests
        .singleWhere((row) => row.method == 'POST' && row.path == _path);
    expect(post.body!['account_id'], '21');
    expect(post.body!['transaction_currency_code'], 'USD');
    expect(post.body, isNot(contains('order')));
    expect(post.body, isNot(contains('colour')));

    // The create and edit share a Drift timestamp.
    final secondWallet =
        (await context.idMap.byRemote(FireflyEntityType.walletAccount, '22'))!
            .localPk;
    await (db.update(db.objectives)
          ..where((row) => row.objectivePk.equals(goal.objectivePk)))
        .write(ObjectivesCompanion(
      name: const Value('Local edit'),
      walletFk: Value(secondWallet),
      amount: const Value(132.15),
      endDate: const Value(null),
      dateTimeModified: Value(now),
    ));
    await sync();
    final edited = await api.piggyBanks.get(id);
    expect(edited.name, 'Local edit');
    expect(edited.targetAmount, 132.15);
    expect(edited.targetDate, isNull);
    expect(edited.accounts.single.id, '22');
    final put = emulator.requests
        .singleWhere((row) => row.method == 'PUT' && row.path == '$_path/$id');
    expect(put.body!['accounts'], [
      {'account_id': '22', 'current_amount': '0.00'}
    ]);

    await api.piggyBanks.update(id, {
      'name': 'Server edit',
      'target_amount': '145.00',
      'order': 99,
      'notes': 'Some server notes',
    });
    await sync();
    final saved = (await db.fireflyObjective(goal.objectivePk))!;
    expect(saved.name, 'Server edit');
    expect(saved.amount, 145);
    expect(saved.walletFk, secondWallet);
    expect(saved.order, goal.order);
    expect(saved.colour, goal.colour);
    expect(saved.iconName, goal.iconName);
    expect(saved.emojiIconName, goal.emojiIconName);
    expect(saved.pinned, goal.pinned);
    expect(saved.income, goal.income);
    expect(saved.archived, goal.archived);

    emulator.requests.clear();
    await sync();
    expect(emulator.requests.where((row) => row.method != 'GET'), isEmpty);
    await db.removeFireflyGoal(goal.objectivePk);
    await db.createDeleteLog(DeleteLogType.Objective, goal.objectivePk);
    await sync();
    await expectLater(api.piggyBanks.get(id), throwsA(isA<FireflyNotFound>()));
    expect(await context.idMap.byLocal(_piggyBank, goal.objectivePk), isNull);
    expect(await context.cache.read(_piggyBank, id), isNull);
  });

  test('adjusts the saved total online and pulls paginated signed events',
      () async {
    emulator.seedBank('31', 'Trip', accounts: [
      {'id': '21', 'current_amount': '3.00'},
      {'id': '22', 'current_amount': '12.00'},
    ]);
    await sync();
    final pk = (await context.idMap.byRemote(_piggyBank, '31'))!.localPk;
    expect(await db.fireflyPiggyBankCurrentAmount(pk), 15);

    await setFireflyPiggyBankAmount(context, pk, 18.25);
    expect((await api.piggyBanks.get('31')).currentAmount, 18.25);
    expect(await db.fireflyPiggyBankCurrentAmount(pk), 18.25);
    expect(await db.fireflyPiggyBankEvents(pk), isEmpty);
    await sync();
    final added = (await db.fireflyPiggyBankEvents(pk)).single;
    expect(added.amount, 3.25);
    expect(added.journalId, isNull);

    await setFireflyPiggyBankAmount(context, pk, 7.50);
    final bank = await api.piggyBanks.get('31');
    expect(bank.currentAmount, 7.50);
    expect(bank.accounts.map((account) => account.id), ['21', '22']);
    expect(bank.accounts.map((account) => account.currentAmount), [0, 7.5]);
    emulator.requests.clear();
    await sync();
    expect((await db.fireflyPiggyBankEvents(pk)).map((event) => event.amount),
        [3.25, -10.75]);
    expect(
        emulator.requests
            .where((row) => row.path == '$_path/31/events')
            .map((row) => row.query['page']),
        ['1', '2']);

    final puts = emulator.requests.where((row) => row.method == 'PUT');
    await setFireflyPiggyBankAmount(context, pk, 7.50);
    expect(puts, isEmpty);
  });

  test('links a first-import journal and an old journal with a new event',
      () async {
    emulator.seedBank('31', 'Travel');
    emulator.seedBank('32', 'Education');
    final old = now.subtract(const Duration(days: 150));
    Future<({String group, String journal})> deposit(String description) async {
      final group = await api.transactions.create({
        'transactions': [
          {
            'type': 'deposit',
            'amount': '5.00',
            'date': old.toIso8601String(),
            'description': description,
            'destination_id': '21',
          }
        ]
      });
      return (group: group.id, journal: group.splits.single.journalId!);
    }

    final first = await deposit('First');
    final late = await deposit('Later');
    emulator.seedEvent('31',
        amount: '5', group: first.group, journal: first.journal);
    await sync(full: true);
    Future<String?> link(String group, String journal) async {
      final mapping =
          (await context.idMap.byRemote(_transaction, group, subId: journal))!;
      return (await db.fireflyTransaction(mapping.localPk))!.objectiveFk;
    }

    final firstGoal = (await context.idMap.byRemote(_piggyBank, '31'))!.localPk;
    final secondGoal =
        (await context.idMap.byRemote(_piggyBank, '32'))!.localPk;
    expect(await link(first.group, first.journal), firstGoal);
    expect(await link(late.group, late.journal), isNull);

    now = now.add(const Duration(days: 3));
    emulator.seedEvent('32', amount: '5', journal: late.journal);
    emulator.requests.clear();
    await sync();
    expect(await link(late.group, late.journal), secondGoal);
    expect(emulator.requests.where((row) => row.method != 'GET'), isEmpty);

    await api.piggyBanks.delete('32');
    await sync();
    expect(await link(late.group, late.journal), isNull);
    expect(await db.fireflyObjective(secondGoal), isNull);
    expect(await context.cache.read(_piggyBank, '32'), isNull);
  });

  test('excludes loans from natural-key matching and remote writes', () async {
    await sync();
    final loan = await addObjective('Same name', type: ObjectiveType.loan);
    emulator.seedBank('31', 'Same name');
    emulator.requests.clear();
    await sync();

    final mapping = (await context.idMap.byRemote(_piggyBank, '31'))!;
    expect(mapping.localPk, isNot(loan.objectivePk));
    expect(
        (await db.fireflyObjective(mapping.localPk))?.type, ObjectiveType.goal);
    expect(await context.idMap.byLocal(_piggyBank, loan.objectivePk), isNull);
    await expectLater(setFireflyPiggyBankAmount(context, loan.objectivePk, 5),
        throwsA(isA<FireflyNotFound>()));
    expect(emulator.requests.where((row) => row.method != 'GET'), isEmpty);
    await (db.delete(db.objectives)
          ..where((row) => row.objectivePk.equals(loan.objectivePk)))
        .go();
    await db.createDeleteLog(DeleteLogType.Objective, loan.objectivePk);
    await sync();
    expect(emulator.requests.where((row) => row.method != 'GET'), isEmpty);
  });

  test('contributes a mapped goal only to a new transfer', () async {
    emulator.seedBank('31', 'Travel');
    await sync();
    final goal = (await context.idMap.byRemote(_piggyBank, '31'))!.localPk;
    await db.into(db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            categoryPk: const Value('0'),
            name: 'Balance correction',
            order: 0,
          ),
        );
    final row = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            name: 'Save',
            amount: -5,
            note: '',
            categoryFk: '0',
            objectiveFk: Value(goal),
          ),
        );
    const contributor = PiggyBankContributor();
    final transfer = <String, Object?>{'type': 'transfer'};
    await contributor.push(context, row, transfer);
    expect(transfer['piggy_bank_id'], '31');
    final deposit = <String, Object?>{'type': 'deposit'};
    await contributor.push(context, row, deposit);
    expect(deposit, isNot(contains('piggy_bank_id')));

    await context.idMap.put(fixtureMapping(
      type: _transaction,
      localPk: row.transactionPk,
      remoteId: '41',
      subId: '42',
    ));
    transfer.remove('piggy_bank_id');
    await contributor.push(context, row, transfer);
    expect(transfer, isNot(contains('piggy_bank_id')));
  });

  test('leaves the previous event cache intact if a page fails', () async {
    emulator.seedBank('31', 'Trip');
    emulator.seedEvent('31', amount: '2');
    await sync();
    final pk = (await context.idMap.byRemote(_piggyBank, '31'))!.localPk;
    now = now.add(const Duration(days: 1));
    emulator.seedBank('31', 'Trip', accounts: [
      {'id': '21', 'current_amount': '5.00'}
    ]);
    emulator.seedEvent('31', amount: '3');
    emulator.onRequest = (request) {
      if (request.path == '$_path/31/events' && request.query['page'] == '2') {
        throw const FireflyUnexpectedResponse(400);
      }
    };
    expect((await engine.run()).succeeded, isFalse);
    expect(await db.fireflyPiggyBankCurrentAmount(pk), 5);
    expect((await db.fireflyPiggyBankEvents(pk)).map((event) => event.amount),
        [2]);

    emulator.onRequest = null;
    await sync();
    expect((await db.fireflyPiggyBankEvents(pk)).map((event) => event.amount),
        [2, 3]);
    final cached = (await context.cache.read(_piggyBank, '31'))!;
    expect(ResourceCacheRepository.decode(cached)['id'], '31');
  });
}

class _PiggyBankEmulator extends FireflyEmulator {
  _PiggyBankEmulator(DateTime Function() clock) : super(clock: clock);

  final _banks = <String, JsonObject>{};
  var _nextEvent = 1;

  String get _time => clock().toIso8601String();

  void seedBank(String id, String name,
      {List<JsonObject> accounts = const [
        {'id': '21', 'current_amount': '0.00'}
      ]}) {
    _storeBank(id, {
      'name': name,
      'created_at': _time,
      'updated_at': _time,
      'target_amount': '500.00',
      'currency_decimal_places': 2,
      'accounts': accounts,
    });
  }

  void seedEvent(String id,
      {required String amount, String? group, String? journal}) {
    seed('$_path/$id/events', '${_nextEvent++}', {
      'amount': amount,
      'created_at': _time,
      'transaction_group_id': group,
      'transaction_journal_id': journal,
    });
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    if (path != '/api/v1$_path') return super.post(path, body, query: query);
    if (body['transaction_currency_code'] == null) {
      throw const FireflyValidation('Missing piggy bank currency');
    }
    final accounts = _accounts(body);
    final resource = await super.post(path, body, query: query);
    return _storeBank(resource['id'] as String, {
      ...body,
      'accounts': accounts,
      'created_at': _time,
      'updated_at': _time,
      'currency_decimal_places': 2,
    });
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    if (!path.startsWith('/api/v1$_path/')) {
      return super.put(path, body, query: query);
    }
    if (body.containsKey('current_amount')) {
      throw const FireflyValidation('Amount belongs to the account');
    }
    final id = path.split('/').last;
    final old = _banks[id];
    if (old == null) throw const FireflyNotFound();
    final accounts = body.containsKey('accounts') ? _accounts(body) : null;
    if (accounts != null) {
      final delta = _total(accounts) -
          parseFireflyAmount(old['current_amount'] as String);
      if (delta.abs() >= 0.005) seedEvent(id, amount: delta.toStringAsFixed(2));
    }
    final resource = await super.put(path, body, query: query);
    return _storeBank(id, {
      ...old,
      ...(resource['attributes'] as JsonObject),
      if (accounts != null) 'accounts': accounts,
    });
  }

  List<JsonObject> _accounts(JsonObject body) => [
        for (final account in (body['accounts'] as List).cast<JsonObject>())
          {
            'account_id': account['account_id'] as String? ??
                (throw const FireflyValidation('Missing nested account_id')),
            'current_amount': account['current_amount'] as String,
          }
      ];

  double _total(List<JsonObject> accounts) => accounts.fold<double>(
      0,
      (sum, account) =>
          sum + parseFireflyAmount(account['current_amount'] as String));

  JsonObject _storeBank(String id, JsonObject bank) {
    final accounts = (bank['accounts'] as List).cast<JsonObject>();
    final attributes = {
      ...bank,
      'current_amount': _total(accounts).toStringAsFixed(2),
    };
    _banks[id] = attributes;
    seed(_path, id, attributes);
    return fireflyResource('piggy-banks', id, attributes);
  }
}

class _LoopbackClient extends http.BaseClient {
  _LoopbackClient(this.target);

  final Uri target;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final url = target.replace(
        path: request.url.path,
        query: request.url.hasQuery ? request.url.query : null);
    final copy = http.Request(request.method, url)
      ..headers.addAll(request.headers)
      ..bodyBytes = (request as http.Request).bodyBytes;
    return _inner.send(copy);
  }

  @override
  void close() => _inner.close();
}

import 'dart:async';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/about.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/resources/about_api.dart';
import 'package:budget/firefly/api/resources/accounts_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/delete_log_queries.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _enabled =
    FireflyConfig(mode: true, baseUrl: 'https://example.test/api/v1');
const _currency = FireflyEntityType.currency;
const _category = FireflyEntityType.category;
const _wallet = FireflyEntityType.walletAccount;
const _transaction = FireflyEntityType.transaction;

void main() {
  late FinanceDatabase db;
  late FakeFireflyTransport transport;
  late SyncContext context;
  late DateTime now;
  late List<String> calls;

  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    transport = FakeFireflyTransport();
    now = fixtureTime;
    calls = [];
    context = SyncContext(
      db: db,
      api: _FakeApi(transport),
      config: _enabled,
      now: () => now,
    );
  });

  SyncEngine engineFor(
    List<EntitySyncer> syncers, {
    List<TransactionContributor> contributors = const [],
    SyncContext? withContext,
  }) {
    final engine = SyncEngine(withContext ?? context,
        syncers: syncers, contributors: contributors);
    addTearDown(engine.dispose);
    return engine;
  }

  test('runs phases in dependency order and rereads pushed transactions',
      () async {
    transport.onRequest = (request) => calls.add(request.path);
    final engine = engineFor([
      _Syncer(_category, calls),
      _Syncer(_transaction, calls, dependsOn: {_category}, onPush: (cycle) {
        cycle.pushedTransactionIds.add('123');
      }),
    ]);
    final progress = <SyncProgress>[];
    final complete = Completer<void>();
    final events = engine.progress.listen((event) {
      progress.add(event);
      if (event.phase == SyncPhase.complete) complete.complete();
    });
    addTearDown(events.cancel);

    final report = await engine.run();
    await complete.future;
    expect(report.succeeded, isTrue);
    expect(engine.lastReport, same(report));
    expect(engine.isRunning, isFalse);
    expect(calls, [
      '/about',
      '/about/user',
      'pull:category',
      'pull:transaction',
      'push:category',
      'push:transaction',
      'delete:transaction',
      'delete:category',
      'reread:transaction',
    ]);
    expect(progress.map((event) => event.phase), [
      SyncPhase.preflight,
      SyncPhase.pull,
      SyncPhase.pull,
      SyncPhase.push,
      SyncPhase.push,
      SyncPhase.delete,
      SyncPhase.delete,
      SyncPhase.reread,
      SyncPhase.parity,
      SyncPhase.complete,
    ]);
    expect(progress[2].entityType, _transaction);
    expect(await context.meta.readDate(SyncMetaRepository.lastSync),
        now.toLocal());
  });

  test('shares one future and cycle with concurrent triggers', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final engine = engineFor([
      _Syncer(_category, calls, onPull: (_) async {
        entered.complete();
        await release.future;
      }),
    ]);

    final first = engine.run();
    expect(engine.isRunning, isTrue);
    await entered.future;
    final second = engine.run(fullResync: true);
    expect(second, same(first));
    release.complete();
    expect(await second, same(await first));
    expect(calls, ['pull:category', 'push:category', 'delete:category']);
    expect(transport.requests.map((request) => request.path),
        ['/about', '/about/user']);
  });

  test('cancellation stops between entities and leaves the engine reusable',
      () async {
    var cancelledBySyncer = false;
    late SyncEngine engine;
    engine = engineFor([
      _Syncer(_category, calls, onPull: (cycle) {
        if (cancelledBySyncer) return;
        cancelledBySyncer = true;
        engine.cancel();
        expect(cycle.isCancelled(), isTrue);
      }),
      _Syncer(_transaction, calls),
    ]);

    expect((await engine.run()).cancelled, isTrue);
    expect(calls, ['pull:category']);
    expect(await context.meta.read(SyncMetaRepository.lastSync), isNull);
    calls.clear();
    expect((await engine.run()).succeeded, isTrue);
    expect(calls, contains('pull:transaction'));
  });

  test('401 stops the cycle and preserves local data and delete cursor',
      () async {
    final wallet = await db.into(db.wallets).insertReturning(
          WalletsCompanion.insert(name: 'Example', order: 0),
        );
    await context.idMap.put(fixtureMapping());
    await db.into(db.deleteLogs).insert(DeleteLogsCompanion.insert(
        entryPk: 'local', type: DeleteLogType.TransactionCategory));
    transport.onRequest = (request) {
      if (request.path == '/about/user') throw const FireflyUnauthorized();
    };
    final engine = engineFor([_Syncer(_category, calls)]);

    final report = await engine.run();
    expect(report.succeeded, isFalse);
    expect(report.issues.single.message, 'firefly-sync-auth-required');
    expect(report.issues.single.phase, SyncPhase.preflight);
    expect(calls, isEmpty);
    expect(await db.select(db.wallets).getSingle(), wallet);
    expect((await context.idMap.byLocal(_category, 'local'))?.state,
        FireflySyncState.synced);
    expect(await context.meta.read(SyncMetaRepository.deleteLogCursor), isNull);
    expect(await context.meta.read(SyncMetaRepository.serverUserId), isNull);
  });

  test('401 and exhausted network failures during an entity abort later work',
      () async {
    for (final error in [
      const FireflyUnauthorized(),
      const FireflyNetworkError(),
    ]) {
      calls.clear();
      final engine = engineFor([
        _Syncer(_category, calls, onPull: (_) => throw error),
        _Syncer(_wallet, calls),
      ]);

      final report = await engine.run();
      expect(report.issues.single.entityType, _category);
      expect(report.issues.single.phase, SyncPhase.pull);
      expect(calls, ['pull:category']);
    }
  });

  test('entity errors block dependents and leave independent work running',
      () async {
    final engine = engineFor([
      _Syncer(_category, calls,
          onPull: (_) => throw StateError('Example error')),
      _Syncer(_transaction, calls, dependsOn: {_category}),
      _Syncer(_currency, calls),
    ]);

    final report = await engine.run();
    expect(report.issues.single.entityType, _category);
    expect(report.issues.single.phase, SyncPhase.pull);
    expect(calls,
        ['pull:category', 'pull:currency', 'push:currency', 'delete:currency']);
    expect(await context.meta.read(SyncMetaRepository.lastSync), isNull);
  });

  test('rejects a different URL or user before mutating finance data',
      () async {
    final engine = engineFor([_Syncer(_category, calls)]);
    expect((await engine.run()).succeeded, isTrue);
    final storedUrlHash =
        await context.meta.read(SyncMetaRepository.serverUrlHash);
    expect(storedUrlHash, hasLength(64));

    calls.clear();
    transport.requests.clear();
    final otherEngine = engineFor([_Syncer(_category, calls)],
        withContext: SyncContext(
          db: db,
          api: context.api,
          config: const FireflyConfig(
              mode: true, baseUrl: 'https://other.example.test'),
        ));
    expect((await otherEngine.run()).issues.single.message,
        'firefly-sync-identity-changed');
    expect(transport.requests, isEmpty);

    await context.meta.write(SyncMetaRepository.serverUserId, 'other-user');
    final report = await engine.run();
    expect(report.issues.single.message, 'firefly-sync-identity-changed');
    expect(report.issues.single.phase, SyncPhase.preflight);
    expect(
        await context.meta.read(SyncMetaRepository.serverUserId), 'other-user');
    expect(await context.meta.read(SyncMetaRepository.serverUrlHash),
        storedUrlHash);
    expect(transport.requests.map((request) => request.path),
        ['/about', '/about/user']);
    expect(calls, isEmpty);
  });

  test('marks mapped deletes, ignores unmapped ones and handles timestamp ties',
      () async {
    await context.idMap.put(fixtureMapping(localPk: 'mapped'));
    await context.idMap.put(fixtureMapping(localPk: 'late', remoteId: '2'));

    Future<void> log(String pk) => db.into(db.deleteLogs).insert(
          DeleteLogsCompanion.insert(
            deleteLogPk: Value(pk),
            entryPk: pk,
            type: DeleteLogType.TransactionCategory,
            dateTimeModified: Value(now),
          ),
        );

    await log('mapped');
    await log('unmapped');
    final engine = engineFor([]);
    expect((await engine.run()).succeeded, isTrue);
    expect((await context.idMap.byLocal(_category, 'mapped'))?.state,
        FireflySyncState.pendingDelete);
    expect(await context.idMap.byLocal(_category, 'unmapped'), isNull);
    final cursor =
        await context.meta.readDate(SyncMetaRepository.deleteLogCursor);
    expect(cursor, now.toLocal());

    // Simulate restoration by a pull, then a second delete at the same timestamp.
    await context.idMap.put(fixtureMapping(localPk: 'mapped'));
    await log('late');
    expect(await db.fireflyDeleteLogs(after: cursor), isEmpty);
    expect((await engine.run()).succeeded, isTrue);
    expect((await context.idMap.byLocal(_category, 'mapped'))?.state,
        FireflySyncState.synced);
    expect((await context.idMap.byLocal(_category, 'late'))?.state,
        FireflySyncState.pendingDelete);
  });

  test('reconciles weekly and after a contributor change or manual request',
      () async {
    final modes = <SyncPullMode>[];
    final contributor = _Contributor();
    var failPull = false;
    final key = SyncMetaRepository.contributorVersion(contributor.id);
    final engine = engineFor([
      _Syncer(_transaction, calls, onPull: (cycle) async {
        modes.add(cycle.pullMode);
        if (failPull) throw const FireflyInvalidPayload();
        if (cycle.pullMode == SyncPullMode.initial) {
          await cycle.meta.write(SyncMetaRepository.transactionPage, '3');
        }
      }),
    ], contributors: [
      contributor
    ]);

    expect((await engine.run()).succeeded, isTrue);
    expect(await context.meta.read(key), '0');
    expect(await context.meta.read(SyncMetaRepository.transactionPage), isNull);
    now = now.add(const Duration(days: 6));
    await engine.run();
    now = now.add(const Duration(days: 1));
    await engine.run();

    contributor.version = 1;
    now = now.add(const Duration(days: 1));
    failPull = true;
    expect((await engine.run()).succeeded, isFalse);
    expect(await context.meta.read(key), '0');
    expect(await context.meta.readDate(SyncMetaRepository.transactionCursor),
        now.subtract(const Duration(days: 1)).toLocal());

    failPull = false;
    expect((await engine.run()).succeeded, isTrue);
    expect(await context.meta.read(key), '1');
    await engine.run(fullResync: true);
    expect(modes, [
      SyncPullMode.initial,
      SyncPullMode.incremental,
      SyncPullMode.full,
      SyncPullMode.full,
      SyncPullMode.full,
      SyncPullMode.full,
    ]);
  });

  test('compares paid asset totals with the refreshed server balance',
      () async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('asset'), name: 'Example', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('category'), name: 'Example', order: 0));
    await context.idMap.put(fixtureMapping(type: _wallet, localPk: 'asset'));
    for (final paid in [true, false]) {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            name: 'Example',
            amount: 5,
            note: '',
            categoryFk: 'category',
            walletFk: const Value('asset'),
            paid: Value(paid),
          ));
    }
    transport.seed('/accounts', '1', {'current_balance': '5.001'});
    final engine = engineFor([]);
    expect((await engine.run()).balanceMismatches, isEmpty);

    transport.seed('/accounts', '1', {'current_balance': '4.50'});
    final report = await engine.run();
    expect(report.succeeded, isTrue);
    expect(report.balanceMismatches, {'asset': 0.5});
  });

  test('mode off makes manual and automatic triggers inert', () async {
    final engine = engineFor([_Syncer(_category, calls)],
        withContext: SyncContext(
          db: db,
          api: context.api,
          config: const FireflyConfig(),
        ));
    final scheduler = SyncScheduler(engine);
    addTearDown(scheduler.dispose);
    scheduler.start();
    scheduler.localWrite();
    expect((await scheduler.syncNow()).cancelled, isTrue);
    expect(engine.isRunning, isFalse);
    expect(transport.requests, isEmpty);
    expect(calls, isEmpty);
  });

  testWidgets('scheduler debounces writes and runs only foreground timers',
      (tester) async {
    final engine = _RecordingEngine(context);
    final scheduler = SyncScheduler(engine);
    addTearDown(engine.dispose);
    addTearDown(scheduler.dispose);
    scheduler.start();
    scheduler.start();
    expect(engine.requests, [false]);

    scheduler.localWrite();
    await tester.pump(const Duration(seconds: 4));
    scheduler.localWrite();
    await tester.pump(const Duration(seconds: 4));
    expect(engine.requests, [false]);
    await tester.pump(const Duration(seconds: 1));
    expect(engine.requests, [false, false]);

    scheduler.localWrite();
    scheduler.pause();
    await tester.pump(const Duration(minutes: 15));
    expect(engine.requests, [false, false]);
    scheduler.resume();
    await tester.pump(const Duration(minutes: 15));
    expect(engine.requests, [false, false, false, false]);
    await scheduler.syncNow(fullResync: true);
    expect(engine.requests.last, isTrue);
    scheduler.dispose();
  });

  testWidgets('scheduler ignores late watcher events during suppression',
      (tester) async {
    final engine = _RecordingEngine(context);
    final scheduler = SyncScheduler(engine);
    addTearDown(engine.dispose);
    addTearDown(scheduler.dispose);
    scheduler.start();

    scheduler.suppressLocalWrites(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    scheduler.localWrite();
    await tester.pump(const Duration(seconds: 5));
    expect(engine.requests, [false]);

    scheduler.localWrite();
    await tester.pump(const Duration(seconds: 5));
    expect(engine.requests, [false, false]);
    scheduler.dispose();
  });
}

class _Syncer extends EntitySyncer {
  _Syncer(this.type, this.calls,
      {this.dependsOn = const {}, this.onPull, this.onPush});

  @override
  final FireflyEntityType type;
  @override
  final Set<FireflyEntityType> dependsOn;
  final List<String> calls;
  final FutureOr<void> Function(SyncContext)? onPull;
  final void Function(SyncContext)? onPush;

  @override
  Future<void> pull(SyncContext context) async {
    calls.add('pull:${type.name}');
    await onPull?.call(context);
  }

  @override
  Future<void> push(SyncContext context) async {
    calls.add('push:${type.name}');
    onPush?.call(context);
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    calls.add('delete:${type.name}');
  }

  @override
  Future<void> rereadPushed(SyncContext context) async {
    expect(context.pushedTransactionIds, {'123'});
    calls.add('reread:${type.name}');
  }
}

class _Contributor extends TransactionContributor {
  @override
  String get id => 'example';

  @override
  int version = 0;
}

class _FakeApi extends FireflyApi {
  _FakeApi(super.transport);

  @override
  AboutApi get about => _FakeAbout(transport);

  @override
  AccountsApi get accounts => _FakeAccounts(transport);
}

// WP-03 owns the production about client. Use the typed client contract here.
class _FakeAbout extends AboutApi {
  const _FakeAbout(super.transport);

  @override
  Future<FireflyAbout> get() async {
    final data = await transport.get('/about');
    return FireflyAbout(version: data['version']! as String);
  }

  @override
  Future<FireflyUser> getUser() async {
    final data = await transport.get('/about/user');
    return FireflyUser(id: data['id']! as String);
  }
}

class _FakeAccounts extends AccountsApi {
  const _FakeAccounts(super.transport);

  @override
  Future<FireflyAccount> get(String id) async {
    final data = await transport.get('/accounts/$id');
    return FireflyAccount(
        id: id, attributes: data['attributes']! as JsonObject);
  }
}

class _RecordingEngine extends SyncEngine {
  _RecordingEngine(super.context);

  final requests = <bool>[];

  @override
  Future<SyncReport> run({bool fullResync = false}) async {
    requests.add(fullResync);
    return const SyncReport();
  }
}

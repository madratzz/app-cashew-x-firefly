import 'dart:io';

import 'package:budget/database/generatePreviewData.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/sync/bootstrap_upload.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/wallet_account_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../e2e/phase2/support/phase2_emulator.dart';
import '../e2e/support/e2e_harness.dart';

final _time = DateTime(2025, 5, 15);
const _base = 'https://firefly.example';

class UploadServer extends Phase2Emulator {
  UploadServer() : super(clock: () => _time) {
    seed('/currencies', 'BTC', {
      'code': 'BTC',
      'decimal_places': 8,
      'enabled': false,
    });
    seed('/currencies', 'EUR', {
      'code': 'EUR',
      'decimal_places': 2,
      'enabled': false,
    });
  }

  String? loseBefore;
  String? loseAfter;
  bool loseBytes = false;
  bool omitMarker = false;
  bool wrongBalance = false;
  bool implicitCash = false;
  bool invalidPage = false;
  final commits = <({String path, String id})>[];

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    path = path.replaceFirst('/api/v1/', '/');
    if (invalidPage && path == '/attachments') {
      return const FireflyPage(
          items: [], total: 1, currentPage: 1, perPage: 1, totalPages: 1);
    }
    return super.getPage(path, query: query);
  }

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    path = path.replaceFirst('/api/v1/', '/');
    final row = await super.get(path, query: query);
    if (wrongBalance && path.startsWith('/accounts/')) {
      return {
        ...row,
        'attributes': {
          ...row['attributes']! as JsonObject,
          'current_balance': '1'
        },
      };
    }
    return row;
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    path = path.replaceFirst('/api/v1/', '/');
    if (path == loseBefore) {
      loseBefore = null;
      throw const FireflyNetworkError();
    }
    final clean = {
      ...body,
      if (path == '/accounts' && body['currency_code'] == 'BTC')
        'currency_decimal_places': 8,
    };
    if (path == loseAfter && omitMarker) clean.remove('notes');
    if (path == '/transactions' && implicitCash) {
      clean['transactions'] = [
        for (final split in (body['transactions']! as List).cast<JsonObject>())
          _cashCounterparty(split),
      ];
    }
    final row = await super.post(path, clean, query: query);
    if (!path.endsWith('/enable')) {
      commits.add((path: path, id: row['id']! as String));
    }
    if (path == loseAfter) {
      loseAfter = null;
      throw const FireflyTimeout();
    }
    return row;
  }

  JsonObject _cashCounterparty(JsonObject split) {
    final side = switch (split['type']) {
      'withdrawal' => 'destination',
      'deposit' => 'source',
      _ => null,
    };
    if (side == null || split['${side}_id'] != null) return split;
    seed('/accounts', '1000000', {
      'name': 'Cash account',
      'type': 'cash',
      'currency_code': 'USD',
    });
    return {
      ...split,
      '${side}_id': '1000000',
      '${side}_type': 'Cash account',
    };
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
      {int? length}) async {
    final data = await bytes.expand((chunk) => chunk).toList();
    await super.upload(path, Stream.value(data), length: length);
    final itemPath = path.substring(0, path.length - '/upload'.length);
    final item = await get(itemPath);
    seed('/attachments', item['id']! as String, {
      ...item['attributes']! as JsonObject,
      'size': data.length,
      'hash': md5.convert(data).toString(),
    });
    if (loseBytes) {
      loseBytes = false;
      throw const FireflyTimeout();
    }
  }
}

Future<void> createWallet(FinanceDatabase db, String id, String currency) =>
    db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: Value(id),
          name: 'Wallet $id',
          dateCreated: Value(_time),
          order: 0,
          currency: Value(currency),
          decimals: const Value(2),
        ));

Future<void> _tx(FinanceDatabase db, String id, double amount,
        {String? pair,
        String? group,
        String? payee,
        String? bill,
        String? budget,
        String wallet = '0',
        bool paid = true,
        TransactionSpecialType? type}) =>
    db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: Value(id),
          name: 'Entry $id',
          amount: amount,
          note: '',
          categoryFk: pair == null ? 'food' : '0',
          walletFk: Value(wallet),
          dateCreated: Value(_time),
          income: Value(amount > 0),
          paid: Value(paid),
          type: Value(type),
          pairedTransactionFk: Value(pair),
          payeeFk: Value(payee),
          sharedReferenceBudgetPk: Value(budget),
          billFk: Value(bill),
          splitGroupFk: Value(group),
          splitOrder: Value(group == null
              ? null
              : id == 's1'
                  ? 0
                  : 1),
        ));

Future<Attachment> _fixture(FinanceDatabase db, Directory dir) async {
  await createWallet(db, '0', 'usd');
  await createWallet(db, 'travel', 'eur');
  for (final id in ['0', 'food']) {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(categoryPk: Value(id), name: id, order: 0));
  }
  final spender = await db.into(db.payees).insertReturning(
      PayeesCompanion.insert(name: 'Shop', kind: PayeeKind.expense));
  final tag = await db.into(db.tags).insertReturning(TagsCompanion.insert(
      name: 'Test label', description: const Value('Local description')));
  final budget =
      await db.into(db.budgets).insertReturning(BudgetsCompanion.insert(
            name: 'Envelope',
            startDate: DateTime(2025, 5),
            endDate: DateTime(2025, 5, 31),
            amount: 100,
            reoccurrence: const Value(BudgetReoccurence.monthly),
            periodLength: 1,
            order: 0,
            addedTransactionsOnly: const Value(true),
          ));
  await db.into(db.budgetLimits).insert(BudgetLimitsCompanion.insert(
      budgetFk: budget.budgetPk,
      start: DateTime(2025, 5),
      end: DateTime(2025, 5, 31),
      amount: 80,
      currency: 'usd'));
  await db.writeFireflyGoal(
      name: 'Reserve',
      amount: 50,
      walletPk: '0',
      startDate: _time,
      targetDate: DateTime(2026),
      modifiedAt: _time);
  final bill = await db.saveFireflyBill({
    'name': 'Subscription',
    'amount_min': '4',
    'amount_max': '4',
    'date': '2025-05-15',
    'repeat_freq': 'monthly',
    'skip': 0,
    'active': true,
    'currency_code': 'USD',
  });

  await db.into(db.transactionGroups).insert(const TransactionGroupsCompanion(
      groupPk: Value('group'), title: Value('Split purchase')));
  await _tx(db, 's1', -4,
      group: 'group',
      payee: spender.payeePk,
      bill: bill,
      budget: budget.budgetPk);
  await _tx(db, 's2', -3, group: 'group', payee: spender.payeePk);
  await _tx(db, 'out', -9);
  await _tx(db, 'in', 9, pair: 'out', wallet: 'travel');
  await (db.update(db.transactions)
        ..where((row) => row.transactionPk.equals('out')))
      .write(const TransactionsCompanion(
          pairedTransactionFk: Value('in'), categoryFk: Value('0')));
  await _tx(db, 'lent', -5, type: TransactionSpecialType.credit);
  await _tx(db, 'borrowed', 2, type: TransactionSpecialType.debt);
  await _tx(db, 'unpaid', -8, paid: false);
  await db.into(db.transactionTags).insert(
      TransactionTagsCompanion.insert(transactionFk: 's1', tagFk: tag.tagPk));
  final attachment = await db.prepareFireflyAttachment(
      filename: 'receipt.txt',
      bytes: Stream.value([1, 2, 3]),
      supportDirectory: dir);
  final saved = attachment.copyWith(attachableFk: 's1');
  await db.into(db.attachments).insert(saved);
  return saved;
}

Future<Map<String, Object?>> sourceRows(FinanceDatabase db) async => {
      for (final table in db.allTables)
        if (table.actualTableName != db.fireflyIdMap.actualTableName)
          table.actualTableName: (await db
                  .customSelect('SELECT * FROM "${table.actualTableName}"')
                  .get())
              .map((row) => row.data)
              .toList(),
    };

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late Directory dir;
  late String dbPath;
  late UploadServer server;

  FireflyBootstrapUpload upload({String url = _base}) => FireflyBootstrapUpload(
        SyncContext(
            db: db,
            api: FireflyApi(server),
            config: FireflyConfig(baseUrl: url, pageSize: 1),
            now: () => _time),
        attachmentDirectory: dir,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    globals.sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    dir = await Directory.systemTemp.createTemp('firefly-upload-test');
    dbPath = '${dir.path}/cashew.sqlite';
    db = FinanceDatabase(NativeDatabase(File(dbPath)));
    globals.database = db;
    globals.clientID = 'test-client';
    server = UploadServer();
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> restart() async {
    await db.close();
    db = FinanceDatabase(NativeDatabase(File(dbPath)));
    globals.database = db;
  }

  test('requires a preview and uploads in dependency order without local edits',
      () async {
    final file = await _fixture(db, dir);
    final before = await sourceRows(db);
    final workflow = upload();
    final summary = await workflow.prepare();
    expect(summary.currencies, ['EUR', 'USD']);
    expect(summary.transfers, 1);
    expect(summary.splits, 2);
    expect(summary.splitGroups, 1);
    expect(summary.counts[FireflyEntityType.transaction], 4);
    expect(
        summary.skipped.map((issue) => issue.message),
        unorderedEquals([
          'firefly-upload-skip-loan',
          'firefly-upload-skip-loan',
          'firefly-upload-skip-unpaid',
        ]));
    expect((await workflow.run()).cancelled, isTrue);
    expect(
        server.requests.where((request) => request.method != 'GET'), isEmpty);
    expect(await sourceRows(db), before);
    final report = await workflow.run(confirmed: summary);
    expect(
        report.issues
            .whereType<FireflyUploadIssue>()
            .map((issue) => [issue.message, issue.entityType, issue.item]),
        isEmpty);
    expect(report.balanceMismatches, isEmpty);
    expect(await sourceRows(db), before);
    expect(await File(file.localPath!).readAsBytes(), [1, 2, 3]);

    final writes = server.requests.where((request) => request.method == 'POST');
    expect(
        writes.map((request) => request.path
            .replaceFirst(RegExp(r'/budgets/\d+/limits'), '/limits')),
        [
          '/currencies/EUR/enable',
          '/accounts',
          '/accounts',
          '/categories',
          '/accounts', // Payee
          '/tags',
          '/budgets',
          '/limits',
          '/piggy-banks',
          '/bills',
          '/transactions',
          '/transactions',
          '/attachments',
        ]);
    final transactions =
        writes.where((request) => request.path == '/transactions');
    expect(
        transactions.every((request) =>
            request.body!['apply_rules'] == false &&
            request.body!['fire_webhooks'] == false),
        isTrue);
    final api = workflow.context.api;
    final groups = (await api.transactions.list()).items;
    expect(groups.map((group) => group.splits.length), unorderedEquals([1, 2]));
    expect(
        groups.expand((group) => group.splits).map((split) => split.externalId),
        everyElement(startsWith('cashew-upload:')));
    final attachments = (await api.attachments.list()).items;
    expect(attachments.single.filename, 'receipt.txt');
    expect(attachments.single.hash, file.hash);
    expect(await workflow.context.idMap.list(FireflyEntityType.transaction),
        hasLength(4));
    expect(
        (await workflow.context.idMap.list(FireflyEntityType.transactionGroup))
            .single
            .localPk,
        'group');
    final commits = server.commits.length;
    await restart();
    final ready = upload();
    expect(
        (await ready.run(confirmed: await ready.prepare())).succeeded, isTrue);
    expect(server.commits, hasLength(commits));
    await FireflyBootstrapUpload.finishHandoff(db);
    expect(await FireflyBootstrapUpload.inProgress(db), isFalse);
  });

  for (final path in [
    '/accounts',
    '/categories',
    '/transactions',
    '/attachments'
  ]) {
    test('recovers an accepted create at $path after reopening Cashew',
        () async {
      await _fixture(db, dir);
      final before = await sourceRows(db);
      final first = upload();
      server.loseAfter = path;
      final partial = await first.run(confirmed: await first.prepare());
      expect(partial.issues.single.message, 'firefly-upload-unresolved');
      expect(await sourceRows(db), before);
      final prior =
          server.commits.where((write) => write.path == path).toList();
      await restart();
      final resumed = upload();
      final report = await resumed.run(confirmed: await resumed.prepare());
      expect(
          report.issues
              .whereType<FireflyUploadIssue>()
              .map((issue) => [issue.message, issue.entityType, issue.item]),
          isEmpty);
      expect(report.balanceMismatches, isEmpty);
      final expected = switch (path) {
        '/accounts' => 3,
        '/transactions' => 2,
        _ => 1,
      };
      expect(server.commits.where((write) => write.path == path),
          hasLength(expected));
      expect(server.commits, containsAll(prior));
      expect(await sourceRows(db), before);
    });
  }

  test('recovers after bytes committed and response was lost', () async {
    final file = await _fixture(db, dir);
    final before = await sourceRows(db);
    final first = upload();
    server.loseBytes = true;
    final partial = await first.run(confirmed: await first.prepare());
    expect(partial.succeeded, isFalse);
    await restart();
    final retry = upload();
    expect(
        (await retry.run(confirmed: await retry.prepare())).succeeded, isTrue);
    expect(server.requests.where((request) => request.method == 'UPLOAD'),
        hasLength(1));
    expect(await sourceRows(db), before);
    expect(await File(file.localPath!).exists(), isTrue);
  });

  test(
      'HTTP transport dispatches create once when Firefly commits then returns a 500',
      () async {
    await createWallet(db, '0', 'usd');
    final target = await E2eTarget.fake(() => _time, emulator: (_) => server);
    addTearDown(target.close);
    final transport = target.transport();
    addTearDown(transport.close);
    final flow = FireflyBootstrapUpload(SyncContext(
        db: db,
        api: FireflyApi(transport),
        config: const FireflyConfig(baseUrl: _base)));
    server.loseAfter = '/accounts';
    final first = await flow.run(confirmed: await flow.prepare());
    expect(first.issues.single.message, 'firefly-upload-unresolved');
    expect(server.commits, hasLength(1));
    final retry = await flow.run(confirmed: await flow.prepare());
    expect(retry.issues.map((issue) => issue.message), isEmpty);
    expect(server.commits, hasLength(1));
  });

  test('Check again reconciles a marker without a write', () async {
    await createWallet(db, '0', 'usd');
    final first = upload();
    server.loseAfter = '/accounts';
    expect(
        (await first.run(confirmed: await first.prepare())).succeeded, isFalse);
    expect(await first.pending(), hasLength(1));
    await restart();
    final retry = upload();
    await retry.checkAgain();
    expect(await retry.pending(), isEmpty);
    expect(server.commits, hasLength(1));
    expect(
        (await retry.run(confirmed: await retry.prepare())).succeeded, isTrue);
    expect(server.commits, hasLength(1));
  });

  test('allows explicit linking after the user picks a matching object',
      () async {
    await createWallet(db, '0', 'usd');
    final first = upload();
    server.loseAfter = '/accounts';
    server.omitMarker = true;
    await first.run(confirmed: await first.prepare());
    expect(await first.canUpload(), isFalse);
    final pending = (await first.pending()).single.intent!;
    expect(await first.candidates(pending), [
      (id: server.commits.single.id, label: 'Wallet 0'),
    ]);
    await expectLater(
        first.link(pending, 'unknown'), throwsA(isA<FireflyUploadIssue>()));
    await first.link(pending, server.commits.single.id);
    expect(
        (await first.run(confirmed: await first.prepare())).succeeded, isTrue);
    expect(server.commits, hasLength(1));
  });

  test('requires explicit resend when the marker cannot be found', () async {
    await createWallet(db, '0', 'usd');
    final first = upload();
    server.loseBefore = '/accounts';
    await first.run(confirmed: await first.prepare());
    await restart();
    final retry = upload();
    await retry.checkAgain();
    final pending = (await retry.pending()).single.intent!;
    expect(
        (await retry.run(confirmed: await retry.prepare())).succeeded, isFalse);
    expect(server.commits, isEmpty);
    await retry.authorizeResend(pending);
    expect(
        (await retry.run(confirmed: await retry.prepare())).succeeded, isTrue);
    expect(server.commits, hasLength(1));
  });

  for (final path in [
    '/transactions',
    '/accounts',
    '/categories',
    '/tags',
    '/budgets',
    '/piggy-banks',
    '/bills',
    '/attachments'
  ]) {
    test('refuses preexisting $path even when the local collection is empty',
        () async {
      final first = upload();
      final preview = await first.prepare();
      server.seed(path, '97', const {'name': 'Existing'});
      expect(await first.canUpload(), isFalse);
      final report = await first.run(confirmed: preview);
      expect(report.issues.single.message, 'firefly-upload-nonempty');
      expect(server.commits, isEmpty);
      expect(await FireflyBootstrapUpload.inProgress(db), isFalse);
    });
  }

  test('refuses a malformed empty listing', () async {
    server.invalidPage = true;
    expect(await upload().canUpload(), isFalse);
    expect(server.commits, isEmpty);
  });

  test('reports each rejected category and stops dependent steps', () async {
    await _fixture(db, dir);
    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: 'Second rejected', order: 1));
    server.onRequest = (request) {
      if (request.method == 'POST' && request.path == '/categories') {
        throw const FireflyValidation('Rejected');
      }
    };
    final flow = upload();
    final preview = await flow.prepare();
    final report = await flow.run(confirmed: preview);
    expect(
        report.issues
            .whereType<FireflyUploadIssue>()
            .map((issue) => issue.item),
        unorderedEquals(['food', 'Second rejected']));
    expect(server.commits.map((commit) => commit.path),
        ['/accounts', '/accounts']);
  });

  test('balance mismatch keeps mode off and withholds finance ID mappings',
      () async {
    await createWallet(db, '0', 'usd');
    final flow = upload();
    server.wrongBalance = true;
    final report = await flow.run(confirmed: await flow.prepare());
    expect(report.balanceMismatches, {'0': -1});
    expect(await flow.context.idMap.list(FireflyEntityType.walletAccount),
        isEmpty);
    expect(await FireflyBootstrapUpload.inProgress(db), isTrue);
  });

  test('normal wallet push still repairs selection, bootstrap leaves it alone',
      () async {
    await createWallet(db, '0', 'usd');
    appStateSettings['selectedWalletPk'] = 'missing';
    final flow = upload();
    expect((await flow.run(confirmed: await flow.prepare())).succeeded, isTrue);
    expect(appStateSettings['selectedWalletPk'], 'missing');
    await const WalletAccountSyncer().push(SyncContext(
      db: db,
      api: FireflyApi(server),
      config: const FireflyConfig(mode: true),
    ));
    expect(appStateSettings['selectedWalletPk'], '0');
  });

  test('normal sync skips unpaid regular transactions and existing loan types',
      () async {
    await createWallet(db, '0', 'usd');
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('food'), name: 'Food', order: 0));
    await _tx(db, 'unpaid', -2, paid: false);
    await _tx(db, 'paid', -10);
    await _tx(db, 'settled-credit', -15,
        type: TransactionSpecialType.credit, paid: false);
    await _tx(db, 'settled-debt', 8,
        type: TransactionSpecialType.debt, paid: false);
    final context = SyncContext(
        db: db,
        api: FireflyApi(server),
        config: const FireflyConfig(mode: true));
    await const WalletAccountSyncer().pushForBootstrap(context);
    final category = await context.api.categories.create({'name': 'Food'});
    await context.idMap.put(FireflyIdMapping(
      entityType: FireflyEntityType.category,
      localPk: 'food',
      remoteId: category.id,
      remoteSubId: '',
      remoteRole: 0,
      state: FireflySyncState.synced,
      attempts: 0,
    ));
    await const TransactionSyncer().push(context);
    final transactions = (await context.api.transactions.list()).items;
    expect(transactions.single.splits.single.internalReference, 'cashew:paid');
    for (final pk in ['unpaid', 'settled-credit', 'settled-debt']) {
      final map =
          await context.idMap.byLocal(FireflyEntityType.transaction, pk);
      expect(map?.state, FireflySyncState.localOnly);
    }
  });

  test(
      'cleans only upload markers and reports failed removal without losing mappings',
      () async {
    await createWallet(db, '0', 'usd');
    await db.into(db.tags).insert(TagsCompanion.insert(
        name: 'Paid', description: const Value('An existing description.')));
    await db.into(db.accountDetails).insert(const AccountDetailsCompanion(
          walletFk: Value('0'),
          notes: Value('Existing note with cashew-upload: text.'),
        ));
    final target = await E2eTarget.fake(() => _time, emulator: (_) => server);
    addTearDown(target.close);
    final transport = target.transport();
    addTearDown(transport.close);
    server.onRequest = (request) {
      if (request.method == 'PUT' && request.path.startsWith('/tags/')) {
        throw const FireflyValidation('Cleanup unavailable');
      }
    };
    final flow = FireflyBootstrapUpload(SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: const FireflyConfig(baseUrl: _base, pageSize: 10),
    ));
    final original = await sourceRows(db);
    final report = await flow.run(confirmed: await flow.prepare());
    expect(report.succeeded, isTrue);
    expect(report.cleanupWarnings.single.item, 'Paid');
    expect(await sourceRows(db), original);
    final raw = FireflyApi(server);
    expect((await raw.accounts.list()).items.single.notes,
        'Existing note with cashew-upload: text.');
    final rawTags = (await raw.tags.list()).items;
    expect(rawTags.single.description, contains('cashew-upload:'));

    final normal = FireflyPostUploadTransport(
        baseUrl: target.url,
        readToken: () async => target.token,
        client: target.transport().client);
    addTearDown(normal.close);
    expect((await FireflyApi(normal).tags.list()).items.single.description,
        'An existing description.');
    expect((await FireflyApi(normal).tags.get(rawTags.single.id)).description,
        'An existing description.');
    expect(await flow.context.idMap.list(FireflyEntityType.tag), hasLength(1));
  });

  test('uploads generated preview data with verified parity for every wallet',
      () async {
    await generatePreviewData();
    server.implicitCash = true;
    final target = await E2eTarget.fake(() => _time, emulator: (_) => server);
    addTearDown(target.close);
    final transport = target.transport();
    addTearDown(transport.close);
    final flow = FireflyBootstrapUpload(SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: const FireflyConfig(baseUrl: _base, pageSize: 10),
    ));
    final preview = await flow.prepare();
    expect(preview.counts[FireflyEntityType.walletAccount], 3);
    expect(preview.currencies, ['BTC', 'EUR', 'USD']);
    expect(preview.roundedTransactions, greaterThan(0));
    final source = await sourceRows(db);
    final report = await flow.run(confirmed: preview);
    expect(
        report.issues.map(
            (issue) => [issue.message, (issue as FireflyUploadIssue).item]),
        isEmpty);
    expect(report.balanceMismatches, isEmpty);
    expect(
        server.requests
            .where((request) =>
                request.method == 'GET' &&
                request.path.startsWith('/accounts/'))
            .map((request) => request.path)
            .toSet(),
        hasLength(3));
    expect(await sourceRows(db), source);
  });
}

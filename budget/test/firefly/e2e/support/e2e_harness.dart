import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;

import '../../../support/fake_firefly_server.dart';
import '../../../support/test_database.dart';
import 'firefly_emulator.dart';

/// Only used for the server identity hash; requests go to [E2eTarget.url].
const e2eConfig = FireflyConfig(
  mode: true,
  baseUrl: 'https://firefly.e2e.invalid',
  applyRules: false,
  fireWebhooks: false,
);

/// A Firefly server the suite talks to over HTTP, plus a direct admin client
/// that plays the part of another device editing the server.
class E2eTarget {
  E2eTarget._(this.url, this.token, this.live, this._close, this.emulator,
      {this.loopback});

  final Uri url;

  /// The emulator's real address; [url] is an https placeholder routed here.
  final Uri? loopback;
  final String token;
  final bool live;
  final FireflyEmulator? emulator;
  final Future<void> Function() _close;

  // A device under `flutter test integration_test` does not inherit the host
  // environment, so the values can also come in as --dart-define.
  static String? get liveUrl => _setting(
      const String.fromEnvironment('FIREFLY_E2E_URL'), 'FIREFLY_E2E_URL');
  static String? get liveToken => _setting(
      const String.fromEnvironment('FIREFLY_E2E_TOKEN'), 'FIREFLY_E2E_TOKEN');

  static String? _setting(String defined, String name) =>
      defined.isNotEmpty ? defined : Platform.environment[name];

  /// The disposable server named by FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN.
  static E2eTarget? fromEnvironment() {
    final url = liveUrl;
    final token = liveToken;
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      return null;
    }
    return E2eTarget._(Uri.parse(url), token, true, () async {}, null);
  }

  /// An emulated server on a loopback port, reached through the real transport.
  /// [emulator] and [intercept] let a later phase answer more of the API.
  static Future<E2eTarget> fake(
    DateTime Function() clock, {
    FireflyEmulator Function(DateTime Function() clock)? emulator,
    Future<bool> Function(HttpRequest request)? intercept,
  }) async {
    final fake = emulator?.call(clock) ?? FireflyEmulator(clock: clock);
    final server =
        await FakeFireflyServer.start(transport: fake, intercept: intercept);
    return E2eTarget._(
        Uri.parse(e2eConfig.baseUrl), 'REDACTED', false, server.close, fake,
        loopback: server.baseUrl);
  }

  HttpFireflyTransport transport() => HttpFireflyTransport(
        baseUrl: url,
        readToken: () async => token,
        client: loopback == null ? null : _LoopbackClient(loopback!),
      );

  Future<void> close() => _close();
}

typedef E2eWrite = ({String method, String path});

/// Wraps the app's transport so a test can take the server away and count
/// what the app writes.
class SwitchableTransport implements FireflyTransport {
  SwitchableTransport(this.inner);

  final FireflyTransport inner;
  bool offline = false;
  final writes = <E2eWrite>[];

  Future<T> _call<T>(String method, String path, Future<T> Function() send) {
    if (offline) return Future.error(const FireflyNetworkError());
    if (method != 'GET') writes.add((method: method, path: path));
    return send();
  }

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) =>
      _call('GET', path, () => inner.get(path, query: query));

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
          {FireflyQuery query = const {}}) =>
      _call('GET', path, () => inner.getPage(path, query: query));

  @override
  Future<JsonObject> post(String path, JsonObject body,
          {FireflyQuery query = const {}}) =>
      _call('POST', path, () => inner.post(path, body, query: query));

  @override
  Future<JsonObject> put(String path, JsonObject body,
          {FireflyQuery query = const {}}) =>
      _call('PUT', path, () => inner.put(path, body, query: query));

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) =>
      _call('DELETE', path, () => inner.delete(path, query: query));

  @override
  Future<void> upload(String path, Stream<List<int>> bytes, {int? length}) =>
      _call('POST', path, () => inner.upload(path, bytes, length: length));

  @override
  Future<Stream<List<int>>> download(String path) =>
      _call('GET', path, () => inner.download(path));
}

/// One device: a local database and a sync engine pointed at [target].
class E2eDevice {
  E2eDevice(this.target, this.clock)
      : db = inMemoryFinanceDatabase(),
        transport = SwitchableTransport(target.transport()) {
    admin = FireflyApi(target.transport());
    engine = SyncEngine(SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: e2eConfig,
      now: clock.now,
    ));
  }

  final E2eTarget target;
  final E2eClock clock;
  final FinanceDatabase db;
  final SwitchableTransport transport;
  late final FireflyApi admin;
  late final SyncEngine engine;

  SyncContext get context => engine.context;

  /// Runs one cycle and returns the writes it sent.
  Future<({SyncReport report, List<E2eWrite> writes})> sync() async {
    final before = transport.writes.length;
    final report = await engine.run();
    return (report: report, writes: transport.writes.sublist(before));
  }

  Future<String?> remoteId(FireflyEntityType type, String localPk) async =>
      (await context.idMap.byLocal(type, localPk))?.remoteId;

  Future<String?> localPk(FireflyEntityType type, String remoteId,
          {String subId = ''}) async =>
      (await context.idMap.byRemote(type, remoteId, subId: subId))?.localPk;

  Future<void> close() async {
    await engine.dispose();
    await db.close();
  }

  // Local edits written the way the legacy write paths leave rows behind.

  Future<String> addWallet(String name, String currency) async {
    final row =
        await db.into(db.wallets).insertReturning(WalletsCompanion.insert(
              name: name,
              order: 100,
              currency: Value(currency.toLowerCase()),
              dateCreated: Value(clock.now()),
              dateTimeModified: Value(clock.now()),
            ));
    return row.walletPk;
  }

  Future<void> renameWallet(String pk, String name) =>
      (db.update(db.wallets)..where((row) => row.walletPk.equals(pk))).write(
          WalletsCompanion(
              name: Value(name), dateTimeModified: Value(clock.now())));

  Future<String> addCategory(String name) async {
    final row =
        await db.into(db.categories).insertReturning(CategoriesCompanion.insert(
              name: name,
              order: 100,
              dateCreated: Value(clock.now()),
              dateTimeModified: Value(clock.now()),
            ));
    return row.categoryPk;
  }

  Future<void> renameCategory(String pk, String name) =>
      (db.update(db.categories)..where((row) => row.categoryPk.equals(pk)))
          .write(CategoriesCompanion(
              name: Value(name), dateTimeModified: Value(clock.now())));

  Future<void> deleteCategory(String pk) async {
    await _deleteLog(DeleteLogType.TransactionCategory, pk);
    await (db.delete(db.categories)..where((row) => row.categoryPk.equals(pk)))
        .go();
  }

  Future<String> addTransaction({
    required String name,
    required double amount,
    required String walletPk,
    required String categoryPk,
    String? pairedWith,
  }) async {
    final row = await db
        .into(db.transactions)
        .insertReturning(TransactionsCompanion.insert(
          name: name,
          amount: amount,
          note: '',
          categoryFk: categoryPk,
          walletFk: Value(walletPk),
          pairedTransactionFk: Value(pairedWith),
          dateCreated: Value(clock.now()),
          dateTimeModified: Value(clock.now()),
          income: Value(amount > 0),
          paid: const Value(true),
        ));
    return row.transactionPk;
  }

  /// Two balance-correction rows in category "0", as addWalletPage writes.
  Future<(String, String)> addTransfer(
      String fromWallet, String toWallet, double amount, String name) async {
    await db.into(db.categories).insertOnConflictUpdate(
        CategoriesCompanion.insert(
            categoryPk: const Value('0'),
            name: 'Balance correction',
            order: 0));
    final out = await addTransaction(
        name: name, amount: -amount, walletPk: fromWallet, categoryPk: '0');
    final into = await addTransaction(
        name: name,
        amount: amount,
        walletPk: toWallet,
        categoryPk: '0',
        pairedWith: out);
    await editTransaction(out, pairedWith: into);
    return (out, into);
  }

  Future<void> editTransaction(String pk,
          {String? name, double? amount, String? note, String? pairedWith}) =>
      (db.update(db.transactions)..where((row) => row.transactionPk.equals(pk)))
          .write(TransactionsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        amount: amount == null ? const Value.absent() : Value(amount),
        note: note == null ? const Value.absent() : Value(note),
        pairedTransactionFk:
            pairedWith == null ? const Value.absent() : Value(pairedWith),
        dateTimeModified: Value(clock.now()),
      ));

  Future<void> deleteTransaction(String pk) async {
    await _deleteLog(DeleteLogType.Transaction, pk);
    await (db.update(db.transactions)
          ..where((row) => row.pairedTransactionFk.equals(pk)))
        .write(const TransactionsCompanion(pairedTransactionFk: Value(null)));
    await (db.delete(db.transactions)
          ..where((row) => row.transactionPk.equals(pk)))
        .go();
  }

  Future<void> _deleteLog(DeleteLogType type, String pk) =>
      db.into(db.deleteLogs).insert(DeleteLogsCompanion.insert(
          type: type, entryPk: pk, dateTimeModified: Value(clock.now())));
}

/// The fake target uses a stepped clock so timestamps are distinct without
/// waiting. A live server stamps with its own wall clock, so there the suite
/// waits instead.
class E2eClock {
  E2eClock({required this.live})
      : _now = DateTime.now().subtract(const Duration(days: 1));

  final bool live;
  DateTime _now;

  DateTime now() => live ? DateTime.now() : _now;

  /// Makes the next local or server edit strictly newer than the last sync.
  Future<void> tick() async {
    if (live) {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    } else {
      _now = _now.add(const Duration(minutes: 1));
    }
  }
}

/// Sends https requests for the placeholder host to the loopback emulator, so
/// the fake suite needs no plain-HTTP build define.
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

/// The ids on the server before a run, so the run can delete what it created
/// and leave everything else alone. FIREFLY_E2E_KEEP=1 skips the cleanup.
class E2eServerSnapshot {
  E2eServerSnapshot._(this._transport, this._before);

  // Dependants first: deleting an account also deletes its journals.
  static const _collections = [
    '/transactions',
    '/recurrences',
    '/piggy-banks',
    '/bills',
    '/budgets',
    '/attachments',
    '/tags',
    '/categories',
    '/rules',
    '/rule-groups',
    '/accounts',
  ];

  final FireflyTransport _transport;
  final Map<String, Set<String>> _before;

  static Future<E2eServerSnapshot> take(E2eTarget target) async {
    final transport = target.transport();
    return E2eServerSnapshot._(transport, {
      for (final path in _collections) path: await _ids(transport, path),
    });
  }

  static Future<Set<String>> _ids(
      FireflyTransport transport, String path) async {
    final ids = <String>{};
    for (var page = 1;; page++) {
      final response = await transport.getPage(path, query: {
        'page': '$page',
        'limit': '100',
        if (path == '/accounts') 'type': 'all',
      });
      ids.addAll([for (final item in response.items) '${item['id']}']);
      if (page >= response.totalPages) return ids;
    }
  }

  Future<void> restore() async {
    if (Platform.environment['FIREFLY_E2E_KEEP'] == '1') return;
    for (final path in _collections) {
      final created = (await _ids(_transport, path)).difference(_before[path]!);
      for (final id in created) {
        try {
          await _transport.delete('$path/$id');
        } on FireflyNotFound {
          // Removed with something deleted before it.
        }
      }
    }
  }
}

import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/conflicts_page.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_database.dart';

class _FakeTokens extends TokenStore {
  _FakeTokens(this.token);

  final String? token;

  @override
  Future<String?> read() async => token;
}

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Firefly mode off must not open a connection');
}

Future<void> _setMode(bool on) async {
  appStateSettings['fireflyMode'] = on;
  await FireflyMode.init(() => appStateSettings,
      tokenStore: _FakeTokens(on ? 'REDACTED' : null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    database = inMemoryFinanceDatabase();
    addTearDown(database.close);
  });

  tearDown(() => _setMode(false));

  test('mode off keeps the legacy wallet delete flow', () async {
    await _setMode(false);
    await HttpOverrides.runZoned(() async {
      for (final (pk, order) in [('0', 0), ('spare', 1)]) {
        await database.into(database.wallets).insert(WalletsCompanion.insert(
            walletPk: Value(pk), name: pk, order: order));
      }
      await database.into(database.categories).insert(
          CategoriesCompanion.insert(
              categoryPk: const Value('food'), name: 'Food', order: 0));
      await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
              transactionPk: const Value('coffee'),
              name: 'Coffee',
              amount: -3,
              note: '',
              categoryFk: 'food',
              walletFk: const Value('spare')));
      await database.deleteWallet('spare', 1);
    }, createHttpClient: _NoNetwork().createHttpClient);

    expect(FireflyMode.enabled, isFalse);
    expect(await database.getWalletInstanceOrNull('spare'), isNull);
    expect(await database.tryGetTransactionFromPk('coffee'), isNull);
    final logs = await database.select(database.deleteLogs).get();
    expect(
        logs.map((log) => log.type),
        containsAll(
            [DeleteLogType.Transaction, DeleteLogType.TransactionWallet]));
    expect(await database.select(database.fireflyIdMap).get(), isEmpty);
  });

  test('mode on routes wallet deletes through one Firefly delete intent',
      () async {
    await _setMode(true);
    expect(FireflyMode.enabled, isTrue);
    for (final (pk, order) in [('0', 0), ('spare', 1)]) {
      await database.into(database.wallets).insert(
          WalletsCompanion.insert(walletPk: Value(pk), name: pk, order: order));
    }
    await database.into(database.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('food'), name: 'Food', order: 0));
    await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
            transactionPk: const Value('coffee'),
            name: 'Coffee',
            amount: -3,
            note: '',
            categoryFk: 'food',
            walletFk: const Value('spare')));

    await database.deleteWallet('spare', 1);
    await database.deleteWallet('0', 0);

    expect(await database.getWalletInstanceOrNull('spare'), isNull);
    expect(await database.getWalletInstanceOrNull('0'), isNotNull);
    expect(await database.tryGetTransactionFromPk('coffee'), isNull);
    final logs = await database.select(database.deleteLogs).get();
    // Firefly deletes the account's transactions itself.
    expect(logs.map((log) => (log.type, log.entryPk)),
        [(DeleteLogType.TransactionWallet, 'spare')]);
  });

  test('reserved category and conflict labels fall back to English', () async {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final pk = await db.ensureUncategorizedCategory();
    expect((await db.fireflyCategory(pk))!.name, 'Uncategorized');
    expect(fireflyUncategorizedName(), 'Uncategorized');
    expect(
        fireflyResolutionLabel('someFutureResolution'), 'someFutureResolution');
  });
}

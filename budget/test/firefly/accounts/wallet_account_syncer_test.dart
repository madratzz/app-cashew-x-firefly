import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/resources/currencies_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/entities/wallet_account_syncer.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _accounts = '/accounts';
const _walletType = FireflyEntityType.walletAccount;
const _syncer = WalletAccountSyncer();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FinanceDatabase db;
  late FakeFireflyTransport server;
  late SyncContext context;
  final editedAt = fixtureTime.add(const Duration(days: 1));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = {'selectedWalletPk': '0'};
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    server = FakeFireflyTransport(maxPageSize: 1);
    context = _context(db, server);
  });

  Future<String> localPk(String id) async =>
      (await context.idMap.byRemote(_walletType, id))!.localPk;

  test('pulls paginated assets and their currency, status and account details',
      () async {
    server.seed(
        _accounts,
        '20',
        _account(
          ' Main ',
          extra: {
            'currency_code': 'JPY',
            'currency_decimal_places': 0,
            'active': false,
            'current_balance': '-12500',
            'current_balance_date': '2024-01-01T04:00:00+04:00',
            'virtual_balance': '125.25',
            'include_net_worth': false,
            'notes': 'Account note',
          },
        ));
    server.seed(_accounts, '21', _account('Second', extra: {'order': 2}));
    server.seed(
        _accounts, '22', _account('Merchant', extra: {'type': 'expense'}));

    await _syncer.pull(context);
    final main = (await db.fireflyWallet(await localPk('20')))!;
    final second = (await db.fireflyWallet(await localPk('21')))!;
    expect(main.name, 'Main');
    expect(main.currency, 'jpy');
    expect(main.decimals, 0);
    expect(main.archived, isTrue);
    expect(main.dateCreated, fixtureTime.toLocal());
    expect(main.order, 0);
    expect(second.currency, 'usd');
    expect(second.decimals, 2);
    expect(second.order, 1);
    expect(await context.idMap.byRemote(_walletType, '22'), isNull);
    expect(server.requests.map((r) => r.query['page']), ['1', '2']);
    expect(server.requests.every((r) => r.query['type'] == 'asset'), isTrue);
    final details = (await db.fireflyAccountDetails(main.walletPk))!;
    expect(details.accountRole, 'defaultAsset');
    expect(details.serverBalance, -12500);
    expect(details.serverBalanceDate, fixtureTime.toLocal());
    expect(details.virtualBalance, 125.25);
    expect(details.includeNetWorth, isFalse);
    expect(details.notes, 'Account note');

    server.seed(
        _accounts,
        '20',
        _account('Main', extra: {
          'currency_code': 'JPY',
          'active': false,
          'current_balance': '-12501',
        }));
    await _syncer.pull(context);
    expect(
        (await db.fireflyAccountDetails(main.walletPk))?.serverBalance, -12501);
  });

  test('links the same primary to wallet zero on two devices', () async {
    server.seed(_accounts, '21',
        _account('Savings', extra: {'account_role': 'savingAsset'}));
    server.seed(_accounts, '23', _account('Secondary', extra: {'order': 3}));
    server.seed(_accounts, '20', _account('Primary', extra: {'order': 2}));
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Savings', order: 0));

    await _syncer.pull(context);
    expect(await localPk('20'), '0');
    expect((await db.fireflyWallet('0'))?.name, 'Primary');
    expect(await localPk('21'), isNot('0'));

    await db.close();
    final second = inMemoryFinanceDatabase();
    addTearDown(second.close);
    final secondContext = _context(second, server);
    await _syncer.pull(secondContext);
    expect(
        (await secondContext.idMap.byRemote(_walletType, '20'))?.localPk, '0');
    expect((await second.fireflyWallet('0'))?.name, 'Primary');
  });

  test('links by asset name and preserves local-only fields on pull', () async {
    server.seed(_accounts, '20', _account('Main'));
    server.seed(_accounts, '21', _account(' savings ', extra: {'order': 2}));
    const widgets = [HomePageWidgetDisplay.PieChart];
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('savings'),
        name: 'Savings',
        order: 4,
        colour: const Value('FF00FF'),
        iconName: const Value('bank'),
        currencyFormat: const Value('prefix'),
        homePageWidgetDisplay: const Value(widgets)));
    await _syncer.pull(context);
    expect(await localPk('21'), 'savings');

    server.seed(
        _accounts,
        '21',
        _account('Emergency savings', extra: {
          'order': 2,
          'updated_at': editedAt.toIso8601String(),
        }));
    await _syncer.pull(context);
    final wallet = (await db.fireflyWallet('savings'))!;
    expect(wallet.name, 'Emergency savings');
    expect(wallet.colour, 'FF00FF');
    expect(wallet.iconName, 'bank');
    expect(wallet.currencyFormat, 'prefix');
    expect(wallet.homePageWidgetDisplay, widgets);
    await _syncer.push(context);
    expect(server.requests.every((r) => r.method == 'GET'), isTrue);
  });

  test('enables currency and pushes local create, rename, reorder and delete',
      () async {
    server.seed(_accounts, '20', _account('Main'));
    await _syncer.pull(context);
    final local = await db.into(db.wallets).insertReturning(
          WalletsCompanion.insert(
            name: 'New account',
            order: 1,
            currency: const Value('jpy'),
            currencyFormat: const Value('local-only'),
            iconName: const Value('bank'),
            decimals: const Value(0),
            dateTimeModified: Value(editedAt),
          ),
        );

    await _syncer.push(context);
    final writes = server.requests.where((r) => r.method == 'POST').toList();
    expect(writes.map((r) => r.path), ['/currencies/JPY/enable', _accounts]);
    expect(writes.last.body, {
      'name': 'New account',
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'JPY',
      'active': true,
      'order': 2,
    });
    final mapping = (await context.idMap.byLocal(_walletType, local.walletPk))!;
    await _syncer.pull(context);

    await db.createOrUpdateWallet(local.copyWith(name: 'Renamed'),
        customDateTimeModified: editedAt.add(const Duration(seconds: 1)));
    await db.moveWallet(local.walletPk, 0, 1);
    await _syncer.push(context);

    final id = mapping.remoteId;
    final changed = await context.api.accounts.get(id);
    expect(changed.name, 'Renamed');
    expect(changed.order, 1);
    expect((await context.api.accounts.get('20')).order, 2);
    expect(
        server.requests.any((r) =>
            r.method == 'PUT' &&
            r.path == '$_accounts/$id' &&
            r.body?['name'] == 'Renamed'),
        isTrue);
    appStateSettings['selectedWalletPk'] = local.walletPk;
    await db.deleteWalletLocally(local.walletPk);
    expect(await db.fireflyWallet(local.walletPk), isNull);
    expect(await db.fireflyAccountDetails(local.walletPk), isNull);
    expect(appStateSettings['selectedWalletPk'], '0');
    final logs = await db.select(db.deleteLogs).get();
    expect(logs.single.type, DeleteLogType.TransactionWallet);
    expect(logs.single.entryPk, local.walletPk);

    await DirtyTracker(context.idMap).collectDeletes(logs);
    await _syncer.pull(context);
    await _syncer.pushDeletes(context);
    expect(await context.idMap.byLocal(_walletType, local.walletPk), isNull);
    await expectLater(
        context.api.accounts.get(id), throwsA(isA<FireflyNotFound>()));
    expect(server.requests.where((r) => r.method == 'DELETE').single.path,
        '$_accounts/$id');
  });

  test('removes a remotely deleted wallet and its transactions without a log',
      () async {
    server.seed(_accounts, '20', _account('Main'));
    server.seed(_accounts, '21', _account('Second', extra: {'order': 2}));
    await _syncer.pull(context);
    final removed = await localPk('21');
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Transfer', order: 0));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionPk: const Value('out'),
        categoryFk: '0',
        walletFk: Value(removed),
        name: 'Transfer',
        amount: -50,
        note: ''));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionPk: const Value('in'),
        pairedTransactionFk: const Value('out'),
        categoryFk: '0',
        name: 'Transfer',
        amount: 50,
        note: ''));
    appStateSettings['selectedWalletPk'] = removed;

    server.removeSeed(_accounts, '21');
    await _syncer.pull(context);

    expect(await db.fireflyWallet(removed), isNull);
    expect(await db.fireflyAccountDetails(removed), isNull);
    expect(await context.idMap.byRemote(_walletType, '21'), isNull);
    final transactions = await db.select(db.transactions).get();
    expect(transactions.single.transactionPk, 'in');
    expect(transactions.single.pairedTransactionFk, isNull);
    expect(await db.select(db.deleteLogs).get(), isEmpty);
    expect(appStateSettings['selectedWalletPk'], '0');
    expect(jsonDecode(sharedPreferences.getString('userSettings')!),
        containsPair('selectedWalletPk', '0'));
  });

  test('uses an unmapped placeholder after deletion of the last asset',
      () async {
    server.seed(_accounts, '20', _account('Main'));
    await _syncer.pull(context);
    server.removeSeed(_accounts, '20');

    await _syncer.pull(context);
    final placeholder = (await db.fireflyAssetWallets()).single;
    expect(placeholder.walletPk, '0');
    expect(placeholder.name, isNot('Main'));
    expect(appStateSettings['selectedWalletPk'], placeholder.walletPk);
    expect(await context.idMap.list(_walletType), isEmpty);
    expect(await db.fireflyAccountDetails(placeholder.walletPk), isNull);
    await _syncer.push(context);
    expect(server.requests.every((request) => request.method == 'GET'), isTrue);

    server.seed(_accounts, '21', _account('New primary'));
    await _syncer.pull(context);
    expect(await localPk('21'), placeholder.walletPk);
    expect((await db.fireflyAssetWallets()).single.name, 'New primary');
  });

  test('detects remote reorder when the server timestamp does not advance',
      () async {
    server.seed(_accounts, '20', _account('Main'));
    server.seed(_accounts, '21', _account('Second', extra: {'order': 2}));
    await _syncer.pull(context);
    final firstPk = await localPk('20');
    final secondPk = await localPk('21');
    server.seed(_accounts, '20', _account('Main', extra: {'order': 2}));
    server.seed(_accounts, '21', _account('Second'));

    await _syncer.pull(context);
    expect((await db.fireflyWallet(firstPk))?.order, 1);
    expect((await db.fireflyWallet(secondPk))?.order, 0);
    expect(firstPk, '0');
  });

  test('records a serializable wallet snapshot when a dirty wallet loses',
      () async {
    server.seed(_accounts, '20', _account('Main'));
    await _syncer.pull(context);
    final wallet = (await db.fireflyWallet('0'))!;
    await db.createOrUpdateWallet(wallet.copyWith(name: 'Local rename'),
        customDateTimeModified: editedAt);
    server.seed(_accounts, '20', _account('Remote rename'));

    await _syncer.pull(context);

    final conflict = (await context.conflicts.list()).single;
    expect(
        jsonDecode(conflict.localJson), containsPair('name', 'Local rename'));
    expect((await db.fireflyWallet('0'))?.name, 'Remote rename');
  });
}

JsonObject _account(String name, {JsonObject extra = const {}}) => {
      'name': name,
      'type': 'asset',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
      'currency_decimal_places': 2,
      'order': 1,
      'active': true,
      'created_at': fixtureTime.toIso8601String(),
      'updated_at': fixtureTime.toIso8601String(),
      ...extra,
    };

SyncContext _context(FinanceDatabase db, FakeFireflyTransport server) =>
    SyncContext(
        db: db, api: _TestApi(server), config: const FireflyConfig(mode: true));

// WP-03 fills the shared currency client independently of this package.
class _TestApi extends FireflyApi {
  _TestApi(super.transport);

  late final _currencies = _TestCurrencies(transport);

  @override
  CurrenciesApi get currencies => _currencies;
}

class _TestCurrencies extends CurrenciesApi {
  const _TestCurrencies(super.transport);

  @override
  Future<void> enable(String code) async {
    try {
      await super.enable(code);
    } on FireflyTransportUnavailable {
      await transport.post('/currencies/$code/enable', const {});
    }
  }
}

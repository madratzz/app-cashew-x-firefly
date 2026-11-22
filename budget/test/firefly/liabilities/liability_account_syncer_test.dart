import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/entities/liability_account_syncer.dart';
import 'package:budget/firefly/sync/entities/wallet_account_syncer.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _liabilities = LiabilityAccountSyncer();
const _assets = WalletAccountSyncer();
const _accounts = '/accounts';

void main() {
  late FinanceDatabase db;
  late _AccountTransport server;
  late SyncContext context;

  setUp(() async {
    appStateSettings = {'selectedWalletPk': '0'};
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Checking', order: 0));
    server = _AccountTransport();
    context = SyncContext(
      db: db,
      api: FireflyApi(server),
      config: const FireflyConfig(mode: true),
      now: () => fixtureTime,
    );
  });

  for (final subtype in ['loan', 'debt', 'mortgage']) {
    test('imports and edits a paginated $subtype from Firefly', () async {
      server.seed(_accounts, '10', _liability('Other liability', 'debt'));
      server.seed(
          _accounts,
          '11',
          _liability(' Balance ', subtype, {
            'order': 2,
            'active': false,
            'currency_code': 'JPY',
            'currency_decimal_places': 0,
            'account_number': '00100',
            'virtual_balance': '-20',
            'notes': 'First\nSecond',
            'current_balance': '-125',
            'current_balance_date': fixtureTime.toIso8601String(),
          }));
      server.seed(_accounts, '12', _asset());

      await _liabilities.pull(context);
      final all = await db.fireflyLiabilities();
      expect(all.map((wallet) => wallet.name), ['Other liability', 'Balance']);
      final wallet = all.last;
      expect(wallet.accountKind, AccountKind.liability);
      expect(wallet.walletPk, isNot('0'));
      expect(wallet.currency, 'jpy');
      expect(wallet.archived, isTrue);
      expect(wallet.decimals, 0);
      expect(wallet.order, 1);
      final details = (await db.fireflyAccountDetails(wallet.walletPk))!;
      expect(details.liabilityType, subtype);
      expect(details.liabilityDirection, 'debit');
      expect(details.interest, 8.125);
      expect(details.interestPeriod, 'yearly');
      expect(details.accountNumber, '00100');
      expect(details.virtualBalance, -20);
      expect(details.notes, 'First\nSecond');
      expect(details.serverBalance, -125);
      expect(details.serverBalanceDate, fixtureTime.toLocal());
      expect(details.includeNetWorth, isFalse);
      expect(
        await db.watchFireflyNetWorthWalletPks().first,
        contains('0'),
      );
      await expectLater(db.watchFireflyNetWorthWalletPks().first,
          completion(isNot(contains(wallet.walletPk))));
      expect(
          server.requests.map((request) => request.query['page']), ['1', '2']);

      await db.saveFireflyAccountDetails(
        wallet.walletPk,
        const AccountDetailsCompanion(
          includeNetWorth: Value(true),
          notes: Value(null),
          interest: Value(8.375),
          virtualBalance: Value(-21),
        ),
        modifiedAt: fixtureTime,
      );
      server.seed(
          _accounts,
          '11',
          _liability(' Balance ', subtype, {
            'order': 2,
            'active': false,
            'currency_code': 'JPY',
            'currency_decimal_places': 0,
            'account_number': '00100',
            'virtual_balance': '-20',
            'notes': 'First\nSecond',
            'current_balance': '-93',
            'current_balance_date':
                fixtureTime.add(const Duration(days: 1)).toIso8601String(),
          }));
      await _liabilities.pull(context);
      final edited = (await db.fireflyAccountDetails(wallet.walletPk))!;
      expect(edited.interest, 8.375);
      expect(edited.serverBalance, -93);
      expect(edited.includeNetWorth, isTrue);
      expect(await db.watchFireflyNetWorthWalletPks().first,
          contains(wallet.walletPk));
      await _liabilities.push(context);
      final update = server.requests.singleWhere((r) => r.method == 'PUT');
      expect(update.path, '/accounts/11');
      expect(update.body, {
        'interest': '8.375',
        'virtual_balance': '-21',
        'notes': '',
        'include_net_worth': true,
      });
      await _liabilities.pull(context);
      await _liabilities.push(context);
      expect(server.requests.where((r) => r.method == 'PUT'), hasLength(1));
    });

    test('creates a local $subtype and applies remote edits and deletion',
        () async {
      final wallet = await db.saveFireflyLiability(
        name: ' New $subtype ',
        currency: 'usd',
        decimals: 2,
        order: 0,
        details: AccountDetailsCompanion(
          liabilityType: Value(subtype),
          liabilityDirection: const Value('credit'),
          interest: const Value(2.25),
          interestPeriod: const Value('monthly'),
          includeNetWorth: const Value(false),
          bic: const Value('TESTGB00'),
        ),
        modifiedAt: fixtureTime,
      );
      await _liabilities.pull(context);
      await _liabilities.push(context);
      final writes = server.requests.where((r) => r.method == 'POST').toList();
      expect(writes.map((r) => r.path), ['/currencies/USD/enable', _accounts]);
      expect(writes.last.body, {
        'name': 'New $subtype',
        'type': 'liability',
        'order': 1,
        'currency_code': 'USD',
        'active': true,
        'liability_type': subtype,
        'liability_direction': 'credit',
        'interest': '2.25',
        'interest_period': 'monthly',
        'include_net_worth': false,
        'bic': 'TESTGB00',
      });
      final map =
          (await context.idMap.byLocal(_liabilities.type, wallet.walletPk))!;
      server.seed(
          _accounts,
          map.remoteId,
          _liability('Edited', subtype, {
            'active': false,
            'liability_direction': 'credit',
            'interest': '9.75',
            'interest_period': 'daily',
            'updated_at':
                fixtureTime.add(const Duration(minutes: 1)).toIso8601String(),
          }));
      await _liabilities.pull(context);
      expect((await db.fireflyWallet(wallet.walletPk))?.name, 'Edited');
      final details = (await db.fireflyAccountDetails(wallet.walletPk))!;
      expect(details.interest, 9.75);
      expect(details.interestPeriod, 'daily');
      expect(details.bic, isNull);
      expect(await db.watchFireflyLiabilities().first, hasLength(1));

      server.removeSeed(_accounts, map.remoteId);
      await _liabilities.pull(context);
      expect(await db.fireflyWallet(wallet.walletPk), isNull);
      expect(await db.fireflyAccountDetails(wallet.walletPk), isNull);
      expect(await context.idMap.byLocal(_liabilities.type, wallet.walletPk),
          isNull);
    });
  }

  test('rejects an initial virtual balance without saving a partial liability',
      () async {
    await expectLater(
      db.saveFireflyLiability(
        name: 'House',
        currency: 'usd',
        decimals: 2,
        order: 0,
        details: const AccountDetailsCompanion(virtualBalance: Value(-25)),
      ),
      throwsArgumentError,
    );
    expect(await db.fireflyLiabilities(), isEmpty);
    expect(await db.select(db.accountDetails).get(), isEmpty);
  });

  test('links an unmapped liability by name and pushes a local delete',
      () async {
    final wallet = await db.saveFireflyLiability(
        name: 'House', currency: 'usd', decimals: 2, order: 0);
    server.seed(_accounts, '11', _liability('house', 'mortgage'));

    await _liabilities.pull(context);
    expect((await context.idMap.byRemote(_liabilities.type, '11'))?.localPk,
        wallet.walletPk);
    await db.deleteWalletLocally(wallet.walletPk);
    await DirtyTracker(context.idMap)
        .collectDeletes(await db.select(db.deleteLogs).get());
    await _liabilities.pushDeletes(context);
    expect(server.requests.last.method, 'DELETE');
    expect(server.requests.last.path, '/accounts/11');
    expect(await context.idMap.byLocal(_liabilities.type, wallet.walletPk),
        isNull);
  });

  test('migrates a legacy asset hash and pushes a details-only edit', () async {
    server.seed(_accounts, '20', _asset({'current_balance': '10'}));
    await _assets.pull(context);
    final mapping = (await context.idMap.byLocal(_assets.type, '0'))!;
    await context.idMap.put(mapping.copyWith(
      syncedHash: Value(syncedFieldsHash({
        'name': 'Checking',
        'currency_code': 'USD',
        'order': 0,
        'active': true,
      })),
    ));

    await db.saveFireflyAccountDetails(
      '0',
      const AccountDetailsCompanion(
        accountRole: Value('savingAsset'),
        notes: Value('Local note'),
        iban: Value('GB82 WEST 1234 5698 7654 32'),
        bic: Value('TESTGB00'),
        accountNumber: Value('00001'),
        includeNetWorth: Value(false),
        virtualBalance: Value(-12.25),
        serverBalance: Value(999),
      ),
      modifiedAt: fixtureTime,
    );
    server.seed(_accounts, '20', _asset({'current_balance': '12'}));
    await _assets.pull(context);

    final details = (await db.fireflyAccountDetails('0'))!;
    expect(details.notes, 'Local note');
    expect(details.serverBalance, 12);
    expect(await context.conflicts.list(), isEmpty);
    await _assets.push(context);
    expect(server.requests.singleWhere((r) => r.method == 'PUT').body, {
      'account_role': 'savingAsset',
      'notes': 'Local note',
      'iban': 'GB82WEST12345698765432',
      'bic': 'TESTGB00',
      'account_number': '00001',
      'include_net_worth': false,
      'virtual_balance': '-12.25',
    });
    await _assets.pull(context);
    await _assets.push(context);
    expect(server.requests.where((r) => r.method == 'PUT'), hasLength(1));
    expect(await db.watchFireflyNetWorthWalletPks().first, isEmpty);
  });

  test('applies a same-second server detail edit and snapshots the local edit',
      () async {
    server.seed(_accounts, '20', _asset());
    await _assets.pull(context);
    await db.saveFireflyAccountDetails(
      '0',
      const AccountDetailsCompanion(notes: Value('Changed locally')),
      modifiedAt: fixtureTime,
    );
    server.seed(_accounts, '20', _asset({'notes': 'Changed remotely'}));
    await _assets.pull(context);
    await _assets.push(context);

    expect((await db.fireflyAccountDetails('0'))!.notes, 'Changed remotely');
    final conflict = (await context.conflicts.list()).single;
    final local = jsonDecode(conflict.localJson) as Map<String, dynamic>;
    expect(local['accountDetails']['notes'], 'Changed locally');
    expect(server.requests.every((r) => r.method == 'GET'), isTrue);
  });

  test('mode off leaves local liabilities and the server untouched', () async {
    final wallet = await db.saveFireflyLiability(
        name: 'Local', currency: 'usd', decimals: 2, order: 0);
    final disabled = SyncContext(
        db: db, api: FireflyApi(server), config: const FireflyConfig());

    await _liabilities.pull(disabled);
    await _liabilities.push(disabled);
    await _liabilities.pushDeletes(disabled);
    expect(await db.fireflyWallet(wallet.walletPk), wallet);
    expect(server.requests, isEmpty);
  });
}

JsonObject _asset([JsonObject extra = const {}]) => {
      'type': 'asset',
      'name': 'Checking',
      'account_role': 'defaultAsset',
      'currency_code': 'USD',
      'updated_at': fixtureTime.toIso8601String(),
      ...extra,
    };

JsonObject _liability(String name, String subtype,
        [JsonObject extra = const {}]) =>
    {
      // FakeFireflyTransport filters stored records by their type verbatim.
      'type': 'liability',
      'name': name,
      'liability_type': subtype,
      'liability_direction': 'debit',
      'currency_code': 'USD',
      'interest': '8.125',
      'interest_period': 'yearly',
      'include_net_worth': false,
      'updated_at': fixtureTime.toIso8601String(),
      ...extra,
    };

/// Keeps the shared fake's filtering and emits Firefly 6.6.2 read envelopes.
class _AccountTransport extends FakeFireflyTransport {
  _AccountTransport() : super(maxPageSize: 1);

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    final page = await super.getPage(path, query: query);
    return path == _accounts ? page.map(_readShape) : page;
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final result = await super.post(path, body, query: query);
    return path == _accounts ? _readShape(result) : result;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final result = await super.put(path, body, query: query);
    return path.startsWith('$_accounts/') ? _readShape(result) : result;
  }

  JsonObject _readShape(JsonObject resource) {
    final attributes = resource['attributes'] as JsonObject;
    if (attributes['type'] != 'liability') return resource;
    return {
      ...resource,
      'attributes': {...attributes, 'type': 'liabilities'},
    };
  }
}

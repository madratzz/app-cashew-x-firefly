import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/foreign_currency_contributor.dart';
import 'package:budget/firefly/sync/entities/currency_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/firefly_emulator.dart';

const _currencies = CurrencySyncer();
const _transactions = TransactionSyncer();
const _custom = 'XWPQA';
const _transactionPath = '/transactions';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FinanceDatabase db;
  late DateTime now;
  late _CurrencyServer transport;

  SyncContext context({bool active = true}) => SyncContext(
        db: db,
        api: FireflyApi(transport),
        config: FireflyConfig(
          mode: active,
          pageSize: 2,
          applyRules: false,
          fireWebhooks: false,
        ),
        pullMode: SyncPullMode.initial,
        now: () => now,
      );

  Future<void> setUpLocalMappings() async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('wallet'),
          name: 'Wallet',
          order: 0,
          currency: const Value('usd'),
          decimals: const Value(2),
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value('food'),
          name: 'Food',
          order: 0,
        ));
    await context().idMap.put(fixtureMapping(
          type: FireflyEntityType.walletAccount,
          localPk: 'wallet',
          remoteId: '11',
        ));
    await context().idMap.put(fixtureMapping(localPk: 'food', remoteId: '21'));
  }

  Future<void> editForeign(String pk, double? amount, String? currency) async {
    now = now.add(const Duration(seconds: 1));
    await (db.update(db.transactions)
          ..where((row) => row.transactionPk.equals(pk)))
        .write(TransactionsCompanion(
      foreignAmount: Value(amount),
      foreignCurrency: Value(currency),
      dateTimeModified: Value(now),
    ));
  }

  setUp(() {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    now = fixtureTime;
    transport = _CurrencyServer(clock: () => now);
  });

  test('caches the full list, registers custom codes and refreshes actions',
      () async {
    final sync = context();
    await _currencies.pull(sync);

    final custom = (await db.watchFireflyCustomCurrencies().first).single;
    expect(custom.code, _custom.toLowerCase());
    expect(custom.id, '3');
    expect(custom.name, 'Test currency');
    expect(custom.symbol, '¤');
    expect(custom.decimalPlaces, 3);
    expect(custom.enabled, isFalse);
    expect(
        (await db.fireflyCurrency('  XwPqA  '))?.resourcePk, 'currency:xwpqa');
    expect((await db.fireflyPrimaryCurrency())?.code, 'usd');
    expect(
      (await db.watchFireflyCurrencies().first).map((row) => row.code),
      ['eur', 'usd', 'xwpqa'],
    );

    await _currencies.setEnabled(sync, _custom, enabled: true);
    expect(
        (await db.watchFireflyCustomCurrencies().first).single.enabled, isTrue);
    await _currencies.setEnabled(sync, _custom, enabled: false);
    expect((await db.watchFireflyCustomCurrencies().first).single.enabled,
        isFalse);
    await _currencies.setPrimary(sync, _custom.toLowerCase());
    expect((await db.fireflyPrimaryCurrency())?.code, 'xwpqa');
    expect((await db.fireflyPrimaryCurrency())?.enabled, isTrue);
    expect((await db.fireflyCurrencies()).where((row) => row.primary == true),
        hasLength(1));

    await expectLater(
      _currencies.setEnabled(sync, _custom, enabled: false),
      throwsA(isA<FireflyUnexpectedResponse>()
          .having((error) => error.statusCode, 'statusCode', 409)),
    );
    expect((await db.fireflyPrimaryCurrency())?.code, 'xwpqa');

    await _currencies.setPrimary(sync, 'USD');
    transport.removeSeed('/currencies', '3');
    await _currencies.pull(sync);
    expect(await db.fireflyCurrency(_custom), isNull);
    expect(await db.watchFireflyCustomCurrencies().first, isEmpty);
  });

  test('leaves the last complete cache intact when a page fails', () async {
    await _currencies.pull(context());
    transport.removeSeed('/currencies', '2');
    transport.seed('/currencies', '4', {'code': 'GBP', 'enabled': true});
    transport.onRequest = (request) {
      if (request.path == '/currencies' && request.query['page'] == '2') {
        throw const FireflyNetworkError();
      }
    };
    await expectLater(
        _currencies.pull(context()), throwsA(isA<FireflyNetworkError>()));
    expect(await db.fireflyCurrency('eur'), isNotNull);
    expect((await db.fireflyPrimaryCurrency())?.code, 'usd');
  });

  test('mode off makes no currency requests', () async {
    final sync = context(active: false);
    await _currencies.pull(sync);
    await _currencies.setEnabled(sync, _custom, enabled: true);
    await _currencies.setPrimary(sync, _custom);
    expect(transport.requests, isEmpty);
    expect(await db.fireflyCurrencies(), isEmpty);
  });

  test('withdrawal foreign amount round trips and clears in either direction',
      () async {
    final sync = context();
    await setUpLocalMappings();
    await _currencies.pull(sync);
    transport.seed(_transactionPath, '31', {
      'updated_at': now.toIso8601String(),
      'transactions': [
        _withdrawal('41',
            {'foreign_currency_code': _custom, 'foreign_amount': '12.345'}),
      ],
    });
    await _transactions.pull(sync);

    final mapping = (await sync.idMap
        .byRemote(FireflyEntityType.transaction, '31', subId: '41'))!;
    final pk = mapping.localPk;
    Future<(double?, String?)> readLocal() async {
      final row = (await db.fireflyTransaction(pk))!;
      expect(row.amount, -10);
      return (row.foreignAmount, row.foreignCurrency);
    }

    expect(await readLocal(), (12.345, 'xwpqa'));
    final row = (await db.fireflyTransaction(pk))!;
    final projected = await const ForeignCurrencyContributor().projectRemote(
      sync,
      const FireflyTransaction(id: '31'),
      FireflyTransactionSplit(_withdrawal('41')),
      row,
    );
    expect((projected.foreignAmount, projected.foreignCurrency), (null, null));
    expect(await readLocal(), (12.345, 'xwpqa'));

    await editForeign(pk, 13.125, 'xwpqa');
    await _transactions.push(sync);
    final written = (await sync.api.transactions.get('31')).splits.single;
    expect((written.foreignAmount, written.foreignCurrencyCode),
        (13.125, _custom));
    expect(written.fields['foreign_amount'], '13.125');
    await _transactions.rereadPushed(sync);
    expect(await readLocal(), (13.125, 'xwpqa'));

    now = now.add(const Duration(seconds: 1));
    transport.seed(_transactionPath, '31', {
      'updated_at': now.toIso8601String(),
      'transactions': [_withdrawal('41')],
    });
    await _transactions.pull(sync);
    expect(await readLocal(), (null, null));

    await editForeign(pk, 16.25, 'xwpqa');
    await _transactions.push(sync);
    await _transactions.rereadPushed(sync);
    await editForeign(pk, null, null);
    transport.requests.clear();
    await _transactions.push(sync);
    final update = transport.requests.singleWhere((request) =>
        request.method == 'PUT' && request.path == '/transactions/31');
    expect(
        FireflyEmulator.splitsOf(update.body!).single['foreign_amount'], '0');
    final cleared = (await sync.api.transactions.get('31')).splits.single;
    expect((cleared.foreignAmount, cleared.foreignCurrencyCode), (null, null));
    await _transactions.rereadPushed(sync);
    expect(await readLocal(), (null, null));

    transport.requests.clear();
    await _transactions.pull(sync);
    await _transactions.push(sync);
    expect(
        transport.requests.every((request) => request.method == 'GET'), isTrue);
  });

  test('new withdrawal sends its foreign amount on create', () async {
    final sync = context();
    await setUpLocalMappings();
    await _currencies.pull(sync);
    final row = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            name: 'New withdrawal',
            note: '',
            amount: -8,
            categoryFk: 'food',
            walletFk: const Value('wallet'),
            dateCreated: Value(now),
            dateTimeModified: Value(now),
            foreignCurrency: const Value('xwpqa'),
            foreignAmount: const Value(73.125),
          ),
        );

    await _transactions.push(sync);
    final mapping = (await sync.idMap
        .byLocal(FireflyEntityType.transaction, row.transactionPk))!;
    final split =
        (await sync.api.transactions.get(mapping.remoteId)).splits.single;
    expect((split.foreignAmount, split.foreignCurrencyCode), (73.125, _custom));
    await _transactions.rereadPushed(sync);
    expect((await db.fireflyTransaction(row.transactionPk))?.foreignAmount,
        73.125);
  });
}

JsonObject _withdrawal(String journal, [JsonObject foreign = const {}]) => {
      'transaction_journal_id': journal,
      'type': 'withdrawal',
      'date': fixtureTime.toIso8601String(),
      'amount': '10.00',
      'currency_code': 'USD',
      'category_id': '21',
      'source_id': '11',
      'destination_id': '12',
      'description': 'Lunch',
      ...foreign,
    };

class _CurrencyServer extends FireflyEmulator {
  _CurrencyServer({required super.clock}) {
    removeSeed('/currencies', 'primary');
    removeSeed('/currencies', 'USD');
    removeSeed('/currencies', 'EUR');
    for (final entry in currencies.entries) {
      seed('/currencies', entry.key, entry.value);
    }
  }

  final currencies = <String, JsonObject>{
    '1': {
      'code': 'USD',
      'name': 'Dollar',
      'decimal_places': 2,
      'enabled': true
    },
    '2': {'code': 'EUR', 'name': 'Euro', 'decimal_places': 2, 'enabled': true},
    '3': {
      'code': _custom,
      'name': 'Test currency',
      'symbol': '¤',
      'decimal_places': 3,
      'enabled': false,
      'primary': true,
    },
  };
  String primaryId = '1';

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    if (path == '/currencies/primary') {
      requests.add((method: 'GET', path: path, query: query, body: null));
      return fireflyResource('currencies', primaryId,
          {...currencies[primaryId]!, 'primary': true});
    }
    return super.get(path, query: query);
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final match = RegExp(r'^/currencies/([^/]+)/(enable|disable|primary)$')
        .firstMatch(path);
    if (match == null) return super.post(path, body, query: query);
    final entry = currencies.entries
        .singleWhere((entry) => entry.value['code'] == match[1]);
    requests.add((method: 'POST', path: path, query: query, body: body));
    if (match[2] == 'disable' && entry.key == primaryId) {
      throw const FireflyUnexpectedResponse(409);
    }
    if (match[2] == 'primary') primaryId = entry.key;
    entry.value['enabled'] = match[2] != 'disable';
    seed('/currencies', entry.key, entry.value);
    return const {};
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final result = await super.put(path, body, query: query);
    if (!path.startsWith('$_transactionPath/')) return result;
    final attributes = result['attributes']! as JsonObject;
    final splits = FireflyEmulator.splitsOf(attributes).map(Map.of).toList();
    for (final split in splits) {
      if (split['foreign_amount'] == '0') {
        split.remove('foreign_amount');
        split.remove('foreign_currency_code');
      }
    }
    final updated = {...attributes, 'transactions': splits};
    seed(_transactionPath, result['id']! as String, updated);
    return {...result, 'attributes': updated};
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/category_syncer.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/struct/databaseGlobal.dart' as globals;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _path = '/categories';
const _type = FireflyEntityType.category;
const _syncer = CategorySyncer();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceDatabase db;
  late FakeFireflyTransport transport;
  late FireflyApi api;

  SyncContext context({String separator = ' / ', bool mode = true}) =>
      SyncContext(
        db: db,
        api: api,
        config: FireflyConfig(mode: mode, subcategorySeparator: separator),
        now: () => fixtureTime,
      );

  Future<void> sync({String separator = ' / ', bool mode = true}) async {
    final cycle = context(separator: separator, mode: mode);
    await DirtyTracker(cycle.idMap)
        .collectDeletes(await db.select(db.deleteLogs).get());
    await _syncer.pull(cycle);
    await _syncer.push(cycle);
    await _syncer.pushDeletes(cycle);
  }

  Future<TransactionCategory> localByRemote(String id) async {
    final mapping = await context().idMap.byRemote(_type, id);
    return (await db.fireflyCategory(mapping!.localPk))!;
  }

  Future<void> addCategory(
    String pk,
    String name, {
    String? parent,
    DateTime? modifiedAt,
  }) =>
      db.into(db.categories).insert(CategoriesCompanion.insert(
            categoryPk: Value(pk),
            name: name,
            mainCategoryPk: Value(parent),
            order: 12,
            dateTimeModified: Value(modifiedAt ?? fixtureTime),
          ));

  Future<void> renameLocal(String pk, String name, {DateTime? at}) =>
      (db.update(db.categories)..where((row) => row.categoryPk.equals(pk)))
          .write(CategoriesCompanion(
        name: Value(name),
        dateTimeModified: Value(at ?? fixtureTime.add(const Duration(days: 1))),
      ));

  Future<Transaction> addTransaction(String main, {String? sub}) async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Wallet', order: 0));
    return db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            name: 'Sample',
            amount: -12,
            note: '',
            categoryFk: main,
            subCategoryFk: Value(sub),
          ),
        );
  }

  setUp(() async {
    db = inMemoryFinanceDatabase();
    globals.database = db;
    SharedPreferences.setMockInitialValues({});
    globals.sharedPreferences = await SharedPreferences.getInstance();
    addTearDown(db.close);
    transport = FakeFireflyTransport(maxPageSize: 1);
    api = FireflyApi(transport);
  });

  test('remote create, rename and delete preserve Cashew-only attributes',
      () async {
    final remote = await api.categories.create({
      'name': '  Groceries  ',
      'notes': 'Stored on Firefly',
    });
    await sync();
    final initial = await localByRemote(remote.id);
    expect(initial.name, 'Groceries');
    expect(initial.iconName, 'groceries.png');

    await (db.update(db.categories)
          ..where((row) => row.categoryPk.equals(initial.categoryPk)))
        .write(const CategoriesCompanion(
      colour: Value('FFABCDEF'),
      iconName: Value('heart.png'),
      emojiIconName: Value('🥕'),
      order: Value(42),
      income: Value(true),
      methodAdded: Value(MethodAdded.csv),
    ));
    await api.categories.update(remote.id, {'name': 'Market'});
    transport.requests.clear();
    await sync();
    final renamed = await localByRemote(remote.id);
    expect(renamed.categoryPk, initial.categoryPk);
    expect(renamed.name, 'Market');
    expect(renamed.colour, 'FFABCDEF');
    expect(renamed.iconName, 'heart.png');
    expect(renamed.emojiIconName, '🥕');
    expect(renamed.order, 42);
    expect(renamed.income, isTrue);
    expect(renamed.methodAdded, MethodAdded.csv);
    expect(transport.requests.map((r) => r.method), ['GET']);

    final transaction = await addTransaction(renamed.categoryPk);
    await api.categories.delete(remote.id);
    transport.requests.clear();
    await sync();
    expect(await db.fireflyCategory(renamed.categoryPk), isNull);
    expect(await context().idMap.byRemote(_type, remote.id), isNull);
    final retained = await db.select(db.transactions).getSingle();
    expect(retained.transactionPk, transaction.transactionPk);
    expect(retained.categoryFk, fireflyUncategorizedCategoryPk);
    expect(retained.subCategoryFk, isNull);
    expect(await db.select(db.deleteLogs).get(), isEmpty);
    expect(
        (await db.fireflyCategory(retained.categoryFk))?.name, 'Uncategorized');
    expect(transport.requests.map((r) => r.method), ['GET']);
  });

  test('local create, rename and delete send only the synchronized name',
      () async {
    await addCategory('local', ' Fuel ');
    await sync();
    final id = (await context().idMap.byLocal(_type, 'local'))!.remoteId;
    expect(transport.requests.last.body, {'name': 'Fuel'});

    await api.categories.update(id, {'notes': 'Keep this'});
    await sync();
    await renameLocal('local', 'Transport');
    transport.requests.clear();
    await sync();
    expect(transport.requests.last.method, 'PUT');
    expect(transport.requests.last.body, {'name': 'Transport'});
    expect((await api.categories.get(id)).notes, 'Keep this');

    await db.deleteCategory('local', 12);
    transport.requests.clear();
    await sync();
    expect(transport.requests.last.method, 'DELETE');
    expect(transport.requests.last.path, '$_path/$id');
    expect(await context().idMap.byLocal(_type, 'local'), isNull);
    await expectLater(api.categories.get(id), throwsA(isA<FireflyNotFound>()));
  });

  test('child imports before parent and pushes local child and parent renames',
      () async {
    const separator = ' / ';
    transport.seed(_path, '1', {'name': 'Food / Groceries'});
    transport.seed(_path, '2', {'name': 'Food'});
    await sync(separator: separator);
    final child = await localByRemote('1');
    final parent = await localByRemote('2');
    expect(child.name, 'Groceries');
    expect(child.mainCategoryPk, parent.categoryPk);

    await renameLocal(child.categoryPk, 'Market');
    await sync();
    expect((await api.categories.get('1')).name, 'Food / Market');

    transport.requests.clear();
    await renameLocal(parent.categoryPk, 'Pantry');
    await sync();
    final updates = transport.requests.where((r) => r.method == 'PUT');
    expect(updates.map((r) => r.body), [
      {'name': 'Pantry'},
      {'name': 'Pantry / Market'},
    ]);
    transport.requests.clear();
    await sync();
    expect(transport.requests.map((r) => r.method), ['GET', 'GET']);
  });

  test('custom separator round-trips a local parent and child', () async {
    await addCategory('parent', 'Food');
    await addCategory('child', 'Groceries', parent: 'parent');
    await sync(separator: ' :: ');
    expect(
      transport.requests.where((r) => r.method == 'POST').map((r) => r.body),
      [
        {'name': 'Food'},
        {'name': 'Food :: Groceries'},
      ],
    );
    final parent = (await context().idMap.byLocal(_type, 'parent'))!;
    final child = (await context().idMap.byLocal(_type, 'child'))!;
    // The legacy delete logs the parent and removes its local children.
    await db.deleteCategory('parent', 12);
    transport.requests.clear();
    await sync(separator: ' :: ');
    expect(
      transport.requests.where((r) => r.method == 'DELETE').map((r) => r.path),
      unorderedEquals(
          ['$_path/${parent.remoteId}', '$_path/${child.remoteId}']),
    );
  });

  test('deleting a remote parent keeps surviving children and transactions',
      () async {
    transport.seed(_path, '1', {'name': 'Food'});
    transport.seed(_path, '2', {'name': 'Food / Groceries'});
    await sync();
    final parent = await localByRemote('1');
    final child = await localByRemote('2');
    await addTransaction(parent.categoryPk, sub: child.categoryPk);

    transport.removeSeed(_path, '1');
    transport.requests.clear();
    await sync();

    final retained = await localByRemote('2');
    expect(retained.categoryPk, child.categoryPk);
    expect(retained.name, 'Food / Groceries');
    expect(retained.mainCategoryPk, isNull);
    final transaction = await db.select(db.transactions).getSingle();
    expect(transaction.categoryFk, child.categoryPk);
    expect(transaction.subCategoryFk, isNull);
    expect(transport.requests.map((r) => r.method), ['GET']);
  });

  test(
      'balance correction and fallback stay local and disabled mode sends nothing',
      () async {
    await addCategory('0', 'Balance correction');
    final fallback = await db.ensureUncategorizedCategory();
    expect(await db.ensureUncategorizedCategory(), fallback);
    await addCategory('other', 'Travel');
    await sync(mode: false);
    expect(transport.requests, isEmpty);

    await sync();
    expect(
        transport.requests.where((r) => r.method == 'POST').map((r) => r.body),
        [
          {'name': 'Travel'}
        ]);
    expect(await context().idMap.byLocal(_type, '0'), isNull);
    expect(await context().idMap.byLocal(_type, fallback), isNull);
  });

  test('links existing categories and recovers a duplicate create', () async {
    await addCategory('local', 'Fuel');
    transport.seed(_path, '1', {'name': 'fuel'});
    await sync();
    expect((await localByRemote('1')).categoryPk, 'local');

    await addCategory('second', 'Books');
    transport.onRequest = (request) {
      if (request.method == 'POST') {
        transport.seed(_path, '2', {'name': 'Books'});
        throw const FireflyValidation(
          'Invalid category',
          errors: {
            'name': ['The name has already been taken.']
          },
        );
      }
    };
    await sync();
    expect((await localByRemote('2')).categoryPk, 'second');
  });
}

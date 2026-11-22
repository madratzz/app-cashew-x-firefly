import 'dart:convert';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/meta_roaming.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../e2e/support/e2e_harness.dart';

const _category = FireflyEntityType.category;
const _preferencePath = '/api/v1/preferences';

void main() {
  late _PreferencesRoute preferences;
  late FireflyApi api;
  late FinanceDatabase first;
  late FinanceDatabase second;

  FireflyMetaRoaming roaming(FinanceDatabase db,
      {bool? enabled, bool mode = true}) {
    final context = SyncContext(
      db: db,
      api: api,
      config: FireflyConfig(mode: mode),
      now: () => fixtureTime,
    );
    return enabled == null
        ? FireflyMetaRoaming(context)
        : FireflyMetaRoaming(context, enabled: enabled);
  }

  setUp(() async {
    preferences = _PreferencesRoute();
    final target =
        await E2eTarget.fake(() => fixtureTime, intercept: preferences.handle);
    addTearDown(target.close);
    final transport = target.transport();
    addTearDown(transport.close);
    api = FireflyApi(transport);
    first = inMemoryFinanceDatabase();
    final warn = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    try {
      second = inMemoryFinanceDatabase();
    } finally {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = warn;
    }
    addTearDown(first.close);
    addTearDown(second.close);
  });

  test('reads and writes named preferences with a separate resource ID',
      () async {
    await expectLater(
        api.preferences.get('cashew.example'), throwsA(isA<FireflyNotFound>()));
    await expectLater(
      api.preferences.update('cashew.example', {'data': 'absent'}),
      throwsA(isA<FireflyNotFound>()),
    );
    final created = await api.preferences.create({
      'name': 'cashew.example',
      'data': {
        'nested': [1, false]
      },
    });
    expect(created.id, '1');
    expect(created.name, 'cashew.example');
    expect(created.updatedAt?.toUtc(), fixtureTime);
    expect(created.data, {
      'nested': [1, false]
    });
    await expectLater(
        api.preferences.get(created.id), throwsA(isA<FireflyNotFound>()));
    expect((await api.preferences.list(limit: 1)).items.single.id, created.id);
    expect(
      (await api.preferences.update('cashew.example', {'data': 'updated'}))
          .data,
      'updated',
    );
    final before = preferences.requests.length;
    await expectLater(
        api.preferences.delete('cashew.example'), throwsUnsupportedError);
    expect(preferences.requests, hasLength(before));
  });

  test('disable by default and skip all requests when Firefly mode is off',
      () async {
    await _seed(first, 'a', styled: true);
    await roaming(first).pull();
    await roaming(first).push();
    await roaming(first, enabled: true, mode: false).pull();
    await roaming(first, enabled: true, mode: false).push();
    expect(preferences.requests, isEmpty);
    expect(await first.select(first.fireflySyncMeta).get(), isEmpty);
  });

  test('pulls style across databases using remote IDs and keeps writes local',
      () async {
    await _seed(first, 'a', styled: true);
    await _seed(second, 'b', styled: false);
    await roaming(first, enabled: true).push();
    await roaming(second, enabled: true).pull();

    final wallet = (await second.fireflyWallet('b-wallet'))!;
    expect((wallet.colour, wallet.iconName, wallet.order),
        ('112233', 'wallet', 0));
    final category = (await second.fireflyCategory('b-category'))!;
    expect(
      (
        category.colour,
        category.iconName,
        category.emojiIconName,
        category.order
      ),
      ('112233', 'category', '🍋', 7),
    );
    expect(category.name, 'b category');
    expect(category.dateTimeModified?.toUtc(), fixtureTime);
    final budget = (await second.fireflyBudget('b-budget'))!;
    expect((budget.colour, budget.order, budget.amount), ('112233', 7, 25));
    final goal = (await second.fireflyObjective('b-goal'))!;
    expect(
      (goal.colour, goal.iconName, goal.emojiIconName, goal.order),
      ('112233', 'goal', '🍋', 7),
    );

    preferences.requests.clear();
    await roaming(second, enabled: true).push();
    expect(preferences.requests.map((request) => request.method),
        everyElement('GET'));
  });

  test('merges independent edits and resolves overlapping edits by time',
      () async {
    await _seed(first, 'a', styled: true);
    await _seed(second, 'b', styled: false);
    final a = roaming(first, enabled: true);
    final b = roaming(second, enabled: true);
    await a.push();
    await b.pull();

    await _editCategory(first, 'a', 10, colour: const Value('223344'));
    await _editCategory(second, 'b', 20,
        colour: const Value('334455'), icon: const Value(null));
    // The late upload of the older colour edit must not replace the newer one.
    await b.push();
    await a.pull();
    await a.push();
    expect((await first.fireflyCategory('a-category'))!.colour, '334455');
    expect((await first.fireflyCategory('a-category'))!.iconName, isNull);

    await _editCategory(first, 'a', 40, colour: const Value('445566'));
    await _editCategory(second, 'b', 30, order: const Value(15));
    await a.push();
    await b.pull();
    await b.push();
    await a.pull();
    for (final (db, prefix) in [(first, 'a'), (second, 'b')]) {
      final row = (await db.fireflyCategory('$prefix-category'))!;
      expect((row.colour, row.order), ('445566', 15));
    }

    await _editCategory(first, 'a', 50, colour: const Value('556677'));
    await _editCategory(second, 'b', 60, colour: const Value('667788'));
    await a.push();
    await b.pull();
    expect((await second.fireflyCategory('b-category'))!.colour, '667788');
    await b.push();
    await a.pull();
    expect((await first.fireflyCategory('a-category'))!.colour, '667788');
  });

  test('retries a failed upload without dropping its local edits', () async {
    await _seed(first, 'a', styled: true);
    await _seed(second, 'b', styled: false);
    final a = roaming(first, enabled: true);
    final b = roaming(second, enabled: true);
    await a.push();
    await b.pull();
    await _editCategory(first, 'a', 10, order: const Value(19));
    preferences.rejectUpdate = true;
    await expectLater(a.push(), throwsA(isA<FireflyValidation>()));
    preferences.rejectUpdate = false;
    await a.push();
    await b.pull();
    expect((await second.fireflyCategory('b-category'))!.order, 19);
  });
}

Future<void> _seed(FinanceDatabase db, String prefix,
    {required bool styled}) async {
  final colour = Value(styled ? '112233' : null);
  final emoji = Value(styled ? '🍋' : null);
  final order = styled ? 7 : 0;
  final wallet = '$prefix-wallet';
  final category = '$prefix-category';
  final budget = '$prefix-budget';
  final goal = '$prefix-goal';
  await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: Value(wallet),
        name: '$prefix wallet',
        order: order,
        colour: colour,
        iconName: Value(styled ? 'wallet' : null),
        dateTimeModified: Value(fixtureTime),
      ));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: Value(category),
        name: '$prefix category',
        order: order,
        colour: colour,
        iconName: Value(styled ? 'category' : null),
        emojiIconName: emoji,
        dateTimeModified: Value(fixtureTime),
      ));
  await db.into(db.budgets).insert(BudgetsCompanion.insert(
        budgetPk: Value(budget),
        walletFk: Value(wallet),
        name: '$prefix budget',
        amount: 25,
        startDate: fixtureTime,
        endDate: fixtureTime,
        periodLength: 1,
        order: order,
        colour: colour,
        dateTimeModified: Value(fixtureTime),
      ));
  await db.into(db.objectives).insert(ObjectivesCompanion.insert(
        objectivePk: Value(goal),
        walletFk: Value(wallet),
        name: '$prefix goal',
        amount: 100,
        order: order,
        colour: colour,
        iconName: Value(styled ? 'goal' : null),
        emojiIconName: emoji,
        dateTimeModified: Value(fixtureTime),
      ));

  for (final (type, pk) in [
    (FireflyEntityType.walletAccount, wallet),
    (_category, category),
    (FireflyEntityType.budget, budget),
    (FireflyEntityType.piggyBank, goal),
  ]) {
    await db
        .into(db.fireflyIdMap)
        .insert(fixtureMapping(type: type, localPk: pk, remoteId: '15'));
  }
}

Future<void> _editCategory(
  FinanceDatabase db,
  String prefix,
  int seconds, {
  Value<String?> colour = const Value.absent(),
  Value<String?> icon = const Value.absent(),
  Value<int> order = const Value.absent(),
}) =>
    (db.update(db.categories)
          ..where((row) => row.categoryPk.equals('$prefix-category')))
        .write(CategoriesCompanion(
      colour: colour,
      iconName: icon,
      order: order,
      dateTimeModified: Value(fixtureTime.add(Duration(seconds: seconds))),
    ));

/// The generic harness keys resources by ID. Firefly's preference routes use
/// names while returning numeric resource IDs.
class _PreferencesRoute {
  final _items = <String, JsonObject>{};
  final requests = <({String method, String path})>[];
  bool rejectUpdate = false;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path != _preferencePath && !path.startsWith('$_preferencePath/')) {
      return false;
    }
    requests.add((method: request.method, path: path));
    final response = request.response
      ..headers.contentType =
          ContentType('application', 'vnd.api+json', charset: 'utf-8');
    final name = request.uri.pathSegments.last;
    final item = _items[name];

    switch (request.method) {
      case 'GET' when path == _preferencePath:
        final limit = int.parse(request.uri.queryParameters['limit']!);
        final page = int.parse(request.uri.queryParameters['page']!);
        response.write(jsonEncode({
          'data': _items.values.skip((page - 1) * limit).take(limit).toList(),
          'meta': {
            'pagination': {
              'total': _items.length,
              'per_page': limit,
              'current_page': page,
              'total_pages': (_items.length / limit).ceil(),
            },
          },
        }));
      case 'GET' when item != null:
        response.write(jsonEncode({'data': item}));
      case 'POST' when path == _preferencePath:
        final body = await _read(request);
        final key = body['name']! as String;
        final id = _items[key]?['id'] ?? '${_items.length + 1}';
        final created = fireflyResource('preferences', id as String, {
          ...body,
          'updated_at': fixtureTime.toIso8601String(),
        });
        _items[key] = created;
        response.write(jsonEncode({'data': created}));
      case 'PUT' when item != null:
        if (rejectUpdate) {
          response.statusCode = HttpStatus.unprocessableEntity;
          response.write(jsonEncode({'message': 'Fixture rejection'}));
        } else {
          final body = await _read(request);
          final updated =
              fireflyResource('preferences', item['id']! as String, {
            ...item['attributes']! as JsonObject,
            'data': body['data'],
          });
          _items[name] = updated;
          response.write(jsonEncode({'data': updated}));
        }
      default:
        response.statusCode = HttpStatus.notFound;
    }
    return true;
  }

  Future<JsonObject> _read(HttpRequest request) async =>
      jsonDecode(await utf8.decoder.bind(request).join()) as JsonObject;
}

import 'dart:math';

import 'package:budget/firefly/api/transport.dart';

import '../../../support/fake_firefly_transport.dart';

/// An in-memory Firefly III 6.6.2 with the behaviour the Phase 1 sync relies
/// on: journal ids, date windows, `updated_at_after` search, computed
/// `current_balance`, server-assigned account order and cascading deletes. It answers like the live server
/// for the requests the E2E suite sends, and nothing more.
class FireflyEmulator extends FakeFireflyTransport {
  FireflyEmulator({DateTime Function()? clock})
      : clock = clock ?? DateTime.now,
        super(maxPageSize: 100) {
    seed('/currencies', 'primary', _currency('USD', 2, primary: true));
    seed('/currencies', 'USD', _currency('USD', 2, primary: true));
    seed('/currencies', 'EUR', _currency('EUR', 2));
  }

  DateTime Function() clock;

  final _accounts = <String, JsonObject>{};
  final _groups = <String, JsonObject>{};
  final _categories = <String, JsonObject>{};
  var _nextJournal = 5000;

  static JsonObject _currency(String code, int decimals,
          {bool primary = false}) =>
      {
        'code': code,
        'name': code,
        'symbol': code,
        'decimal_places': decimals,
        'enabled': true,
        'primary': primary,
      };

  static String _normalize(String raw) {
    var path = raw.startsWith('/') ? raw : '/$raw';
    if (path.startsWith('/api/v1/')) path = path.substring('/api/v1'.length);
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  /// Firefly stamps whole seconds with an offset.
  String get _now {
    final now = clock().toUtc();
    return DateTime.utc(
            now.year, now.month, now.day, now.hour, now.minute, now.second)
        .toIso8601String()
        .replaceFirst('.000Z', '+00:00');
  }

  Map<String, JsonObject>? _store(String path) => switch (path) {
        '/accounts' => _accounts,
        '/transactions' => _groups,
        '/categories' => _categories,
        _ => null,
      };

  @override
  void seed(String path, String id, JsonObject attributes) {
    super.seed(path, id, attributes);
    _store(path)?[id] = Map.of(attributes);
  }

  @override
  void removeSeed(String path, String id) {
    super.removeSeed(path, id);
    _store(path)?.remove(id);
  }

  static List<JsonObject> splitsOf(JsonObject group) =>
      (group['transactions'] as List<Object?>? ?? const []).cast<JsonObject>();

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    path = _normalize(path);
    final item = await super.get(path, query: query);
    if (path.startsWith('/accounts/')) {
      final attributes = Map.of(item['attributes']! as JsonObject);
      attributes['current_balance'] = _balance(item['id']! as String);
      return {...item, 'attributes': attributes};
    }
    return item;
  }

  String _balance(String accountId) {
    final account = _accounts[accountId]!;
    var total = double.tryParse('${account['opening_balance'] ?? 0}') ?? 0;
    for (final group in _groups.values) {
      for (final split in splitsOf(group)) {
        final amount = double.parse('${split['amount']}');
        if (split['source_id'] == accountId) total -= amount;
        if (split['destination_id'] == accountId) total += amount;
      }
    }
    final places = account['currency_decimal_places'] as int? ?? 2;
    return total.toStringAsFixed(places);
  }

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    path = _normalize(path);
    if (path == '/transactions' || path == '/search/transactions') {
      requests.add((method: 'GET', path: path, query: query, body: null));
      onRequest?.call(requests.last);
      return _transactionPage(path, query);
    }
    return super.getPage(path, query: query);
  }

  FireflyPage<JsonObject> _transactionPage(String path, FireflyQuery query) {
    bool Function(JsonObject) keep = (_) => true;
    if (path == '/transactions') {
      final start = query['start'];
      final end = query['end'];
      if (start != null && end != null) {
        keep = (group) => splitsOf(group).any((split) {
              final date = (split['date']! as String).substring(0, 10);
              return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
            });
      }
    } else {
      final search = query['query'] ?? '';
      final match = RegExp(r'^updated_at_after:(\d{4}-\d{2}-\d{2})$')
          .firstMatch(search.trim());
      if (match == null) throw const FireflyValidation('Unsupported query');
      final after = match.group(1)!;
      keep = (group) =>
          (group['updated_at']! as String).substring(0, 10).compareTo(after) >
          0;
    }
    final entries = _groups.entries.where((entry) => keep(entry.value)).toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    final perPage = min(maxPageSize, int.tryParse(query['limit'] ?? '') ?? 50);
    final page = int.tryParse(query['page'] ?? '') ?? 1;
    final total = entries.length;
    return FireflyPage(
      items: [
        for (final entry in entries.skip((page - 1) * perPage).take(perPage))
          fireflyGroup(entry.key, entry.value),
      ],
      total: total,
      currentPage: page,
      perPage: perPage,
      totalPages: max(1, (total + perPage - 1) ~/ perPage),
    );
  }

  static JsonObject fireflyGroup(String id, JsonObject attributes) => {
        'type': 'transactions',
        'id': id,
        'attributes': attributes,
        'links': {'self': '/api/v1/transactions/$id'},
      };

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    path = _normalize(path);
    switch (path) {
      case '/transactions':
        final splits = [
          for (final split in splitsOf(body))
            {
              'currency_code': _currencyOf(split),
              'reconciled': false,
              ...split,
              'transaction_journal_id': '${_nextJournal++}',
            },
        ];
        final created = await super.post(
            path, {...body, 'transactions': splits, 'created_at': _now},
            query: query);
        return _touch(path, created);
      case '/accounts':
        final created = await super.post(
            path,
            {
              'active': true,
              'currency_code': 'USD',
              'currency_decimal_places': 2,
              ...body,
              // Firefly assigns the order itself and ignores the one sent.
              'order': 1 +
                  _accounts.values
                      .where((account) => account['type'] == body['type'])
                      .length,
            },
            query: query);
        return _touch(path, created);
      case '/categories':
        return _touch(path, await super.post(path, body, query: query));
    }
    if (RegExp(r'^/currencies/[A-Z]+/enable$').hasMatch(path)) {
      requests.add((method: 'POST', path: path, query: query, body: body));
      return const {};
    }
    return super.post(path, body, query: query);
  }

  /// Firefly takes the split currency from the asset side of the journal.
  String _currencyOf(JsonObject split) {
    for (final key in ['source_id', 'destination_id']) {
      final account = _accounts[split[key]];
      if (account != null) return account['currency_code']! as String;
    }
    return 'USD';
  }

  JsonObject _touch(String collection, JsonObject resource) {
    final id = resource['id']! as String;
    final attributes = {
      ...resource['attributes']! as JsonObject,
      'updated_at': _now,
    };
    seed(collection, id, attributes);
    return {...resource, 'attributes': attributes};
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    path = _normalize(path);
    final slash = path.lastIndexOf('/');
    final collection = path.substring(0, slash);
    final id = path.substring(slash + 1);
    if (collection == '/transactions') {
      final previous = _groups[id];
      if (previous == null) {
        requests.add((method: 'PUT', path: path, query: query, body: body));
        throw const FireflyNotFound();
      }
      final byJournal = {
        for (final split in splitsOf(previous))
          split['transaction_journal_id']: split,
      };
      final incoming = splitsOf(body);
      final merged = incoming.isEmpty
          ? splitsOf(previous)
          : [
              for (final split in incoming)
                {
                  ...?byJournal[split['transaction_journal_id']],
                  ...split,
                  'transaction_journal_id':
                      split['transaction_journal_id'] ?? '${_nextJournal++}',
                },
            ];
      return _touch(
          collection,
          await super
              .put(path, {...body, 'transactions': merged}, query: query));
    }
    final updated = await super.put(path, body, query: query);
    return _store(collection) == null ? updated : _touch(collection, updated);
  }

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) async {
    path = _normalize(path);
    final journal =
        RegExp(r'^/transaction-journals/(\w+)$').firstMatch(path)?.group(1);
    if (journal != null) {
      requests.add((method: 'DELETE', path: path, query: query, body: null));
      final entry = _groups.entries.where((entry) => splitsOf(entry.value)
          .any((split) => split['transaction_journal_id'] == journal));
      if (entry.isEmpty) throw const FireflyNotFound();
      final groupId = entry.first.key;
      final rest = [
        for (final split in splitsOf(entry.first.value))
          if (split['transaction_journal_id'] != journal) split,
      ];
      if (rest.isEmpty) {
        removeSeed('/transactions', groupId);
      } else {
        seed('/transactions', groupId,
            {...entry.first.value, 'transactions': rest, 'updated_at': _now});
      }
      return;
    }
    await super.delete(path, query: query);
    final slash = path.lastIndexOf('/');
    final collection = path.substring(0, slash);
    final id = path.substring(slash + 1);
    _store(collection)?.remove(id);
    if (collection == '/accounts') {
      // Firefly deletes every journal that touches a deleted account.
      for (final entry in _groups.entries.toList()) {
        if (splitsOf(entry.value).any((split) =>
            split['source_id'] == id || split['destination_id'] == id)) {
          removeSeed('/transactions', entry.key);
        }
      }
    } else if (collection == '/categories') {
      for (final entry in _groups.entries.toList()) {
        final splits = splitsOf(entry.value);
        if (!splits.any((split) => split['category_id'] == id)) continue;
        seed('/transactions', entry.key, {
          ...entry.value,
          'updated_at': _now,
          'transactions': [
            for (final split in splits)
              split['category_id'] == id
                  ? {...split, 'category_id': null, 'category_name': null}
                  : split,
          ],
        });
      }
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:budget/firefly/api/transport.dart';

import '../../support/e2e_harness.dart';
import '../../support/firefly_emulator.dart';

/// The Phase 1 emulator plus what budgets, piggy banks, bills and
/// recurrences need: piggy bank account amounts with history events, the
/// recurrence trigger, and the 6.6.2 PUT validation of repetition moments.
class Phase2Emulator extends FireflyEmulator {
  Phase2Emulator({super.clock});

  static const _banks = '/piggy-banks';
  var _nextEvent = 1;

  /// Firefly 6.6.2 `UpdateRequest` rejects numeric moments from 0 to 10 on
  /// PUT although the API documents them. POST accepts them.
  static bool rejectedMoment(Object? moment) {
    final value = int.tryParse('$moment');
    return value != null && value >= 0 && value <= 10;
  }

  /// An emulated Phase 2 server, reached through the real transport.
  static Future<E2eTarget> target(DateTime Function() clock) async {
    final emulator = Phase2Emulator(clock: clock);
    return E2eTarget.fake(clock,
        emulator: (_) => emulator, intercept: emulator._trigger);
  }

  String get _time => clock().toUtc().toIso8601String();

  static String _normalize(String raw) {
    var path = raw.startsWith('/') ? raw : '/$raw';
    if (path.startsWith('/api/v1/')) path = path.substring('/api/v1'.length);
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  /// `POST /recurrences/{id}/trigger` answers with a list of groups, which
  /// the generic loopback server cannot express.
  Future<bool> _trigger(HttpRequest request) async {
    final match = RegExp(r'^/api/v1/recurrences/(\w+)/trigger$')
        .firstMatch(request.uri.path);
    if (request.method != 'POST' || match == null) return false;
    await request.drain<void>();
    final id = match.group(1)!;
    final date = request.uri.queryParameters['date'];
    requests.add((
      method: 'POST',
      path: '/recurrences/$id/trigger',
      query: request.uri.queryParameters,
      body: null,
    ));
    final groups = <JsonObject>[];
    final recurrence = await _recurrence(id);
    if (recurrence == null) {
      request.response.statusCode = HttpStatus.notFound;
    } else if (date != null && !_triggered.add('$id@$date')) {
      // Firefly creates each occurrence once.
    } else {
      final template = FireflyEmulator.splitsOf(recurrence).first;
      groups.add(await post('/transactions', {
        'transactions': [
          {
            'type': recurrence['type'] ?? 'withdrawal',
            'description': template['description'],
            'amount': template['amount'],
            'date': _time,
            'source_id': template['source_id'],
            'destination_id': template['destination_id'],
          },
        ],
      }));
    }
    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'data': groups}));
    await request.response.close();
    return true;
  }

  final _triggered = <String>{};

  Future<JsonObject?> _recurrence(String id) async {
    try {
      return (await super.get('/recurrences/$id'))['attributes'] as JsonObject;
    } on FireflyNotFound {
      return null;
    }
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    if (_normalize(path) == '/budgets') return _postBudget(body, query);
    if (_normalize(path) != _banks) return super.post(path, body, query: query);
    // Firefly 6.6.2 StoreRequest requires a start date.
    if (body['start_date'] == null) {
      throw const FireflyValidation('The start date field is required.',
          errors: {
            'start_date': ['The start date field is required.'],
          });
    }
    if (body['transaction_currency_code'] == null) {
      throw const FireflyValidation('Missing piggy bank currency');
    }
    final accounts = _accounts(body);
    final resource = await super.post(path, body, query: query);
    final id = resource['id']! as String;
    final bank = _storeBank(id, {
      ...body,
      'accounts': accounts,
      'created_at': _time,
      'updated_at': _time,
      'currency_decimal_places': 2,
    });
    final total = _total(accounts);
    if (total.abs() >= 0.005) _event(id, total);
    return bank;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final normalized = _normalize(path);
    if (normalized.startsWith('/recurrences/')) {
      for (final repetition
          in (body['repetitions'] as List<Object?>? ?? const [])) {
        if (repetition is JsonObject && rejectedMoment(repetition['moment'])) {
          requests
              .add((method: 'PUT', path: normalized, query: query, body: body));
          throw const FireflyValidation('The moment field is invalid.',
              errors: {
                'repetitions.0.moment': ['The moment field is invalid.'],
              });
        }
      }
    }
    if (!normalized.startsWith('$_banks/')) {
      return super.put(path, body, query: query);
    }
    if (body.containsKey('current_amount')) {
      throw const FireflyValidation('Amount belongs to the account');
    }
    final id = normalized.split('/').last;
    final old = (await super.get(normalized))['attributes'] as JsonObject;
    final accounts = body.containsKey('accounts') ? _accounts(body) : null;
    if (accounts != null) {
      final delta =
          _total(accounts) - parseFireflyAmount('${old['current_amount']}');
      if (delta.abs() >= 0.005) _event(id, delta);
    }
    final resource = await super.put(path, body, query: query);
    return _storeBank(id, {
      ...old,
      ...(resource['attributes'] as JsonObject),
      'updated_at': _time,
      if (accounts != null) 'accounts': accounts,
    });
  }

  /// Firefly 6.6.2 creates the current period's limit for a new auto
  /// budget, and accepts a second limit for the same period.
  Future<JsonObject> _postBudget(JsonObject body, FireflyQuery query) async {
    final budget = await super.post('/budgets', body, query: query);
    final type = body['auto_budget_type'];
    final amount = body['auto_budget_amount'];
    if ((type == 'reset' || type == 'rollover') &&
        amount != null &&
        body['auto_budget_period'] == 'monthly') {
      final now = clock();
      await super.post('/budgets/${budget['id']}/limits', {
        'start': formatFireflyDate(DateTime(now.year, now.month)),
        'end': formatFireflyDate(DateTime(now.year, now.month + 1, 0)),
        'amount': '$amount',
        'currency_code': body['auto_budget_currency_code'] ?? 'USD',
        'updated_at': _time,
      });
    }
    return budget;
  }

  void _event(String bank, double amount) =>
      seed('$_banks/$bank/events', '${_nextEvent++}', {
        'amount': amount.toStringAsFixed(2),
        'created_at': _time,
        'transaction_group_id': null,
        'transaction_journal_id': null,
      });

  List<JsonObject> _accounts(JsonObject body) => [
        for (final account in (body['accounts'] as List).cast<JsonObject>())
          {
            'account_id': account['account_id'] as String? ??
                (throw const FireflyValidation('Missing nested account_id')),
            'current_amount': '${account['current_amount'] ?? '0.00'}',
          }
      ];

  double _total(List<JsonObject> accounts) => accounts.fold<double>(
      0,
      (sum, account) =>
          sum + parseFireflyAmount(account['current_amount'] as String));

  JsonObject _storeBank(String id, JsonObject bank) {
    final accounts = (bank['accounts'] as List).cast<JsonObject>();
    final attributes = {
      ...bank,
      'current_amount': _total(accounts).toStringAsFixed(2),
    };
    seed(_banks, id, attributes);
    return FireflyEmulator.fireflyGroup(id, attributes)
      ..['type'] = 'piggy_banks'
      ..['links'] = {'self': '/api/v1$_banks/$id'};
  }
}

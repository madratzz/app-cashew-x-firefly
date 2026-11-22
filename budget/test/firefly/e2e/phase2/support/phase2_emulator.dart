import 'dart:convert';
import 'dart:io';

import 'package:budget/firefly/api/transport.dart';

import '../../support/e2e_harness.dart';
import '../../support/firefly_emulator.dart';

/// The Phase 1 emulator plus what budgets, piggy banks, bills and
/// recurrences need: piggy bank account amounts with history events, the
/// auto-budget limit, weekly recurrence occurrences with the trigger, and
/// the 6.6.2 rules that a piggy bank needs a start date and a recurrence PUT
/// needs its transactions.
class Phase2Emulator extends FireflyEmulator {
  Phase2Emulator({super.clock});

  static const _banks = '/piggy-banks';
  var _nextEvent = 1;

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
    } else if (date != null && !_occurs(recurrence, date)) {
      // Firefly creates nothing for a date that is not an occurrence.
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

  static bool _occurs(JsonObject recurrence, String date) {
    final listed = [
      for (final repetition in (recurrence['repetitions'] as List? ?? const [])
          .cast<JsonObject>())
        ...(repetition['occurrences'] as List? ?? const []),
    ];
    return listed.isEmpty ||
        listed.any((occurrence) => '$occurrence'.startsWith(date));
  }

  static List<String> _weekly(DateTime first, int weekday) {
    final start = first.add(Duration(days: (weekday - first.weekday) % 7));
    return [
      for (var week = 0; week < 4; week++)
        '${formatFireflyDate(start.add(Duration(days: 7 * week)))}T00:00:00+00:00',
    ];
  }

  /// Firefly lists each repetition's next occurrences. Only weekly moments
  /// (1 Monday to 7 Sunday) are modelled.
  JsonObject _withOccurrences(JsonObject body) {
    final first = DateTime.tryParse('${body['first_date']}');
    return {
      ...body,
      // 6.6.2 reads a template without tags back as `tags: []`.
      'transactions': [
        for (final transaction
            in (body['transactions'] as List? ?? const []).cast<JsonObject>())
          {'tags': <String>[], ...transaction},
      ],
      'repetitions': [
        for (final repetition
            in (body['repetitions'] as List? ?? const []).cast<JsonObject>())
          if (first != null && repetition['type'] == 'weekly')
            {
              ...repetition,
              'occurrences':
                  _weekly(first, int.parse('${repetition['moment']}')),
            }
          else
            repetition,
      ],
    };
  }

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
    if (_normalize(path) == '/recurrences') {
      return super.post(path, _withOccurrences(body), query: query);
    }
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
    if (normalized.startsWith('/recurrences/') &&
        body['transactions'] is! List) {
      requests.add((method: 'PUT', path: normalized, query: query, body: body));
      throw const FireflyValidation('Need at least one transaction.');
    }
    if (normalized.startsWith('/recurrences/') &&
        (body['transactions'] as List).any((transaction) {
          final tags = (transaction as JsonObject)['tags'];
          return tags is List && tags.isEmpty;
        })) {
      requests.add((method: 'PUT', path: normalized, query: query, body: body));
      throw const FireflyValidation(
          'The transactions.0.tags must be at least 1 characters.');
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
      // Seeded, not posted: the server makes it, the client sends nothing.
      seed('/budgets/${budget['id']}/limits', 'auto${budget['id']}', {
        'start': formatFireflyDate(DateTime(now.year, now.month)),
        'end': formatFireflyDate(DateTime(now.year, now.month + 1, 0)),
        'amount': '$amount',
        // Without a budget currency Firefly uses its primary currency.
        'currency_code': body['auto_budget_currency_code'] ??
            ((await super.get('/currencies/primary'))['attributes']!
                as JsonObject)['code'],
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

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';

const _piggyBank = FireflyEntityType.piggyBank;
const _walletAccount = FireflyEntityType.walletAccount;

class PiggyBankSyncer extends EntitySyncer {
  const PiggyBankSyncer();

  static final _cycles = Expando<CollectionSync<FireflyPiggyBank>>();

  @override
  FireflyEntityType get type => _piggyBank;

  @override
  Set<FireflyEntityType> get dependsOn => const {_walletAccount};

  CollectionSync<FireflyPiggyBank> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _PiggyBankAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    final adapter = cycle.adapter as _PiggyBankAdapter;
    await adapter.detachLoanMappings();
    final result = await cycle.pull();
    if (context.isCancelled()) return;
    await adapter.refreshHistory(complete: result.complete);
  }

  @override
  Future<void> push(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).push();
    }
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      final cycle = _cycle(context);
      await (cycle.adapter as _PiggyBankAdapter).detachLoanMappings();
      await cycle.pushDeletes();
    }
  }
}

/// Sets the goal's total saved amount online and refreshes cached progress.
/// The next regular pull picks up the history entry created by Firefly.
Future<FireflyPiggyBank> setFireflyPiggyBankAmount(
    SyncContext context, String objectivePk, double amount) async {
  if (!context.config.mode || context.isCancelled()) {
    throw const FireflyTransportUnavailable();
  }
  if (!amount.isFinite || amount < 0) {
    throw ArgumentError.value(
        amount, 'amount', 'Expected a non-negative total');
  }
  final mapping = await context.db.fireflyPiggyBankMapping(objectivePk);
  if (mapping == null) throw const FireflyNotFound();
  final bank = await context.api.piggyBanks.get(mapping.remoteId);
  final accounts = bank.accounts;
  if (accounts.isEmpty) throw const FireflyInvalidPayload();
  final goal = await context.db.fireflyObjective(objectivePk);
  final wallet =
      goal == null ? null : await context.db.fireflyWallet(goal.walletFk);
  final decimals = bank.currencyDecimalPlaces ?? wallet?.decimals ?? 2;
  final desired = formatFireflyAmount(amount, decimals);
  if (desired == formatFireflyAmount(bank.currentAmount, decimals)) {
    await _cacheBank(context, bank);
    return bank;
  }

  // Add to the first account. When removing more than it holds, use the other
  // accounts in server order while retaining all existing account links.
  final allocated = accounts.fold<double>(
      0, (total, account) => total + account.currentAmount);
  var delta = parseFireflyAmount(desired) - allocated;
  final updates = <JsonObject>[];
  for (final account in accounts) {
    final next = (account.currentAmount + delta).clamp(0.0, double.infinity);
    updates.add(_accountBody(account.id, next.toDouble(), decimals));
    delta -= next - account.currentAmount;
  }
  if (context.isCancelled()) throw const FireflyTransportUnavailable();
  final saved =
      await context.api.piggyBanks.update(bank.id, {'accounts': updates});
  await _cacheBank(context, saved);
  return saved;
}

class _PiggyBankAdapter extends CollectionAdapter<FireflyPiggyBank> {
  _PiggyBankAdapter(this.context);

  final SyncContext context;
  final _listed = <String, FireflyPiggyBank>{};

  FinanceDatabase get _db => context.db;

  @override
  FireflyEntityType get type => _piggyBank;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyPiggyBank>>> page(
      int page, int limit) async {
    if (page == 1) _listed.clear();
    final result = await context.api.piggyBanks.list(page: page, limit: limit);
    for (final bank in result.items) {
      _listed[bank.id] = bank;
    }
    return FireflyPage(
      items: [for (final bank in result.items) await _remoteRow(bank)],
      total: result.total,
      currentPage: result.currentPage,
      perPage: result.perPage,
      totalPages: result.totalPages,
    );
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async => [
        for (final goal in await _db.fireflyGoals())
          if (await _walletMapping(goal.walletFk) != null) _localRow(goal),
      ];

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final goal = await _db.fireflyObjective(pk);
    if (goal == null || goal.type != ObjectiveType.goal) return null;
    final mapping = await context.idMap.byLocal(type, pk);
    // Drift stores whole seconds, so two edits can share a timestamp.
    return _localRow(goal,
        hashOnly:
            mapping != null && mapping.localVersionAt == goal.dateTimeModified);
  }

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyPiggyBank> remote) async {
    final name = (remote.fields['name'] as String).toLowerCase();
    for (final goal in await _db.fireflyGoals()) {
      if (goal.name.trim().toLowerCase() != name) continue;
      final mapping = await context.idMap.byLocal(type, goal.objectivePk);
      if (mapping == null ||
          (IdMapRepository.isProvisional(mapping) &&
              mapping.state != FireflySyncState.localOnly)) {
        return goal.objectivePk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
      RemoteCollectionRow<FireflyPiggyBank> remote,
      {String? localPk}) async {
    final bank = remote.value;
    final saved = await _db.writeFireflyGoal(
      pk: localPk,
      name: remote.fields['name'] as String,
      amount: remote.fields['target_amount'] as double,
      walletPk: remote.fields['wallet_fk'] as String,
      startDate: _start(bank),
      targetDate: bank.targetDate,
      modifiedAt: bank.updatedAt,
    );
    return _localRow(saved);
  }

  @override
  Future<void> removeLocal(String pk) => _db.removeFireflyGoal(pk);

  @override
  Future<RemoteCollectionRow<FireflyPiggyBank>> createRemote(
      LocalCollectionRow local) async {
    final walletPk = local.fields['wallet_fk'] as String;
    final account = await _walletMapping(walletPk);
    final wallet = await _db.fireflyWallet(walletPk);
    if (account == null || wallet == null) {
      throw const FireflyValidation('An asset account is required');
    }
    final currency = wallet.currency?.toUpperCase() ??
        (await context.api.currencies.primary()).code;
    if (currency == null) throw const FireflyInvalidPayload();
    final bank = await context.api.piggyBanks.create({
      ..._body(local, wallet.decimals),
      'account_id': account.remoteId,
      'accounts': [_accountBody(account.remoteId, 0, wallet.decimals)],
      'transaction_currency_code': currency,
    });
    await _cacheBank(context, bank);
    return _remoteRow(bank);
  }

  @override
  Future<RemoteCollectionRow<FireflyPiggyBank>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local) async {
    final bank = _listed[mapping.remoteId] ??
        await context.api.piggyBanks.get(mapping.remoteId);
    final remote = await _remoteRow(bank);
    final walletPk = local.fields['wallet_fk'] as String;
    final account = await _walletMapping(walletPk);
    final wallet = await _db.fireflyWallet(walletPk);
    if (account == null || wallet == null) {
      throw const FireflyValidation('An asset account is required');
    }
    final decimals = bank.currencyDecimalPlaces ?? wallet.decimals;
    final body = _body(local, decimals)
      ..removeWhere((key, _) => remote.fields[key] == local.fields[key]);
    if (walletPk != remote.fields['wallet_fk']) {
      final accounts = bank.accounts;
      final primary = accounts.firstOrNull;
      final secondary = accounts.skip(1);
      final chosen = secondary.where((item) => item.id == account.remoteId);
      body['accounts'] = [
        _accountBody(
            account.remoteId,
            (primary?.currentAmount ?? 0) +
                (chosen.firstOrNull?.currentAmount ?? 0),
            decimals),
        for (final item in secondary)
          if (item.id != account.remoteId)
            _accountBody(item.id, item.currentAmount, decimals),
      ];
    }
    final saved = body.isEmpty
        ? bank
        : await context.api.piggyBanks.update(bank.id, body);
    await _cacheBank(context, saved);
    return _remoteRow(saved);
  }

  @override
  Future<void> removeRemote(String id) async {
    try {
      await context.api.piggyBanks.delete(id);
    } on FireflyNotFound {
      // A retried delete can find the bank already gone.
    }
    await context.cache.remove(type, id);
  }

  @override
  Future<RemoteCollectionRow<FireflyPiggyBank>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate =
        RegExp(r'already (?:in use|exists|been taken)', caseSensitive: false);
    if (!(error.errors['name'] ?? [error.message]).any(duplicate.hasMatch)) {
      return null;
    }
    final name = (local.fields['name'] as String).toLowerCase();
    for (var page = 1; !context.isCancelled(); page++) {
      final result = await context.api.piggyBanks
          .list(page: page, limit: context.config.pageSize);
      for (final bank in result.items) {
        if (bank.name?.trim().toLowerCase() == name) return _remoteRow(bank);
      }
      if (result.currentPage != page ||
          page >= result.totalPages ||
          result.items.isEmpty) {
        break;
      }
    }
    return null;
  }

  // If an existing objective was converted to a loan, leave both the loan
  // and the server piggy bank intact. The bank can import as its own goal.
  Future<void> detachLoanMappings() async {
    for (final mapping in await context.idMap.list(type)) {
      final objective = await _db.fireflyObjective(mapping.localPk);
      if (objective?.type == ObjectiveType.loan) {
        await context.idMap.remove(type, mapping.localPk);
      }
    }
  }

  Future<void> refreshHistory({required bool complete}) async {
    for (final bank in _listed.values) {
      if (context.isCancelled()) return;
      final mapping = await context.idMap.byRemote(type, bank.id);
      if (mapping == null ||
          await _db.fireflyPiggyBankMapping(mapping.localPk) == null) {
        continue;
      }
      await _cacheBank(context, bank);
      try {
        final events = await _listEvents(bank.id);
        if (context.isCancelled()) return;
        await _cacheBank(context, bank, events: events);
      } on FireflyNotFound {
        // The bank disappeared after the list request. Reconcile next cycle.
      }
    }

    if (complete) {
      final mappings = await context.idMap.list(type);
      final retained = {
        for (final mapping in mappings)
          ResourceCacheRepository.resourcePk(type, mapping.remoteId),
      };
      for (final cached in await context.cache.list(type)) {
        if (!retained.contains(cached.resourcePk)) {
          final id = ResourceCacheRepository.decode(cached)['id'] as String;
          await context.cache.remove(type, id);
        }
      }
    }
    await _db.linkFireflyPiggyBankJournals();
  }

  Future<List<JsonObject>> _listEvents(String id) async {
    final events = <String, JsonObject>{};
    int? total;
    int? totalPages;
    for (var page = 1; !context.isCancelled(); page++) {
      final result = await context.api.piggyBanks
          .listEvents(id, page: page, limit: context.config.pageSize);
      total ??= result.total;
      totalPages ??= result.totalPages;
      if (result.currentPage != page ||
          result.total != total ||
          result.totalPages != totalPages ||
          result.perPage <= 0 ||
          result.items.length > result.perPage) {
        throw const FireflyInvalidPayload();
      }
      for (final row in result.items) {
        final event = FireflyPiggyBankEvent.fromJson(row);
        if (events.containsKey(event.id)) throw const FireflyInvalidPayload();
        events[event.id] = row;
      }
      if (page >= totalPages) {
        if (events.length != total) throw const FireflyInvalidPayload();
        return events.values.toList();
      }
      if (result.items.isEmpty) throw const FireflyInvalidPayload();
    }
    return [];
  }

  Future<FireflyIdMapping?> _walletMapping(String pk) async {
    final mapping = await context.idMap.byLocal(_walletAccount, pk);
    return mapping == null ||
            IdMapRepository.isProvisional(mapping) ||
            mapping.state == FireflySyncState.pendingDelete ||
            mapping.state == FireflySyncState.localOnly
        ? null
        : mapping;
  }

  LocalCollectionRow _localRow(Objective goal, {bool hashOnly = false}) =>
      LocalCollectionRow(
        pk: goal.objectivePk,
        modifiedAt: hashOnly ? null : goal.dateTimeModified,
        fields: {
          'name': goal.name.trim(),
          'target_amount': goal.amount == 0 ? 0.0 : goal.amount,
          'start_date': _date(goal.dateCreated),
          'target_date': _date(goal.endDate),
          'wallet_fk': goal.walletFk,
        },
        snapshot: goal.toJson(),
      );

  Future<RemoteCollectionRow<FireflyPiggyBank>> _remoteRow(
      FireflyPiggyBank bank) async {
    final name = bank.name?.trim();
    if (name == null || name.isEmpty) throw const FireflyInvalidPayload();
    final account = bank.accounts.firstOrNull;
    final mapping = account == null
        ? null
        : await context.idMap.byRemote(_walletAccount, account.id);
    final wallet =
        mapping == null ? null : await _db.fireflyWallet(mapping.localPk);
    return RemoteCollectionRow(
      id: bank.id,
      value: bank,
      updatedAt: bank.updatedAt,
      fields: {
        'name': _truncateName(name),
        'target_amount': bank.targetAmount ?? 0.0,
        'start_date': _date(_start(bank)),
        'target_date': _date(bank.targetDate),
        'wallet_fk': wallet?.walletPk ?? '0',
      },
      snapshot: bank.attributes,
    );
  }

  DateTime _start(FireflyPiggyBank bank) =>
      bank.startDate ??
      bank.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  JsonObject _body(LocalCollectionRow local, int decimals) => {
        'name': local.fields['name'],
        'target_amount': formatFireflyAmount(
            local.fields['target_amount'] as double, decimals),
        'start_date': local.fields['start_date'],
        'target_date': local.fields['target_date'],
      };
}

String _truncateName(String name) {
  if (name.length <= NAME_LIMIT) return name;
  final splitsSurrogatePair = name.codeUnitAt(NAME_LIMIT) & 0xFC00 == 0xDC00;
  return name.substring(0, splitsSurrogatePair ? NAME_LIMIT - 1 : NAME_LIMIT);
}

String? _date(DateTime? date) => date == null
    ? null
    : formatFireflyDateTime(DateTime.fromMillisecondsSinceEpoch(
        date.millisecondsSinceEpoch ~/ 1000 * 1000));

JsonObject _accountBody(String id, double amount, int decimals) => {
      'account_id': id,
      'current_amount': formatFireflyAmount(amount, decimals),
    };

Future<void> _cacheBank(SyncContext context, FireflyPiggyBank bank,
        {List<JsonObject>? events}) =>
    context.db.transaction(() async {
      final cached = await context.cache.read(_piggyBank, bank.id);
      final previous =
          cached == null ? null : ResourceCacheRepository.decode(cached);
      final older = cached?.dateTimeModified != null &&
          bank.updatedAt != null &&
          bank.updatedAt!.isBefore(cached!.dateTimeModified!);
      final data = {
        'id': bank.id,
        'attributes': older ? previous!['attributes'] : bank.attributes,
        'events': events ?? previous?['events'] ?? const [],
      };
      if (previous == null || canonicalJson(previous) != canonicalJson(data)) {
        await context.cache.write(_piggyBank, bank.id, data,
            modifiedAt: older ? cached.dateTimeModified : bank.updatedAt);
      }
    });

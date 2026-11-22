import 'dart:math' as math;

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';

const _type = FireflyEntityType.liabilityAccount;
const _accountType = 'liability';

class LiabilityAccountSyncer extends EntitySyncer {
  const LiabilityAccountSyncer();

  static final _cycles = Expando<_LiabilityAccounts>();

  @override
  FireflyEntityType get type => _type;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
        FireflyEntityType.walletAccount,
      };

  _LiabilityAccounts _cycle(SyncContext context) =>
      _cycles[context] ??= _LiabilityAccounts(context);

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    cycle.listed.clear();
    await cycle.sync.pull();
    await cycle.refreshBalances();
    await context.db.repairFireflyWalletSelection();
  }

  @override
  Future<void> push(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _cycle(context).sync.push();
    await context.db.repairFireflyWalletSelection();
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _cycle(context).sync.pushDeletes();
  }
}

class _LiabilityAccounts extends CollectionAdapter<FireflyAccount> {
  _LiabilityAccounts(this.context);

  final SyncContext context;
  late final sync = CollectionSync(
    adapter: this,
    idMap: context.idMap,
    conflicts: context.conflicts,
    pageSize: context.config.pageSize,
    now: context.now,
  );
  final listed = <String, RemoteCollectionRow<FireflyAccount>>{};

  FinanceDatabase get _db => context.db;

  @override
  FireflyEntityType get type => _type;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyAccount>>> page(
      int page, int limit) async {
    final result = await context.api.accounts.list(
      type: _accountType,
      page: page,
      limit: limit,
    );
    final mapped = result.map(_remoteRow);
    for (final row in mapped.items) {
      listed[row.id] = row;
    }
    return mapped;
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async => [
        for (final wallet in await _db.fireflyLiabilities())
          await _localRow(wallet),
      ];

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final wallet = await _db.fireflyWallet(pk);
    return wallet?.accountKind == AccountKind.liability
        ? _localRow(wallet!)
        : null;
  }

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyAccount> remote) async {
    final name = (remote.fields['name']! as String).toLowerCase();
    for (final wallet in await _db.fireflyLiabilities()) {
      if (_name(wallet.name).toLowerCase() != name) continue;
      final mapping = await context.idMap.byLocal(type, wallet.walletPk);
      if (mapping == null ||
          (mapping.state != FireflySyncState.localOnly &&
              IdMapRepository.isProvisional(mapping))) {
        return wallet.walletPk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
    RemoteCollectionRow<FireflyAccount> remote, {
    String? localPk,
  }) async {
    final wallet = await _db.writeFireflyLiabilityWallet(
      remote.value,
      walletPk: localPk,
      name: remote.fields['name']! as String,
      currency: (remote.fields['currency_code'] as String?)?.toLowerCase(),
      order: remote.fields['order']! as int,
      archived: !(remote.fields['active']! as bool),
      now: context.now(),
    );
    await _db.applyFireflyAccountDetails(wallet.walletPk, remote.value);
    return _localRow(wallet);
  }

  Future<void> refreshBalances() => _db.transaction(() async {
        for (final mapping in await context.idMap.list(type)) {
          final account = listed[mapping.remoteId]?.value;
          if (account != null && mapping.state != FireflySyncState.localOnly) {
            await _db.refreshFireflyAccountBalance(mapping.localPk, account);
          }
        }
      });

  @override
  Future<void> removeLocal(String pk) => _db.removeFireflyWallet(pk);

  @override
  Future<RemoteCollectionRow<FireflyAccount>> createRemote(
      LocalCollectionRow local) async {
    final body = fireflyAccountWriteFields(local.fields);
    final currency = local.fields['currency_code'] as String? ??
        (await context.api.currencies.primary()).code;
    if (currency == null || currency.isEmpty) {
      throw const FireflyInvalidPayload();
    }
    await context.api.currencies.enable(currency);
    return _remoteRow(await context.api.accounts.create({
      ...body,
      'type': _accountType,
      'currency_code': currency,
      'interest': body['interest'] ?? '0',
    }));
  }

  @override
  Future<RemoteCollectionRow<FireflyAccount>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local) async {
    final previous = listed[mapping.remoteId] ??
        _remoteRow(await context.api.accounts.get(mapping.remoteId));
    final changed = {
      for (final entry in local.fields.entries)
        if (entry.value != previous.fields[entry.key]) entry.key: entry.value,
    };
    final body = fireflyAccountWriteFields(changed, update: true);
    if (body.isEmpty) return previous;
    if (body['currency_code'] case final String currency) {
      await context.api.currencies.enable(currency);
    }
    return _remoteRow(
        await context.api.accounts.update(mapping.remoteId, body));
  }

  @override
  Future<void> removeRemote(String id) => context.api.accounts.delete(id);

  @override
  Future<RemoteCollectionRow<FireflyAccount>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate =
        RegExp(r'already (exists|in use|been taken)', caseSensitive: false);
    if (!(error.errors['name'] ?? [error.message]).any(duplicate.hasMatch)) {
      return null;
    }
    final name = (local.fields['name']! as String).toLowerCase();
    var page = 1;
    while (true) {
      final result = await context.api.accounts.list(
        type: _accountType,
        page: page,
        limit: context.config.pageSize,
      );
      for (final account in result.items) {
        if (_name(account.name ?? '').toLowerCase() == name) {
          return _remoteRow(account);
        }
      }
      if (result.currentPage != page ||
          page >= result.totalPages ||
          result.items.isEmpty) {
        return null;
      }
      page++;
    }
  }

  Future<LocalCollectionRow> _localRow(TransactionWallet wallet) async {
    final details = await _db.fireflyAccountDetails(wallet.walletPk);
    return LocalCollectionRow(
      pk: wallet.walletPk,
      modifiedAt: fireflyAccountLocalVersion(wallet, details),
      fields: {
        'name': _name(wallet.name),
        'currency_code': _currencyCode(wallet.currency),
        'order': wallet.order,
        'active': !wallet.archived,
        ...fireflyAccountDetailFields(details, liability: true),
      },
      snapshot: {
        ...wallet.toJson(),
        'homePageWidgetDisplay': wallet.homePageWidgetDisplay
            ?.map((widget) => widget.index)
            .toList(),
        if (details != null) 'accountDetails': details.toJson(),
      },
    );
  }

  RemoteCollectionRow<FireflyAccount> _remoteRow(FireflyAccount account) {
    final name = _name(account.name ?? '');
    if (name.isEmpty ||
        (account.type != _accountType && account.type != 'liabilities')) {
      throw const FireflyInvalidPayload();
    }
    return RemoteCollectionRow(
      id: account.id,
      value: account,
      updatedAt: account.updatedAt,
      fields: {
        'name': name,
        'currency_code': _currencyCode(account.currencyCode),
        'order': math.max(0, (account.order ?? 1) - 1),
        'active': account.active ?? true,
        ...fireflyRemoteAccountDetailFields(account, liability: true),
      },
    );
  }

  String _name(String name) =>
      String.fromCharCodes(name.trim().runes.take(NAME_LIMIT)).trimRight();

  String? _currencyCode(String? currency) {
    final code = currency?.trim().toUpperCase();
    return code == null || code.isEmpty ? null : code;
  }
}

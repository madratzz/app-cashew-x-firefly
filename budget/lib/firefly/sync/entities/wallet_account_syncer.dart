import 'dart:math' as math;

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:drift/drift.dart' show Value;

const _type = FireflyEntityType.walletAccount;
const _primaryPk = '0';
const _asset = 'asset';
const _defaultRole = 'defaultAsset';

class WalletAccountSyncer extends EntitySyncer {
  const WalletAccountSyncer();

  static final _cycles = Expando<_WalletAccounts>();

  @override
  FireflyEntityType get type => _type;

  @override
  Set<FireflyEntityType> get dependsOn => const {FireflyEntityType.currency};

  _WalletAccounts _cycle(SyncContext context) =>
      _cycles[context] ??= _WalletAccounts(context);

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _cycle(context);
    cycle.beginPull();
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
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).sync.pushDeletes();
    }
  }
}

class _WalletAccounts extends CollectionAdapter<FireflyAccount> {
  _WalletAccounts(this.context);

  final SyncContext context;
  late final sync = CollectionSync(
    adapter: this,
    idMap: context.idMap,
    conflicts: context.conflicts,
    pageSize: context.config.pageSize,
    now: context.now,
  );
  final _listedAccounts = <String, RemoteCollectionRow<FireflyAccount>>{};
  FireflyAccount? _primary;

  FinanceDatabase get _db => context.db;

  @override
  FireflyEntityType get type => _type;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  void beginPull() {
    _listedAccounts.clear();
    _primary = null;
  }

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyAccount>>> page(
      int page, int limit) async {
    final result = await context.api.accounts.list(
      type: _asset,
      page: page,
      limit: limit,
    );
    for (final account in result.items) {
      if (account.type != _asset) throw const FireflyInvalidPayload();
      final primary = _primary;
      if (primary == null || _compareForPrimary(account, primary) < 0) {
        _primary = account;
      }
    }
    final mapped = result.map(_remoteRow);
    for (final row in mapped.items) {
      _listedAccounts[row.id] = row;
      await _migrateDetailsHash(row);
    }
    return mapped;
  }

  // Choose the first default asset in Firefly order, even across page boundaries.
  // Use the first asset in that order when there is no default role.
  int _compareForPrimary(FireflyAccount left, FireflyAccount right) {
    int priority(FireflyAccount account) =>
        (account.accountRole == _defaultRole ? 0 : 2) +
        (account.active == false ? 1 : 0);
    final byRole = priority(left).compareTo(priority(right));
    if (byRole != 0) return byRole;
    final byOrder = (left.order ?? 0).compareTo(right.order ?? 0);
    if (byOrder != 0) return byOrder;
    return left.id.compareTo(right.id);
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async => [
        for (final wallet in await _db.fireflyAssetWallets())
          if (!await _db.isFireflyWalletPlaceholder(wallet))
            await _localRow(wallet),
      ];

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final wallet = await _db.fireflyWallet(pk);
    return wallet?.accountKind == AccountKind.asset ? _localRow(wallet!) : null;
  }

  @override
  Future<String?> recoverLocalPk(
          RemoteCollectionRow<FireflyAccount> remote) async =>
      remote.id == _primary?.id ? _primaryPk : null;

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyAccount> remote) async {
    // Reserve the default wallet for the primary asset, even if a different
    // account appears earlier in the listing with the same name.
    final name = remote.value.name!.trim().toLowerCase();
    for (final wallet in await _db.fireflyAssetWallets()) {
      if (wallet.walletPk == _primaryPk ||
          _name(wallet.name).toLowerCase() != name) {
        continue;
      }
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
    if (localPk == null &&
        remote.id == _primary?.id &&
        await _db.fireflyWallet(_primaryPk) == null &&
        await context.idMap.byLocal(type, _primaryPk) == null) {
      localPk = _primaryPk;
    }
    final row = await _db.writeFireflyAssetWallet(
      remote.value,
      walletPk: localPk,
      name: remote.fields['name']! as String,
      currency: (remote.fields['currency_code'] as String?)?.toLowerCase(),
      order: remote.fields['order']! as int,
      archived: !(remote.fields['active']! as bool),
      now: context.now(),
    );
    await _db.applyFireflyAccountDetails(row.walletPk, remote.value);
    return _localRow(row);
  }

  // Maps from older builds hashed only the wallet columns. Rebase their
  // baseline before the new fields participate in conflict detection.
  Future<void> _migrateDetailsHash(
          RemoteCollectionRow<FireflyAccount> remote) =>
      _db.transaction(() async {
        final mapping = await context.idMap.byRemote(type, remote.id);
        if (mapping == null || mapping.state == FireflySyncState.localOnly) {
          return;
        }
        final wallet = await _db.fireflyWallet(mapping.localPk);
        if (wallet == null) return;
        final details = await _db.fireflyAccountDetails(wallet.walletPk);
        final remoteDetails =
            fireflyRemoteAccountDetailFields(remote.value, liability: false);
        final legacyRemote = Map.of(remote.fields)
          ..removeWhere((key, _) => remoteDetails.containsKey(key));
        final legacyLocal = _walletFields(wallet);
        final localWasBaseline =
            mapping.syncedHash == syncedFieldsHash(legacyLocal);
        final remoteWasBaseline =
            mapping.syncedHash == syncedFieldsHash(legacyRemote);
        if (!localWasBaseline && !remoteWasBaseline) return;

        final modifiedAt = details?.dateTimeModified;
        final syncedAt = mapping.localVersionAt;
        final detailsEdited = modifiedAt != null &&
            syncedAt != null &&
            modifiedAt.isAfter(syncedAt);
        if (!remoteWasBaseline && detailsEdited) return;
        final baseline = remoteWasBaseline ? legacyRemote : legacyLocal;
        await context.idMap.put(mapping.copyWith(
          syncedHash: Value(syncedFieldsHash({
            ...baseline,
            ...(detailsEdited || details == null
                ? remoteDetails
                : fireflyAccountDetailFields(details, liability: false)),
          })),
        ));
      });

  Future<void> refreshBalances() async {
    // Transaction changes can alter the balance without touching updated_at.
    await _db.transaction(() async {
      for (final mapping in await context.idMap.list(type)) {
        final account = _listedAccounts[mapping.remoteId]?.value;
        final wallet = await _db.fireflyWallet(mapping.localPk);
        if (account != null &&
            wallet != null &&
            mapping.state != FireflySyncState.localOnly &&
            !await _db.isFireflyWalletPlaceholder(wallet)) {
          await _db.refreshFireflyAccountBalance(mapping.localPk, account);
        }
      }
    });
  }

  @override
  Future<void> removeLocal(String pk) => _db.removeFireflyWallet(pk);

  @override
  Future<RemoteCollectionRow<FireflyAccount>> createRemote(
      LocalCollectionRow local) async {
    final currency = local.fields['currency_code'] as String? ??
        (await context.api.currencies.primary()).code;
    if (currency == null || currency.isEmpty) {
      throw const FireflyInvalidPayload();
    }
    await context.api.currencies.enable(currency);
    return _remoteRow(await context.api.accounts.create({
      ...fireflyAccountWriteFields(local.fields),
      'type': _asset,
      'currency_code': currency,
    }));
  }

  @override
  Future<RemoteCollectionRow<FireflyAccount>> updateRemote(
      FireflyIdMapping mapping, LocalCollectionRow local) async {
    final previous = _listedAccounts[mapping.remoteId] ??
        _remoteRow(await context.api.accounts.get(mapping.remoteId));
    // Preserve server precision and unrelated values on a partial update.
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

    var page = 1;
    while (true) {
      final result = await context.api.accounts.list(
        type: _asset,
        page: page,
        limit: context.config.pageSize,
      );
      for (final account in result.items) {
        final name = account.name;
        if (account.type == _asset &&
            name != null &&
            name.trim().toLowerCase() ==
                (local.fields['name']! as String).toLowerCase()) {
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

  JsonObject _walletFields(TransactionWallet wallet) => {
        'name': _name(wallet.name),
        'currency_code': _currencyCode(wallet.currency),
        'order': wallet.order,
        'active': !wallet.archived,
      };

  Future<LocalCollectionRow> _localRow(TransactionWallet wallet) async {
    final details = await _db.fireflyAccountDetails(wallet.walletPk);
    return LocalCollectionRow(
      pk: wallet.walletPk,
      modifiedAt: fireflyAccountLocalVersion(wallet, details),
      fields: {
        ..._walletFields(wallet),
        ...fireflyAccountDetailFields(details, liability: false),
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
    final name = account.name;
    if (name == null || name.trim().isEmpty) {
      throw const FireflyInvalidPayload();
    }

    return RemoteCollectionRow(
      id: account.id,
      value: account,
      updatedAt: account.updatedAt,
      fields: {
        'name': _name(name),
        'currency_code': _currencyCode(account.currencyCode),
        // Firefly orders active accounts from 1; Cashew's UI starts from 0.
        'order': math.max(0, (account.order ?? 1) - 1),
        'active': account.active ?? true,
        ...fireflyRemoteAccountDetailFields(account, liability: false),
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

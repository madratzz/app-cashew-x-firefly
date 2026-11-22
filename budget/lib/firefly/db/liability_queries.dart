import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:drift/drift.dart';

extension FireflyLiabilityQueries on FinanceDatabase {
  SimpleSelectStatement<$WalletsTable, TransactionWallet>
      _fireflyLiabilityQuery() => select(wallets)
        ..where((row) => row.accountKind.equalsValue(AccountKind.liability))
        ..orderBy([
          (row) => OrderingTerm.asc(row.order),
          (row) => OrderingTerm.asc(row.walletPk),
        ]);

  Future<List<TransactionWallet>> fireflyLiabilities() =>
      _fireflyLiabilityQuery().get();

  Stream<List<TransactionWallet>> watchFireflyLiabilities() =>
      _fireflyLiabilityQuery().watch();

  Stream<AccountDetail?> watchFireflyAccountDetails(String walletPk) =>
      (select(accountDetails)..where((row) => row.walletFk.equals(walletPk)))
          .watchSingleOrNull();

  /// Wallets without an explicit Firefly exclusion keep their legacy default.
  /// Callers can intersect these keys with the user's selected wallets.
  Stream<List<String>> watchFireflyNetWorthWalletPks() {
    final query = selectOnly(wallets).join([
      leftOuterJoin(
        accountDetails,
        accountDetails.walletFk.equalsExp(wallets.walletPk),
        useColumns: false,
      ),
    ])
      ..addColumns([wallets.walletPk])
      ..where(accountDetails.includeNetWorth.equals(true) |
          accountDetails.includeNetWorth.isNull());
    return query.watch().map(
          (rows) => rows.map((row) => row.read(wallets.walletPk)!).toList(),
        );
  }

  /// Saves a partial edit for an existing asset or liability.
  /// An absent field is preserved. Value(null) clears an optional field.
  Future<void> saveFireflyAccountDetails(
    String walletPk,
    AccountDetailsCompanion changes, {
    DateTime? modifiedAt,
  }) =>
      transaction(() async {
        final wallet = await fireflyWallet(walletPk);
        if (wallet == null || wallet.accountKind == AccountKind.cash) {
          throw ArgumentError.value(walletPk, 'walletPk');
        }
        final stamp = await _fireflyAccountEditTime(wallet, modifiedAt);
        await _saveFireflyAccountDetails(wallet, changes, stamp);
        // The existing auto-sync watcher observes wallet edits.
        await (update(wallets)..where((row) => row.walletPk.equals(walletPk)))
            .write(WalletsCompanion(dateTimeModified: Value(stamp)));
      });

  /// Creates or edits a liability and saves its account details atomically.
  /// Set [walletPk] to edit an existing liability. Firefly accepts nonzero
  /// virtual balances only after the liability has been created remotely.
  Future<TransactionWallet> saveFireflyLiability({
    String? walletPk,
    required String name,
    required String currency,
    required int decimals,
    required int order,
    bool archived = false,
    AccountDetailsCompanion details = const AccountDetailsCompanion(),
    DateTime? modifiedAt,
  }) =>
      transaction(() async {
        final existing =
            walletPk == null ? null : await fireflyWallet(walletPk);
        if (walletPk != null &&
            existing?.accountKind != AccountKind.liability) {
          throw ArgumentError.value(walletPk, 'walletPk');
        }
        final cleanName = name.trim();
        final cleanCurrency = currency.trim().toLowerCase();
        if (cleanName.isEmpty) throw ArgumentError.value(name, 'name');
        if (cleanCurrency.isEmpty) {
          throw ArgumentError.value(currency, 'currency');
        }

        final stamp = await _fireflyAccountEditTime(existing, modifiedAt);
        final fields = WalletsCompanion(
          name: Value(cleanName),
          currency: Value(cleanCurrency),
          decimals: Value(decimals),
          order: Value(order),
          archived: Value(archived),
          accountKind: const Value(AccountKind.liability),
          dateTimeModified: Value(stamp),
        );
        final wallet = await into(wallets).insertReturning(
          fields.copyWith(
            walletPk: walletPk == null ? const Value.absent() : Value(walletPk),
            dateCreated: Value(existing?.dateCreated ?? stamp),
          ),
          onConflict: DoUpdate((_) => fields),
        );
        await _saveFireflyAccountDetails(wallet, details, stamp);
        return wallet;
      });

  Future<DateTime> _fireflyAccountEditTime(
    TransactionWallet? wallet,
    DateTime? modifiedAt,
  ) async {
    final now = modifiedAt ?? DateTime.now();
    if (wallet == null) return now;
    final type = wallet.accountKind == AccountKind.liability
        ? FireflyEntityType.liabilityAccount
        : FireflyEntityType.walletAccount;
    final mapping = await IdMapRepository(this).byLocal(type, wallet.walletPk);
    final details = await fireflyAccountDetails(wallet.walletPk);
    var second = now.millisecondsSinceEpoch ~/ 1000;
    for (final previous in [
      mapping?.localVersionAt,
      wallet.dateTimeModified,
      details?.dateTimeModified,
    ]) {
      if (previous == null) continue;
      final previousSecond = previous.millisecondsSinceEpoch ~/ 1000;
      if (second <= previousSecond) second = previousSecond + 1;
    }
    return DateTime.fromMillisecondsSinceEpoch(second * 1000);
  }

  Future<void> _saveFireflyAccountDetails(
    TransactionWallet wallet,
    AccountDetailsCompanion changes,
    DateTime stamp,
  ) async {
    final liability = wallet.accountKind == AccountKind.liability;
    final virtualBalance = changes.virtualBalance;
    if (liability &&
        virtualBalance.present &&
        (virtualBalance.value ?? 0) != 0) {
      final mapping = await IdMapRepository(this)
          .byLocal(FireflyEntityType.liabilityAccount, wallet.walletPk);
      // Firefly drops a liability's virtual balance on POST but accepts it on PUT.
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        throw ArgumentError.value(virtualBalance.value, 'virtualBalance');
      }
    }
    final fields = AccountDetailsCompanion(
      accountRole: liability ? const Value.absent() : changes.accountRole,
      liabilityType: liability ? changes.liabilityType : const Value.absent(),
      liabilityDirection:
          liability ? changes.liabilityDirection : const Value.absent(),
      interest: liability ? changes.interest : const Value.absent(),
      interestPeriod: liability ? changes.interestPeriod : const Value.absent(),
      iban: changes.iban,
      bic: changes.bic,
      accountNumber: changes.accountNumber,
      notes: changes.notes,
      includeNetWorth: changes.includeNetWorth,
      virtualBalance: virtualBalance,
      dateTimeModified: Value(stamp),
    );
    await into(accountDetails).insert(
      fields.copyWith(walletFk: Value(wallet.walletPk)),
      onConflict: DoUpdate((_) => fields),
    );
  }

  Future<TransactionWallet> writeFireflyLiabilityWallet(
    FireflyAccount account, {
    required String name,
    required String? currency,
    required int order,
    required bool archived,
    required DateTime now,
    String? walletPk,
  }) async {
    final existing = walletPk == null ? null : await fireflyWallet(walletPk);
    final fields = WalletsCompanion(
      name: Value(name),
      currency: Value(currency),
      decimals: Value(account.currencyDecimalPlaces ?? existing?.decimals ?? 2),
      order: Value(order),
      archived: Value(archived),
      accountKind: const Value(AccountKind.liability),
      dateTimeModified: Value(account.updatedAt),
    );
    return into(wallets).insertReturning(
      fields.copyWith(
        walletPk: walletPk == null ? const Value.absent() : Value(walletPk),
        dateCreated: Value(account.createdAt ?? existing?.dateCreated ?? now),
      ),
      onConflict: DoUpdate((_) => fields),
    );
  }

  Future<void> applyFireflyAccountDetails(
      String walletPk, FireflyAccount account) async {
    final incoming = _remoteDetails(walletPk, account);
    if (incoming == await fireflyAccountDetails(walletPk)) return;
    // A complete account response also clears fields omitted by Firefly.
    await into(accountDetails)
        .insertOnConflictUpdate(incoming.toCompanion(false));
  }

  /// Balances can change without an account edit or a new account timestamp.
  Future<void> refreshFireflyAccountBalance(
      String walletPk, FireflyAccount account) async {
    final balance = account.currentBalance;
    final date = account.currentBalanceDate;
    final existing = await fireflyAccountDetails(walletPk);
    if (existing == null) {
      if (await fireflyWallet(walletPk) != null) {
        await applyFireflyAccountDetails(walletPk, account);
      }
      return;
    }
    if (balance == existing.serverBalance &&
        date == existing.serverBalanceDate) {
      return;
    }
    await (update(accountDetails)
          ..where((row) => row.walletFk.equals(walletPk)))
        .write(AccountDetailsCompanion(
      serverBalance: Value(balance),
      serverBalanceDate: Value(date),
    ));
  }
}

DateTime? fireflyAccountLocalVersion(
    TransactionWallet wallet, AccountDetail? details) {
  final walletVersion = wallet.dateTimeModified;
  final detailVersion = details?.dateTimeModified;
  return detailVersion != null &&
          (walletVersion == null || detailVersion.isAfter(walletVersion))
      ? detailVersion
      : walletVersion;
}

/// Writable Firefly fields form the same canonical map on both sides.
/// Account fields Firefly rewrites by itself: it renumbers `order` when
/// accounts or their transactions change, advancing `updated_at` without a
/// client edit. Such a rewrite must not win over a local edit or delete.
const fireflyAccountServerOwned = {'order'};

JsonObject fireflyAccountDetailFields(
  AccountDetail? details, {
  required bool liability,
}) {
  final virtualBalance = details?.virtualBalance;
  return {
    if (liability) ...{
      'liability_type': _text(details?.liabilityType)?.toLowerCase(),
      'liability_direction': _text(details?.liabilityDirection)?.toLowerCase(),
      'interest': _decimal(details?.interest),
      'interest_period': _text(details?.interestPeriod)?.toLowerCase(),
    } else ...{
      'account_role': _text(details?.accountRole) ?? 'defaultAsset',
    },
    'virtual_balance': virtualBalance == 0 ? null : _decimal(virtualBalance),
    'iban': _text(details?.iban?.replaceAll(RegExp(r'\s+'), '')),
    'bic': _text(details?.bic),
    'account_number': _text(details?.accountNumber),
    'notes': _text(details?.notes),
    // Firefly creates accounts with inclusion enabled by default.
    'include_net_worth': details?.includeNetWorth == false ? false : null,
  };
}

JsonObject fireflyRemoteAccountDetailFields(
  FireflyAccount account, {
  required bool liability,
}) =>
    fireflyAccountDetailFields(_remoteDetails('', account),
        liability: liability);

AccountDetail _remoteDetails(String walletPk, FireflyAccount account) =>
    AccountDetail(
      walletFk: walletPk,
      accountRole: account.accountRole,
      liabilityType: account.liabilityType,
      liabilityDirection: account.liabilityDirection,
      interest: account.interest,
      interestPeriod: account.interestPeriod,
      iban: account.iban,
      bic: account.bic,
      accountNumber: account.accountNumber,
      notes: account.notes,
      includeNetWorth: account.includeNetWorth,
      virtualBalance: account.virtualBalance,
      serverBalance: account.currentBalance,
      serverBalanceDate: account.currentBalanceDate,
      dateTimeModified: account.updatedAt,
    );

/// Uses clear values accepted by Firefly's update validator and converter.
JsonObject fireflyAccountWriteFields(JsonObject fields, {bool update = false}) {
  final result = <String, Object?>{};
  for (final entry in fields.entries) {
    if (entry.value != null) {
      result[entry.key] = entry.value;
    } else if (update) {
      switch (entry.key) {
        case 'iban':
        case 'bic':
        case 'account_number':
        case 'notes':
          result[entry.key] = '';
        case 'interest':
        case 'virtual_balance':
          result[entry.key] = '0';
        case 'include_net_worth':
          result[entry.key] = true;
      }
    }
  }
  if (result['order'] case final int order) result['order'] = order + 1;
  return result;
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

String? _decimal(double? value) {
  if (value == null) return null;
  final unsigned = formatFireflyAmount(value, 12);
  final normalized = unsigned.replaceFirst(RegExp(r'\.?0+$'), '');
  return value < 0 && normalized != '0' ? '-$normalized' : normalized;
}

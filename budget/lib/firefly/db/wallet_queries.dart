import 'package:budget/database/initializeDefaultDatabase.dart'
    show defaultWallet;
import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/walletEntry.dart' show setPrimaryWallet;
import 'package:drift/drift.dart';

const _placeholderKey = 'wallet.emptyPlaceholder';

extension FireflyWalletQueries on FinanceDatabase {
  Future<TransactionWallet?> fireflyWallet(String pk) =>
      getWalletInstanceOrNull(pk);

  Future<AccountDetail?> fireflyAccountDetails(String walletPk) =>
      (select(accountDetails)..where((row) => row.walletFk.equals(walletPk)))
          .getSingleOrNull();

  Future<List<TransactionWallet>> fireflyAssetWallets() => (select(wallets)
        ..where((row) => row.accountKind.equalsValue(AccountKind.asset))
        ..orderBy([
          (row) => OrderingTerm.asc(row.order),
          (row) => OrderingTerm.asc(row.walletPk),
        ]))
      .get();

  Future<TransactionWallet> writeFireflyAssetWallet(
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
      order: Value(order),
      currency: Value(currency),
      decimals: Value(account.currencyDecimalPlaces ?? existing?.decimals ?? 2),
      dateCreated: Value(account.createdAt ?? existing?.dateCreated ?? now),
      dateTimeModified: Value(account.updatedAt),
      archived: Value(archived),
    );
    if (walletPk == '0') {
      await SyncMetaRepository(this).remove(_placeholderKey);
    }
    return into(wallets).insertReturning(
      fields.copyWith(
        walletPk: walletPk == null ? const Value.absent() : Value(walletPk),
        homePageWidgetDisplay: Value(defaultWalletHomePageWidgetDisplay),
      ),
      onConflict: DoUpdate((_) => fields),
    );
  }

  Future<void> refreshFireflyAccountDetails(
      String walletPk, FireflyAccount account) async {
    final details = AccountDetail(
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
    if (details != await fireflyAccountDetails(walletPk)) {
      await into(accountDetails).insertOnConflictUpdate(details);
    }
  }

  /// Deletes a wallet from Cashew and records the single remote delete intent.
  /// Firefly deletes the account's transactions as part of deleting the account.
  Future<void> deleteWalletLocally(String walletPk) async {
    await transaction(() async {
      if (await fireflyWallet(walletPk) == null) return;
      await removeFireflyWallet(walletPk);
      await createDeleteLog(DeleteLogType.TransactionWallet, walletPk);
    });
    await repairFireflyWalletSelection();
  }

  /// Removes a wallet during reconciliation without enqueuing a remote delete.
  /// The caller runs this in its transaction with the mapping.
  Future<void> removeFireflyWallet(String walletPk) async {
    final transactionPks = selectOnly(transactions)
      ..addColumns([transactions.transactionPk])
      ..where(transactions.walletFk.equals(walletPk));
    await (update(transactions)
          ..where((row) => row.pairedTransactionFk.isInQuery(transactionPks)))
        .write(const TransactionsCompanion(pairedTransactionFk: Value(null)));
    await (delete(transactions)..where((row) => row.walletFk.equals(walletPk)))
        .go();
    await (delete(accountDetails)
          ..where((row) => row.walletFk.equals(walletPk)))
        .go();

    var fallback = await _fireflyWalletFallback(excluding: walletPk);
    if (fallback == null) {
      // Cashew needs wallet zero even when Firefly has no asset accounts left.
      fallback = defaultWallet().copyWith(
        dateTimeModified: Value(DateTime.fromMillisecondsSinceEpoch(0)),
      );
      await into(wallets).insertOnConflictUpdate(fallback);
      await SyncMetaRepository(this).write(_placeholderKey, fallback.walletPk);
    }
    if (fallback.walletPk == walletPk) return;

    // Keep local budgets, goals and scanner rules usable after wallet removal.
    final replacement = Value(fallback.walletPk);
    await (update(budgets)..where((row) => row.walletFk.equals(walletPk)))
        .write(BudgetsCompanion(walletFk: replacement));
    await (update(objectives)..where((row) => row.walletFk.equals(walletPk)))
        .write(ObjectivesCompanion(walletFk: replacement));
    await (update(scannerTemplates)
          ..where((row) => row.walletFk.equals(walletPk)))
        .write(ScannerTemplatesCompanion(walletFk: replacement));
    await (update(categoryBudgetLimits)
          ..where((row) => row.walletFk.equals(walletPk)))
        .write(CategoryBudgetLimitsCompanion(walletFk: replacement));
    await (delete(wallets)..where((row) => row.walletPk.equals(walletPk))).go();
  }

  Future<bool> isFireflyWalletPlaceholder(TransactionWallet wallet) async =>
      wallet.dateTimeModified?.millisecondsSinceEpoch == 0 &&
      await SyncMetaRepository(this).read(_placeholderKey) == wallet.walletPk;

  Future<void> repairFireflyWalletSelection() async {
    final selected = appStateSettings['selectedWalletPk'] as String? ?? '0';
    if (await fireflyWallet(selected) != null) return;

    final fallback = await _fireflyWalletFallback();
    final replacement = fallback?.walletPk ?? '0';
    if (replacement != selected) await setPrimaryWallet(replacement);
  }

  Future<TransactionWallet?> _fireflyWalletFallback({String? excluding}) =>
      (select(wallets)
            ..where((row) => excluding == null
                ? const Constant(true)
                : row.walletPk.equals(excluding).not())
            ..orderBy([
              (row) => OrderingTerm.asc(row.archived),
              (row) => OrderingTerm.desc(row.walletPk.equals('0')),
              (row) => OrderingTerm.asc(row.order),
              (row) => OrderingTerm.asc(row.walletPk),
            ])
            ..limit(1))
          .getSingleOrNull();
}

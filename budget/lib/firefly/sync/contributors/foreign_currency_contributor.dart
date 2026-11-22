import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart' show Value;

class ForeignCurrencyContributor extends TransactionContributor {
  const ForeignCurrencyContributor();

  @override
  String get id => 'foreignCurrency';

  @override
  int get version => 1;

  @override
  Future<Transaction> projectRemote(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Transaction row,
  ) async {
    if (!context.config.mode || context.isCancelled()) return row;
    // A mixed asset and liability withdrawal or deposit is projected as a
    // local transfer pair whose rows already carry their own amounts.
    final eligible = (split.type == 'withdrawal' || split.type == 'deposit') &&
        row.fireflyType != FireflyTransactionType.transfer;
    final code = eligible ? split.foreignCurrencyCode?.trim() : null;
    final amount = eligible ? split.foreignAmount?.abs() : null;
    final hasForeign =
        code != null && code.isNotEmpty && amount != null && amount > 0;
    return row.copyWith(
      foreignCurrency: Value(hasForeign ? code.toLowerCase() : null),
      foreignAmount: Value(hasForeign ? amount : null),
    );
  }

  @override
  Future<void> push(
    SyncContext context,
    Transaction transaction,
    JsonObject split,
  ) async {
    final kind = transaction.fireflyType;
    // Cross-currency transfers use the amounts of their paired wallet rows.
    if (!context.config.mode ||
        context.isCancelled() ||
        transaction.pairedTransactionFk != null ||
        (kind != null &&
            kind != FireflyTransactionType.withdrawal &&
            kind != FireflyTransactionType.deposit)) {
      return;
    }

    final code = transaction.foreignCurrency?.trim().toUpperCase();
    final amount = transaction.foreignAmount?.abs();
    if (code != null &&
        code.isNotEmpty &&
        amount != null &&
        amount.isFinite &&
        amount > 0) {
      final cached = await context.db.fireflyCurrency(code);
      final decimals = cached == null
          ? null
          : ResourceCacheRepository.decode(cached)['decimal_places'] as int?;
      final value = formatFireflyAmount(amount, (decimals ?? 12).clamp(0, 20));
      if (parseFireflyAmount(value) > 0) {
        split['foreign_amount'] = value;
        split['foreign_currency_code'] = code;
        return;
      }
    }

    // The hash map starts empty. The writable split already has its base
    // amount. Firefly 6.6.2 clears foreign fields on the exact string "0".
    if (split.containsKey('amount')) split['foreign_amount'] = '0';
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart';

class BudgetContributor extends TransactionContributor {
  const BudgetContributor();

  @override
  String get id => 'budget';

  @override
  int get version => 1;

  @override
  Future<Transaction> projectRemote(
      SyncContext context,
      FireflyTransaction group,
      FireflyTransactionSplit split,
      Transaction row) async {
    // Legacy references on non-withdrawals are outside the Firefly budget model.
    if (split.type != 'withdrawal') return row;
    final budgetId = split.budgetId;
    final mapping = budgetId == null
        ? null
        : await context.idMap.byRemote(FireflyEntityType.budget, budgetId);
    return row.copyWith(
      sharedReferenceBudgetPk:
          Value(_usable(mapping) ? mapping!.localPk : null),
    );
  }

  @override
  Future<void> push(
      SyncContext context, Transaction transaction, JsonObject split) async {
    final withdrawal = !transaction.income &&
        switch (transaction.fireflyType) {
          null => transaction.categoryFk != '0',
          FireflyTransactionType.withdrawal ||
          FireflyTransactionType.deposit =>
            true,
          _ => false,
        };
    if (!withdrawal) return;
    final pk = transaction.sharedReferenceBudgetPk;
    if (pk == null) {
      // The transaction adapter supplies a date in write payloads. Omit null
      // in hash projections so unassigned journals keep their existing hash.
      if (split.containsKey('date')) split['budget_id'] = null;
      return;
    }
    final mapping = await context.idMap.byLocal(FireflyEntityType.budget, pk);
    if (_usable(mapping)) split['budget_id'] = mapping!.remoteId;
  }

  bool _usable(FireflyIdMapping? mapping) =>
      mapping != null &&
      !IdMapRepository.isProvisional(mapping) &&
      mapping.state != FireflySyncState.pendingDelete &&
      mapping.state != FireflySyncState.localOnly;
}

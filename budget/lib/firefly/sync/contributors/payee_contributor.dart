import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart' show Value;

const _type = FireflyEntityType.payeeAccount;

class PayeeContributor extends TransactionContributor {
  const PayeeContributor();

  @override
  String get id => 'payee';

  @override
  int get version => 1;

  @override
  Future<Transaction> projectRemote(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Transaction row,
  ) async {
    final kind = switch (split.type) {
      'withdrawal' => PayeeKind.expense,
      'deposit' => PayeeKind.revenue,
      _ => null,
    };
    final remoteId = _counterpartId(kind, split);
    final mapping =
        remoteId == null ? null : await context.idMap.byRemote(_type, remoteId);
    final payee = _usable(mapping)
        ? await context.db.fireflyPayee(mapping!.localPk)
        : null;
    return row.copyWith(
      payeeFk:
          Value(payee != null && payee.kind == kind ? payee.payeePk : null),
    );
  }

  @override
  Future<void> push(
      SyncContext context, Transaction transaction, JsonObject split) async {
    final kind = _localKind(transaction);
    final pk = transaction.payeeFk;
    if (kind == null || pk == null) return;
    final payee = await context.db.fireflyPayee(pk);
    if (payee?.kind != kind) return;
    final mapping = await context.idMap.byLocal(_type, pk);
    if (_usable(mapping)) split[_idField(kind)] = mapping!.remoteId;
  }

  @override
  Future<bool> pushSplitWrite(
    SyncContext context,
    Transaction row,
    JsonObject fields, {
    FireflyTransactionSplit? prior,
  }) async {
    final kind = _localKind(row);
    if (kind == null) return true;

    final field = _idField(kind);
    if (row.payeeFk != null) {
      await push(context, row, fields);
      return fields[field] != null;
    }

    final priorId = _counterpartId(kind, prior);
    if (priorId != null) {
      final mapping = await context.idMap.byRemote(_type, priorId);
      final payee = _usable(mapping)
          ? await context.db.fireflyPayee(mapping!.localPk)
          : null;
      if (payee?.kind == kind) {
        // An explicit null switches a prior payee to Firefly's cash account.
        fields[field] = null;
      }
    }
    return true;
  }

  PayeeKind? _localKind(Transaction row) {
    if (row.pairedTransactionFk != null) return null;
    return switch (row.fireflyType) {
      null when row.categoryFk == '0' => null,
      null ||
      FireflyTransactionType.withdrawal ||
      FireflyTransactionType.deposit =>
        row.income ? PayeeKind.revenue : PayeeKind.expense,
      _ => null,
    };
  }

  String _idField(PayeeKind kind) =>
      kind == PayeeKind.expense ? 'destination_id' : 'source_id';

  String? _counterpartId(PayeeKind? kind, FireflyTransactionSplit? split) =>
      switch (kind) {
        PayeeKind.expense => split?.destinationId,
        PayeeKind.revenue => split?.sourceId,
        null => null,
      };

  bool _usable(FireflyIdMapping? mapping) =>
      mapping != null &&
      !IdMapRepository.isProvisional(mapping) &&
      mapping.state != FireflySyncState.pendingDelete &&
      mapping.state != FireflySyncState.localOnly;
}

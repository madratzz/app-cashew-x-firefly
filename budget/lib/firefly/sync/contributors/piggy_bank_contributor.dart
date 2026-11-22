import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:drift/drift.dart' show Value;

class PiggyBankContributor extends TransactionContributor {
  const PiggyBankContributor();

  static final _links = Expando<Future<Map<String, PiggyBankJournalLink>>>();

  @override
  String get id => 'piggyBank';

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
    final links =
        await (_links[context] ??= context.db.fireflyPiggyBankJournalLinks());
    final link = links[split.journalId];
    String? objectivePk;
    if (link != null && (link.groupId == null || link.groupId == group.id)) {
      objectivePk = link.objectivePk;
    } else {
      final bankId = split.piggyBankId;
      if (bankId != null) {
        final mapping =
            await context.idMap.byRemote(FireflyEntityType.piggyBank, bankId);
        if (mapping != null &&
            await context.db.fireflyPiggyBankMapping(mapping.localPk) != null) {
          objectivePk = mapping.localPk;
        }
      }
    }
    return row.copyWith(objectiveFk: Value(objectivePk));
  }

  @override
  Future<void> push(
    SyncContext context,
    Transaction transaction,
    JsonObject split,
  ) async {
    final objectivePk = transaction.objectiveFk;
    // Firefly accepts this field when creating transfers. Event-derived
    // links must not become transaction updates or dirty the hash.
    if (!context.config.mode ||
        context.isCancelled() ||
        split['type'] != 'transfer' ||
        objectivePk == null) {
      return;
    }
    final mapping = await context.idMap
        .byLocal(FireflyEntityType.transaction, transaction.transactionPk);
    if (mapping != null && !IdMapRepository.isProvisional(mapping)) return;
    final bank = await context.db.fireflyPiggyBankMapping(objectivePk);
    if (bank != null) split['piggy_bank_id'] = bank.remoteId;
  }
}

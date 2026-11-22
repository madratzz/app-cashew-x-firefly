import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

extension FireflySplitQueries on FinanceDatabase {
  /// Returns all local rows in journal order, including both sides of a pair.
  Future<List<Transaction>> fireflyGroupSplits(String groupPk) =>
      (select(transactions)
            ..where((row) => row.splitGroupFk.equals(groupPk))
            ..orderBy([
              (row) => OrderingTerm.asc(row.splitOrder.isNull()),
              (row) => OrderingTerm.asc(row.splitOrder),
              (row) => OrderingTerm.asc(row.transactionPk),
            ]))
          .get();

  Future<String?> fireflyGroupTitle(String groupPk) async =>
      (await fireflyTransactionGroup(groupPk))?.title;

  /// Saves the complete ordered draft. A nonempty draft includes the saved
  /// transaction under its real PK (or '-1' for the unsaved form row).
  /// Give each additional new row a fresh PK.
  ///
  /// An empty draft keeps the saved transaction and collapses its group.
  /// An explicit one-journal draft also collapses the group, applying the
  /// draft's description, amount and category to the surviving row.
  Future<void> persistFireflyGroupDraft(
    String transactionPk,
    List<Transaction> splits,
    String? title,
  ) =>
      transaction(() async {
        final anchor = await fireflyTransaction(transactionPk);
        if (anchor == null) {
          if (splits.isEmpty) return;
          throw ArgumentError('Save the transaction before its split draft.');
        }
        final inputs = [
          for (final row in splits)
            row.transactionPk == '-1'
                ? row.copyWith(transactionPk: transactionPk)
                : row,
        ];
        final oldGroupPk =
            anchor.splitGroupFk ?? await _detachedSplitGroupPk(anchor, inputs);
        final existing = oldGroupPk == null
            ? [anchor]
            : [
                ...await fireflyGroupSplits(oldGroupPk),
                if (anchor.splitGroupFk == null) anchor,
              ];
        if (oldGroupPk == null && anchor.pairedTransactionFk != null) {
          final partner = await fireflyTransaction(anchor.pairedTransactionFk!);
          if (partner != null) existing.add(partner);
        }
        final stored = {for (final row in existing) row.transactionPk: row};
        final draft = inputs.isEmpty
            ? [
                anchor,
                if (anchor.pairedTransactionFk case final partnerPk?)
                  if (stored[partnerPk] case final partner?) partner,
              ]
            : inputs;
        final byPk = {for (final row in draft) row.transactionPk: row};
        if (byPk.length != draft.length || !byPk.containsKey(transactionPk)) {
          throw ArgumentError('The draft must contain the saved transaction '
              'and unique transaction keys.');
        }

        final orders = <String, int>{};
        var journalCount = 0;
        for (final row in draft) {
          final pk = row.transactionPk;
          final persisted = stored[pk];
          if (persisted == null && await fireflyTransaction(pk) != null) {
            throw ArgumentError(
                'A split already belongs to another transaction.');
          }
          final partner = row.pairedTransactionFk;
          if (partner != null &&
              (partner == pk ||
                  byPk[partner]?.pairedTransactionFk != pk ||
                  persisted?.pairedTransactionFk != partner)) {
            throw ArgumentError('Keep or remove both rows of a transfer.');
          }
          if (persisted?.pairedTransactionFk != partner) {
            throw ArgumentError('The draft cannot change a transfer pair.');
          }
          if (!row.amount.isFinite) {
            throw ArgumentError('A split amount must be finite.');
          }
          if (!orders.containsKey(pk)) {
            orders[pk] = journalCount;
            if (partner != null) orders[partner] = journalCount;
            journalCount++;
          }
        }

        final now = DateTime.now();
        final groupPk =
            journalCount > 1 ? oldGroupPk ?? const Uuid().v4() : null;
        var titleChanged = false;
        if (groupPk != null) {
          final trimmed = title?.trim();
          final normalized = trimmed == '' ? null : trimmed;
          if (normalized != null && normalized.runes.length > 1000) {
            throw ArgumentError(
                'A split group title has at most 1000 characters.');
          }
          final previous = await fireflyTransactionGroup(groupPk);
          if (previous == null || previous.title != normalized) {
            titleChanged = true;
            await into(transactionGroups).insertOnConflictUpdate(
              TransactionGroup(
                groupPk: groupPk,
                title: normalized,
                dateTimeModified: now,
              ).toCompanion(false),
            );
          }
        }

        final oldOrder = [
          for (final row in existing)
            if (byPk.containsKey(row.transactionPk)) row.transactionPk,
        ];
        final keepOrder = oldGroupPk != null &&
            anchor.splitGroupFk != null &&
            oldOrder.length == draft.length &&
            Iterable<int>.generate(draft.length).every(
                (index) => draft[index].transactionPk == oldOrder[index]);
        for (final input in draft) {
          final pk = input.transactionPk;
          final previous = stored[pk];
          final row = (previous ?? input).copyWith(
            name: input.name.trim(),
            amount: (previous ?? input).income
                ? input.amount.abs()
                : -input.amount.abs(),
            categoryFk: input.categoryFk,
            subCategoryFk: Value(input.subCategoryFk),
            splitGroupFk: Value(groupPk),
            splitOrder: Value(groupPk == null
                ? null
                : keepOrder
                    ? previous?.splitOrder
                    : orders[pk]),
          );
          // The legacy auto-sync watcher observes transactions.
          if (row != previous || (titleChanged && pk == transactionPk)) {
            await into(transactions).insertOnConflictUpdate(
              row.copyWith(dateTimeModified: Value(now)).toCompanion(false),
            );
          }
        }

        await _deleteSplitRows(
            stored.keys.where((pk) => !byPk.containsKey(pk)));
        if (oldGroupPk != null && groupPk == null) {
          await _deleteUnmappedSplitGroup(oldGroupPk);
        }
      });

  Future<String?> _detachedSplitGroupPk(
      Transaction anchor, List<Transaction> draft) async {
    final idMap = IdMapRepository(this);
    final mapping = await idMap.byLocal(
        FireflyEntityType.transaction, anchor.transactionPk);
    if (mapping != null && !IdMapRepository.isProvisional(mapping)) {
      final group = await idMap.byRemote(
          FireflyEntityType.transactionGroup, mapping.remoteId);
      if (group != null) return group.localPk;
    }
    // The legacy form reconstructs the saved anchor before persisting its
    // draft. An offline draft still carries its original group on that row.
    for (final row in draft) {
      final groupPk = row.splitGroupFk;
      if (row.transactionPk == anchor.transactionPk &&
          groupPk != null &&
          await fireflyTransactionGroup(groupPk) != null) {
        return groupPk;
      }
    }
    return null;
  }

  /// Deletes a complete group and queues the mapped journals for sync.
  Future<void> deleteFireflyGroup(String groupPk) => transaction(() async {
        await _deleteSplitRows(
          (await fireflyGroupSplits(groupPk)).map((row) => row.transactionPk),
        );
        await _deleteUnmappedSplitGroup(groupPk);
      });

  Future<void> _deleteSplitRows(Iterable<String> keys) async {
    final pks = keys.toList();
    if (pks.isEmpty) return;
    final idMap = IdMapRepository(this);
    for (final pk in pks) {
      if (!await idMap.markPendingDelete(FireflyEntityType.transaction, pk)) {
        await idMap.remove(FireflyEntityType.transaction, pk);
      }
    }
    await removeFireflyTransactions(pks);
  }

  Future<void> _deleteUnmappedSplitGroup(String groupPk) async {
    // The syncer needs the mapped group until it confirms the remote deletion
    // or the surviving journal's conversion back to a single transaction.
    if (await IdMapRepository(this)
            .byLocal(FireflyEntityType.transactionGroup, groupPk) ==
        null) {
      await (delete(transactionGroups)
            ..where((row) => row.groupPk.equals(groupPk)))
          .go();
    }
  }
}

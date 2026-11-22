import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/conflict_policy.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:drift/drift.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';

const _transaction = FireflyEntityType.transaction;
const _group = FireflyEntityType.transactionGroup;
const _single = 0;
const _source = 1;
const _destination = 2;
const _initialTotal = 'transactionPage.total';
const _searchUnavailable = 'transactionSearchUnavailable';

class TransactionSyncer extends EntitySyncer {
  const TransactionSyncer();

  @override
  FireflyEntityType get type => _transaction;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.currency,
        FireflyEntityType.walletAccount,
        FireflyEntityType.liabilityAccount,
        FireflyEntityType.payeeAccount,
        FireflyEntityType.category,
        FireflyEntityType.tag,
        FireflyEntityType.budget,
        FireflyEntityType.bill,
        FireflyEntityType.piggyBank,
      };

  @override
  Future<void> pull(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _TransactionCycle(context).pull();
  }

  @override
  Future<void> push(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _TransactionCycle(context).push();
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    await _TransactionCycle(context).pushDeletes();
  }

  @override
  Future<void> rereadPushed(SyncContext context) async {
    if (!context.config.mode || context.isCancelled()) return;
    final cycle = _TransactionCycle(context);
    for (final id in context.pushedTransactionIds.toList()) {
      if (context.isCancelled()) return;
      await cycle.fetchGroup(id, preserveDirty: true);
      context.pushedTransactionIds.remove(id);
    }
  }
}

class _TransactionCycle {
  _TransactionCycle(this.context);

  final SyncContext context;

  FinanceDatabase get db => context.db;
  IdMapRepository get idMap => context.idMap;
  SyncMetaRepository get meta => context.meta;
  bool get cancelled => context.isCancelled();
  int get pageSize => context.config.pageSize;

  Future<void> pull() async {
    final lastFull = await meta.readDate(SyncMetaRepository.lastFullReconcile);
    final cursor = await meta.readDate(SyncMetaRepository.transactionCursor);
    final now = context.now();
    final initial = context.pullMode == SyncPullMode.initial ||
        (context.pullMode == SyncPullMode.incremental && cursor == null);
    if (initial) {
      await _pullInitial();
      return;
    }

    final searchUnavailable = await meta.read(_searchUnavailable) != null;
    final interval = Duration(days: searchUnavailable ? 1 : 7);
    if (context.pullMode == SyncPullMode.full ||
        await _hasUnconfirmedCreate() ||
        (lastFull != null && now.difference(lastFull) >= interval)) {
      await _fullReconcile();
      return;
    }

    if (!searchUnavailable && cursor != null) {
      final from = formatFireflyDate(cursor.subtract(const Duration(days: 1)));
      try {
        final searched =
            await _pullPages((page) => context.api.search.transactions(
                  'updated_at_after:$from',
                  page: page,
                  limit: pageSize,
                ));
        if (searched == null && !cancelled) throw const FireflyInvalidPayload();
      } on FireflyException catch (error) {
        final unsupported = error is FireflyValidation ||
            error is FireflyNotFound ||
            (error is FireflyUnexpectedResponse && error.statusCode == 400);
        if (!unsupported) rethrow;
        await meta.write(_searchUnavailable, 'true');
        if (lastFull == null ||
            now.difference(lastFull) >= const Duration(days: 1)) {
          await _fullReconcile();
          return;
        }
      }
    }

    final today = now.toLocal();
    final start = DateTime(
      today.year,
      today.month,
      today.day - context.config.transactionWindowDays,
    );
    final end = DateTime(today.year, today.month, today.day + 366);
    final seen = await _pullPages((page) => context.api.transactions.list(
          page: page,
          limit: pageSize,
          start: start,
          end: end,
        ));
    if (cancelled) return;
    if (seen == null) throw const FireflyInvalidPayload();

    for (final id in await _missingGroups(seen, start: start, end: end)) {
      if (cancelled) return;
      // Editing a transaction can move it out of the date window.
      await fetchGroup(id);
    }
  }

  Future<bool> _hasUnconfirmedCreate() async {
    final mappings = await idMap.list(_transaction);
    return mappings.any((map) =>
        IdMapRepository.isProvisional(map) &&
        (map.state == FireflySyncState.creating ||
            map.state == FireflySyncState.pendingDelete));
  }

  Future<void> _pullInitial() async {
    final checkpoint = await meta.read(SyncMetaRepository.transactionPage);
    final first = int.tryParse(checkpoint ?? '') ?? 1;
    final previousTotal = int.tryParse(await meta.read(_initialTotal) ?? '');
    final seen = await _pullPages(
      (page) => context.api.transactions.list(page: page, limit: pageSize),
      first: first,
      expectedTotal: previousTotal,
      checkpoint: true,
    );
    if (cancelled) return;
    if (seen == null) {
      await _clearInitialCheckpoint();
      throw const FireflyInvalidPayload();
    }
    await db.transaction(() async {
      await _clearInitialCheckpoint();
      await meta.writeDate(SyncMetaRepository.lastFullReconcile, context.now());
    });
  }

  Future<void> _clearInitialCheckpoint() => db.transaction(() async {
        await meta.remove(SyncMetaRepository.transactionPage);
        await meta.remove(_initialTotal);
      });

  Future<void> _fullReconcile() async {
    final seen = await _pullPages(
      (page) => context.api.transactions.list(page: page, limit: pageSize),
    );
    if (cancelled) return;
    if (seen == null) throw const FireflyInvalidPayload();
    for (final id in await _missingGroups(seen)) {
      if (cancelled) return;
      await _removeGroup(id);
    }
    if (cancelled) return;
    await db.transaction(() async {
      await _clearInitialCheckpoint();
      await meta.writeDate(SyncMetaRepository.lastFullReconcile, context.now());
    });
  }

  Future<Set<String>?> _pullPages(
    Future<FireflyPage<FireflyTransaction>> Function(int) fetch, {
    int first = 1,
    int? expectedTotal,
    bool checkpoint = false,
  }) async {
    final seen = <String>{};
    var total = expectedTotal;
    var count = 0;
    for (var page = first; !cancelled; page++) {
      final response = await fetch(page);
      if (cancelled) return null;
      total ??= response.total;
      if (page != response.currentPage ||
          total != response.total ||
          response.perPage < 1 ||
          page > response.totalPages && !(page == 1 && total == 0)) {
        return null;
      }
      for (final group in response.items) {
        if (cancelled || !seen.add(group.id)) return null;
        await _applyGroup(group,
            refreshContributors:
                checkpoint || context.pullMode == SyncPullMode.full);
      }
      count += response.items.length;
      if (page >= response.totalPages) {
        // On resume, the previous pages were counted and applied before their
        // checkpoint was written.
        return (first - 1) * response.perPage + count == total ? seen : null;
      }
      if (response.items.length != response.perPage) return null;
      if (checkpoint && !cancelled) {
        await db.transaction(() async {
          await meta.write(SyncMetaRepository.transactionPage, '${page + 1}');
          await meta.write(_initialTotal, '$total');
        });
      }
    }
    return null;
  }

  Future<Set<String>> _missingGroups(Set<String> seen,
      {DateTime? start, DateTime? end}) async {
    final missing = <String>{};
    final lastDay =
        end == null ? null : DateTime(end.year, end.month, end.day + 1);
    for (final mapping in await idMap.list(_transaction)) {
      final id = mapping.remoteId;
      if (seen.contains(id) ||
          missing.contains(id) ||
          IdMapRepository.isProvisional(mapping)) {
        continue;
      }
      if (start != null && lastDay != null) {
        final row = await db.fireflyTransaction(mapping.localPk);
        if (row == null ||
            row.dateCreated.isBefore(start) ||
            !row.dateCreated.isBefore(lastDay)) {
          continue;
        }
      }
      missing.add(id);
    }
    if (start == null) {
      for (final mapping in await idMap.list(_group)) {
        if (!seen.contains(mapping.remoteId)) missing.add(mapping.remoteId);
      }
    }
    return missing;
  }

  Future<FireflyTransaction?> fetchGroup(String id,
      {bool preserveDirty = false}) async {
    final FireflyTransaction remote;
    try {
      remote = await context.api.transactions.get(id);
    } on FireflyNotFound {
      if (!cancelled) await _removeGroup(id);
      return null;
    }
    if (!cancelled) {
      await _applyGroup(remote,
          preserveDirty: preserveDirty, refreshContributors: preserveDirty);
    }
    return remote;
  }

  Future<void> _applyGroup(
    FireflyTransaction remote, {
    bool refreshContributors = false,
    bool preserveDirty = false,
  }) =>
      db.transaction(() async {
        final splits = remote.splits;
        if (splits.isEmpty) throw const FireflyInvalidPayload();
        final mappings = await idMap.forRemoteGroup(_transaction, remote.id);
        final splitIds = <String>{};
        final groupPk = await _applyGroupTitle(remote, splits.length > 1,
            preserveDirty: preserveDirty);
        for (final split in splits) {
          final journal = _journal(split);
          if (!splitIds.add(journal)) throw const FireflyInvalidPayload();
          final existing = mappings.where((map) => map.remoteSubId == journal);
          await _applySplit(
            remote,
            split,
            {for (final map in existing) map.remoteRole: map},
            groupPk: groupPk,
            refreshContributors: refreshContributors,
            preserveDirty: preserveDirty,
          );
        }
        await _removeMappings(
          mappings.where((map) => !splitIds.contains(map.remoteSubId)),
        );
        if (groupPk == null) await _removeEmptyGroup(remote.id);
      });

  Future<String?> _applyGroupTitle(FireflyTransaction remote, bool multiple,
      {required bool preserveDirty}) async {
    if (!multiple) return null;
    final mapping = await idMap.byRemote(_group, remote.id);
    final pk = mapping?.localPk ?? const Uuid().v4();
    final local = await db.fireflyTransactionGroup(pk);
    final title = remote.groupTitle;
    final hash = _titleHash(title);
    final dirty =
        mapping != null && local != null && _groupDirty(mapping, local);
    final sameVersion =
        _secondOrNull(remote.updatedAt) == mapping?.remoteUpdatedAt;
    if (mapping?.state == FireflySyncState.error && sameVersion) return pk;
    if (dirty && (preserveDirty || hash == mapping.syncedHash)) return pk;
    if (dirty && local.title != title) {
      await context.conflicts.record(
        type: _group,
        localPk: pk,
        remoteId: remote.id,
        local: {'title': local.title},
        remote: {'title': title},
        resolution: 'remoteWins',
        createdAt: context.now(),
      );
    }
    if (local?.title == title &&
        local != null &&
        mapping?.syncedHash == hash &&
        sameVersion) {
      return pk;
    }
    await db.into(db.transactionGroups).insertOnConflictUpdate(
          TransactionGroup(
              groupPk: pk, title: title, dateTimeModified: remote.updatedAt),
        );
    await idMap.put(FireflyIdMapping(
      entityType: _group,
      localPk: pk,
      remoteId: remote.id,
      remoteSubId: '',
      remoteRole: _single,
      attempts: 0,
      remoteUpdatedAt: remote.updatedAt,
      localVersionAt: remote.updatedAt,
      syncedHash: hash,
      state: FireflySyncState.synced,
    ));
    return pk;
  }

  bool _groupDirty(FireflyIdMapping mapping, TransactionGroup group) =>
      _titleHash(group.title) != mapping.syncedHash &&
      (group.dateTimeModified == null ||
          mapping.localVersionAt == null ||
          !group.dateTimeModified!.isBefore(mapping.localVersionAt!));

  Future<void> _applySplit(
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Map<int, FireflyIdMapping> mappings, {
    required String? groupPk,
    required bool refreshContributors,
    required bool preserveDirty,
  }) async {
    final kind = _kind(split.type);
    if (kind == null) throw const FireflyInvalidPayload();
    final amount = split.amount?.abs();
    final date = split.date;
    if (amount == null || date == null) throw const FireflyInvalidPayload();

    final from = await _localWallet(split.sourceId);
    final to = await _localWallet(split.destinationId);
    final transfer = kind == FireflyTransactionType.transfer;
    final ordinary = kind == FireflyTransactionType.withdrawal ||
        kind == FireflyTransactionType.deposit;
    final incoming = kind == FireflyTransactionType.deposit ||
        (!ordinary && !transfer && to != null);
    final wallet = incoming ? to : from;
    // For example, a liability side can be unmapped until liability sync is
    // enabled. Keep any existing mapping and retry on a later listing.
    if (wallet == null || (transfer && to == null)) return;

    final category = ordinary
        ? await _localCategory(split.categoryId)
        : (category: await _balanceCategory(), subcategory: null);
    final description = (split.description ?? '').trim();
    var fullName = description;
    if (fullName.isEmpty && ordinary) {
      final subcategory = category.subcategory;
      final fallback = subcategory == null
          ? category.category
          : await db.fireflyCategory(subcategory);
      final remoteName = split.categoryName?.trim();
      fullName = remoteName != null && remoteName.isNotEmpty
          ? remoteName
          : fallback?.name ?? '';
    }
    final fullNote = split.notes ?? '';
    final name = _truncate(fullName, NAME_LIMIT);
    final note = _truncate(fullNote, NOTE_LIMIT);
    final lossy = {
      if (name != fullName || (description.isEmpty && name.isNotEmpty))
        'description': fireflyTextHash(name),
      if (note != fullNote) 'notes': fireflyTextHash(note),
    };
    final roles = transfer ? [_source, _destination] : [_single];
    final recovered = await _recoverMappings(split, mappings);
    final updates = <_RemoteRow>[];
    for (final role in roles) {
      final mapping = mappings[role] ?? recovered[role];
      final pk = mapping?.localPk ?? const Uuid().v4();
      final local = await db.fireflyTransaction(pk);
      final isIncoming = role == _destination || incoming;
      final foreign = transfer &&
          to!.currency?.toUpperCase() != from!.currency?.toUpperCase();
      final row = (local ??
              Transaction(
                transactionPk: pk,
                name: '',
                amount: 0,
                note: '',
                categoryFk: category.category.categoryPk,
                walletFk: wallet.walletPk,
                dateCreated: date,
                income: false,
                paid: true,
                skipPaid: false,
              ))
          .copyWith(
        name: name,
        note: note,
        amount: isIncoming
            ? (foreign ? (split.foreignAmount?.abs() ?? amount) : amount)
            : -amount,
        income: isIncoming,
        paid: true,
        walletFk: role == _destination ? to!.walletPk : wallet.walletPk,
        categoryFk: category.category.categoryPk,
        subCategoryFk: Value(category.subcategory),
        dateCreated: date,
        dateTimeModified: Value(group.updatedAt),
        fireflyType: Value(kind),
        splitGroupFk: Value(groupPk),
        splitOrder: Value(groupPk == null ? null : split.order),
        reconciled: split.reconciled ?? false,
      );
      updates.add((row: row, mapping: mapping, local: local, role: role));
    }

    final recoveringDelete = recovered.values
        .any((map) => map.state == FireflySyncState.pendingDelete);
    if (recovered.isNotEmpty) {
      for (var index = 0; index < updates.length; index++) {
        final entry = updates[index];
        final map = entry.mapping;
        final local = entry.local;
        if (map == null ||
            (!recoveringDelete &&
                local != null &&
                await _hash(local) == map.syncedHash)) {
          continue;
        }
        final linked = map.copyWith(
          remoteId: group.id,
          remoteSubId: _journal(split),
          remoteUpdatedAt: Value(group.updatedAt),
          syncedHash: Value(await _hash(entry.row)),
          lossyFields: Value(lossy.isEmpty ? null : jsonEncode(lossy)),
          state: map.state == FireflySyncState.pendingDelete || local == null
              ? FireflySyncState.pendingDelete
              : FireflySyncState.synced,
          attempts: 0,
          lastError: const Value(null),
        );
        await idMap.put(linked);
        updates[index] = (
          row: entry.row,
          mapping: linked,
          local: local,
          role: entry.role,
        );
      }
    }

    final pendingDelete = updates
        .any((entry) => entry.mapping?.state == FireflySyncState.pendingDelete);
    final decisions = <ConflictDecision>[];
    for (final entry in updates) {
      decisions.add(await _pullDecision(
        group,
        entry,
        refreshContributors: refreshContributors && !pendingDelete,
        preserveDirty: preserveDirty,
      ));
    }
    if (preserveDirty && pendingDelete) return;
    if (preserveDirty && decisions.contains(ConflictDecision.pushLocal)) {
      // Rebase a newer local edit on the returned server version. Keep the
      // last submitted local version so the edit remains eligible for push.
      for (var index = 0; index < updates.length; index++) {
        if (decisions[index] != ConflictDecision.pushLocal) continue;
        final entry = updates[index];
        await idMap.put(entry.mapping!.copyWith(
          remoteUpdatedAt: Value(group.updatedAt),
          syncedHash: Value(await _hash(entry.row)),
          lossyFields: Value(lossy.isEmpty ? null : jsonEncode(lossy)),
        ));
      }
      return;
    }
    if (decisions.every((decision) =>
        decision == ConflictDecision.none ||
        decision == ConflictDecision.pushLocal ||
        decision == ConflictDecision.deleteRemote)) {
      return;
    }
    if (decisions.contains(ConflictDecision.deleteRemote)) {
      if (!decisions.contains(ConflictDecision.applyRemoteWithConflict) &&
          !decisions.contains(ConflictDecision.applyRemote) &&
          !decisions.contains(ConflictDecision.markSynced)) {
        return;
      }
      for (var index = 0; index < decisions.length; index++) {
        if (decisions[index] == ConflictDecision.deleteRemote) {
          decisions[index] = ConflictDecision.applyRemoteWithConflict;
        }
      }
    }

    final stale =
        mappings.values.where((map) => !roles.contains(map.remoteRole));
    await _removeMappings(stale);
    for (var index = 0; index < updates.length; index++) {
      final entry = updates[index];
      final decision = decisions[index];
      if (decision == ConflictDecision.applyRemoteWithConflict) {
        await _recordConflict(
            entry.mapping!, entry.local, split.fields, 'remoteWins');
      }
      // First insert both rows without references so self-FKs work on import.
      if (decision == ConflictDecision.pushLocal) continue;
      await db.into(db.transactions).insertOnConflictUpdate(
            entry.row.copyWith(pairedTransactionFk: const Value(null)),
          );
    }
    for (final entry in updates) {
      if (transfer) {
        final partner = updates.firstWhere((other) => other.role != entry.role);
        await (db.update(db.transactions)
              ..where(
                  (row) => row.transactionPk.equals(entry.row.transactionPk)))
            .write(TransactionsCompanion(
                pairedTransactionFk: Value(partner.row.transactionPk)));
      }
    }
    for (var index = 0; index < updates.length; index++) {
      final entry = updates[index];
      if (decisions[index] == ConflictDecision.pushLocal) continue;
      for (final contributor in transactionContributors) {
        await contributor.pull(context, group, split, entry.row.transactionPk);
      }
      final stored = (await db.fireflyTransaction(entry.row.transactionPk))!;
      await _writeMapping(
        stored,
        remoteId: group.id,
        journalId: _journal(split),
        role: entry.role,
        updatedAt: group.updatedAt,
        hash: await _hash(stored),
        lossy: lossy.isEmpty ? null : jsonEncode(lossy),
      );
    }
  }

  Future<ConflictDecision> _pullDecision(
    FireflyTransaction group,
    _RemoteRow entry, {
    required bool refreshContributors,
    required bool preserveDirty,
  }) async {
    final mapping = entry.mapping;
    final local = entry.local;
    if (mapping == null || IdMapRepository.isProvisional(mapping)) {
      return ConflictDecision.insertLocal;
    }
    final incomingAt = group.updatedAt;
    final previousAt = mapping.remoteUpdatedAt;
    if (incomingAt != null &&
        previousAt != null &&
        _second(incomingAt).isBefore(previousAt)) {
      return ConflictDecision.none;
    }
    final incoming = await _hash(entry.row);
    final localHash = local == null ? null : await _hash(local);
    final rejected = mapping.state == FireflySyncState.error;
    final sameRemoteVersion = _secondOrNull(incomingAt) == previousAt;
    // A local delete of a related row (for example its category) changes the
    // locally mapped hash without a server edit. Same version means no edit.
    final deletingUnchanged =
        mapping.state == FireflySyncState.pendingDelete && sameRemoteVersion;
    final changed = !(rejected && sameRemoteVersion) &&
        !deletingUnchanged &&
        (incoming != mapping.syncedHash ||
            (_secondOrNull(incomingAt) != previousAt &&
                transactionContributors
                    .any((contributor) => contributor.version > 0)));
    final localVersion = mapping.state == FireflySyncState.pendingDelete ||
            (local == null && mapping.state == FireflySyncState.error)
        ? LocalSyncVersion.pendingDelete
        : local == null
            ? LocalSyncVersion.missing
            : _dirty(mapping, local, localHash!)
                ? LocalSyncVersion.dirty
                : LocalSyncVersion.clean;
    if (preserveDirty && localVersion == LocalSyncVersion.dirty) {
      return ConflictDecision.pushLocal;
    }
    final decision = resolveConflict(
      local: localVersion,
      remote: changed ? RemoteSyncVersion.changed : RemoteSyncVersion.unchanged,
      sameHash: incoming == localHash,
    );
    if (decision == ConflictDecision.none &&
        !rejected &&
        (refreshContributors || !sameRemoteVersion)) {
      return ConflictDecision.applyRemote;
    }
    return decision;
  }

  Future<Map<int, FireflyIdMapping>> _recoverMappings(
      FireflyTransactionSplit split,
      Map<int, FireflyIdMapping> mappings) async {
    final reference = split.internalReference;
    if (mappings.isNotEmpty ||
        reference == null ||
        !reference.startsWith('cashew:')) {
      return {};
    }
    final localPk = reference.substring('cashew:'.length);
    final mapping = await idMap.byLocal(_transaction, localPk);
    if (mapping == null || !IdMapRepository.isProvisional(mapping)) return {};
    final pending = await idMap.forRemoteGroup(_transaction, mapping.remoteId);
    return {for (final row in pending) row.remoteRole: row};
  }

  Future<TransactionWallet?> _localWallet(String? id) async {
    if (id == null) return null;
    final mapping = await idMap.byRemote(FireflyEntityType.walletAccount, id) ??
        await idMap.byRemote(FireflyEntityType.liabilityAccount, id);
    return mapping == null ? null : db.fireflyWallet(mapping.localPk);
  }

  Future<({TransactionCategory category, String? subcategory})> _localCategory(
      String? id) async {
    final mapping = id == null
        ? null
        : await idMap.byRemote(FireflyEntityType.category, id);
    final mapped =
        mapping == null ? null : await db.fireflyCategory(mapping.localPk);
    final parent = mapped?.mainCategoryPk;
    if (parent != null) {
      final category = await db.fireflyCategory(parent);
      if (category != null) {
        return (category: category, subcategory: mapped!.categoryPk);
      }
    }
    if (mapped != null) return (category: mapped, subcategory: null);
    final pk = await db.ensureUncategorizedCategory();
    return (category: (await db.fireflyCategory(pk))!, subcategory: null);
  }

  Future<TransactionCategory> _balanceCategory() async {
    final category = await db.fireflyCategory('0');
    if (category != null) return category;
    return db.into(db.categories).insertReturning(CategoriesCompanion.insert(
          categoryPk: const Value('0'),
          name: '',
          order: 0,
        ));
  }

  Future<void> _removeGroup(String id, {bool recordConflict = true}) =>
      db.transaction(() async {
        await _removeMappings(await idMap.forRemoteGroup(_transaction, id),
            recordConflict: recordConflict);
        await _removeEmptyGroup(id);
      });

  Future<void> _removeEmptyGroup(String remoteId) async {
    final group = await idMap.byRemote(_group, remoteId);
    if (group == null) return;
    final used = await (db.select(db.transactions)
          ..where((row) => row.splitGroupFk.equals(group.localPk))
          ..limit(1))
        .getSingleOrNull();
    if (used != null) return;
    await (db.delete(db.transactionGroups)
          ..where((row) => row.groupPk.equals(group.localPk)))
        .go();
    await idMap.remove(_group, group.localPk);
  }

  Future<void> _removeMappings(Iterable<FireflyIdMapping> mappings,
      {bool recordConflict = true}) async {
    final remove = <String>[];
    for (final mapping in mappings) {
      final row = await db.fireflyTransaction(mapping.localPk);
      if (recordConflict &&
          row != null &&
          _dirty(mapping, row, await _hash(row))) {
        await _recordConflict(mapping, row, null, 'remoteDeleted');
      }
      remove.add(mapping.localPk);
    }
    await db.removeFireflyTransactions(remove);
    for (final pk in remove) {
      await idMap.remove(_transaction, pk);
    }
  }

  Future<void> _recordConflict(FireflyIdMapping mapping, Transaction? local,
      JsonObject? remote, String resolution) async {
    await context.conflicts.record(
      type: _transaction,
      localPk: mapping.localPk,
      remoteId: mapping.remoteId,
      local: local == null ? {'pendingDelete': true} : local.toJson(),
      remote: remote,
      resolution: resolution,
      createdAt: context.now(),
    );
  }

  Future<void> push() async {
    final locals = await db.fireflyTransactions();
    final maps = {
      for (final map in await idMap.list(_transaction)) map.localPk: map,
    };
    final seen = <String>{};
    final editedGroups = <String>{};
    for (final row in locals) {
      if (cancelled) return;
      if (!seen.add(row.transactionPk)) continue;
      final mapping = maps[row.transactionPk];
      if (mapping?.state == FireflySyncState.pendingDelete) continue;
      if (!_eligible(row)) {
        if (mapping == null) {
          await idMap.put(FireflyIdMapping(
            entityType: _transaction,
            localPk: row.transactionPk,
            remoteId: IdMapRepository.creatingId(row.transactionPk),
            remoteSubId: '',
            remoteRole: _single,
            attempts: 0,
            state: FireflySyncState.localOnly,
          ));
        }
        continue;
      }
      final hash = await _hash(row);
      if (mapping != null && !IdMapRepository.isProvisional(mapping)) {
        if (_dirty(mapping, row, hash) && editedGroups.add(mapping.remoteId)) {
          await _updateGroup(mapping.remoteId);
        }
        continue;
      }
      final partner = row.pairedTransactionFk == null
          ? null
          : await db.fireflyTransaction(row.pairedTransactionFk!);
      if (partner != null) {
        final partnerMap = maps[partner.transactionPk];
        if ((partnerMap != null &&
                !IdMapRepository.isProvisional(partnerMap)) ||
            partnerMap?.state == FireflySyncState.pendingDelete) {
          continue;
        }
        seen.add(partner.transactionPk);
      }
      final first = partner != null && row.income ? partner : row;
      final second = partner == null
          ? null
          : row.income
              ? row
              : partner;
      final draft = [
        await _localRow(first, maps[first.transactionPk]),
        if (second != null) await _localRow(second, maps[second.transactionPk]),
      ];
      if (draft.any(_needsPush)) await _create(draft);
    }
    for (final map in await idMap.list(_group)) {
      if (cancelled) return;
      if (editedGroups.contains(map.remoteId)) continue;
      final group = await db.fireflyTransactionGroup(map.localPk);
      if (group != null && _groupDirty(map, group)) {
        await _updateGroup(map.remoteId);
      }
    }
  }

  bool _eligible(Transaction row) =>
      row.type != TransactionSpecialType.credit &&
      row.type != TransactionSpecialType.debt &&
      row.objectiveLoanFk == null &&
      (row.type == null || row.paid);

  Future<_LocalRow> _localRow(
          Transaction row, FireflyIdMapping? mapping) async =>
      (row: row, mapping: mapping, hash: await _hash(row));

  bool _needsPush(_LocalRow local) =>
      _eligible(local.row) &&
      (local.mapping == null ||
          local.mapping!.state == FireflySyncState.localOnly ||
          _dirty(local.mapping!, local.row, local.hash));

  Future<void> _create(List<_LocalRow> draft) async {
    final first = draft.first.row;
    final split = await _writableSplit(draft);
    if (split == null || cancelled) return;
    split['internal_reference'] = 'cashew:${first.transactionPk}';
    final provisionalId = IdMapRepository.creatingId(first.transactionPk);
    final maps = <FireflyIdMapping>[];
    for (var index = 0; index < draft.length; index++) {
      final item = draft[index];
      maps.add(FireflyIdMapping(
        entityType: _transaction,
        localPk: item.row.transactionPk,
        remoteId: provisionalId,
        remoteSubId: '',
        remoteRole: draft.length == 1 ? _single : index + 1,
        state: FireflySyncState.creating,
        localVersionAt: item.row.dateTimeModified,
        syncedHash: item.hash,
        attempts: (item.mapping?.attempts ?? 0) + 1,
        lastAttemptAt: context.now(),
      ));
    }
    final marked = await db.transaction(() async {
      for (final item in draft) {
        if (await db.fireflyTransaction(item.row.transactionPk) != item.row ||
            await idMap.byLocal(_transaction, item.row.transactionPk) !=
                item.mapping) {
          return false;
        }
      }
      for (final mapping in maps) {
        await idMap.put(mapping);
      }
      return true;
    });
    if (!marked) return;

    final FireflyTransaction response;
    try {
      response = await _postSplit(split, first);
    } on FireflyValidation catch (error) {
      final knownId =
          RegExp(r'Duplicate of transaction #(\d+)', caseSensitive: false)
              .firstMatch(error.message)?[1];
      if (knownId != null && !cancelled) {
        final existing = await fetchGroup(knownId);
        if (existing?.splits.any((item) =>
                item.internalReference == split['internal_reference']) ??
            false) {
          return;
        }
      }
      await _markError(maps, error);
      return;
    }
    final splits = response.splits;
    if (splits.length != 1) throw const FireflyInvalidPayload();
    final journal = _journal(splits.single);
    await db.transaction(() async {
      for (final mapping in maps) {
        final latest = await idMap.byLocal(_transaction, mapping.localPk);
        final row = await db.fireflyTransaction(mapping.localPk);
        await idMap.put(mapping.copyWith(
          remoteId: response.id,
          remoteSubId: journal,
          remoteUpdatedAt: Value(response.updatedAt),
          state: row == null || latest?.state == FireflySyncState.pendingDelete
              ? FireflySyncState.pendingDelete
              : FireflySyncState.synced,
          attempts: 0,
        ));
      }
    });
    context.pushedTransactionIds.add(response.id);
  }

  Future<FireflyTransaction> _postSplit(
      JsonObject split, Transaction row) async {
    Future<FireflyTransaction> post() => context.api.transactions.create({
          ..._writeFlags,
          'error_if_duplicate_hash': true,
          'transactions': [split],
        });
    try {
      return await post();
    } on FireflyValidation catch (error) {
      final correction = row.categoryFk == '0' &&
          row.fireflyType == null &&
          row.pairedTransactionFk == null;
      final rejectedReconciliation = error.errors.keys.any((field) =>
          field.endsWith('.type') ||
          field.endsWith('.source_id') ||
          field.endsWith('.destination_id'));
      if (!correction || !rejectedReconciliation || cancelled) rethrow;
      split['type'] = row.income ? 'deposit' : 'withdrawal';
      split['description'] = 'default-category-account-amount-balancing'.tr();
      return post();
    }
  }

  Future<void> _updateGroup(String id) async {
    final group = await fetchGroup(id);
    if (group == null || cancelled) return;
    final mappings = await idMap.forRemoteGroup(_transaction, id);
    final outgoing = <JsonObject>[];
    final submitted = <_LocalRow>[];
    for (final remote in group.splits) {
      final journal = _journal(remote);
      final relevant = mappings
          .where((map) => map.remoteSubId == journal)
          .toList()
        ..sort((a, b) => a.remoteRole.compareTo(b.remoteRole));
      final local = <_LocalRow>[];
      for (final map in relevant) {
        final row = await db.fireflyTransaction(map.localPk);
        if (row != null) local.add(await _localRow(row, map));
      }
      final complete = local.length == relevant.length &&
          !relevant.any((map) => map.state == FireflySyncState.pendingDelete);
      final fields = complete && local.any(_needsPush)
          ? await _writableSplit(local, remote: remote)
          : null;
      // The server removes journals omitted from a group update.
      outgoing.add({'transaction_journal_id': journal, ...?fields});
      if (fields != null) submitted.addAll(local);
    }
    final titleMap = await idMap.byRemote(_group, id);
    final localGroup = titleMap == null
        ? null
        : await db.fireflyTransactionGroup(titleMap.localPk);
    final titleDirty = localGroup != null && _groupDirty(titleMap!, localGroup);
    if ((submitted.isEmpty && !titleDirty) || cancelled) return;

    final FireflyTransaction response;
    try {
      response = await context.api.transactions.update(id, {
        ..._writeFlags,
        if (submitted.isNotEmpty) 'transactions': outgoing,
        if (titleDirty) 'group_title': localGroup.title ?? '',
      });
    } on FireflyNotFound {
      await _removeGroup(id);
      return;
    } on FireflyValidation catch (error) {
      await _markError(
        [
          if (titleDirty)
            titleMap.copyWith(
              localVersionAt: Value(localGroup.dateTimeModified),
              syncedHash: Value(_titleHash(localGroup.title)),
            ),
          for (final item in submitted)
            item.mapping!.copyWith(
              localVersionAt: Value(item.row.dateTimeModified),
              syncedHash: Value(item.hash),
            ),
        ],
        error,
      );
      return;
    }
    await db.transaction(() async {
      if (titleDirty) {
        await idMap.put(titleMap.copyWith(
          remoteUpdatedAt: Value(response.updatedAt),
          localVersionAt: Value(localGroup.dateTimeModified),
          syncedHash: Value(_titleHash(localGroup.title)),
          state: FireflySyncState.synced,
          lastError: const Value(null),
          attempts: 0,
        ));
      }
      for (final item in submitted) {
        final map = item.mapping!;
        final latest = await idMap.byLocal(_transaction, map.localPk);
        final row = await db.fireflyTransaction(map.localPk);
        await idMap.put(map.copyWith(
          remoteUpdatedAt: Value(response.updatedAt),
          localVersionAt: Value(item.row.dateTimeModified),
          syncedHash: Value(item.hash),
          state: row == null || latest?.state == FireflySyncState.pendingDelete
              ? FireflySyncState.pendingDelete
              : FireflySyncState.synced,
          lastError: const Value(null),
          attempts: 0,
        ));
      }
    });
    context.pushedTransactionIds.add(response.id);
  }

  Future<void> _markError(
          Iterable<FireflyIdMapping> maps, FireflyValidation error) =>
      db.transaction(() async {
        for (final map in maps) {
          final latest = await idMap.byLocal(map.entityType, map.localPk);
          if (latest?.state == FireflySyncState.pendingDelete) continue;
          await idMap.put(map.copyWith(
            state: FireflySyncState.error,
            lastError: Value(redactFireflyLog(error.message)),
            lastAttemptAt: Value(context.now()),
            attempts: (latest?.attempts ?? 0) +
                (latest?.state == FireflySyncState.creating ? 0 : 1),
          ));
        }
      });

  Future<JsonObject?> _writableSplit(List<_LocalRow> entries,
      {FireflyTransactionSplit? remote}) async {
    final first = entries.first.row;
    final second = entries.length == 2 ? entries.last.row : null;
    final transfer = second != null;
    final preferred = entries.where(_needsPush).fold<_LocalRow>(entries.first,
        (current, candidate) {
      final date = candidate.row.dateTimeModified;
      final previous = current.row.dateTimeModified;
      return !_needsPush(current) ||
              (date != null && (previous == null || date.isAfter(previous)))
          ? candidate
          : current;
    });
    final row = preferred.row;
    final balanceCorrection =
        first.categoryFk == '0' && first.fireflyType == null && !transfer;
    final kind = transfer
        ? FireflyTransactionType.transfer
        : balanceCorrection
            ? FireflyTransactionType.reconciliation
            : first.fireflyType == null ||
                    first.fireflyType == FireflyTransactionType.withdrawal ||
                    first.fireflyType == FireflyTransactionType.deposit
                ? first.income
                    ? FireflyTransactionType.deposit
                    : FireflyTransactionType.withdrawal
                : first.fireflyType!;
    if (kind == FireflyTransactionType.transfer && !transfer) return null;
    final wallet = await db.fireflyWallet(first.walletFk);
    final account = await _remoteWallet(first.walletFk);
    if (wallet == null || account == null) return null;
    final destWallet =
        transfer ? await db.fireflyWallet(second.walletFk) : null;
    final destAccount = transfer ? await _remoteWallet(second.walletFk) : null;
    if (transfer && (destAccount == null || destWallet == null)) return null;

    final incoming = kind == FireflyTransactionType.deposit ||
        (kind != FireflyTransactionType.withdrawal &&
            !transfer &&
            first.income);
    final categoryPk = row.subCategoryFk ?? row.categoryFk;
    final category =
        categoryPk == '0' || categoryPk == fireflyUncategorizedCategoryPk
            ? null
            : await idMap.byLocal(FireflyEntityType.category, categoryPk);
    if (categoryPk != '0' &&
        categoryPk != fireflyUncategorizedCategoryPk &&
        (category == null || IdMapRepository.isProvisional(category))) {
      return null;
    }
    final description = row.name.trim();
    final categoryName = description.isEmpty
        ? (await db.fireflyCategory(categoryPk))?.name.trim()
        : null;
    final text = description.isNotEmpty
        ? description
        : categoryName?.isNotEmpty == true
            ? categoryName!
            : 'transaction'.tr();
    final currency = wallet.currency?.toUpperCase();
    final destCurrency = destWallet?.currency?.toUpperCase();
    final crossCurrency = transfer &&
        destWallet != null &&
        destCurrency != null &&
        currency != destCurrency;
    final notes = row.note;
    final fields = <String, Object?>{
      if (_kind(remote?.type) != kind) 'type': _wireKind(kind),
      'date': formatFireflyDateTime(row.dateCreated),
      'amount': formatFireflyAmount(first.amount, wallet.decimals),
      if (currency != null) 'currency_code': currency,
      if (first.splitOrder != null && first.splitOrder != remote?.order)
        'order': first.splitOrder,
      if (crossCurrency) ...{
        'foreign_currency_code': destCurrency,
        'foreign_amount':
            formatFireflyAmount(second.amount, destWallet.decimals),
      },
      if (transfer || !incoming) 'source_id': account,
      if (transfer || incoming) 'destination_id': destAccount ?? account,
      if (!transfer &&
          (kind == FireflyTransactionType.withdrawal ||
              kind == FireflyTransactionType.deposit))
        'category_id': category?.remoteId,
      'reconciled': row.reconciled,
      if (!_keepLossy(preferred.mapping, 'description', row.name))
        'description': text,
      if (!_keepLossy(preferred.mapping, 'notes', row.note))
        'notes': notes.isEmpty ? null : notes,
    };
    // Both local rows participate, with the edited side taking precedence for
    // any contributor field common to both sides of the journal.
    for (final entry in [
      ...entries.where((item) => item != preferred),
      preferred
    ]) {
      for (final contributor in transactionContributors) {
        await contributor.push(context, entry.row, fields);
      }
    }
    return fields;
  }

  Map<String, bool> get _writeFlags => {
        'apply_rules': context.config.applyRules,
        'fire_webhooks': context.config.fireWebhooks,
      };

  Future<String?> _remoteWallet(String pk) async {
    final mapping = await idMap.byLocal(FireflyEntityType.walletAccount, pk) ??
        await idMap.byLocal(FireflyEntityType.liabilityAccount, pk);
    return mapping == null || IdMapRepository.isProvisional(mapping)
        ? null
        : mapping.remoteId;
  }

  Future<void> pushDeletes() async {
    final seen = <String>{};
    for (final map in await idMap.list(
      _transaction,
      state: FireflySyncState.pendingDelete,
    )) {
      if (cancelled) return;
      if (IdMapRepository.isProvisional(map)) {
        await idMap.remove(_transaction, map.localPk);
        continue;
      }
      if (!seen.add(map.remoteId)) continue;
      final remote = await fetchGroup(map.remoteId);
      if (remote == null || cancelled) continue;
      final pending = (await idMap.forRemoteGroup(_transaction, map.remoteId))
          .where((item) => item.state == FireflySyncState.pendingDelete)
          .map((item) => item.remoteSubId)
          .toSet();
      if (pending.isEmpty) continue;
      final journals = remote.splits.map(_journal).toSet();
      if (journals.every(pending.contains)) {
        try {
          await context.api.transactions.delete(map.remoteId);
        } on FireflyNotFound {
          // An earlier attempt may already have deleted the group.
        }
        await _removeGroup(map.remoteId, recordConflict: false);
      } else {
        for (final journal in pending) {
          if (cancelled) return;
          try {
            await context.api.transactions.deleteJournal(journal);
          } on FireflyNotFound {
            // Journal deletion is idempotent across retries.
          }
          await db.transaction(() async {
            final rows = await idMap.forRemoteGroup(_transaction, map.remoteId);
            await _removeMappings(
                rows.where((row) => row.remoteSubId == journal),
                recordConflict: false);
          });
        }
        if (!cancelled) await fetchGroup(map.remoteId);
      }
    }
  }

  Future<String> _hash(Transaction row) async {
    final fields = <String, Object?>{};
    for (final contributor in transactionContributors) {
      await contributor.push(context, row, fields);
    }
    return syncedFieldsHash({
      'name': row.name.trim(),
      'note': row.note,
      'amount': row.amount == 0 ? 0.0 : row.amount,
      'income': row.income,
      'wallet': row.walletFk,
      'category': row.categoryFk,
      'subcategory': row.subCategoryFk,
      'date': _second(row.dateCreated).millisecondsSinceEpoch,
      'type': row.fireflyType?.name,
      'reconciled': row.reconciled,
      'group': row.splitGroupFk,
      'order': row.splitOrder,
      'contributions': fields,
    });
  }

  bool _dirty(FireflyIdMapping map, Transaction row, String hash) {
    final change = detectLocalChange(
      mapping: map,
      modifiedAt: row.dateTimeModified,
      hash: hash,
    );
    return change == LocalChange.created ||
        change == LocalChange.updated ||
        (map.state != FireflySyncState.localOnly &&
            map.state != FireflySyncState.pendingDelete &&
            row.dateTimeModified == map.localVersionAt &&
            hash != map.syncedHash);
  }

  Future<void> _writeMapping(
    Transaction row, {
    required String remoteId,
    required String journalId,
    required int role,
    required DateTime? updatedAt,
    required String hash,
    required String? lossy,
  }) =>
      idMap.put(FireflyIdMapping(
        entityType: _transaction,
        localPk: row.transactionPk,
        remoteId: remoteId,
        remoteSubId: journalId,
        attempts: 0,
        remoteRole: role,
        remoteUpdatedAt: updatedAt,
        localVersionAt: row.dateTimeModified,
        syncedHash: hash,
        lossyFields: lossy,
        state: FireflySyncState.synced,
      ));
}

typedef _RemoteRow = ({
  Transaction row,
  FireflyIdMapping? mapping,
  Transaction? local,
  int role,
});
typedef _LocalRow = ({
  Transaction row,
  FireflyIdMapping? mapping,
  String hash,
});

String _titleHash(String? title) => syncedFieldsHash({'title': title});

String _journal(FireflyTransactionSplit split) =>
    split.journalId ?? (throw const FireflyInvalidPayload());

FireflyTransactionType? _kind(String? type) => switch (type?.toLowerCase()) {
      'withdrawal' => FireflyTransactionType.withdrawal,
      'deposit' => FireflyTransactionType.deposit,
      'transfer' => FireflyTransactionType.transfer,
      'reconciliation' => FireflyTransactionType.reconciliation,
      'opening balance' ||
      'opening-balance' =>
        FireflyTransactionType.openingBalance,
      _ => null,
    };

String _wireKind(FireflyTransactionType kind) =>
    kind == FireflyTransactionType.openingBalance
        ? 'opening-balance'
        : kind.name;

DateTime _second(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
    value.millisecondsSinceEpoch ~/ 1000 * 1000);

DateTime? _secondOrNull(DateTime? value) =>
    value == null ? null : _second(value);

String _truncate(String text, int limit) {
  if (text.length <= limit) return text;
  final unit = text.codeUnitAt(limit - 1);
  return text.substring(
      0, unit >= 0xd800 && unit <= 0xdbff ? limit - 1 : limit);
}

bool _keepLossy(FireflyIdMapping? mapping, String field, String value) {
  final lossy = mapping?.lossyFields;
  return lossy != null &&
      (jsonDecode(lossy) as JsonObject)[field] == fireflyTextHash(value);
}

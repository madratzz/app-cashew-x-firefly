import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/conflict_policy.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  test('implements the plan conflict table', () {
    const clean = LocalSyncVersion.clean;
    const dirty = LocalSyncVersion.dirty;
    const pending = LocalSyncVersion.pendingDelete;
    const absent = LocalSyncVersion.missing;
    const changed = RemoteSyncVersion.changed;
    const unchanged = RemoteSyncVersion.unchanged;
    const deleted = RemoteSyncVersion.deleted;
    const unknown = RemoteSyncVersion.missing;

    const cases = [
      (clean, changed, false, ConflictDecision.applyRemote),
      (clean, changed, true, ConflictDecision.applyRemote),
      (clean, unchanged, true, ConflictDecision.none),
      (dirty, unchanged, false, ConflictDecision.pushLocal),
      (dirty, changed, false, ConflictDecision.applyRemoteWithConflict),
      (dirty, changed, true, ConflictDecision.markSynced),
      (pending, unchanged, false, ConflictDecision.deleteRemote),
      (pending, changed, false, ConflictDecision.applyRemoteWithConflict),
      (dirty, deleted, false, ConflictDecision.deleteLocalWithConflict),
      (clean, deleted, false, ConflictDecision.deleteLocal),
      (pending, deleted, false, ConflictDecision.deleteLocal),
      (dirty, unknown, false, ConflictDecision.createRemote),
      (clean, unknown, false, ConflictDecision.createRemote),
      (absent, changed, false, ConflictDecision.insertLocal),
      (absent, unknown, false, ConflictDecision.none),
    ];
    for (final (local, remote, sameHash, decision) in cases) {
      expect(resolveConflict(local: local, remote: remote, sameHash: sameHash),
          decision,
          reason: '$local / $remote / same hash = $sameHash');
    }
  });

  test('detects creates, updates and pending deletes using mapped fields', () {
    final baseline =
        fixtureMapping(localVersionAt: fixtureTime, syncedHash: 'a');
    final later = fixtureTime.add(const Duration(seconds: 1));
    expect(detectLocalChange(mapping: null, modifiedAt: null, hash: 'a'),
        LocalChange.created);
    expect(detectLocalChange(mapping: baseline, modifiedAt: later, hash: 'b'),
        LocalChange.updated);
    expect(detectLocalChange(mapping: baseline, modifiedAt: null, hash: 'b'),
        LocalChange.updated);
    expect(
        detectLocalChange(
            mapping: fixtureMapping(), modifiedAt: later, hash: 'b'),
        LocalChange.updated);
    expect(
        detectLocalChange(
            mapping: baseline, modifiedAt: fixtureTime, hash: 'b'),
        LocalChange.clean);
    expect(detectLocalChange(mapping: baseline, modifiedAt: later, hash: 'a'),
        LocalChange.clean);
    for (final (state, change) in [
      (FireflySyncState.pendingDelete, LocalChange.deleted),
      (FireflySyncState.localOnly, LocalChange.clean),
      (FireflySyncState.creating, LocalChange.created),
    ]) {
      expect(
        detectLocalChange(
            mapping: baseline.copyWith(state: state),
            modifiedAt: later,
            hash: 'b'),
        change,
      );
    }
  });

  test('marks mapped deletes after the cursor and skips unsupported rows',
      () async {
    final db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    final mappings = IdMapRepository(db);
    final tracker = DirtyTracker(mappings);
    const recognized = {
      DeleteLogType.TransactionCategory: FireflyEntityType.category,
      DeleteLogType.Budget: FireflyEntityType.budget,
      DeleteLogType.Transaction: FireflyEntityType.transaction,
      DeleteLogType.Objective: FireflyEntityType.piggyBank,
    };
    for (final (type, pk) in [
      for (final entry in recognized.entries) (entry.value, entry.key.name),
      (FireflyEntityType.walletAccount, 'asset'),
      (FireflyEntityType.liabilityAccount, 'liability'),
      (FireflyEntityType.category, 'old'),
      (FireflyEntityType.budgetLimit, 'limit'),
    ]) {
      await mappings.put(fixtureMapping(type: type, localPk: pk, remoteId: pk));
    }
    final later = fixtureTime.add(const Duration(seconds: 1));
    DeleteLog log(DeleteLogType type, String pk, [DateTime? date]) => DeleteLog(
        deleteLogPk: pk,
        entryPk: pk,
        type: type,
        dateTimeModified: date ?? later);
    expect(
        await tracker.collectDeletes([
          ...recognized.keys.map((type) => log(type, type.name)),
          log(DeleteLogType.TransactionWallet, 'asset'),
          log(DeleteLogType.TransactionWallet, 'liability'),
          log(DeleteLogType.TransactionCategory, 'old', fixtureTime),
          log(DeleteLogType.TransactionCategory, 'missing'),
          log(DeleteLogType.CategoryBudgetLimit, 'limit'),
          log(DeleteLogType.ScannerTemplate, 'ignored'),
        ], after: fixtureTime),
        6);
    for (final type in [
      ...recognized.values,
      FireflyEntityType.walletAccount,
      FireflyEntityType.liabilityAccount
    ]) {
      expect(await mappings.list(type, state: FireflySyncState.pendingDelete),
          hasLength(1));
    }
    expect((await mappings.byLocal(FireflyEntityType.category, 'old'))?.state,
        FireflySyncState.synced);
    expect(
        (await mappings.byLocal(FireflyEntityType.budgetLimit, 'limit'))?.state,
        FireflySyncState.synced);
  });

  test('canonical JSON sorts nested keys while retaining array order', () {
    final a = {
      'z': [
        {'b': 2, 'a': 1},
        null,
      ],
      'x': false,
    };
    final b = {
      'x': false,
      'z': [
        {'a': 1, 'b': 2},
        null,
      ],
    };
    expect(canonicalJson(a), '{"x":false,"z":[{"a":1,"b":2},null]}');
    expect(syncedFieldsHash(a), syncedFieldsHash(b));
    expect(
        syncedFieldsHash(
            {...b, 'z': (b['z']! as List<Object?>).reversed.toList()}),
        isNot(syncedFieldsHash(a)));
    expect(fireflyTextHash('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
}

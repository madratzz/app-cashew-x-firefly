import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:drift/drift.dart';

const _piggyBank = FireflyEntityType.piggyBank;
const _transaction = FireflyEntityType.transaction;

typedef PiggyBankJournalLink = ({String objectivePk, String? groupId});

extension FireflyObjectiveQueries on FinanceDatabase {
  Future<Objective?> fireflyObjective(String pk) =>
      (select(objectives)..where((row) => row.objectivePk.equals(pk)))
          .getSingleOrNull();

  Future<List<Objective>> fireflyGoals() => (select(objectives)
        ..where((row) => row.type.equalsValue(ObjectiveType.goal))
        ..orderBy([(row) => OrderingTerm.asc(row.objectivePk)]))
      .get();

  Future<Objective> writeFireflyGoal({
    String? pk,
    required String name,
    required double amount,
    required String walletPk,
    required DateTime startDate,
    required DateTime? targetDate,
    required DateTime? modifiedAt,
  }) async {
    final fields = ObjectivesCompanion(
      name: Value(name),
      amount: Value(amount),
      walletFk: Value(walletPk),
      dateCreated: Value(startDate),
      endDate: Value(targetDate),
      dateTimeModified: Value(modifiedAt),
    );
    return into(objectives).insertReturning(
      fields.copyWith(
        objectivePk: pk == null ? const Value.absent() : Value(pk),
        order: const Value(0),
      ),
      onConflict: DoUpdate((_) => fields),
    );
  }

  Future<void> removeFireflyGoal(String pk) async {
    await (update(transactions)..where((row) => row.objectiveFk.equals(pk)))
        .write(const TransactionsCompanion(objectiveFk: Value(null)));
    await (update(transactions)..where((row) => row.objectiveLoanFk.equals(pk)))
        .write(const TransactionsCompanion(objectiveLoanFk: Value(null)));
    await (delete(objectives)..where((row) => row.objectivePk.equals(pk))).go();
  }

  Future<void> linkFireflyGoal(String transactionPk, String objectivePk) =>
      (update(transactions)
            ..where((row) =>
                row.transactionPk.equals(transactionPk) &
                (row.objectiveFk.isNull() |
                    row.objectiveFk.equals(objectivePk).not())))
          .write(TransactionsCompanion(objectiveFk: Value(objectivePk)));

  Future<FireflyIdMapping?> fireflyPiggyBankMapping(String objectivePk) async {
    if ((await fireflyObjective(objectivePk))?.type != ObjectiveType.goal) {
      return null;
    }
    final mapping =
        await IdMapRepository(this).byLocal(_piggyBank, objectivePk);
    return mapping == null ||
            IdMapRepository.isProvisional(mapping) ||
            mapping.state == FireflySyncState.pendingDelete ||
            mapping.state == FireflySyncState.localOnly
        ? null
        : mapping;
  }

  /// The last server-supplied amount, or null before the goal has synced.
  Future<double?> fireflyPiggyBankCurrentAmount(String objectivePk) async {
    final cached = await _piggyBankCache(objectivePk);
    if (cached == null) return null;
    return FireflyPiggyBank.fromJson(ResourceCacheRepository.decode(cached))
        .currentAmount;
  }

  Future<List<FireflyPiggyBankEvent>> fireflyPiggyBankEvents(
      String objectivePk) async {
    final cached = await _piggyBankCache(objectivePk);
    return cached == null ? [] : _cachedEvents(cached);
  }

  Future<Map<String, PiggyBankJournalLink>>
      fireflyPiggyBankJournalLinks() async {
    final cache = ResourceCacheRepository(this);
    final mappings = await IdMapRepository(this).list(_piggyBank);
    final goals = {for (final goal in await fireflyGoals()) goal.objectivePk};
    final localPks = {
      for (final mapping in mappings)
        if (goals.contains(mapping.localPk) &&
            !IdMapRepository.isProvisional(mapping) &&
            mapping.state != FireflySyncState.pendingDelete &&
            mapping.state != FireflySyncState.localOnly)
          ResourceCacheRepository.resourcePk(_piggyBank, mapping.remoteId):
              mapping.localPk,
    };
    final latest = <String, FireflyPiggyBankEvent>{};
    final links = <String, PiggyBankJournalLink>{};
    for (final row in await cache.list(_piggyBank)) {
      final objectivePk = localPks[row.resourcePk];
      if (objectivePk == null) continue;
      for (final event in _cachedEvents(row)) {
        final journalId = event.journalId;
        if (journalId == null) continue;
        final previous = latest[journalId];
        if (previous != null && !_isLater(event, previous)) continue;
        latest[journalId] = event;
        links[journalId] = (objectivePk: objectivePk, groupId: event.groupId);
      }
    }
    return links;
  }

  // A journal may be outside the transaction syncer's current pull window.
  Future<void> linkFireflyPiggyBankJournals() => transaction(() async {
        final links = await fireflyPiggyBankJournalLinks();
        final journalIds = links.keys.toList();
        const batchSize = 500;
        for (var offset = 0; offset < journalIds.length; offset += batchSize) {
          final batch = journalIds.skip(offset).take(batchSize);
          final mappings = await (select(fireflyIdMap)
                ..where((row) =>
                    row.entityType.equalsValue(_transaction) &
                    row.remoteSubId.isIn(batch) &
                    row.state
                        .equalsValue(FireflySyncState.pendingDelete)
                        .not() &
                    row.state.equalsValue(FireflySyncState.localOnly).not()))
              .get();
          for (final mapping in mappings) {
            final link = links[mapping.remoteSubId]!;
            if (link.groupId == null || link.groupId == mapping.remoteId) {
              await linkFireflyGoal(mapping.localPk, link.objectivePk);
            }
          }
        }
      });

  Future<FireflyCachedResource?> _piggyBankCache(String objectivePk) async {
    final mapping = await fireflyPiggyBankMapping(objectivePk);
    return mapping == null
        ? null
        : ResourceCacheRepository(this).read(_piggyBank, mapping.remoteId);
  }
}

List<FireflyPiggyBankEvent> _cachedEvents(FireflyCachedResource cached) {
  final events = ResourceCacheRepository.decode(cached)['events'] as List;
  return events.cast<JsonObject>().map(FireflyPiggyBankEvent.fromJson).toList();
}

bool _isLater(FireflyPiggyBankEvent event, FireflyPiggyBankEvent previous) {
  final date = event.createdAt;
  final previousDate = previous.createdAt;
  if (date != previousDate) {
    return date != null && (previousDate == null || date.isAfter(previousDate));
  }
  final id = int.tryParse(event.id);
  final previousId = int.tryParse(previous.id);
  return id != null && previousId != null
      ? id > previousId
      : event.id.compareTo(previous.id) > 0;
}

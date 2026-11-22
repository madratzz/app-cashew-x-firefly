import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:drift/drift.dart';

extension FireflyTagQueries on FinanceDatabase {
  Future<Tag?> fireflyTag(String tagPk) =>
      (select(tags)..where((row) => row.tagPk.equals(tagPk))).getSingleOrNull();

  Future<List<Tag>> fireflyTransactionTags(String transactionPk) async =>
      _sortedTags(await _fireflyTransactionTagsQuery(transactionPk).get());

  Stream<List<Tag>> watchFireflyTransactionTags(String transactionPk) =>
      _fireflyTransactionTagsQuery(transactionPk).watch().map(_sortedTags);

  Future<List<Tag>> fireflyTags({String? search}) async =>
      _sortedTags(await select(tags).get(), search: search);

  Future<List<Tag>> fireflyTagsWithNames(Set<String> names) =>
      (select(tags)..where((row) => row.name.isIn(names))).get();

  Stream<List<Tag>> watchFireflyTags({String? search}) =>
      select(tags).watch().map((rows) => _sortedTags(rows, search: search));

  /// Creates a tag when [tagPk] is absent, otherwise updates the existing row.
  /// A null description or date clears the corresponding field.
  Future<Tag> saveFireflyTag({
    String? tagPk,
    required String name,
    String? description,
    DateTime? date,
  }) async {
    final normalized = name.trim();
    final details = description?.trim();
    if (normalized.isEmpty || normalized.runes.length > 1024) {
      throw ArgumentError.value(name, 'name');
    }
    if (details != null && details.runes.length > 32768) {
      throw ArgumentError.value(description, 'description');
    }
    final fields = TagsCompanion(
      name: Value(normalized),
      description: Value(details == '' ? null : details),
      date: Value(
          date == null ? null : DateTime(date.year, date.month, date.day)),
      dateTimeModified: Value(DateTime.now()),
    );
    if (tagPk == null) return into(tags).insertReturning(fields);
    final rows = await (update(tags)..where((row) => row.tagPk.equals(tagPk)))
        .writeReturning(fields);
    return rows.single;
  }

  /// Queues a mapped deletion and removes its links atomically.
  Future<void> deleteFireflyTag(String tagPk) => transaction(() async {
        final idMap = IdMapRepository(this);
        final map = await idMap.byLocal(FireflyEntityType.tag, tagPk);
        if (map != null && IdMapRepository.isProvisional(map)) {
          // The server may have accepted a POST whose response was lost.
          final tag = await fireflyTag(tagPk);
          if (tag != null) {
            await SyncMetaRepository(this)
                .write(fireflyTagDeleteKey(tagPk), tag.name.trim());
          }
        }
        await idMap.markPendingDelete(FireflyEntityType.tag, tagPk);
        await removeFireflyTagLocally(tagPk);
      });

  /// Removes a tag after an accepted remote deletion without queuing a write.
  Future<void> removeFireflyTagLocally(String tagPk) => transaction(() async {
        // Some native database connections do not enable FK cascades.
        await (delete(transactionTags)..where((row) => row.tagFk.equals(tagPk)))
            .go();
        await (delete(tags)..where((row) => row.tagPk.equals(tagPk))).go();
      });

  /// Replaces accepted remote memberships without changing the transaction stamp.
  Future<void> replaceFireflyTransactionTagLinks(
      String transactionPk, Set<String> tagPks) {
    return transaction(() async {
      final existing = {
        for (final tag in await fireflyTransactionTags(transactionPk))
          tag.tagPk,
      };
      final removed = existing.difference(tagPks);
      if (removed.isNotEmpty) {
        await (delete(transactionTags)
              ..where((row) =>
                  row.transactionFk.equals(transactionPk) &
                  row.tagFk.isIn(removed)))
            .go();
      }
      final added = tagPks.difference(existing);
      if (added.isEmpty) return;
      final available =
          await (select(tags)..where((row) => row.tagPk.isIn(added))).get();
      await batch((batch) {
        batch.insertAll(transactionTags, [
          for (final tag in available)
            TransactionTagsCompanion.insert(
                transactionFk: transactionPk, tagFk: tag.tagPk),
        ]);
      });
    });
  }

  Selectable<Tag> _fireflyTransactionTagsQuery(String transactionPk) =>
      (select(tags).join([
        innerJoin(transactionTags, transactionTags.tagFk.equalsExp(tags.tagPk),
            useColumns: false),
      ])
            ..where(transactionTags.transactionFk.equals(transactionPk)))
          .map((row) => row.readTable(tags));
}

List<Tag> _sortedTags(List<Tag> rows, {String? search}) {
  final term = search?.trim().toLowerCase();
  final result = [
    for (final row in rows)
      if (term == null || row.name.toLowerCase().contains(term)) row,
  ];
  result.sort((a, b) {
    final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return order == 0 ? a.tagPk.compareTo(b.tagPk) : order;
  });
  return result;
}

String fireflyTagDeleteKey(String tagPk) => 'tag.pendingDeleteName.$tagPk';

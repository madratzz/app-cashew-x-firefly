import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/tag_syncer.dart';

class TagsContributor extends TransactionContributor {
  const TagsContributor();

  @override
  String get id => 'tags';

  @override
  int get version => 1;

  @override
  Future<Transaction> projectRemote(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    Transaction row,
  ) async {
    // Membership lives in junction rows and is projected by contributeHash.
    return row;
  }

  @override
  Future<void> contributeHash(
    SyncContext context,
    Transaction row,
    JsonObject fields, {
    FireflyTransaction? group,
    FireflyTransactionSplit? split,
  }) async {
    if (!context.config.mode) return;
    final tagPks = split == null
        ? [
            for (final tag
                in await context.db.fireflyTransactionTags(row.transactionPk))
              tag.tagPk,
          ]
        : (await _remoteTagPks(context, split)).toList();
    // Preserve existing hashes for transactions without tags.
    if (tagPks.isEmpty) {
      fields.remove('tags');
    } else {
      fields['tags'] = tagPks..sort();
    }
  }

  @override
  Future<void> pull(
    SyncContext context,
    FireflyTransaction group,
    FireflyTransactionSplit split,
    String transactionPk,
  ) async {
    if (!context.config.mode) return;
    final tagPks = await _remoteTagPks(context, split);
    await context.db.replaceFireflyTransactionTagLinks(transactionPk, tagPks);
  }

  @override
  Future<void> push(
    SyncContext context,
    Transaction transaction,
    JsonObject split,
  ) async {
    if (!context.config.mode) return;
    final names = <String>{};
    for (final tag
        in await context.db.fireflyTransactionTags(transaction.transactionPk)) {
      final map = await context.idMap.byLocal(FireflyEntityType.tag, tag.tagPk);
      final remoteName =
          map == null ? null : TagSyncer.remoteNameForId(context, map.remoteId);
      names.add(remoteName ?? tag.name.trim());
    }
    split['tags'] = names.toList()..sort();
  }

  Future<Set<String>> _remoteTagPks(
      SyncContext context, FireflyTransactionSplit split) async {
    final names = split.fields['tags'];
    if (names == null) return {};
    if (names is! List || names.any((name) => name is! String)) {
      throw const FireflyInvalidPayload();
    }
    final result = <String>{};
    final unlistedNames = <String>{};
    for (final name
        in names.cast<String>().map((name) => name.trim()).toSet()) {
      final id = TagSyncer.remoteIdForName(context, name);
      if (id == null) {
        unlistedNames.add(name);
        continue;
      }
      final map = await context.idMap.byRemote(FireflyEntityType.tag, id);
      if (map != null) result.add(map.localPk);
    }
    // An incomplete listing may omit an already-mapped tag. Keep the known
    // link unless the current listing supplies a different server name.
    if (unlistedNames.isNotEmpty) {
      for (final tag in await context.db.fireflyTagsWithNames(unlistedNames)) {
        final map =
            await context.idMap.byLocal(FireflyEntityType.tag, tag.tagPk);
        if (map != null &&
            map.state != FireflySyncState.localOnly &&
            !IdMapRepository.isProvisional(map) &&
            TagSyncer.remoteNameForId(context, map.remoteId) == null) {
          result.add(tag.tagPk);
        }
      }
    }
    return result;
  }
}

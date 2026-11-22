import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction_link.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/object_group_syncer.dart';
import 'package:drift/drift.dart';

const _entity = FireflyEntityType.transactionLink;
// The frozen schema stores links and their type catalog under one enum value.
const _linkTypePrefix = 'link-type:';

class TransactionLinkSyncer extends EntitySyncer {
  const TransactionLinkSyncer();

  static final _pending = Expando<Future<void>>();

  @override
  FireflyEntityType get type => _entity;

  @override
  Set<FireflyEntityType> get dependsOn => const {
        FireflyEntityType.transaction,
      };

  @override
  Future<void> pull(SyncContext context) => _serialize(context.db, () async {
        await pullFireflyCachedResources(
          context,
          type,
          (page, limit) => context.api.transactionLinks
              .listTypes(page: page, limit: limit)
              .then((page) => page.map(FireflyLinkType.fromJson)),
          (linkType) => linkType.toJson(),
          keyPrefix: _linkTypePrefix,
        );
        await pullFireflyCachedResources(
          context,
          type,
          (page, limit) =>
              context.api.transactionLinks.list(page: page, limit: limit),
          (link) => link.toJson(),
          excludedPrefix: _linkTypePrefix,
        );
      });

  /// Online write using the journal IDs mapped to the two local rows.
  Future<FireflyTransactionLink> createLink(
    SyncContext context, {
    required String inwardTransactionPk,
    required String outwardTransactionPk,
    required String linkTypeId,
    String? notes,
  }) =>
      _serialize(context.db, () async {
        _requireConnection(context);
        final inward = await _journalId(context, inwardTransactionPk);
        final outward = await _journalId(context, outwardTransactionPk);
        if (inward == outward) {
          throw const FireflyValidation('Select two journals.');
        }
        final link = await context.api.transactionLinks.create({
          'inward_id': inward,
          'outward_id': outward,
          'link_type_id': linkTypeId,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        });
        await writeFireflyCachedResource(context, type, link.id, link.toJson(),
            updatedAt: link.updatedAt);
        return link;
      });

  Future<void> deleteLink(SyncContext context, String id) =>
      _serialize(context.db, () async {
        _requireConnection(context);
        try {
          await context.api.transactionLinks.delete(id);
        } on FireflyNotFound {
          // A prior attempt or another device already removed it.
        }
        await context.cache.remove(type, id);
      });

  void _requireConnection(SyncContext context) {
    if (!context.config.mode || context.isCancelled()) {
      throw const FireflyTransportUnavailable();
    }
  }

  Future<String> _journalId(SyncContext context, String localPk) async {
    final mapping =
        await context.idMap.byLocal(FireflyEntityType.transaction, localPk);
    if (mapping == null || !_hasJournal(mapping)) {
      throw const FireflyValidation('Sync the transaction before linking it.');
    }
    return mapping.remoteSubId;
  }

  Future<T> _serialize<T>(FinanceDatabase db, Future<T> Function() action) {
    final previous = _pending[db] ?? Future<void>.value();
    final result = previous.then((_) => action());
    _pending[db] =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

typedef FireflyLinkTarget = ({
  String transactionPk,
  String journalId,
  String name
});

extension FireflyLinkQueries on FinanceDatabase {
  Stream<List<FireflyTransactionLink>> watchFireflyTransactionLinks() =>
      _watchLinkCache(types: false).map((rows) => rows
          .map((row) => FireflyTransactionLink.fromJson(
              ResourceCacheRepository.decode(row)))
          .toList());

  Stream<List<FireflyLinkType>> watchFireflyLinkTypes() =>
      _watchLinkCache(types: true).map((rows) => rows
          .map((row) =>
              FireflyLinkType.fromJson(ResourceCacheRepository.decode(row)))
          .toList());

  Stream<List<FireflyCachedResource>> _watchLinkCache({required bool types}) =>
      ResourceCacheRepository(this).watch(_entity).map((rows) => [
            for (final row in rows)
              if (row.resourcePk
                      .startsWith('${_entity.name}:$_linkTypePrefix') ==
                  types)
                row,
          ]);

  Stream<List<FireflyLinkTarget>> watchFireflyLinkTargets() {
    final query = select(fireflyIdMap).join([
      innerJoin(transactions,
          transactions.transactionPk.equalsExp(fireflyIdMap.localPk)),
    ])
      ..where(
          fireflyIdMap.entityType.equalsValue(FireflyEntityType.transaction))
      ..orderBy([
        OrderingTerm.asc(fireflyIdMap.remoteRole),
        OrderingTerm.desc(transactions.dateCreated),
      ]);
    return query.watch().map((rows) {
      final targets = <String, FireflyLinkTarget>{};
      for (final row in rows) {
        final mapping = row.readTable(fireflyIdMap);
        if (!_hasJournal(mapping)) continue;
        final transaction = row.readTable(transactions);
        targets.putIfAbsent(
            mapping.remoteSubId,
            () => (
                  transactionPk: transaction.transactionPk,
                  journalId: mapping.remoteSubId,
                  name: transaction.name,
                ));
      }
      return targets.values.toList();
    });
  }
}

bool _hasJournal(FireflyIdMapping mapping) =>
    mapping.remoteSubId.isNotEmpty &&
    mapping.state != FireflySyncState.pendingDelete &&
    mapping.state != FireflySyncState.localOnly &&
    !IdMapRepository.isProvisional(mapping);

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';

enum SyncPullMode { incremental, initial, full }

enum SyncPhase { preflight, pull, push, delete, reread, parity, complete }

class SyncContext {
  SyncContext({
    required this.db,
    required this.api,
    required this.config,
    this.pullMode = SyncPullMode.incremental,
    DateTime Function()? now,
    bool Function()? isCancelled,
  })  : now = now ?? DateTime.now,
        isCancelled = isCancelled ?? _neverCancelled,
        idMap = IdMapRepository(db),
        meta = SyncMetaRepository(db),
        conflicts = ConflictRepository(db),
        cache = ResourceCacheRepository(db);

  final FinanceDatabase db;
  final FireflyApi api;
  final FireflyConfig config;
  final SyncPullMode pullMode;
  final DateTime Function() now;
  final bool Function() isCancelled;
  final IdMapRepository idMap;
  final SyncMetaRepository meta;
  final ConflictRepository conflicts;
  final ResourceCacheRepository cache;
  final Set<String> pushedTransactionIds = {};

  static bool _neverCancelled() => false;
}

class SyncIssue {
  const SyncIssue(this.message, {this.entityType, this.phase});
  final String message;
  final FireflyEntityType? entityType;
  final SyncPhase? phase;
}

class SyncReport {
  const SyncReport({
    this.startedAt,
    this.finishedAt,
    this.cancelled = false,
    this.issues = const [],
    this.balanceMismatches = const {},
  });

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool cancelled;
  final List<SyncIssue> issues;
  final Map<String, double> balanceMismatches;
  bool get succeeded => !cancelled && issues.isEmpty;
}

class SyncProgress {
  const SyncProgress(this.phase, {this.entityType});
  final SyncPhase phase;
  final FireflyEntityType? entityType;
}

abstract class EntitySyncer {
  const EntitySyncer();

  FireflyEntityType get type;
  Set<FireflyEntityType> get dependsOn => const {};
  Future<void> pull(SyncContext context) async {}
  Future<void> push(SyncContext context) async {}
  Future<void> pushDeletes(SyncContext context) async {}

  /// The transaction syncer reloads ids in context.pushedTransactionIds.
  Future<void> rereadPushed(SyncContext context) async {}
}

abstract class TransactionContributor {
  const TransactionContributor();

  String get id;
  int get version => 0;

  /// Projects remote split fields onto the candidate row for conflict hashing.
  /// Perform no writes here. Clear owned local fields absent from the split.
  Future<Transaction> projectRemote(
          SyncContext context,
          FireflyTransaction group,
          FireflyTransactionSplit split,
          Transaction row) async =>
      row;

  /// Runs in the same database transaction as applying the split.
  Future<void> pull(SyncContext context, FireflyTransaction group,
      FireflyTransactionSplit split, String transactionPk) async {}

  /// Adds owned fields to the outgoing writable split map.
  Future<void> push(
      SyncContext context, Transaction transaction, JsonObject split) async {}

  /// Adds owned fields to the hash of a local row or a projected remote row.
  /// Remote fields can be used directly for relationships stored separately.
  Future<void> contributeHash(
    SyncContext context,
    Transaction row,
    JsonObject fields, {
    FireflyTransaction? group,
    FireflyTransactionSplit? split,
  }) =>
      push(context, row, fields);

  /// Adds owned fields to a transaction group create or update body.
  Future<void> pushGroup(
      SyncContext context, TransactionGroup group, JsonObject fields) async {}
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/db/delete_log_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/dirty_tracker.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:budget/firefly/sync/meta_roaming.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  SyncEngine(this.context,
      {this.syncers = entitySyncers,
      this.contributors = transactionContributors});

  final SyncContext context;
  final List<EntitySyncer> syncers;
  final List<TransactionContributor> contributors;
  final _progress = StreamController<SyncProgress>.broadcast();
  Future<SyncReport>? _running;
  bool _cancelled = false;
  bool _disposed = false;
  SyncReport? _lastReport;

  bool get isRunning => _running != null;
  SyncReport? get lastReport => _lastReport;
  Stream<SyncProgress> get progress => _progress.stream;

  bool get _shouldStop =>
      _cancelled ||
      _disposed ||
      !context.config.mode ||
      kIsWeb ||
      context.isCancelled();

  Future<SyncReport> run({bool fullResync = false}) {
    final running = _running;
    if (running != null) return running;
    _cancelled = false;
    if (_shouldStop) return Future.value(const SyncReport(cancelled: true));
    // Install the lock before entering preflight or invoking any cycle hooks.
    return _running =
        Future.microtask(() => _runCycle(fullResync)).whenComplete(() {
      _running = null;
      _progress.add(const SyncProgress(SyncPhase.complete));
    });
  }

  void cancel() => _cancelled = true;

  Future<void> dispose() async {
    _disposed = true;
    await _running;
    await _progress.close();
  }

  Future<SyncReport> _runCycle(bool fullResync) async {
    final startedAt = context.now();
    final issues = <SyncIssue>[];
    final mismatches = <String, double>{};
    final failed = <FireflyEntityType>{};
    var phase = SyncPhase.preflight;
    FireflyEntityType? entityType;

    void reportError(Object error) {
      final message = switch (error) {
        FireflyUnauthorized() => 'firefly-sync-auth-required',
        _ServerIdentityChanged() => 'firefly-sync-identity-changed',
        _ => 'firefly-sync-failed',
      };
      issues.add(SyncIssue(message, entityType: entityType, phase: phase));
      // Exception text can include request details or local data.
      logFirefly(
          'Firefly sync ${phase.name} ${entityType?.name ?? ""}: ${error.runtimeType}');
    }

    Future<void> runPhase(
      SyncPhase nextPhase,
      Iterable<EntitySyncer> ordered,
      Future<void> Function(EntitySyncer) action,
    ) async {
      phase = nextPhase;
      entityType = null;
      _checkCancelled();
      final blockedDeletes = <FireflyEntityType>{};
      for (final syncer in ordered) {
        _checkCancelled();
        final type = syncer.type;
        if (failed.contains(type) ||
            syncer.dependsOn.any(failed.contains) ||
            blockedDeletes.contains(type)) {
          failed.add(type);
          if (phase == SyncPhase.delete) {
            blockedDeletes.addAll(syncer.dependsOn);
          }
          continue;
        }
        entityType = type;
        _progress.add(SyncProgress(phase, entityType: type));
        try {
          await action(syncer);
        } on _CycleCancelled {
          rethrow;
        } catch (error) {
          if (_abortsCycle(error)) rethrow;
          reportError(error);
          failed.add(type);
          if (phase == SyncPhase.delete) {
            blockedDeletes.addAll(syncer.dependsOn);
          }
        }
      }
      entityType = null;
    }

    // Presentation roaming never blocks the entity sync around it.
    Future<void> runRoaming(Future<void> Function() action) async {
      if (!context.config.metaRoaming) return;
      _checkCancelled();
      entityType = null;
      try {
        await action();
      } catch (error) {
        if (_abortsCycle(error)) rethrow;
        reportError(error);
      }
      _checkCancelled();
    }

    try {
      _checkCancelled();
      _progress.add(const SyncProgress(SyncPhase.preflight));
      await _preflight();
      _checkCancelled();
      await _collectDeletes();
      _checkCancelled();

      final versions = {
        for (final contributor in contributors)
          SyncMetaRepository.contributorVersion(contributor.id):
              contributor.version.toString(),
      };
      final pullMode = await _pullMode(startedAt, fullResync, versions);
      final cycle = SyncContext(
        db: context.db,
        api: context.api,
        config: context.config,
        pullMode: pullMode,
        now: context.now,
        isCancelled: () => _shouldStop,
      );

      await runPhase(SyncPhase.pull, syncers, (syncer) async {
        await syncer.pull(cycle);
        _checkCancelled();
        if (syncer.type == FireflyEntityType.transaction) {
          await _checkpointTransactionPull(cycle, startedAt, versions);
        }
      });
      final roaming =
          FireflyMetaRoaming(cycle, enabled: cycle.config.metaRoaming);
      await runRoaming(roaming.pull);
      await runPhase(SyncPhase.push, syncers, (syncer) => syncer.push(cycle));
      await runPhase(SyncPhase.delete, syncers.reversed,
          (syncer) => syncer.pushDeletes(cycle));
      await runRoaming(roaming.push);

      _checkCancelled();
      phase = SyncPhase.reread;
      if (cycle.pushedTransactionIds.isNotEmpty) {
        entityType = FireflyEntityType.transaction;
        _progress.add(SyncProgress(phase, entityType: entityType));
        try {
          await syncers
              .firstWhere(
                  (syncer) => syncer.type == FireflyEntityType.transaction)
              .rereadPushed(cycle);
        } on _CycleCancelled {
          rethrow;
        } catch (error) {
          if (_abortsCycle(error)) rethrow;
          reportError(error);
        }
        entityType = null;
      }

      _checkCancelled();
      phase = SyncPhase.parity;
      _progress.add(const SyncProgress(SyncPhase.parity));
      if (!failed.contains(FireflyEntityType.walletAccount)) {
        await _checkBalances(cycle, mismatches);
      }
      _checkCancelled();
      phase = SyncPhase.complete;
      if (issues.isEmpty) {
        await context.meta
            .writeDate(SyncMetaRepository.lastSync, context.now());
      }
    } on _CycleCancelled {
      _cancelled = true;
    } catch (error) {
      reportError(error);
    }

    return _lastReport = SyncReport(
      startedAt: startedAt,
      finishedAt: context.now(),
      cancelled: _shouldStop,
      issues: List.unmodifiable(issues),
      balanceMismatches: Map.unmodifiable(mismatches),
    );
  }

  void _checkCancelled() {
    if (_shouldStop) throw const _CycleCancelled();
  }

  bool _abortsCycle(Object error) => switch (error) {
        FireflyUnauthorized() ||
        FireflyRateLimited() ||
        FireflyServerError() ||
        FireflyNetworkError() ||
        FireflyTimeout() =>
          true,
        _ => false,
      };

  Future<void> _preflight() async {
    final urlHash =
        fireflyTextHash(normalizeFireflyUrl(context.config.baseUrl).toString());
    final meta = context.meta;
    final storedUrlHash = await meta.read(SyncMetaRepository.serverUrlHash);
    if (storedUrlHash != null && storedUrlHash != urlHash) {
      throw const _ServerIdentityChanged();
    }

    _checkCancelled();
    final about = await context.api.about.get();
    _checkCancelled();
    // A new token can change the authenticated identity at the same URL.
    final user = await context.api.about.getUser();
    if (user.id.isEmpty || about.version.isEmpty) {
      throw const FireflyInvalidPayload();
    }
    _checkCancelled();

    await context.db.transaction(() async {
      final storedUser = await meta.read(SyncMetaRepository.serverUserId);
      if (storedUser != null && storedUser != user.id) {
        throw const _ServerIdentityChanged();
      }
      await meta.write(SyncMetaRepository.serverUrlHash, urlHash);
      await meta.write(SyncMetaRepository.serverUserId, user.id);
      await meta.write(SyncMetaRepository.serverVersion, about.version);
    });
  }

  static const _deleteLogBoundary = 'deleteLogCursor.processedIds';

  Future<void> _collectDeletes() => context.db.transaction(() async {
        final meta = context.meta;
        final cursor = await meta.readDate(SyncMetaRepository.deleteLogCursor);
        final boundary = await meta.read(_deleteLogBoundary);
        final processed = boundary == null
            ? <String>{}
            : Set<String>.from(jsonDecode(boundary) as List<Object?>);
        // Drift stores timestamps in seconds. A new delete can occupy the same
        // second as an already checkpointed log. Keep the PKs at that boundary.
        final logs = await context.db
            .fireflyDeleteLogs(after: cursor, includeAfter: true);
        final pending =
            logs.where((log) => !processed.contains(log.deleteLogPk)).toList();
        if (pending.isEmpty) return;
        await DirtyTracker(context.idMap).collectDeletes(pending);
        final latest = pending.last.dateTimeModified;
        await meta.writeDate(SyncMetaRepository.deleteLogCursor, latest);
        await meta.write(
          _deleteLogBoundary,
          jsonEncode([
            for (final log in logs)
              if (log.dateTimeModified == latest) log.deleteLogPk,
          ]),
        );
      });

  Future<SyncPullMode> _pullMode(
      DateTime startedAt, bool fullResync, Map<String, String> versions) async {
    if (fullResync || context.pullMode == SyncPullMode.full) {
      return SyncPullMode.full;
    }
    final meta = context.meta;
    final cursor = await meta.readDate(SyncMetaRepository.transactionCursor);
    if (cursor == null || context.pullMode == SyncPullMode.initial) {
      return SyncPullMode.initial;
    }
    final lastFull = await meta.readDate(SyncMetaRepository.lastFullReconcile);
    if (lastFull == null ||
        startedAt.difference(lastFull) >= const Duration(days: 7)) {
      return SyncPullMode.full;
    }
    for (final entry in versions.entries) {
      if (await meta.read(entry.key) != entry.value) return SyncPullMode.full;
    }
    return SyncPullMode.incremental;
  }

  Future<void> _checkpointTransactionPull(SyncContext cycle, DateTime startedAt,
          Map<String, String> versions) =>
      cycle.db.transaction(() async {
        final meta = cycle.meta;
        await meta.writeDate(SyncMetaRepository.transactionCursor, startedAt);
        if (cycle.pullMode != SyncPullMode.incremental) {
          await meta.writeDate(SyncMetaRepository.lastFullReconcile, startedAt);
          await meta.remove(SyncMetaRepository.transactionPage);
          for (final entry in versions.entries) {
            await meta.write(entry.key, entry.value);
          }
        }
      });

  Future<void> _checkBalances(
      SyncContext cycle, Map<String, double> mismatches) async {
    const type = FireflyEntityType.walletAccount;
    for (final mapping
        in await cycle.idMap.list(type, state: FireflySyncState.synced)) {
      _checkCancelled();
      if (IdMapRepository.isProvisional(mapping)) continue;
      final wallet = await cycle.db.getWalletInstanceOrNull(mapping.localPk);
      if (wallet == null || wallet.accountKind != AccountKind.asset) continue;
      _checkCancelled();

      // The pull snapshot predates pushes and server-side rules in this cycle.
      final Object? balance;
      try {
        final account = await cycle.api.accounts.get(mapping.remoteId);
        balance = account.attributes['current_balance'];
      } on FireflyNotFound {
        continue;
      }
      if (balance == null) continue;
      final remote = parseFireflyAmount(balance.toString());
      _checkCancelled();
      final local = await cycle.db
              .watchTotalOfWalletNoConversion(wallet.walletPk)
              .first ??
          0;
      final difference = local - remote;
      final halfMinorUnit = math.pow(10, -wallet.decimals) / 2;
      if (difference.abs() >= halfMinorUnit) {
        mismatches[wallet.walletPk] = difference;
      }
    }
  }
}

class _CycleCancelled implements Exception {
  const _CycleCancelled();
}

class _ServerIdentityChanged implements Exception {
  const _ServerIdentityChanged();
}

import 'dart:io';
import 'dart:math' as math;

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/db/transaction_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/attachment_syncer.dart';
import 'package:budget/firefly/sync/entities/wallet_account_syncer.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:budget/firefly/sync/registry.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'bootstrap_database_unsupported.dart'
    if (dart.library.io) 'bootstrap_database_native.dart';

typedef _Type = FireflyEntityType;

const _steps = [
  _Type.walletAccount,
  _Type.liabilityAccount,
  _Type.category,
  _Type.payeeAccount,
  _Type.tag,
  _Type.budget,
  _Type.budgetLimit,
  _Type.piggyBank,
  _Type.bill,
  _Type.transaction,
  _Type.attachment,
];

class FireflyUploadIssue extends SyncIssue {
  const FireflyUploadIssue(super.message,
      {super.entityType, super.phase, this.item, this.intent, this.detail});

  final String? item;
  final String? intent;
  final String? detail;
}

class FireflyUploadReport extends SyncReport {
  const FireflyUploadReport({
    super.startedAt,
    super.finishedAt,
    super.cancelled,
    super.issues,
    super.balanceMismatches,
    this.cleanupWarnings = const [],
  });

  final List<FireflyUploadIssue> cleanupWarnings;
}

class FireflyUploadPreview {
  FireflyUploadPreview._({
    required Map<_Type, List<_Item>> items,
    required this.transfers,
    required this.splits,
    required this.splitGroups,
    required this.roundedTransactions,
    required Set<String> currencies,
    required List<FireflyUploadIssue> skipped,
    required this.resuming,
    required String snapshot,
    required String destination,
  })  : counts = Map.unmodifiable({
          for (final type in _steps) type: items[type]?.length ?? 0,
          _Type.currency: currencies.length,
        }),
        currencies = List.unmodifiable(currencies.toList()..sort()),
        skipped = List.unmodifiable(skipped),
        _items = items,
        _snapshot = snapshot,
        _destination = destination;

  /// Transaction count is Cashew rows. Each transfer combines two such rows.
  final Map<FireflyEntityType, int> counts;
  final int transfers;
  final int splits;
  final int splitGroups;
  final int roundedTransactions;
  final List<String> currencies;
  final List<FireflyUploadIssue> skipped;
  final bool resuming;
  final Map<_Type, List<_Item>> _items;
  final String _snapshot;
  final String _destination;
}

typedef _Item = ({String pk, String label});
typedef FireflyUploadCandidate = ({String id, String label});

/// First-connect upload. The ordinary syncer pushes run on a private copy
/// because their normal bookkeeping also updates finance rows and caches.
class FireflyBootstrapUpload {
  const FireflyBootstrapUpload(this.context, {this.attachmentDirectory});

  final SyncContext context;
  final Directory? attachmentDirectory;

  static final _running = Expando<bool>();
  static const _sessionKey = 'cashew.bootstrap/session';
  static const _intentPrefix = 'cashew.bootstrap/intent/';
  // Currency catalog entries have no ordinary ID mappings. Reserve these
  // synthetic keys for durable upload intents without touching finance rows.
  static const _journalType = _Type.currency;

  static Future<bool> inProgress(FinanceDatabase db) async =>
      _running[db] == true ||
      await IdMapRepository(db).byLocal(_journalType, _sessionKey) != null;

  /// Acknowledge the handoff only after Firefly mode has been enabled.
  static Future<void> finishHandoff(FinanceDatabase db) async {
    final ids = IdMapRepository(db);
    if ((await ids.byLocal(_journalType, _sessionKey))?.state ==
        FireflySyncState.synced) {
      await db.transaction(() async {
        for (final entry in await _intents(ids)) {
          await ids.remove(_journalType, entry.localPk);
        }
        await ids.remove(_journalType, _sessionKey);
      });
    }
  }

  /// Forget an unfinished attempt. Firefly's data is left in place.
  static Future<void> abandon(FinanceDatabase db) => db.transaction(() async {
        if (_running[db] == true) {
          throw const FireflyUploadIssue('firefly-upload-busy');
        }
        final ids = IdMapRepository(db);
        final session = await ids.byLocal(_journalType, _sessionKey);
        if (session?.state == FireflySyncState.synced) {
          throw const FireflyUploadIssue('firefly-upload-ready');
        }
        for (final entry in await _intents(ids)) {
          await ids.remove(_journalType, entry.localPk);
        }
        await ids.remove(_journalType, _sessionKey);
      });

  Future<bool> canUpload() async {
    try {
      await prepare();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FireflyUploadPreview> prepare() async {
    final snapshot = await _UploadSnapshot.read(context.db);
    return _prepare(snapshot);
  }

  Future<String> _destination() async {
    final user = await context.api.about.getUser();
    return syncedFieldsHash({
      'url': context.config.baseUrl,
      'user': user.id,
    });
  }

  Future<FireflyUploadPreview> _prepare(_UploadSnapshot snapshot) async {
    _ensureInactive();
    final session = await context.idMap.byLocal(_journalType, _sessionKey);
    final destination = await _destination();
    if (session != null && session.remoteSubId != destination) {
      throw const FireflyUploadIssue('firefly-upload-destination-changed');
    }
    if (session?.state != FireflySyncState.synced &&
        snapshot.hasOtherMappings) {
      throw const FireflyUploadIssue('firefly-upload-source-linked');
    }
    if (session != null && session.syncedHash != snapshot.hash) {
      throw const FireflyUploadIssue('firefly-upload-source-changed');
    }
    await _inventory(await _intents(context.idMap));
    final db = await snapshot.open();
    try {
      return await snapshot.preview(db,
          destination: destination,
          resuming: session != null, primaryCurrency: () async {
        final code = (await context.api.currencies.primary()).code;
        if (code == null || code.trim().isEmpty) {
          throw const FireflyInvalidPayload();
        }
        return code;
      });
    } finally {
      await db.close();
    }
  }

  void _ensureInactive() {
    if (context.config.baseUrl.trim().isEmpty) {
      throw const FireflyUploadIssue('firefly-connection-url-required');
    }
    if (context.config.mode || context.isCancelled()) {
      throw const FireflyUploadIssue('firefly-upload-mode-active');
    }
  }

  Future<FireflyUploadReport> run({FireflyUploadPreview? confirmed}) async {
    if (confirmed == null) return const FireflyUploadReport(cancelled: true);
    final db = context.db;
    if (_running[db] == true) {
      return const FireflyUploadReport(
          issues: [FireflyUploadIssue('firefly-upload-busy')]);
    }
    _running[db] = true;
    final started = context.now();
    final issues = <SyncIssue>[];
    final mismatches = <String, double>{};
    List<FireflyUploadIssue> cleanupWarnings = const [];
    FinanceDatabase? copy;
    try {
      final snapshot = await _UploadSnapshot.read(db);
      final preview = await _prepare(snapshot);
      if (preview._snapshot != confirmed._snapshot ||
          preview._destination != confirmed._destination) {
        throw const FireflyUploadIssue('firefly-upload-source-changed');
      }
      final session = await _claim(preview, started);
      if (session.state != FireflySyncState.synced) {
        copy = await snapshot.open();
        await snapshot.stage(copy, preview);
        final pipe = _UploadTransport(this, session, copy);
        final staging = SyncContext(
          db: copy,
          api: FireflyApi(pipe),
          config: FireflyConfig(
            mode: true,
            baseUrl: context.config.baseUrl,
            applyRules: false,
            fireWebhooks: false,
            pageSize: context.config.pageSize,
            subcategorySeparator: context.config.subcategorySeparator,
          ),
          now: () => session.lastAttemptAt!,
          isCancelled: context.isCancelled,
        );
        await _enableCurrencies(staging, preview, issues);
        for (final type in _steps) {
          if (issues.isNotEmpty || context.isCancelled()) break;
          await _push(staging, pipe, preview, type, issues);
        }
        if (!context.isCancelled() && issues.isEmpty) {
          await _checkBalances(staging, preview, issues, mismatches);
        }
        if (!context.isCancelled() && issues.isEmpty && mismatches.isEmpty) {
          await _inventory(await _intents(context.idMap));
          await _publish(staging, session);
        }
      } else {
        await _checkBalances(context, preview, issues, mismatches);
      }
      if (issues.isEmpty && mismatches.isEmpty && !context.isCancelled()) {
        cleanupWarnings = await _cleanup(session);
      }
    } on FireflyUploadIssue catch (issue) {
      issues.add(issue);
    } on FireflyException catch (error) {
      issues.add(
          FireflyUploadIssue(_errorKey(error), phase: SyncPhase.preflight));
    } finally {
      try {
        await copy?.close();
      } finally {
        _running[db] = false;
      }
    }
    return FireflyUploadReport(
      startedAt: started,
      finishedAt: context.now(),
      issues: List.unmodifiable(issues),
      cancelled: context.isCancelled(),
      balanceMismatches: Map.unmodifiable(mismatches),
      cleanupWarnings: List.unmodifiable(cleanupWarnings),
    );
  }

  Future<FireflyIdMapping> _claim(
          FireflyUploadPreview preview, DateTime started) =>
      context.db.transaction(() async {
        final ids = context.idMap;
        final existing = await ids.byLocal(_journalType, _sessionKey);
        if (existing != null) return existing;
        final current = await _UploadSnapshot.read(context.db);
        if (current.hash != preview._snapshot || current.hasOtherMappings) {
          throw const FireflyUploadIssue('firefly-upload-source-changed');
        }
        final session = FireflyIdMapping(
          entityType: _journalType,
          localPk: _sessionKey,
          remoteId: const Uuid().v4(),
          remoteSubId: preview._destination,
          remoteRole: 0,
          syncedHash: preview._snapshot,
          state: FireflySyncState.creating,
          attempts: 0,
          lastAttemptAt: started,
        );
        await ids.put(session);
        return session;
      });

  Future<void> _publish(SyncContext staging, FireflyIdMapping session) async {
    final maps = await staging.db.select(staging.db.fireflyIdMap).get();
    await context.db.transaction(() async {
      _ensureInactive();
      final current = await _UploadSnapshot.read(context.db);
      if (current.hash != session.syncedHash || current.hasOtherMappings) {
        throw const FireflyUploadIssue('firefly-upload-source-changed');
      }
      for (final map in maps) {
        if (map.state == FireflySyncState.synced) await context.idMap.put(map);
      }
      await context.idMap.put(session.copyWith(state: FireflySyncState.synced));
    });
  }

  Future<List<FireflyUploadIssue>> _cleanup(FireflyIdMapping session) async {
    final transport = context.api.transport;
    final issues = <FireflyUploadIssue>[];
    for (final entry in await _intents(context.idMap)) {
      if (context.isCancelled()) break;
      final path = entry.remoteSubId;
      if (path == '/transactions' || entry.state != FireflySyncState.synced) {
        continue;
      }
      final item = '$path/${Uri.encodeComponent(entry.remoteId)}';
      final marker = _marker(session, entry);
      final field = _attribute(path);
      try {
        final remote = _RemoteRow(path, await transport.get(item));
        if (remote.marker != marker) continue;
        final value =
            _withoutMarker(remote.attributes[field] as String, marker);
        final response =
            _RemoteRow(path, await transport.put(item, {field: value ?? ''}));
        if (response.marker == marker) throw const FireflyInvalidPayload();
      } on FireflyException catch (error) {
        issues.add(FireflyUploadIssue('firefly-upload-cleanup-warning',
            item: entry.lastError, detail: _errorKey(error)));
      }
    }
    return issues;
  }

  Future<void> _enableCurrencies(SyncContext staging,
      FireflyUploadPreview preview, List<SyncIssue> issues) async {
    for (final code in preview.currencies) {
      if (context.isCancelled()) return;
      try {
        final currency = await staging.api.currencies.get(code);
        if (currency.enabled != true) await staging.api.currencies.enable(code);
      } on FireflyException catch (error) {
        issues.add(FireflyUploadIssue(_errorKey(error),
            entityType: _Type.currency, phase: SyncPhase.push, item: code));
      }
    }
  }

  Future<void> _push(SyncContext staging, _UploadTransport pipe,
      FireflyUploadPreview preview, _Type type, List<SyncIssue> issues) async {
    final items = preview._items[type] ?? const [];
    if (items.isEmpty) return;
    pipe.stage = type;
    final syncer = type == _Type.attachment
        ? AttachmentSyncer(supportDirectory: attachmentDirectory)
        : entitySyncers.singleWhere((syncer) => syncer.type == type);
    try {
      if (syncer is WalletAccountSyncer) {
        await syncer.pushForBootstrap(staging);
      } else {
        // Establish the attachment syncer's complete, empty staging view.
        // Previously created stages are replayed by their upload markers.
        if (type == _Type.attachment) await syncer.pull(staging);
        await syncer.push(staging);
      }
    } on FireflyUploadIssue catch (issue) {
      issues.add(issue);
      return;
    } on FireflyException catch (error) {
      issues.add(FireflyUploadIssue(_errorKey(error),
          entityType: type, phase: SyncPhase.push));
      return;
    }
    if (context.isCancelled()) return;
    for (final item in items) {
      final map = await staging.idMap.byLocal(type, item.pk);
      if (map?.state == FireflySyncState.synced &&
          !IdMapRepository.isProvisional(map!) &&
          pipe.accepted(type, map.remoteId)) {
        continue;
      }
      issues.add(FireflyUploadIssue(
          map?.state == FireflySyncState.error
              ? 'firefly-upload-rejected'
              : 'firefly-upload-item-unmapped',
          entityType: type,
          phase: SyncPhase.push,
          item: item.label,
          detail: map?.lastError == null
              ? null
              : redactFireflyLog(map!.lastError!)));
    }
  }

  Future<List<FireflyUploadIssue>> pending() async {
    final entries = await _intents(context.idMap);
    return [
      for (final entry in entries)
        if (entry.state == FireflySyncState.creating) _unresolved(entry),
    ];
  }

  /// Looks for definitive receipts without dispatching any create request.
  Future<void> checkAgain() async {
    _ensureInactive();
    final session = await context.idMap.byLocal(_journalType, _sessionKey);
    if (session == null || _running[context.db] == true) return;
    if (session.remoteSubId != await _destination()) {
      throw const FireflyUploadIssue('firefly-upload-destination-changed');
    }
    for (final entry in await _intents(context.idMap)) {
      if (entry.state != FireflySyncState.creating) continue;
      final matches = (await _list(entry.remoteSubId))
          .where((row) => row.hasMarker(_marker(session, entry)))
          .toList();
      if (matches.length == 1) {
        await context.db.transaction(() async {
          await _unchanged(entry);
          await context.idMap.put(entry.copyWith(
              remoteId: matches.single.id, state: FireflySyncState.synced));
        });
      }
    }
  }

  Future<List<FireflyUploadCandidate>> candidates(String key) async {
    final (session, entry) = await _pendingIntent(key);
    final rows = await _list(entry.remoteSubId);
    final matches = _candidates(session, entry, rows);
    return [
      for (final row in matches) (id: row.id, label: _label(row.attributes))
    ];
  }

  /// Confirmed by the user only after they inspect the matching resources.
  Future<void> link(String key, String id) async {
    final (session, entry) = await _pendingIntent(key);
    final rows = await _list(entry.remoteSubId);
    final matches = _candidates(session, entry, rows);
    if (!matches.any((row) => row.id == id)) {
      throw const FireflyUploadIssue('firefly-upload-link-mismatch');
    }
    if ((await _intents(context.idMap)).any((other) =>
        other != entry &&
        other.remoteSubId == entry.remoteSubId &&
        other.remoteId == id)) {
      throw const FireflyUploadIssue('firefly-upload-link-mismatch');
    }
    await context.db.transaction(() async {
      await _unchanged(entry);
      await context.idMap
          .put(entry.copyWith(remoteId: id, state: FireflySyncState.synced));
    });
  }

  Iterable<_RemoteRow> _candidates(
      FireflyIdMapping session, FireflyIdMapping entry, List<_RemoteRow> rows) {
    final tagged = rows.where((row) => row.hasMarker(_marker(session, entry)));
    return tagged.isEmpty
        ? rows.where((row) =>
            _identity(entry.remoteSubId, row.attributes) == entry.syncedHash)
        : tagged;
  }

  /// Authorizes one new attempt for an unresolved create. Always rechecks
  /// the full collection for the original marker before the next dispatch.
  Future<void> authorizeResend(String key) async {
    final (_, entry) = await _pendingIntent(key);
    await context.db.transaction(() async {
      await _unchanged(entry);
      await context.idMap.put(entry.copyWith(state: FireflySyncState.error));
    });
  }

  Future<void> _unchanged(FireflyIdMapping entry) async {
    if (_running[context.db] == true ||
        await context.idMap.byLocal(_journalType, entry.localPk) != entry) {
      throw const FireflyUploadIssue('firefly-upload-busy');
    }
  }

  Future<(FireflyIdMapping, FireflyIdMapping)> _pendingIntent(
      String key) async {
    _ensureInactive();
    final session = await context.idMap.byLocal(_journalType, _sessionKey);
    final entry = await context.idMap.byLocal(_journalType, key);
    if (_running[context.db] == true ||
        session == null ||
        session.remoteSubId != await _destination() ||
        !key.startsWith(_intentPrefix) ||
        entry?.state != FireflySyncState.creating) {
      throw const FireflyUploadIssue('firefly-upload-unverified');
    }
    return (session, entry!);
  }

  Future<List<_RemoteRow>> _list(String path) async {
    final rows = <String, _RemoteRow>{};
    int? total;
    int? pages;
    for (var number = 1;; number++) {
      if (context.isCancelled()) {
        throw const FireflyUploadIssue('firefly-upload-unverified');
      }
      final page = await context.api.transport.getPage(path, query: {
        'page': '$number',
        'limit': '${context.config.pageSize}',
        if (path == '/accounts' || path == '/transactions') 'type': 'all',
      });
      total ??= page.total;
      pages ??= page.totalPages;
      if (page.currentPage != number ||
          page.total != total ||
          page.totalPages != pages ||
          page.perPage <= 0 ||
          page.items.length > page.perPage ||
          total < 0 ||
          pages < 0 ||
          (pages < number && !(number == 1 && pages == 0 && total == 0))) {
        throw const FireflyInvalidPayload();
      }
      for (final json in page.items) {
        final row = _RemoteRow(path, json);
        if (rows.containsKey(row.id)) throw const FireflyInvalidPayload();
        rows[row.id] = row;
      }
      if (number >= pages) {
        if (total != rows.length) throw const FireflyInvalidPayload();
        return rows.values.toList();
      }
      if (page.items.isEmpty) throw const FireflyInvalidPayload();
    }
  }

  Future<void> _inventory(List<FireflyIdMapping> entries) async {
    final session = await context.idMap.byLocal(_journalType, _sessionKey);
    final authorized = <String, List<FireflyIdMapping>>{};
    for (final entry in entries) {
      (authorized[entry.remoteSubId] ??= []).add(entry);
    }
    final indirectAccounts = <String>{};
    Future<List<_RemoteRow>> check(String path) async {
      final rows = await _list(path);
      final allowed = authorized[path] ?? const <FireflyIdMapping>[];
      final byMarker = {
        if (session != null)
          for (final entry in allowed) _marker(session, entry): entry,
      };
      final byId = {
        for (final entry in allowed)
          if (entry.state == FireflySyncState.synced) entry.remoteId: entry,
      };
      final receipts = <String>{};
      for (final row in rows) {
        final entry =
            byId[row.id] ?? (byMarker.isEmpty ? null : byMarker[row.marker]);
        if (entry == null &&
            !(path == '/accounts' && indirectAccounts.contains(row.id))) {
          throw FireflyUploadIssue('firefly-upload-nonempty',
              phase: SyncPhase.preflight, item: path);
        }
        if (entry != null && !receipts.add(entry.localPk)) {
          throw FireflyUploadIssue('firefly-upload-duplicate',
              phase: SyncPhase.preflight, item: entry.lastError);
        }
        if (path == '/transactions') {
          indirectAccounts.addAll(row.implicitAccounts);
        }
      }
      for (final entry in byId.values) {
        if (!receipts.contains(entry.localPk)) {
          throw FireflyUploadIssue('firefly-upload-missing-receipt',
              phase: SyncPhase.preflight, item: entry.lastError);
        }
      }
      return rows;
    }

    await check('/transactions');
    await check('/accounts');
    await check('/categories');
    await check('/tags');
    final budgets = await check('/budgets');
    for (final budget in budgets) {
      await check('/budgets/${Uri.encodeComponent(budget.id)}/limits');
    }
    await check('/piggy-banks');
    await check('/bills');
    await check('/attachments');
  }

  Future<void> _checkBalances(SyncContext staging, FireflyUploadPreview preview,
      List<SyncIssue> issues, Map<String, double> mismatches) async {
    final included =
        preview._items[_Type.transaction]!.map((row) => row.pk).toSet();
    final walletPrecision = {
      for (final row in await staging.db.select(staging.db.wallets).get())
        row.walletPk: row.decimals,
    };
    final totals = <String, double>{};
    for (final row in await staging.db.fireflyTransactions()) {
      final decimals = walletPrecision[row.walletFk];
      if (decimals == null || !included.contains(row.transactionPk)) continue;
      final amount = _atCurrencyPrecision(row.amount, decimals);
      totals.update(row.walletFk, (total) => total + amount,
          ifAbsent: () => amount);
    }
    for (final type in [_Type.walletAccount, _Type.liabilityAccount]) {
      for (final item in preview._items[type] ?? const <_Item>[]) {
        if (context.isCancelled()) return;
        final wallet = (await staging.db.fireflyWallet(item.pk))!;
        final map = (await staging.idMap.byLocal(type, item.pk))!;
        try {
          final remote =
              (await context.api.accounts.get(map.remoteId)).currentBalance;
          if (remote == null) throw const FireflyInvalidPayload();
          final local = totals[item.pk] ?? 0;
          final difference = local - remote;
          if (difference.abs() >= math.pow(10, -wallet.decimals) / 2) {
            mismatches[item.pk] = difference;
            issues.add(FireflyUploadIssue('firefly-upload-balance-mismatch',
                entityType: type, phase: SyncPhase.parity, item: item.label));
          }
        } on FireflyException catch (error) {
          issues.add(FireflyUploadIssue(_errorKey(error),
              entityType: type, phase: SyncPhase.parity, item: item.label));
        }
      }
    }
  }
}

String _errorKey(FireflyException error) => switch (error) {
      FireflyUnauthorized() => 'firefly-connection-error-auth',
      FireflyNetworkError() ||
      FireflyTimeout() =>
        'firefly-connection-error-network',
      FireflyValidation() => 'firefly-upload-rejected',
      _ => 'firefly-upload-unverified',
    };

Future<List<FireflyIdMapping>> _intents(IdMapRepository ids) async =>
    (await ids.list(FireflyBootstrapUpload._journalType))
        .where((entry) =>
            entry.localPk.startsWith(FireflyBootstrapUpload._intentPrefix))
        .toList();

String _marker(FireflyIdMapping session, FireflyIdMapping entry) =>
    'cashew-upload:${session.remoteId}:${entry.localPk.split('/').last}';

FireflyUploadIssue _unresolved(FireflyIdMapping entry) => FireflyUploadIssue(
      'firefly-upload-unresolved',
      phase: SyncPhase.push,
      item: entry.lastError,
      intent: entry.localPk,
    );

String _attribute(String path) => switch (path) {
      '/tags' => 'description',
      '/transactions' => 'external_id',
      _ => 'notes',
    };

List<JsonObject> _journals(JsonObject attributes) {
  final journals = attributes['transactions'];
  if (journals is! List || journals.isEmpty) {
    throw const FireflyInvalidPayload();
  }
  return journals.map((journal) {
    if (journal is! JsonObject) throw const FireflyInvalidPayload();
    return journal;
  }).toList();
}

String _label(JsonObject fields) {
  final journal = fields['transactions'];
  return (fields['name'] ??
          fields['tag'] ??
          fields['title'] ??
          fields['filename'] ??
          fields['group_title'] ??
          fields['start'] ??
          (journal is List ? _journals(fields).first['description'] : null) ??
          '')
      .toString();
}

String _identity(String path, JsonObject fields) {
  final matchFields = switch (path) {
    '/transactions' => {
        'journals': _journals(fields)
            .map((row) => row['internal_reference'] as String? ?? '')
            .toList()
          ..sort(),
      },
    '/attachments' => {
        'filename': fields['filename'],
        'attachable': fields['attachable_id']?.toString(),
      },
    _ when path.endsWith('/limits') => {
        'start': fields['start']?.toString().split('T').first,
        'end': fields['end']?.toString().split('T').first,
      },
    '/accounts' => {
        'name': _label(fields).trim(),
        'kind': fields['type'],
      },
    _ => {'name': _label(fields).trim()},
  };
  return syncedFieldsHash(matchFields);
}

final _uploadMarker = RegExp(r'cashew-upload:[a-f0-9-]{36}:[a-f0-9]{64}$');

String? _withoutMarker(String text, String marker) {
  final prefix = text.trimRight();
  final end = prefix.length - marker.length;
  if (end < 0 || !prefix.endsWith(marker)) return text;
  if (end == 0) return null;
  // Some Firefly fields normalize the separating newline to a space.
  final separator = prefix[end - 1];
  if (separator != '\n' && separator != ' ') return text;
  final original = prefix.substring(0, end - 1);
  return original.isEmpty ? null : original;
}

/// Ordinary sync ignores only the reserved suffix if Firefly could not clear
/// a marker. Bootstrap itself uses an unfiltered transport for recovery.
class FireflyPostUploadTransport extends HttpFireflyTransport {
  FireflyPostUploadTransport({
    required super.baseUrl,
    required super.readToken,
    super.client,
  });

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async =>
      _unmark(path, await super.get(path, query: query));

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
          {FireflyQuery query = const {}}) async =>
      (await super.getPage(path, query: query))
          .map((row) => _unmark(path, row));

  @override
  Future<JsonObject> put(String path, JsonObject body,
          {FireflyQuery query = const {}}) async =>
      _unmark(path, await super.put(path, body, query: query));

  JsonObject _unmark(String path, JsonObject row) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.isEmpty ||
        !const {
          'accounts',
          'categories',
          'tags',
          'budgets',
          'piggy-banks',
          'bills',
          'attachments',
        }.contains(segments.first)) {
      return row;
    }
    final field = _attribute('/${segments.first}');
    final attributes = row['attributes'];
    if (attributes is! JsonObject || attributes[field] is! String) return row;
    final text = attributes[field]! as String;
    final marker = _uploadMarker.stringMatch(text.trimRight());
    if (marker == null) return row;
    return {
      ...row,
      'attributes': {...attributes, field: _withoutMarker(text, marker)},
    };
  }
}

class _RemoteRow {
  _RemoteRow(this.path, this.json) {
    if (id.isEmpty) throw const FireflyInvalidPayload();
    attributes;
  }

  final String path;
  final JsonObject json;

  String get id => switch (json['id']) {
        final String id => id,
        _ => throw const FireflyInvalidPayload(),
      };
  JsonObject get attributes => switch (json['attributes']) {
        final JsonObject attributes => attributes,
        _ => throw const FireflyInvalidPayload(),
      };

  String? get marker {
    if (path == '/transactions') {
      final markers =
          _journals(attributes).map((row) => row['external_id']).toSet();
      return markers.length == 1 && markers.single is String
          ? markers.single as String
          : null;
    }
    final value = attributes[_attribute(path)];
    return value is String
        ? _uploadMarker.stringMatch(value.trimRight())
        : null;
  }

  bool hasMarker(String marker) => this.marker == marker;

  /// Firefly generates the counterparty for a legacy split without a payee.
  Iterable<String> get implicitAccounts sync* {
    for (final row in _journals(attributes)) {
      for (final side in ['source', 'destination']) {
        final type = row['${side}_type']?.toString().toLowerCase();
        final id = row['${side}_id']?.toString();
        if (id != null &&
            (type == 'expense account' ||
                type == 'revenue account' ||
                type == 'expense' ||
                type == 'revenue' ||
                type == 'cash account' ||
                type == 'cash' ||
                type == 'initial balance account')) {
          yield id;
        }
      }
    }
  }
}

class _UploadTransport implements FireflyTransport {
  _UploadTransport(this.owner, this.session, this.staging);

  final FireflyBootstrapUpload owner;
  final FireflyIdMapping session;
  final FinanceDatabase staging;
  final _accepted = <_Type, Set<String>>{};
  final _enabled = <String>{};
  final _replay = <String, Map<String, _RemoteRow>>{};
  late _Type stage;

  FireflyTransport get _transport => owner.context.api.transport;
  IdMapRepository get _ids => owner.context.idMap;

  bool accepted(_Type type, String id) => _accepted[type]?.contains(id) == true;

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    try {
      final response = await _transport.get(path, query: query);
      final attributes = response['attributes'];
      if (path.startsWith('/currencies/') &&
          attributes is JsonObject &&
          attributes['enabled'] == true) {
        _enabled.add(path);
        if (attributes['code'] case final String code) {
          _enabled
              .add('/currencies/${Uri.encodeComponent(code.toUpperCase())}');
        }
      }
      return response;
    } on FireflyNotFound {
      if (path.startsWith('/attachments/')) {
        throw FireflyUploadIssue('firefly-upload-unverified',
            entityType: _Type.attachment, item: path, phase: SyncPhase.push);
      }
      rethrow;
    }
  }

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) {
    if (path == '/attachments') {
      return Future.value(const FireflyPage(
          items: [], total: 0, currentPage: 1, perPage: 1, totalPages: 0));
    }
    return _transport.getPage(path, query: query);
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    owner._ensureInactive();
    if (path.startsWith('/currencies/') && path.endsWith('/enable')) {
      final currency = path.substring(0, path.length - '/enable'.length);
      if (!_enabled.contains(currency)) {
        await _transport.post(path, body, query: query);
        _enabled.add(currency);
      }
      return const {};
    }

    final label = _label(body);
    final version = syncedFieldsHash({'path': path, 'body': body});
    final identity = stage == _Type.transaction
        ? _identity(path, body)
        : (await IdMapRepository(staging)
                .list(stage, state: FireflySyncState.creating))
            .single
            .localPk;
    final hash = syncedFieldsHash({'type': stage.name, 'item': identity});
    final key = '${FireflyBootstrapUpload._intentPrefix}$hash';
    final existing =
        await _ids.byLocal(FireflyBootstrapUpload._journalType, key);
    if (existing != null && existing.lossyFields != version) {
      throw FireflyUploadIssue('firefly-upload-source-changed',
          entityType: stage, phase: SyncPhase.push, item: label);
    }
    final pending = existing ??
        FireflyIdMapping(
          entityType: FireflyBootstrapUpload._journalType,
          localPk: key,
          remoteId: IdMapRepository.creatingId(key),
          remoteSubId: path,
          remoteRole: 0,
          syncedHash: _identity(path, body),
          lossyFields: version,
          state: FireflySyncState.creating,
          attempts: 0,
          lastError: label,
        );
    final marker = _marker(session, pending);
    if (existing != null) {
      final Iterable<_RemoteRow> rows;
      if (existing.state == FireflySyncState.synced) {
        if (!_replay.containsKey(path)) {
          _replay[path] = {
            for (final row in await owner._list(path)) row.id: row,
          };
        }
        final row = _replay[path]![existing.remoteId];
        rows = [if (row != null) row];
      } else {
        rows = await owner._list(path);
      }
      final matches = rows
          .where((row) =>
              row.hasMarker(marker) ||
              (existing.state == FireflySyncState.synced &&
                  existing.remoteId == row.id))
          .toList();
      if (matches.length == 1) return _accept(pending, matches.single);
      if (matches.isNotEmpty || existing.state != FireflySyncState.error) {
        throw _unresolved(existing);
      }
    }

    await owner.context.db.transaction(() async {
      if (await _ids.byLocal(FireflyBootstrapUpload._journalType, key) !=
          existing) {
        throw _unresolved(pending);
      }
      await _ids.put(pending.copyWith(state: FireflySyncState.creating));
    });
    final field = _attribute(path);
    final original = body[field] as String?;
    final marked = path == '/transactions'
        ? {
            ...body,
            // The upload journal deduplicates each local record. Identical
            // payments are separate records when their Cashew IDs differ.
            'error_if_duplicate_hash': false,
            'transactions': [
              for (final journal in _journals(body))
                {...journal, field: marker},
            ],
          }
        : {
            ...body,
            field: [if (original?.isNotEmpty == true) original!, marker]
                .join('\n'),
          };
    late final JsonObject response;
    try {
      final transport = _transport;
      response = transport is HttpFireflyTransport
          ? await transport.post(path, marked, query: query, retry: false)
          : await transport.post(path, marked, query: query);
    } on FireflyValidation {
      // A validation response is definitive. The existing syncer may retry a
      // balance correction as a different transaction type.
      await _ids.remove(FireflyBootstrapUpload._journalType, key);
      rethrow;
    } on FireflyException {
      throw _unresolved(pending);
    }
    final row = _RemoteRow(path, response);
    if (!row.hasMarker(marker)) throw _unresolved(pending);
    return _accept(pending, row);
  }

  Future<JsonObject> _accept(FireflyIdMapping pending, _RemoteRow row) async {
    await _ids.put(pending.copyWith(
      remoteId: row.id,
      state: FireflySyncState.synced,
    ));
    final mappingId = stage == _Type.budgetLimit
        ? '${row.path.split('/')[2]}/${Uri.encodeComponent(row.id)}'
        : row.id;
    (_accepted[stage] ??= {}).add(mappingId);
    _replay[row.path]?[row.id] = row;
    return row.json;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    _attachmentPath(path);
    try {
      return await _transport.put(path, body, query: query);
    } on FireflyNotFound {
      throw FireflyUploadIssue('firefly-upload-unverified',
          entityType: _Type.attachment, item: path, phase: SyncPhase.push);
    }
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
      {int? length}) async {
    final itemPath = path.substring(0, path.length - '/upload'.length);
    _attachmentPath(itemPath);
    try {
      await _transport.upload(path, bytes, length: length);
    } on FireflyException catch (error) {
      throw FireflyUploadIssue(_errorKey(error),
          entityType: _Type.attachment, item: itemPath, phase: SyncPhase.push);
    }
  }

  void _attachmentPath(String path) {
    owner._ensureInactive();
    if (!path.startsWith('/attachments/') ||
        !accepted(_Type.attachment,
            Uri.decodeComponent(path.substring('/attachments/'.length)))) {
      throw const FireflyInvalidPayload();
    }
  }

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) =>
      throw const FireflyInvalidPayload();

  @override
  Future<Stream<List<int>>> download(String path) =>
      throw const FireflyInvalidPayload();
}

class _SnapshotDatabase extends FinanceDatabase {
  _SnapshotDatabase() : super(openUploadSnapshot());
}

class _UploadSnapshot {
  _UploadSnapshot(this.tables, this.hasOtherMappings)
      : hash = syncedFieldsHash(tables);

  final Map<String, List<JsonObject>> tables;
  final bool hasOtherMappings;
  final String hash;

  static Future<_UploadSnapshot> read(FinanceDatabase db) =>
      db.transaction(() async {
        final tables = <TableInfo<Table, Object?>>[
          db.wallets,
          db.accountDetails,
          db.categories,
          db.payees,
          db.tags,
          db.budgets,
          db.budgetLimits,
          db.objectives,
          db.transactionGroups,
          db.transactions,
          db.transactionTags,
          db.attachments,
          db.fireflyResourceCache,
          db.fireflySyncMeta,
        ];
        final rows = <String, List<JsonObject>>{};
        for (final table in tables) {
          final name = table.actualTableName;
          final keys = table.$primaryKey.map((column) => column.$name);
          final data = await db
              .customSelect('SELECT * FROM "$name" ORDER BY ${keys.join(', ')}')
              .get();
          rows[name] = [for (final row in data) row.data];
        }

        final maps = await db.select(db.fireflyIdMap).get();
        return _UploadSnapshot(
          rows,
          maps.any((entry) =>
              entry.entityType != FireflyBootstrapUpload._journalType ||
              (entry.localPk != FireflyBootstrapUpload._sessionKey &&
                  !entry.localPk
                      .startsWith(FireflyBootstrapUpload._intentPrefix))),
        );
      });

  Future<FinanceDatabase> open() async {
    final db = _SnapshotDatabase();
    try {
      await db.batch((batch) {
        for (final entry in tables.entries) {
          if (entry.value.isEmpty) continue;
          final columns = entry.value.first.keys.map((key) => '"$key"');
          final params = columns.map((_) => '?');
          for (final row in entry.value) {
            batch.customStatement(
                'INSERT INTO "${entry.key}" (${columns.join(', ')}) '
                'VALUES (${params.join(', ')})',
                row.values.toList());
          }
        }
      });
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<FireflyUploadPreview> preview(FinanceDatabase db,
      {required String destination,
      required bool resuming,
      required Future<String> Function() primaryCurrency}) async {
    final items = <_Type, List<_Item>>{for (final type in _steps) type: []};
    final skipped = <FireflyUploadIssue>[];
    final walletPrecision = <String, int>{};
    final currencies = <String>{};
    void currency(String? code) {
      if (code != null && code.trim().isNotEmpty) {
        currencies.add(code.trim().toUpperCase());
      }
    }

    void add(_Type type, String pk, String label) =>
        items[type]!.add((pk: pk, label: label.isEmpty ? pk : label));
    void skip(_Type type, String label, String reason) =>
        skipped.add(FireflyUploadIssue(reason, entityType: type, item: label));

    for (final wallet in await db.select(db.wallets).get()) {
      if (wallet.accountKind == AccountKind.cash) {
        skip(_Type.walletAccount, wallet.name, 'firefly-upload-skip-cash');
      } else if (!await db.isFireflyWalletPlaceholder(wallet)) {
        add(
            wallet.accountKind == AccountKind.asset
                ? _Type.walletAccount
                : _Type.liabilityAccount,
            wallet.walletPk,
            wallet.name);
        currency(wallet.currency ?? await primaryCurrency());
        walletPrecision[wallet.walletPk] = wallet.decimals;
      }
    }
    for (final row in await db.select(db.categories).get()) {
      if (isFireflySyncableCategory(row.categoryPk)) {
        add(_Type.category, row.categoryPk, row.name);
      }
    }
    for (final row in await db.fireflyPayees()) {
      add(_Type.payeeAccount, row.payeePk, row.name);
    }
    for (final row in await db.fireflyTags()) {
      add(_Type.tag, row.tagPk, row.name);
    }
    final budgets = await db.select(db.budgets).get();
    final envelopes = <String, String>{};
    for (final row in budgets) {
      if (row.addedTransactionsOnly) {
        add(_Type.budget, row.budgetPk, row.name);
        envelopes[row.budgetPk] = row.name;
      } else {
        skip(_Type.budget, row.name, 'firefly-upload-skip-budget');
      }
    }
    for (final row in await db.select(db.budgetLimits).get()) {
      final budget = envelopes[row.budgetFk];
      if (budget != null) {
        add(_Type.budgetLimit, row.budgetLimitPk,
            '$budget (${formatFireflyDate(row.start)})');
        currency(row.currency);
      } else {
        skip(
            _Type.budgetLimit, row.budgetLimitPk, 'firefly-upload-skip-budget');
      }
    }
    final goals = {for (final row in await db.fireflyGoals()) row.objectivePk};
    for (final row in await db.select(db.objectives).get()) {
      if (goals.contains(row.objectivePk)) {
        add(_Type.piggyBank, row.objectivePk, row.name);
      } else {
        skip(_Type.piggyBank, row.name, 'firefly-upload-skip-loan');
      }
    }
    final cache = ResourceCacheRepository(db);
    for (final row in await cache.list(_Type.bill)) {
      final name = ResourceCacheRepository.decode(row)['name'] as String?;
      add(_Type.bill, row.resourcePk, name ?? row.resourcePk);
    }
    for (final row in await cache.list(_Type.recurrence)) {
      final name = ResourceCacheRepository.decode(row)['title'] as String?;
      skip(_Type.recurrence, name ?? row.resourcePk,
          'firefly-upload-skip-recurrence');
    }

    final txs = await db.fireflyTransactions();
    final excluded = <String, String>{};
    for (final row in txs) {
      if (row.type == TransactionSpecialType.credit ||
          row.type == TransactionSpecialType.debt ||
          row.objectiveLoanFk != null) {
        excluded[row.transactionPk] = 'firefly-upload-skip-loan';
      } else if (!row.paid) {
        excluded[row.transactionPk] = 'firefly-upload-skip-unpaid';
      }
    }
    final excludedGroups = {
      for (final row in txs)
        if (excluded.containsKey(row.transactionPk) && row.splitGroupFk != null)
          row.splitGroupFk,
    };
    final transfers = <String>{};
    final splits = <String>{};
    final groups = <String>{};
    final selectedTransactions = <String>{};
    var rounded = 0;
    for (final row in txs) {
      final pk = row.transactionPk;
      final partner = row.pairedTransactionFk;
      final group = row.splitGroupFk;
      final reason = excluded[pk] ??
          (excluded.containsKey(partner) || excludedGroups.contains(group)
              ? 'firefly-upload-skip-linked'
              : null);
      if (reason != null) {
        skip(_Type.transaction, row.name.isEmpty ? pk : row.name, reason);
        continue;
      }
      add(_Type.transaction, pk, row.name);
      selectedTransactions.add(pk);
      currency(row.foreignCurrency);
      final decimals = walletPrecision[row.walletFk];
      if (decimals != null &&
          (_atCurrencyPrecision(row.amount, decimals) - row.amount).abs() >
              1e-12) {
        rounded++;
      }
      if (partner != null) transfers.add(row.income ? partner : pk);
      if (group != null) {
        groups.add(group);
        splits.add(row.income && partner != null ? partner : pk);
      }
    }

    for (final row in await db.select(db.attachments).get()) {
      if (row.uploadState == fireflyAttachmentDeleted) continue;
      if (row.attachableType == FireflyAttachment.transactionJournal &&
          selectedTransactions.contains(row.attachableFk)) {
        add(_Type.attachment, row.attachmentPk, row.filename);
      } else {
        skip(_Type.attachment, row.filename, 'firefly-upload-skip-attachment');
      }
    }

    return FireflyUploadPreview._(
      items: items,
      transfers: transfers.length,
      splits: splits.length,
      splitGroups: groups.length,
      roundedTransactions: rounded,
      currencies: currencies,
      skipped: skipped,
      resuming: resuming,
      snapshot: hash,
      destination: destination,
    );
  }

  Future<void> stage(FinanceDatabase db, FireflyUploadPreview preview) async {
    final transactions =
        preview._items[_Type.transaction]!.map((row) => row.pk).toSet();
    final attachments =
        preview._items[_Type.attachment]!.map((row) => row.pk).toSet();
    final skippedTransactions = (await db.fireflyTransactions())
        .where((row) => !transactions.contains(row.transactionPk));
    final skippedAttachments = (await db.select(db.attachments).get())
        .where((row) => !attachments.contains(row.attachmentPk));
    await db.batch((batch) {
      for (final row in skippedTransactions) {
        batch.deleteWhere(db.transactionTags,
            (tag) => tag.transactionFk.equals(row.transactionPk));
        batch.delete(db.transactions, row);
      }
      for (final row in skippedAttachments) {
        batch.delete(db.attachments, row);
      }
      // The normal syncer also handles existing remote-only attachments.
      // For an upload, every selected file goes through its verified queue.
      batch.update(
          db.attachments,
          const AttachmentsCompanion(
              uploadState: Value(fireflyAttachmentQueued)));
    });
  }
}

double _atCurrencyPrecision(double amount, int decimals) =>
    double.parse(formatFireflyAmount(amount, decimals)) * (amount < 0 ? -1 : 1);

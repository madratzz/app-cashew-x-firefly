import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/conflict_policy.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _type = FireflyEntityType.attachment;
const _journal = FireflyAttachment.transactionJournal;

class AttachmentSyncer extends EntitySyncer {
  const AttachmentSyncer({this.supportDirectory});

  final Directory? supportDirectory;
  static final _cycles = Expando<_AttachmentCycle>();

  _AttachmentCycle _cycle(SyncContext context) =>
      _cycles[context] ??= _AttachmentCycle(context, supportDirectory);

  @override
  FireflyEntityType get type => _type;

  @override
  Set<FireflyEntityType> get dependsOn => const {FireflyEntityType.transaction};

  @override
  Future<void> pull(SyncContext context) => _cycle(context).pull();

  @override
  Future<void> push(SyncContext context) => _cycle(context).push();

  @override
  Future<void> pushDeletes(SyncContext context) =>
      _cycle(context).pushDeletes();
}

class _AttachmentCycle {
  _AttachmentCycle(this.context, Directory? directory)
      : files = FireflyAttachmentFiles(directory);

  final SyncContext context;
  final FireflyAttachmentFiles files;
  final _seen = <String, FireflyAttachment>{};
  var _complete = false;

  FinanceDatabase get db => context.db;
  IdMapRepository get ids => context.idMap;
  String _rejectedKey(String pk) => 'attachmentRejected.$pk';
  String _stageName(String pk) =>
      'cashew-upload-${syncedFieldsHash({'pk': pk})}';

  Future<void> pull() async {
    _complete = false;
    _seen.clear();
    int? total;
    var consistent = true;
    for (var page = 1; !context.isCancelled(); page++) {
      final result = await context.api.attachments
          .list(page: page, limit: context.config.pageSize);
      total ??= result.total;
      consistent = consistent && result.total == total;
      for (final item in result.items) {
        if (_seen.containsKey(item.id)) consistent = false;
        _seen[item.id] = item;
      }
      if (page != result.currentPage) break;
      if (result.totalPages == page ||
          (page == 1 && result.totalPages == 0 && total == 0)) {
        _complete = consistent && total == _seen.length;
        break;
      }
      if (result.items.isEmpty || result.totalPages < page) break;
    }

    final staged = {
      for (final mapping in await ids.list(_type))
        if (IdMapRepository.isProvisional(mapping))
          _stageName(mapping.localPk): mapping,
    };
    for (final item in _seen.values) {
      if (context.isCancelled()) return;
      final discarded = await db.transaction(() => _pullOne(item, staged));
      await files.delete(discarded);
    }
    if (!_complete) return;
    for (final mapping in await ids.list(_type)) {
      if (context.isCancelled()) return;
      if (!IdMapRepository.isProvisional(mapping) &&
          !_seen.containsKey(mapping.remoteId)) {
        final discarded = await db.transaction(() => _removeMissing(mapping));
        await files.delete(discarded);
      }
    }
  }

  Future<String?> _pullOne(
      FireflyAttachment item, Map<String, FireflyIdMapping> staged) async {
    final recovered = staged[item.filename];
    final existing = await ids.byRemote(_type, item.id);
    final mapping = existing ?? recovered;
    final local =
        mapping == null ? null : await db.fireflyAttachment(mapping.localPk);
    final parent = item.attachableType == _journal
        ? await _journalOwner(item.attachableId, local?.attachableFk)
        : item.attachableId;

    if (mapping != null &&
        item.attachableType == _journal &&
        item.filename == _stageName(mapping.localPk)) {
      if (existing == null && local != null) {
        // The create may have succeeded just before the response was lost.
        await ids.put(mapping.copyWith(remoteId: item.id));
        staged.remove(item.filename);
      }
      return null;
    }
    if (parent == null) return null;
    final fields = _remoteFields(item);
    final hash = syncedFieldsHash(fields);
    final remoteTime = _timestamp(item.updatedAt);
    final previousTime = mapping?.remoteUpdatedAt;
    final changed = hash != mapping?.syncedHash ||
        (remoteTime != null &&
            (previousTime == null || remoteTime.isAfter(previousTime)));
    final matchingQueuedFile = local?.uploadState == fireflyAttachmentQueued &&
        local?.hash == item.hash &&
        local?.size == item.size;
    if (mapping != null && !matchingQueuedFile) {
      final decision = resolveConflict(
        local: _localVersion(mapping, local, item.attachableId),
        remote:
            changed ? RemoteSyncVersion.changed : RemoteSyncVersion.unchanged,
        sameHash: local != null &&
            syncedFieldsHash(_localFields(local, item.attachableId)) == hash,
      );
      switch (decision) {
        case ConflictDecision.applyRemoteWithConflict:
          await _conflict(mapping, local, fields, 'remoteWins');
        case ConflictDecision.applyRemote:
        case ConflictDecision.markSynced:
        case ConflictDecision.insertLocal:
          break;
        default:
          if (local != null && local.attachableFk != parent) {
            await _write(local.copyWith(attachableFk: parent));
          }
          return null;
      }
    }

    final keepFile = item.hash == local?.hash && item.size == local?.size;
    final row = Attachment(
      attachmentPk: mapping?.localPk ?? const Uuid().v4(),
      attachableType: item.attachableType,
      attachableFk: parent,
      filename: item.filename,
      title: item.title,
      mime: item.mime,
      size: item.size,
      localPath: keepFile ? local?.localPath : null,
      hash: item.hash,
      uploadState: fireflyAttachmentSynced,
      dateCreated: item.createdAt ?? local?.dateCreated ?? context.now(),
      dateTimeModified: remoteTime,
    );
    await _write(row);
    await _synced(row.attachmentPk, item, row.dateTimeModified);
    return keepFile ? null : local?.localPath;
  }

  Future<void> push() async {
    final rows = await (db.select(db.attachments)
          ..where((row) =>
              row.attachableType.equals(_journal) &
              row.uploadState.equals(fireflyAttachmentDeleted).not()))
        .get();
    for (final snapshot in rows) {
      if (context.isCancelled()) return;
      final row = await db.fireflyAttachment(snapshot.attachmentPk);
      if (row == null || row.uploadState == fireflyAttachmentDeleted) continue;
      final pk = row.attachmentPk;
      var mapping = await ids.byLocal(_type, pk);
      if (mapping?.state == FireflySyncState.pendingDelete ||
          mapping?.state == FireflySyncState.localOnly) {
        continue;
      }
      final journalId = await _journalFor(row.attachableFk);
      if (journalId == null) continue;
      final localHash = syncedFieldsHash(_localFields(row, journalId));
      if (mapping?.state == FireflySyncState.error &&
          await context.meta.read(_rejectedKey(pk)) == localHash) {
        continue;
      }
      try {
        if (row.uploadState == fireflyAttachmentQueued) {
          // Without a complete pull we cannot tell an absent stage from an
          // accepted POST whose reply was lost.
          if (!_complete &&
              (mapping == null || IdMapRepository.isProvisional(mapping))) {
            continue;
          }
          final file = await files.verified(row);
          if (mapping == null || IdMapRepository.isProvisional(mapping)) {
            final claimed = await db.transaction(() async {
              final current = await db.fireflyAttachment(pk);
              if (current?.uploadState != fireflyAttachmentQueued) return null;
              final creating = _mapping(pk, IdMapRepository.creatingId(pk),
                  FireflySyncState.creating);
              await ids.put(creating);
              return creating;
            });
            if (claimed == null || context.isCancelled()) continue;
            mapping = claimed;
            final item = await context.api.attachments.create({
              'filename': _stageName(pk),
              'attachable_type': _journal,
              'attachable_id': journalId,
            });
            _seen[item.id] = item;
            mapping = await db.transaction(() async {
              final latest = await ids.byLocal(_type, pk);
              final linked = (latest ?? claimed).copyWith(remoteId: item.id);
              await ids.put(linked);
              return linked;
            });
          }
          final id = mapping.remoteId;
          final stage = _seen[id] ?? await context.api.attachments.get(id);
          if (context.isCancelled() ||
              (await db.fireflyAttachment(pk))?.uploadState !=
                  fireflyAttachmentQueued) {
            continue;
          }
          FireflyAttachment uploaded = stage;
          if (stage.hash != row.hash || stage.size != row.size) {
            await context.api.attachments
                .upload(id, file.openRead(0, row.size), length: row.size);
            uploaded = await context.api.attachments.get(id);
          }
          if (uploaded.hash != row.hash || uploaded.size != row.size) {
            throw const FireflyAttachmentException(
                FireflyAttachmentFailure.integrity);
          }
          if (context.isCancelled()) return;
          final saved = await context.api.attachments
              .update(id, _updateFields(row, uploaded.title));
          await _finishPush(row, saved);
        } else if (mapping != null && localHash != mapping.syncedHash) {
          final remote = _seen[mapping.remoteId] ??
              await context.api.attachments.get(mapping.remoteId);
          final saved = await context.api.attachments
              .update(mapping.remoteId, _updateFields(row, remote.title));
          await _finishPush(row, saved);
        }
      } on FireflyNotFound {
        if (mapping != null && !IdMapRepository.isProvisional(mapping)) {
          final discarded =
              await db.transaction(() => _removeMissing(mapping!));
          await files.delete(discarded);
        } else {
          rethrow;
        }
      } on FireflyValidation catch (error) {
        await _reject(pk, localHash, error.message);
      } on FireflyAttachmentException catch (error) {
        await _reject(pk, localHash, error.failure.name);
      } on FileSystemException {
        await _reject(pk, localHash, FireflyAttachmentFailure.unavailable.name);
      }
    }
  }

  Future<void> pushDeletes() async {
    final rows = await (db.select(db.attachments)
          ..where((row) => row.uploadState.equals(fireflyAttachmentDeleted)))
        .get();
    for (final row in rows) {
      if (context.isCancelled()) return;
      final mapping = await ids.byLocal(_type, row.attachmentPk);
      if (mapping != null) {
        if (mapping.state != FireflySyncState.pendingDelete) continue;
        if (IdMapRepository.isProvisional(mapping)) {
          if (!_complete) continue;
        } else {
          try {
            await context.api.attachments.delete(mapping.remoteId);
          } on FireflyNotFound {
            // The remote attachment is already gone.
          }
        }
      }
      await db.transaction(() => _forget(row.attachmentPk));
      await files.delete(row.localPath);
    }
  }

  Future<void> _finishPush(Attachment sent, FireflyAttachment saved) =>
      db.transaction(() async {
        final pk = sent.attachmentPk;
        final current = await db.fireflyAttachment(pk);
        if (current == null) return;
        if (current.uploadState == fireflyAttachmentDeleted) {
          await _synced(pk, saved, sent.dateTimeModified, pendingDelete: true);
          return;
        }
        final row = current.copyWith(
          filename: current.filename == sent.filename
              ? saved.filename
              : current.filename,
          title:
              Value(current.title == sent.title ? saved.title : current.title),
          size: Value(saved.size),
          mime: Value(saved.mime),
          hash: Value(saved.hash),
          uploadState: fireflyAttachmentSynced,
        );
        await _write(row);
        await _synced(pk, saved, sent.dateTimeModified);
      });

  Future<void> _reject(String pk, String hash, String error) =>
      db.transaction(() async {
        final current = await ids.byLocal(_type, pk) ??
            _mapping(
                pk, IdMapRepository.creatingId(pk), FireflySyncState.creating);
        if (current.state == FireflySyncState.pendingDelete ||
            (await db.fireflyAttachment(pk))?.uploadState ==
                fireflyAttachmentDeleted) {
          return;
        }
        await ids.put(current.copyWith(
          state: FireflySyncState.error,
          attempts: current.attempts + 1,
          lastError: Value(redactFireflyLog(error)),
          lastAttemptAt: Value(context.now()),
        ));
        await context.meta.write(_rejectedKey(pk), hash);
      });

  Future<String?> _removeMissing(FireflyIdMapping mapping) async {
    final row = await db.fireflyAttachment(mapping.localPk);
    if (row?.uploadState == fireflyAttachmentQueued) {
      // A missing metadata-only stage does not delete a queued local file.
      await ids.remove(_type, mapping.localPk);
      await context.meta.remove(_rejectedKey(mapping.localPk));
      return null;
    }
    final parent = row == null
        ? null
        : await _journalFor(row.attachableFk) ?? row.attachableFk;
    if (parent != null &&
        _localVersion(mapping, row, parent) == LocalSyncVersion.dirty) {
      await _conflict(mapping, row, null, 'remoteDeleted');
    }
    await _forget(mapping.localPk);
    return row?.localPath;
  }

  Future<void> _forget(String pk) async {
    await (db.delete(db.attachments)
          ..where((row) => row.attachmentPk.equals(pk)))
        .go();
    await ids.remove(_type, pk);
    await context.meta.remove(_rejectedKey(pk));
  }

  Future<void> _write(Attachment row) =>
      db.into(db.attachments).insertOnConflictUpdate(row);

  Future<void> _synced(String pk, FireflyAttachment item, DateTime? localTime,
      {bool pendingDelete = false}) async {
    final state = pendingDelete
        ? FireflySyncState.pendingDelete
        : FireflySyncState.synced;
    await ids.put(_mapping(pk, item.id, state).copyWith(
      remoteUpdatedAt: Value(_timestamp(item.updatedAt)),
      syncedHash: Value(syncedFieldsHash(_remoteFields(item))),
      localVersionAt: Value(localTime),
    ));
    await context.meta.remove(_rejectedKey(pk));
  }

  Future<void> _conflict(FireflyIdMapping mapping, Attachment? row,
      JsonObject? remote, String resolution) async {
    await context.conflicts.record(
      type: _type,
      localPk: mapping.localPk,
      remoteId: mapping.remoteId,
      local: row == null || row.uploadState == fireflyAttachmentDeleted
          ? const {'deleted': true}
          : _edit(row),
      remote: remote,
      resolution: resolution,
      createdAt: context.now(),
    );
  }

  Future<String?> _journalFor(String pk) async {
    final parent = await (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.transactionPk])
          ..where(db.transactions.transactionPk.equals(pk)))
        .getSingleOrNull();
    if (parent == null) return null;
    final mapping = await ids.byLocal(FireflyEntityType.transaction, pk);
    if (mapping == null ||
        mapping.remoteSubId.isEmpty ||
        mapping.state == FireflySyncState.pendingDelete ||
        IdMapRepository.isProvisional(mapping)) {
      return null;
    }
    return mapping.remoteSubId;
  }

  Future<String?> _journalOwner(String journalId, String? preferred) async {
    final map = db.fireflyIdMap;
    final tx = db.transactions;
    final candidates = await (db.select(map).join([
      innerJoin(tx, tx.transactionPk.equalsExp(map.localPk), useColumns: false),
    ])
          ..where(map.entityType.equalsValue(FireflyEntityType.transaction) &
              map.remoteSubId.equals(journalId))
          ..orderBy([OrderingTerm.asc(map.remoteRole)]))
        .map((row) => row.readTable(map).localPk)
        .get();
    if (candidates.contains(preferred)) return preferred;
    return candidates.firstOrNull;
  }
}

FireflyIdMapping _mapping(String pk, String id, FireflySyncState state) =>
    FireflyIdMapping(
      entityType: _type,
      localPk: pk,
      remoteId: id,
      remoteSubId: '',
      remoteRole: 0,
      state: state,
      attempts: 0,
    );

JsonObject _edit(Attachment row) => {
      'filename': row.filename,
      'title': row.title,
    };

JsonObject _remoteFields(FireflyAttachment item) => {
      'attachable_type': item.attachableType,
      'attachable_id': item.attachableId,
      'filename': item.filename,
      'title': item.title,
      'mime': item.mime,
      'size': item.size,
      'hash': item.hash,
    };

JsonObject _localFields(Attachment row, String parent) => {
      ..._edit(row),
      'attachable_type': row.attachableType,
      'attachable_id': parent,
      'mime': row.mime,
      'size': row.size,
      'hash': row.hash,
    };

LocalSyncVersion _localVersion(
    FireflyIdMapping mapping, Attachment? row, String parent) {
  if (row == null || row.uploadState == fireflyAttachmentDeleted) {
    return LocalSyncVersion.pendingDelete;
  }
  return syncedFieldsHash(_localFields(row, parent)) == mapping.syncedHash
      ? LocalSyncVersion.clean
      : LocalSyncVersion.dirty;
}

// Firefly 6.6.2 accepts omitted titles but rejects null and empty updates.
// Use the filename as the display title when clearing an existing title.
JsonObject _updateFields(Attachment row, String? previousTitle) => {
      'filename': row.filename,
      if (row.title != null || previousTitle != null)
        'title': row.title ?? row.filename,
    };

DateTime? _timestamp(DateTime? time) => time == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(
        time.millisecondsSinceEpoch ~/ 1000 * 1000);

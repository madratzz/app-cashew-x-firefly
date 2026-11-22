import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/resources/attachments_api.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum FireflyAttachmentFailure { size, integrity, unavailable, invalidName }

class FireflyAttachmentException implements Exception {
  const FireflyAttachmentException(this.failure);

  final FireflyAttachmentFailure failure;
}

const fireflyAttachmentMaxBytes = 10 * 1024 * 1024;
const fireflyAttachmentQueued = 'queued';
const fireflyAttachmentSynced = 'synced';
const fireflyAttachmentDeleted = 'deleted';

const _journal = FireflyAttachment.transactionJournal;
const _attachment = FireflyEntityType.attachment;
const _transaction = FireflyEntityType.transaction;

extension FireflyAttachmentQueries on FinanceDatabase {
  SimpleSelectStatement<$AttachmentsTable, Attachment> _attachmentByPk(
          String pk) =>
      select(attachments)..where((row) => row.attachmentPk.equals(pk));

  Future<Attachment?> fireflyAttachment(String attachmentPk) =>
      _attachmentByPk(attachmentPk).getSingleOrNull();

  Future<List<Attachment>> fireflyTransactionAttachments(
          String transactionPk) =>
      watchFireflyTransactionAttachments(transactionPk).first;

  Stream<List<Attachment>> watchFireflyTransactionAttachments(
      String transactionPk) {
    // Both transfer rows represent the same journal and share its files.
    final current = alias(fireflyIdMap, 'current_transaction');
    final owners = alias(fireflyIdMap, 'attachment_owner');
    final siblingPks = selectOnly(owners).join([
      innerJoin(
        current,
        current.entityType.equalsValue(_transaction) &
            current.localPk.equals(transactionPk) &
            current.remoteSubId.equalsExp(owners.remoteSubId) &
            current.remoteId.equalsExp(owners.remoteId),
        useColumns: false,
      ),
    ])
      ..addColumns([owners.localPk])
      ..where(owners.entityType.equalsValue(_transaction) &
          owners.remoteSubId.equals('').not());
    return (select(attachments)
          ..where((row) =>
              row.attachableType.equals(_journal) &
              row.uploadState.equals(fireflyAttachmentDeleted).not() &
              (row.attachableFk.equals(transactionPk) |
                  row.attachableFk.isInQuery(siblingPks)))
          ..orderBy([(row) => OrderingTerm.asc(row.dateCreated)]))
        .watch();
  }

  Stream<List<Attachment>> watchFireflyAttachments() => (select(attachments)
        ..where((row) => row.uploadState.equals(fireflyAttachmentDeleted).not())
        ..orderBy([(row) => OrderingTerm.desc(row.dateCreated)]))
      .watch();

  /// Stages bytes in app support. The returned row is unsaved until persisted.
  Future<Attachment> prepareFireflyAttachment({
    required String filename,
    required Stream<List<int>> bytes,
    String? title,
    String? mime,
    Directory? supportDirectory,
  }) async {
    final cleanName = validateFireflyAttachmentName(filename);
    final cleanTitle = _title(title);
    final stored =
        await FireflyAttachmentFiles(supportDirectory).write(cleanName, bytes);
    final now = DateTime.now();
    return Attachment(
      attachmentPk: const Uuid().v4(),
      attachableType: _journal,
      attachableFk: '',
      filename: cleanName,
      title: cleanTitle,
      mime: mime,
      size: stored.size,
      localPath: stored.file.path,
      hash: stored.hash,
      uploadState: fireflyAttachmentQueued,
      dateCreated: now,
      dateTimeModified: now,
    );
  }

  /// Use for a staged file removed from an unsaved or abandoned draft.
  Future<void> discardFireflyAttachmentDraftFile(Attachment draft,
      {Directory? supportDirectory}) async {
    if (await fireflyAttachment(draft.attachmentPk) != null) return;
    await FireflyAttachmentFiles(supportDirectory).delete(draft.localPath);
  }

  /// Apply only the changes between the loaded snapshot and edited draft.
  /// Callers without a snapshot may persist additions and metadata edits.
  Future<void> persistFireflyAttachmentDraft(
      String transactionPk, List<Attachment> draft,
      {List<Attachment>? baseline, Directory? supportDirectory}) async {
    final edited = {for (final row in draft) row.attachmentPk: row};
    final originals = {
      for (final row in baseline ?? const <Attachment>[]) row.attachmentPk: row
    };
    if (edited.isEmpty && originals.isEmpty) return;

    await transaction(() async {
      final visible = {
        for (final row in await fireflyTransactionAttachments(transactionPk))
          row.attachmentPk: row
      };
      final idMap = IdMapRepository(this);
      final files = FireflyAttachmentFiles(supportDirectory);
      for (final entry in originals.entries) {
        if (edited.containsKey(entry.key) || !visible.containsKey(entry.key)) {
          continue;
        }
        await idMap.markPendingDelete(_attachment, entry.key);
        await (update(attachments)
              ..where((row) => row.attachmentPk.equals(entry.key)))
            .write(const AttachmentsCompanion(
          uploadState: Value(fireflyAttachmentDeleted),
        ));
      }
      for (final entry in edited.entries) {
        final row = entry.value;
        final before = originals[entry.key];
        final current = visible[entry.key];
        if (current == null) {
          if (before != null || await fireflyAttachment(entry.key) != null) {
            continue;
          }
          if (row.attachableType != _journal ||
              row.attachableFk.isNotEmpty ||
              row.uploadState != fireflyAttachmentQueued) {
            throw const FireflyAttachmentException(
                FireflyAttachmentFailure.unavailable);
          }
          await files.verified(row);
          await into(attachments).insert(row.copyWith(
            attachableFk: transactionPk,
            filename: validateFireflyAttachmentName(row.filename),
            title: Value(_title(row.title)),
            dateTimeModified: Value(DateTime.now()),
          ));
          continue;
        }

        final filename = before?.filename == row.filename
            ? current.filename
            : validateFireflyAttachmentName(row.filename);
        final title = before != null && before.title == row.title
            ? current.title
            : _title(row.title);
        if (current.filename == filename && current.title == title) continue;
        await (update(attachments)
              ..where((table) => table.attachmentPk.equals(entry.key)))
            .write(AttachmentsCompanion(
          filename: Value(filename),
          title: Value(title),
          dateTimeModified: Value(DateTime.now()),
        ));
      }
    });
  }

  /// Returns a verified local path, fetching the file only if needed.
  Future<String> openFireflyAttachment(String attachmentPk, AttachmentsApi api,
      {Directory? supportDirectory}) async {
    final row = await fireflyAttachment(attachmentPk);
    if (row == null || row.uploadState == fireflyAttachmentDeleted) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.unavailable);
    }
    final files = FireflyAttachmentFiles(supportDirectory);
    try {
      return (await files.verified(row)).path;
    } on FireflyAttachmentException {
      if (row.uploadState == fireflyAttachmentQueued) rethrow;
    }

    final size = row.size;
    final hash = row.hash;
    FireflyAttachmentFiles.checkSize(size);
    if (hash == null || !RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(hash)) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.integrity);
    }
    final mapping =
        await IdMapRepository(this).byLocal(_attachment, attachmentPk);
    if (mapping == null ||
        mapping.state == FireflySyncState.pendingDelete ||
        IdMapRepository.isProvisional(mapping)) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.unavailable);
    }
    final stored = await files.write(
      row.filename,
      (() async* {
        yield* await api.download(mapping.remoteId);
      })(),
      expectedSize: size,
      expectedHash: hash,
    );
    String? previous;
    String? concurrentCopy;
    try {
      await transaction(() async {
        final current = await fireflyAttachment(attachmentPk);
        if (current == null ||
            current.uploadState == fireflyAttachmentDeleted ||
            current.hash != hash ||
            current.size != size) {
          throw const FireflyAttachmentException(
              FireflyAttachmentFailure.unavailable);
        }
        previous = current.localPath;
        if (previous != row.localPath) {
          try {
            concurrentCopy = (await files.verified(current)).path;
            return;
          } on FireflyAttachmentException {
            // The first copy is no longer available. Publish the new one.
          }
        }
        await (update(attachments)
              ..where((table) => table.attachmentPk.equals(attachmentPk)))
            .write(AttachmentsCompanion(localPath: Value(stored.file.path)));
      });
    } catch (_) {
      await files.delete(stored.file.path);
      rethrow;
    }
    if (concurrentCopy != null) {
      await files.delete(stored.file.path);
      return concurrentCopy!;
    }
    await files.delete(previous);
    return stored.file.path;
  }
}

String validateFireflyAttachmentName(String value) {
  final filename = value.trim();
  if (filename.isEmpty || filename.runes.length > 255) {
    throw const FireflyAttachmentException(
        FireflyAttachmentFailure.invalidName);
  }
  return filename;
}

String? _title(String? value) {
  final title = value?.trim();
  return title == null || title.isEmpty
      ? null
      : validateFireflyAttachmentName(title);
}

/// Private app-support storage shared by draft, sync and lazy download.
class FireflyAttachmentFiles {
  const FireflyAttachmentFiles([this.supportDirectory]);

  final Directory? supportDirectory;

  Future<Directory> _root() async {
    final support = supportDirectory ?? await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final directory = Directory(
        path.join(await support.resolveSymbolicLinks(), 'firefly-attachments'));
    final type =
        await FileSystemEntity.type(directory.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) await directory.create();
    if (await FileSystemEntity.type(directory.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.unavailable);
    }
    return directory;
  }

  static void checkSize(int? size) {
    if (size == null || size <= 0 || size > fireflyAttachmentMaxBytes) {
      throw const FireflyAttachmentException(FireflyAttachmentFailure.size);
    }
  }

  static final _managedName = RegExp(
      r'^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}(?:\.[a-z0-9]{1,10})?$');

  Future<File?> _existing(String? localPath) async {
    if (localPath == null) return null;
    final root = await _root();
    if (path.dirname(localPath) != root.path ||
        !_managedName.hasMatch(path.basename(localPath)) ||
        await FileSystemEntity.type(localPath, followLinks: false) !=
            FileSystemEntityType.file) {
      return null;
    }
    return File(localPath);
  }

  Future<File> verified(Attachment row) async {
    checkSize(row.size);
    final file = await _existing(row.localPath);
    if (file == null) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.unavailable);
    }
    if (await file.length() != row.size ||
        row.hash !=
            (await md5.bind(file.openRead(0, row.size)).single).toString()) {
      throw const FireflyAttachmentException(
          FireflyAttachmentFailure.integrity);
    }
    return file;
  }

  Future<({File file, int size, String hash})> write(
      String filename, Stream<List<int>> bytes,
      {int? expectedSize, String? expectedHash}) async {
    final root = await _root();
    final extension = path.extension(filename).toLowerCase();
    final suffix =
        RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '';
    final temp = await root.createTemp('incoming-');
    final part = File(path.join(temp.path, 'data'));
    try {
      var size = 0;
      final output = await part.open(mode: FileMode.write);
      try {
        await for (final chunk in bytes) {
          size += chunk.length;
          if (size > fireflyAttachmentMaxBytes) checkSize(size);
          if (expectedSize != null && size > expectedSize) {
            throw const FireflyAttachmentException(
                FireflyAttachmentFailure.integrity);
          }
          await output.writeFrom(chunk);
        }
      } finally {
        await output.close();
      }
      checkSize(size);
      final hash = (await md5.bind(part.openRead()).single).toString();
      if ((expectedSize != null && size != expectedSize) ||
          (expectedHash != null && hash != expectedHash.toLowerCase())) {
        throw const FireflyAttachmentException(
            FireflyAttachmentFailure.integrity);
      }
      final file = await part
          .rename(path.join(root.path, '${const Uuid().v4()}$suffix'));
      return (file: file, size: size, hash: hash);
    } finally {
      await temp.delete(recursive: true);
    }
  }

  Future<void> delete(String? localPath) async {
    try {
      await (await _existing(localPath))?.delete();
    } on FileSystemException {
      // A concurrent reader or a missing cache must not block metadata sync.
    } on FireflyAttachmentException {
      // Do not follow a replaced cache directory or file.
    }
  }
}

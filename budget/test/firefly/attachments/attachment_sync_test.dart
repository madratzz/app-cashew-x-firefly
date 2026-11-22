import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/attachment_syncer.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../support/fake_firefly_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _apiPath = '/attachments';
const _journal = FireflyAttachment.transactionJournal;
const _bytes = [37, 80, 68, 70, 10];
const _parent = 'transaction';
const _journalId = '34';
const _otherSide = 'other-side';

void main() {
  late FinanceDatabase db;
  late Directory support;
  late _AttachmentTransport transport;
  late SyncContext context;
  late AttachmentSyncer syncer;

  setUp(() async {
    db = inMemoryFinanceDatabase();
    addTearDown(db.close);
    support =
        await Directory.systemTemp.createTemp('firefly-attachments-test-');
    addTearDown(() => support.delete(recursive: true));
    transport = _AttachmentTransport();
    context = SyncContext(
      db: db,
      api: FireflyApi(transport),
      config: const FireflyConfig(mode: true),
      now: () => fixtureTime,
    );
    syncer = AttachmentSyncer(supportDirectory: support);
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Cash', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Other', order: 0));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: const Value(_parent),
          categoryFk: '0',
          name: 'Fixture',
          note: '',
          amount: -4,
        ));
  });

  Future<void> linkParent() => context.idMap.put(fixtureMapping(
      type: FireflyEntityType.transaction,
      localPk: _parent,
      remoteId: '20',
      subId: _journalId));

  Future<void> cycle() async {
    await syncer.pull(context);
    await syncer.push(context);
    await syncer.pushDeletes(context);
  }

  Future<Attachment> queue() async {
    final draft = await db.prepareFireflyAttachment(
      filename: 'receipt.pdf',
      title: 'Receipt',
      bytes: Stream.value(_bytes),
      supportDirectory: support,
    );
    await db.persistFireflyAttachmentDraft(_parent, [draft],
        baseline: [], supportDirectory: support);
    return draft;
  }

  test(
      'queued offline upload waits for journal and runs once, then renames and deletes',
      () async {
    final draft = await queue();
    transport.offline = true;
    await expectLater(cycle(), throwsA(isA<FireflyNetworkError>()));
    transport.offline = false;
    await cycle();
    expect(transport.writes, isEmpty);

    await linkParent();
    await cycle();
    expect(transport.writes, ['POST', 'UPLOAD', 'PUT']);
    final mapping = (await context.idMap
        .byLocal(FireflyEntityType.attachment, draft.attachmentPk))!;
    final created = await context.api.attachments.get(mapping.remoteId);
    expect(created.attachableId, _journalId);
    expect(created.attachableType, _journal);
    expect(created.filename, 'receipt.pdf');
    expect(created.title, 'Receipt');
    expect(created.hash, md5.convert(_bytes).toString());
    expect(
        await db.openFireflyAttachment(
            draft.attachmentPk, context.api.attachments,
            supportDirectory: support),
        draft.localPath);
    await cycle();
    expect(transport.writes, ['POST', 'UPLOAD', 'PUT']);

    final initial = await db.fireflyTransactionAttachments(_parent);
    await db.persistFireflyAttachmentDraft(
      _parent,
      [
        initial.single
            .copyWith(filename: 'renamed.pdf', title: const Value('Renamed'))
      ],
      baseline: initial,
    );
    await cycle();
    expect((await context.api.attachments.get(mapping.remoteId)).filename,
        'renamed.pdf');
    expect(transport.writes, ['POST', 'UPLOAD', 'PUT', 'PUT']);

    final renamed = await db.fireflyTransactionAttachments(_parent);
    await db.persistFireflyAttachmentDraft(_parent, [], baseline: renamed);
    expect(await db.fireflyTransactionAttachments(_parent), isEmpty);
    await cycle();
    await cycle();
    expect(transport.writes, ['POST', 'UPLOAD', 'PUT', 'PUT', 'DELETE']);
    expect(await File(draft.localPath!).exists(), isFalse);
  });

  test('recovers lost metadata and raw-upload replies without duplicate writes',
      () async {
    await linkParent();
    final draft = await queue();
    transport.loseCreateReply = true;
    await expectLater(cycle(), throwsA(isA<FireflyNetworkError>()));
    transport.loseUploadReply = true;
    await expectLater(cycle(), throwsA(isA<FireflyNetworkError>()));
    await cycle();
    await cycle();
    expect(transport.writes, ['POST', 'UPLOAD', 'PUT']);
    expect(
        (await db.fireflyTransactionAttachments(_parent)).single.attachmentPk,
        draft.attachmentPk);
  });

  test('metadata pull paginates, shares transfer journals and downloads lazily',
      () async {
    await linkParent();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          transactionPk: const Value(_otherSide),
          categoryFk: '0',
          name: 'Fixture',
          note: '',
          amount: 4,
        ));
    await context.idMap.put(fixtureMapping(
        type: FireflyEntityType.transaction,
        localPk: _otherSide,
        remoteId: '20',
        subId: _journalId,
        role: 2));
    final outside = File(path.join(support.path, 'outside.pdf'));
    await outside.writeAsString('original');
    final received = await transport.seedFile('41', '../../outside.pdf');
    await transport.seedFile('42', 'budget.pdf', type: 'Budget');
    final initial = await db.fireflyTransactionAttachments(_parent);
    await cycle();
    final current = (await db.fireflyTransactionAttachments(_parent)).single;
    expect(await db.fireflyTransactionAttachments(_otherSide), [current]);
    expect((await db.watchFireflyAttachments().first), hasLength(2));
    expect(current.filename, '../../outside.pdf');
    expect(current.localPath, isNull);
    expect(transport.requests.where((r) => r.method == 'DOWNLOAD'), isEmpty);

    // Saving an older, untouched draft must keep the preceding remote pull.
    await db.persistFireflyAttachmentDraft(_parent, initial, baseline: initial);
    final cached = await db.openFireflyAttachment(
        current.attachmentPk, context.api.attachments,
        supportDirectory: support);
    expect(path.dirname(cached),
        path.join(await support.resolveSymbolicLinks(), 'firefly-attachments'));
    expect(md5.convert(await File(cached).readAsBytes()).toString(), received);
    expect(await outside.readAsString(), 'original');
    await db.openFireflyAttachment(
        current.attachmentPk, context.api.attachments,
        supportDirectory: support);
    expect(
        transport.requests.where((r) => r.method == 'DOWNLOAD'), hasLength(1));

    await context.api.attachments.update('41', {'filename': 'server.pdf'});
    await cycle();
    final renamed = (await db.fireflyTransactionAttachments(_parent)).single;
    expect(renamed.filename, 'server.pdf');
    expect(renamed.localPath, cached);
    await context.api.attachments.delete('41');
    await cycle();
    expect(await db.fireflyTransactionAttachments(_parent), isEmpty);
    expect(await File(cached).exists(), isFalse);
  });

  test('rejects oversized sources and corrupt downloads without partial files',
      () async {
    await linkParent();
    await expectLater(
      db.prepareFireflyAttachment(
        filename: 'large.pdf',
        bytes: Stream.value(List.filled(fireflyAttachmentMaxBytes + 1, 0)),
        supportDirectory: support,
      ),
      throwsA(isA<FireflyAttachmentException>().having(
          (error) => error.failure, 'failure', FireflyAttachmentFailure.size)),
    );
    await transport.seedFile('41', 'receipt.pdf');
    await cycle();
    final row = (await db.fireflyTransactionAttachments(_parent)).single;
    transport.corruptDownload = true;
    await expectLater(
      db.openFireflyAttachment(row.attachmentPk, context.api.attachments,
          supportDirectory: support),
      throwsA(isA<FireflyAttachmentException>().having((error) => error.failure,
          'failure', FireflyAttachmentFailure.integrity)),
    );
    expect((await db.fireflyAttachment(row.attachmentPk))!.localPath, isNull);
    expect(
        await Directory(path.join(support.path, 'firefly-attachments'))
            .list()
            .toList(),
        isEmpty);
  });

  test('rejects a symlinked cache directory before writing outside app support',
      () async {
    final outside = await Directory.systemTemp.createTemp('firefly-outside-');
    addTearDown(() => outside.delete(recursive: true));
    await Link(path.join(support.path, 'firefly-attachments'))
        .create(outside.path);
    await expectLater(
      db.prepareFireflyAttachment(
        filename: '../escape.pdf',
        bytes: Stream.value(_bytes),
        supportDirectory: support,
      ),
      throwsA(isA<FireflyAttachmentException>()),
    );
    expect(await outside.list().toList(), isEmpty);
  },
      skip: Platform.isWindows
          ? 'Symlink creation requires Windows privileges'
          : false);
}

/// Adds Firefly's server-side hash and metadata changes to the generic fake.
class _AttachmentTransport extends FakeFireflyTransport {
  _AttachmentTransport() : super(maxPageSize: 1) {
    onRequest = (_) {
      if (offline) throw const FireflyNetworkError();
    };
  }

  bool offline = false;
  bool loseCreateReply = false;
  bool loseUploadReply = false;
  bool corruptDownload = false;

  List<String> get writes => [
        for (final request in requests)
          if (request.method != 'GET' && request.method != 'DOWNLOAD')
            request.method,
      ];

  Future<String> seedFile(String id, String filename,
      {String type = _journal}) async {
    seed(_apiPath, id, {
      'attachable_type': type,
      'attachable_id': _journalId,
      'filename': filename,
      'updated_at': fixtureTime.toIso8601String(),
    });
    await upload('$_apiPath/$id/upload', Stream.value(_bytes));
    return md5.convert(_bytes).toString();
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final created = await super.post(
        path,
        {
          ...body,
          if (path == _apiPath) ...{
            'size': 0,
            'hash': '',
            'mime': '',
            'title': null
          },
        },
        query: query);
    if (loseCreateReply) {
      loseCreateReply = false;
      throw const FireflyNetworkError();
    }
    return created;
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
      {int? length}) async {
    final data = await bytes.expand((chunk) => chunk).toList();
    await super.upload(path, Stream.value(data), length: length);
    final item = path.substring(0, path.lastIndexOf('/'));
    final id = item.split('/').last;
    final previous = (await get(item))['attributes'] as JsonObject;
    seed(_apiPath, id, {
      ...previous,
      'hash': md5.convert(data).toString(),
      'size': data.length,
      'mime': 'application/pdf',
    });
    if (loseUploadReply) {
      loseUploadReply = false;
      throw const FireflyNetworkError();
    }
  }

  @override
  Future<Stream<List<int>>> download(String path) async {
    final good = await super.download(path);
    return corruptDownload ? Stream.value(List.filled(_bytes.length, 1)) : good;
  }
}

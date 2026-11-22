import 'dart:io';
import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../../test/firefly/e2e/phase3/support/phase3_emulator.dart';
import '../../test/firefly/e2e/support/e2e_harness.dart';

const _wallet = FireflyEntityType.walletAccount;
const _category = FireflyEntityType.category;
const _transaction = FireflyEntityType.transaction;

/// Replaces the manual on-device attachment check (WP-49). On a real device
/// or desktop target, with the platform's own path_provider and file system,
/// a binary file on disk is attached to a transaction, uploaded, downloaded
/// back by a second device and compared byte for byte.
///
/// Runs against FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN (--dart-define or the
/// environment) when set, otherwise against the emulated server on a
/// loopback port.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final live = E2eTarget.fromEnvironment() != null;
  final clock = E2eClock(live: live);
  final run = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  String named(String name) => 'E2E-att $name $run';

  testWidgets('a picked file uploads and downloads with identical bytes',
      (tester) async {
    await tester.runAsync(() async {
      final target =
          E2eTarget.fromEnvironment() ?? await Phase3Emulator.target(clock.now);
      final device = E2eDevice(target, clock);
      final second = E2eDevice(target, clock);
      final snapshot = live ? await E2eServerSnapshot.take(target) : null;
      final picked = Directory(
          '${(await getTemporaryDirectory()).path}/firefly-att-$run');
      try {
        final admin = device.admin;
        final checkingId = (await admin.accounts.create({
          'name': named('Checking'),
          'type': 'asset',
          'account_role': 'defaultAsset',
          'currency_code': 'USD',
          'opening_balance': '100.00',
          'opening_balance_date': formatFireflyDate(clock.now()),
        }))
            .id;
        final categoryId =
            (await admin.categories.create({'name': named('Receipts')})).id;

        Future<void> sync(E2eDevice on) async {
          final cycle = await on.sync();
          expect(cycle.report.issues.map((issue) => issue.message), isEmpty);
        }

        await sync(device);
        final pk = await device.addTransaction(
          name: named('Receipt purchase'),
          amount: -9.99,
          walletPk: (await device.localPk(_wallet, checkingId))!,
          categoryPk: (await device.localPk(_category, categoryId))!,
        );

        // Every byte value, plus random content, so encoding bugs show.
        final random = Random(7);
        final bytes = [
          for (var i = 0; i < 256; i++) i,
          for (var i = 0; i < 200 * 1024; i++) random.nextInt(256),
        ];
        await picked.create(recursive: true);
        final file = File('${picked.path}/scan.bin');
        await file.writeAsBytes(bytes, flush: true);

        // The same stream the file picker hands over for a path on disk.
        final draft = FireflyTransactionDraft(device.db);
        await draft.load(pk);
        draft.attachments = [
          await device.db.prepareFireflyAttachment(
            filename: 'scan.bin',
            title: named('Scan'),
            bytes: file.openRead(),
            mime: 'application/octet-stream',
          ),
        ];
        await draft.persist(pk);
        await clock.tick();
        await sync(device);
        // The upload waits for the journal id from the first push.
        await sync(device);

        final mapping =
            (await device.context.idMap.byLocal(_transaction, pk))!;
        final remote = (await admin.attachments.list(limit: 100))
            .items
            .where((item) => item.attachableId == mapping.remoteSubId)
            .single;
        final served = await (await admin.attachments.download(remote.id))
            .expand((chunk) => chunk)
            .toList();
        expect(served, bytes, reason: 'server copy');

        await sync(second);
        final otherPk = (await second.localPk(_transaction, mapping.remoteId,
            subId: mapping.remoteSubId))!;
        final row =
            (await second.db.fireflyTransactionAttachments(otherPk)).single;
        final path = await second.db
            .openFireflyAttachment(row.attachmentPk, second.admin.attachments);
        expect(await File(path).readAsBytes(), bytes, reason: 'device copy');
      } finally {
        await snapshot?.restore();
        await device.close();
        await second.close();
        await target.close();
        if (await picked.exists()) await picked.delete(recursive: true);
      }
    });
  });
}

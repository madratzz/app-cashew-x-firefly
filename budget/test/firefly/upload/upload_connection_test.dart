import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/bootstrap_upload.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';
import 'bootstrap_upload_test.dart' show UploadServer, createWallet;

class _MemoryTokenStore extends TokenStore {
  @override
  Future<String?> read() async => 'REDACTED';
}

void main() {
  const url = 'https://firefly.example';

  late FinanceDatabase db;
  late Directory backups;
  late Map<String, Object?> settings;
  late FireflyConnectionController controller;
  late UploadServer server;
  var syncLookups = 0;
  var databaseClosed = false;

  setUp(() async {
    db = inMemoryFinanceDatabase();
    databaseClosed = false;
    await createWallet(db, '0', 'usd');
    backups = await Directory.systemTemp.createTemp('upload-widget-backup');
    settings = {FireflyConfig.baseUrlKey: url, FireflyConfig.modeKey: false};
    appStateSettings = {'selectedWalletPk': '0'};
    server = UploadServer();
    final tokenStore = _MemoryTokenStore();
    controller = FireflyConnectionController(
        writeSetting: (key, value) async => settings[key] = value,
        transportFactory: (serverUrl, _) {
          expect(serverUrl.toString(), url);
          return server;
        },
        tokens: tokenStore);
    await FireflyMode.init(() => settings, tokenStore: tokenStore);
    final resolve = FireflySync.resolve;
    addTearDown(() => FireflySync.resolve = resolve);
    syncLookups = 0;
    FireflySync.resolve = () async {
      syncLookups++;
      expect(settings[FireflyConfig.modeKey], isTrue);
      return null;
    };
  });

  tearDown(() async {
    if (!databaseClosed) await db.close();
    backups.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(850, 2300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: FireflyConnectionPage(
      controller: controller,
      db: db,
      backupDirectory: () async => backups,
    )));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> eventually(WidgetTester tester, Finder finder) async {
    for (var tries = 0; tries < 40 && finder.evaluate().isEmpty; tries++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> closeDatabase(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final closed = db.close().then((_) => databaseClosed = true);
    await tester.pump(const Duration(milliseconds: 10));
    await closed;
  }

  final mode = find.byKey(const ValueKey('firefly-mode'));
  final uploadChoice = find.text('firefly-upload-choice');
  final replaceChoice = find.text('firefly-upload-replace-choice');
  final confirm = find.byKey(const ValueKey('firefly-upload-confirm'));
  final resume = find.text('firefly-upload-resume');
  final abandon = find.text('firefly-upload-abandon');

  testWidgets('first connection uploads only after dry-run confirmation',
      (tester) async {
    await pump(tester);
    await tap(tester, mode);
    await eventually(tester, replaceChoice);
    await tap(tester, uploadChoice);
    await eventually(tester, confirm);
    expect(settings[FireflyConfig.modeKey], isFalse);
    expect(syncLookups, 0);
    expect(server.commits, isEmpty);
    expect(find.text('firefly-upload-accounts'), findsOneWidget);

    await tester.tap(confirm);
    await eventually(tester, mode);
    expect(settings[FireflyConfig.modeKey], isTrue);
    expect(FireflyMode.enabled, isTrue);
    expect(syncLookups, greaterThan(0));
    expect(server.commits.single.path, '/accounts');
    await tester.runAsync(() async {
      expect(await FireflyBootstrapUpload.inProgress(db), isFalse);
      expect(await db.select(db.wallets).get(), hasLength(1));
    });
  });

  testWidgets('first connection can still replace through its backup warning',
      (tester) async {
    await pump(tester);
    await tap(tester, mode);
    await eventually(tester, replaceChoice);
    await tap(tester, replaceChoice);
    expect(find.text('firefly-connection-replace-description'), findsOneWidget);
    final confirmReplace = find.text('firefly-connection-replace-confirm');
    await tester.tap(confirmReplace);
    await eventually(
        tester, find.textContaining('firefly-connection-replace-done'));
    expect(settings[FireflyConfig.modeKey], isTrue);
    expect(server.commits, isEmpty);
    expect(backups.listSync(), hasLength(1));
    await closeDatabase(tester);
  });

  testWidgets('resuming blocks replace and abandoning requires confirmation',
      (tester) async {
    await tester.runAsync(() async {
      final upload = FireflyBootstrapUpload(SyncContext(
          db: db,
          api: FireflyApi(server),
          config: const FireflyConfig(baseUrl: url)));
      server.loseBefore = '/accounts';
      expect((await upload.run(confirmed: await upload.prepare())).succeeded,
          isFalse);
    });
    await pump(tester);
    await tap(tester, mode);
    await eventually(tester, resume);
    expect(replaceChoice, findsNothing);
    await tap(tester, abandon);
    expect(find.text('firefly-upload-abandon-warning'), findsOneWidget);
    expect(syncLookups, 0);
    expect(settings[FireflyConfig.modeKey], isFalse);

    await tap(tester, find.text('firefly-connection-cancel'));
    await tap(tester, mode);
    await eventually(tester, abandon);
    await tap(tester, abandon);
    await tap(
        tester, find.widgetWithText(FilledButton, 'firefly-upload-abandon'));
    expect(settings[FireflyConfig.modeKey], isFalse);
    expect(syncLookups, 0);
    await eventually(
        tester,
        find.byWidgetPredicate((widget) =>
            widget is SwitchListTile &&
            widget.key == const ValueKey('firefly-mode') &&
            widget.onChanged != null));
    await tap(tester, mode);
    await eventually(tester, replaceChoice);
    await closeDatabase(tester);
  });

  testWidgets('cancelled or refused upload never enables normal sync',
      (tester) async {
    server.seed('/tags', 'existing', {'tag': 'Existing'});
    await pump(tester);
    await tap(tester, mode);
    await eventually(tester, uploadChoice);
    await tap(tester, uploadChoice);
    await eventually(tester, find.text('firefly-upload-nonempty'));
    expect(confirm, findsNothing);
    await tap(tester, find.byType(BackButton));
    expect(settings[FireflyConfig.modeKey], isFalse);
    expect(syncLookups, 0);
    expect(server.commits, isEmpty);
    await closeDatabase(tester);
  });
}

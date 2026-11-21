import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/conflicts_page.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_firefly_transport.dart';
import '../../support/test_database.dart';

class MemoryTokenStore extends TokenStore {
  String? token;
  int writes = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    writes++;
    token = value;
  }

  @override
  Future<void> delete() async => token = null;
}

void main() {
  late Map<String, Object?> settings;
  late MemoryTokenStore tokens;
  late FinanceDatabase db;

  FireflyConnectionController controller() => FireflyConnectionController(
        tokens: tokens,
        writeSetting: (key, value) async => settings[key] = value,
        transportFactory: (_, __) => FakeFireflyTransport()
          ..onRequest = (_) => throw const FireflyUnauthorized(),
      );

  Future<void> pumpPage(WidgetTester tester,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: FireflyConnectionPage(controller: controller(), db: db)));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    settings = {FireflyConfig.modeKey: false, FireflyConfig.baseUrlKey: ''};
    tokens = MemoryTokenStore();
    db = inMemoryFinanceDatabase();
    await FireflyMode.init(() => settings, tokenStore: tokens);
  });

  tearDown(() => db.close());

  group('URL validation', () {
    test('rejects invalid and plain HTTP URLs', () {
      expect(fireflyUrlError('not a url'), 'firefly-connection-url-invalid');
      expect(fireflyUrlError('http://firefly.example'),
          'firefly-connection-url-https');
      expect(fireflyUrlError(''), 'firefly-connection-url-required');
      expect(fireflyUrlError('https://firefly.example'), isNull);
    });

    testWidgets('shows a message for invalid and non-HTTPS URLs',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(
          find.byKey(const ValueKey('firefly-token')), 'REDACTED');
      await tester.enterText(
          find.byKey(const ValueKey('firefly-url')), 'nonsense');
      await tester.tap(find.byKey(const ValueKey('firefly-connect')));
      await tester.pumpAndSettle();
      expect(find.text('firefly-connection-url-invalid'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-url')), 'http://firefly.example');
      await tester.tap(find.byKey(const ValueKey('firefly-connect')));
      await tester.pumpAndSettle();
      expect(find.text('firefly-connection-url-https'), findsOneWidget);
      expect(tokens.writes, 0);
    });
  });

  testWidgets('a failed connection test does not save the token',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(
        find.byKey(const ValueKey('firefly-url')), 'https://firefly.example');
    await tester.enterText(
        find.byKey(const ValueKey('firefly-token')), 'REDACTED');
    await tester.tap(find.byKey(const ValueKey('firefly-connect')));
    await tester.pumpAndSettle();
    expect(find.text('firefly-connection-error-auth'), findsOneWidget);
    expect(tokens.writes, 0);
    expect(tokens.token, isNull);
    expect(settings[FireflyConfig.baseUrlKey], '');
  });

  testWidgets('the token field is obscured and empty on reopen',
      (tester) async {
    tokens.token = 'REDACTED';
    await pumpPage(tester);
    final field = tester.widget<TextField>(find.descendant(
        of: find.byKey(const ValueKey('firefly-token')),
        matching: find.byType(TextField)));
    expect(field.obscureText, isTrue);
    expect(field.controller!.text, isEmpty);
    expect(find.text('REDACTED'), findsNothing);
  });

  testWidgets('sign out removes the token and keeps data', (tester) async {
    tokens.token = 'REDACTED';
    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: 'Food', order: 0));
    await pumpPage(tester, size: const Size(390, 2400));
    await tester.tap(find.byKey(const ValueKey('firefly-sign-out')));
    await tester.pumpAndSettle();
    expect(tokens.token, isNull);
    expect(FireflyMode.enabled, isFalse);
    await tester.runAsync(() async {
      expect(await db.select(db.categories).get(), hasLength(1));
    });
  });

  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    testWidgets('lays out without overflow at ${size.width}', (tester) async {
      tokens.token = 'REDACTED';
      await pumpPage(tester, size: size);
      expect(tester.takeException(), isNull);
      final width = tester.getSize(find.byType(ListView).first).width;
      expect(width, lessThanOrEqualTo(fireflyPageMaxWidth));
    });
  }

  test('replace flow writes a backup before clearing and keeps settings',
      () async {
    final dir = await Directory.systemTemp.createTemp('firefly-backup');
    addTearDown(() => dir.delete(recursive: true));
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
        settingsJSON: '{"fireflyMode":false}', dateUpdated: Value(DateTime(2026))));
    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: 'Food', order: 0));
    await SyncMetaRepository(db).write(SyncMetaRepository.lastSync, 'x');

    var categoriesAtBackup = -1;
    final backup = await FireflyReplaceFlow(
      db: db,
      backupDirectory: () async => dir,
      beforeBackup: () async =>
          categoriesAtBackup = (await db.select(db.categories).get()).length,
    ).run();

    expect(categoriesAtBackup, 1);
    expect(await backup.exists(), isTrue);
    final copy = FinanceDatabase(NativeDatabase(backup));
    addTearDown(copy.close);
    expect(await copy.select(copy.categories).get(), hasLength(1));
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.fireflySyncMeta).get(), isEmpty);
    expect((await db.select(db.appSettings).getSingle()).settingsJSON,
        '{"fireflyMode":false}');
    expect(await FireflyReplaceFlow.isFirstConnection(db), isTrue);
  });

  test('re-applying a conflict marks the local row modified', () async {
    final category = await db
        .into(db.categories)
        .insertReturning(CategoriesCompanion.insert(name: 'Server', order: 0));
    final local = category.copyWith(name: 'Local');
    final conflict = await db.into(db.fireflyConflicts).insertReturning(
        FireflyConflictsCompanion.insert(
            entityType: FireflyEntityType.category,
            localPk: category.categoryPk,
            remoteId: '1',
            localJson: local.toJsonString(),
            resolution: 'applyRemoteWithConflict'));
    final at = DateTime(2026, 11, 22, 12);
    expect(await reapplyFireflyConflict(db, conflict, now: () => at), isTrue);
    final row = await db.select(db.categories).getSingle();
    expect(row.name, 'Local');
    expect(row.dateTimeModified, at);
  });
}

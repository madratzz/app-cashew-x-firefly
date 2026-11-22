import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/entry/attachment_chip.dart';
import 'package:budget/firefly/ui/pages/attachments/attachment_actions.dart';
import 'package:budget/firefly/ui/pages/attachments/attachments_page.dart';
import 'package:budget/firefly/ui/transaction/attachments_section.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late FinanceDatabase db;
  late Directory support;
  late String transactionPk;
  final launched = <String>[];

  // Drift cancels stream queries on a zero timer after the widgets unmount.
  void uiTest(String description, Future<void> Function(WidgetTester) body) =>
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        // Let IO started from widget callbacks finish before the database closes.
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(seconds: 1));
        }
        unawaited(db.close());
        await tester.pump();
      });

  setUp(() async {
    db = inMemoryFinanceDatabase();
    support = await Directory.systemTemp.createTemp('attachments-ui-');
    launched.clear();
    FireflyAttachmentActions.supportDirectory = support;
    // The draft saves through path_provider like the app does.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => support.path);
    FireflyAttachmentActions.sources =
        () => FireflyAttachmentSource.values.toList();
    FireflyAttachmentActions.pick = (_) async => (
          name: 'receipt.txt',
          bytes: Stream.value(utf8.encode('receipt')),
          mime: 'text/plain',
        );
    FireflyAttachmentActions.api = () async => null;
    FireflyAttachmentActions.launch = (path) async {
      launched.add(path);
      return true;
    };
    await db.into(db.wallets).insert(WalletsCompanion.insert(
        walletPk: const Value('0'), name: 'Default', order: 0));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        categoryPk: const Value('0'), name: 'Default', order: 0));
    transactionPk = (await db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
                name: 'Purchase', amount: -1, note: '', categoryFk: '0')))
        .transactionPk;
  });

  tearDown(() async {
    await support.delete(recursive: true);
  });

  // Watch-based queries never complete inside runAsync, so read the table.
  Future<List<Attachment>> storedRows() => db.select(db.attachments).get();

  Future<Attachment> stored(String name) async {
    final row = await db.prepareFireflyAttachment(
        filename: name,
        bytes: Stream.value(utf8.encode(name)),
        supportDirectory: support);
    await db.persistFireflyAttachmentDraft(transactionPk, [row],
        supportDirectory: support);
    return (await db.fireflyAttachment(row.attachmentPk))!;
  }

  // Real file and database IO must run outside the fake clock.
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  uiTest('section adds, renames and removes files in the draft',
      (tester) async {
    final draft = FireflyTransactionDraft(db);
    await pump(tester, FireflyAttachmentsSection(draft: draft));
    expect(find.text('firefly-attachments-title'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('firefly-attachments-add')));
    await tester.pumpAndSettle();
    expect(find.text('take-photo'), findsOneWidget);
    await tester.tap(find.text('select-file'));
    await waitFor(tester, () => draft.attachments.isNotEmpty);
    await waitFor(tester,
        () => find.byType(CircularProgressIndicator).evaluate().isEmpty);
    await tester.pumpAndSettle();
    expect(find.text('receipt.txt'), findsOneWidget);
    expect(find.textContaining('firefly-attachments-queued'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('firefly-attachments-rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('firefly-attachment-name')), '  ');
    await tester.pump();
    expect(find.text('firefly-attachments-error-name'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('firefly-attachment-name')), ' Lunch ');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(draft.attachments.single.title, 'Lunch');
    expect(find.text('Lunch'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await waitFor(tester, () => launched.isNotEmpty);
    expect(launched.single, draft.attachments.single.localPath);

    await tester.runAsync(() => draft.persist(transactionPk));
    final saved = await tester.runAsync(() => storedRows());
    expect(saved!.single.title, 'Lunch');
    expect(saved.single.attachableFk, transactionPk);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('firefly-attachments-remove'));
    await tester.pumpAndSettle();
    expect(draft.attachments, isEmpty);
    expect(find.text('Lunch'), findsNothing);
  });

  uiTest('removing an unsaved file discards the staged copy', (tester) async {
    final draft = FireflyTransactionDraft(db);
    final row = (await tester.runAsync(() => db.prepareFireflyAttachment(
        filename: 'a.txt',
        bytes: Stream.value([1, 2, 3]),
        supportDirectory: support)))!;
    draft.attachments = [row];
    await pump(tester, FireflyAttachmentsSection(draft: draft));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('firefly-attachments-remove'));
    await waitFor(tester, () => !File(row.localPath!).existsSync());
  });

  uiTest('a too large pick shows the size error', (tester) async {
    FireflyAttachmentActions.pick = (_) async => (
          name: 'big.bin',
          bytes:
              Stream.value(List<int>.filled(fireflyAttachmentMaxBytes + 1, 0)),
          mime: null,
        );
    final draft = FireflyTransactionDraft(db);
    await pump(tester, FireflyAttachmentsSection(draft: draft));
    await tester.tap(find.byKey(const ValueKey('firefly-attachments-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('select-file'));
    await waitFor(
        tester,
        () =>
            find.text('firefly-attachments-error-size').evaluate().isNotEmpty);
    expect(draft.attachments, isEmpty);
  });

  uiTest('edit draft deletes only rows removed from the loaded snapshot',
      (tester) async {
    await tester.runAsync(() async {
      await stored('one.txt');
      await stored('two.txt');
    });
    final draft = FireflyTransactionDraft(db);
    await tester.runAsync(() => draft.load(transactionPk));
    expect(draft.attachments, hasLength(2));
    draft.attachments = [draft.attachments.last];
    await tester.runAsync(() => draft.persist(transactionPk));
    final left = await tester.runAsync(() => storedRows());
    expect(
        left!
            .where((row) => row.uploadState != fireflyAttachmentDeleted)
            .single
            .filename,
        'two.txt');
  });

  uiTest('chip shows the count and opens the list', (tester) async {
    await tester.runAsync(() async {
      await stored('one.txt');
      await stored('two.txt');
    });
    await pump(
        tester,
        Column(children: [
          FireflyAttachmentChip(transactionPk: 'other', db: db),
          FireflyAttachmentChip(transactionPk: transactionPk, db: db),
        ]));
    await waitFor(tester, () => find.text('2').evaluate().isNotEmpty);
    expect(
        find.byKey(const ValueKey('firefly-attachment-chip')), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FireflyAttachmentsPage), findsOneWidget);
    await waitFor(tester, () => find.text('one.txt').evaluate().isNotEmpty);
    expect(find.text('one.txt'), findsOneWidget);
    expect(find.text('two.txt'), findsOneWidget);
  });

  uiTest('page deletes a file after confirmation', (tester) async {
    final row = (await tester.runAsync(() => stored('one.txt')))!;
    await tester.pumpWidget(MaterialApp(
        home: FireflyAttachmentsPage(transactionPk: transactionPk, db: db)));
    await waitFor(tester, () => find.text('one.txt').evaluate().isNotEmpty);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('firefly-attachments-remove'));
    await tester.pumpAndSettle();
    expect(find.text('firefly-attachments-delete-confirm'), findsOneWidget);
    await tester.tap(find.text('firefly-attachments-remove').last);
    await waitFor(tester,
        () => find.text('firefly-attachments-empty').evaluate().isNotEmpty);
    final current =
        await tester.runAsync(() => db.fireflyAttachment(row.attachmentPk));
    expect(current!.uploadState, fireflyAttachmentDeleted);
    expect(find.text('firefly-attachments-empty'), findsOneWidget);
  });

  uiTest('empty global page shows the empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FireflyAttachmentsPage(db: db)));
    await waitFor(tester,
        () => find.text('firefly-attachments-empty').evaluate().isNotEmpty);
  });
}

import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/conflicts_page.dart';
import 'package:budget/firefly/ui/pages/liabilities/liabilities_page.dart';
import 'package:budget/firefly/ui/slots.dart';
import 'package:budget/firefly/ui/wallet/account_details_section.dart';
import 'package:budget/pages/homePage/homePageNetWorth.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

class _Tokens extends TokenStore {
  String? token = 'REDACTED';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

WidgetTester? _tester;

/// Unmounts inside the test body so Drift stream timers fire before the
/// binding checks for pending timers.
void widgetTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      _tester = tester;
      addTearDown(() => _tester = null);
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

Future<T> io<T>(Future<T> Function() run) async {
  final tester = _tester;
  if (tester == null) return run();
  return (await tester.runAsync(run)) as T;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  late FinanceDatabase db;
  late Map<String, Object?> settings;

  Future<void> setMode(bool on) async {
    settings = {
      FireflyConfig.modeKey: on,
      FireflyConfig.baseUrlKey: 'https://firefly.example',
    };
    await FireflyMode.init(() => settings, tokenStore: _Tokens());
  }

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await settle(tester);
  }

  Future<void> wallet(String pk,
      {AccountKind kind = AccountKind.asset,
      bool archived = false,
      AccountDetailsCompanion? details}) async {
    await io(() async {
      await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: Value(pk),
          name: 'Wallet $pk',
          order: 0,
          currency: const Value('eur'),
          accountKind: Value(kind),
          archived: Value(archived)));
      if (details != null) {
        await db
            .into(db.accountDetails)
            .insert(details.copyWith(walletFk: Value(pk)));
      }
    });
  }

  Future<void> map(String pk) =>
      io(() => IdMapRepository(db).put(FireflyIdMapping(
          entityType: FireflyEntityType.liabilityAccount,
          localPk: pk,
          remoteId: '7$pk',
          remoteSubId: '',
          remoteRole: 0,
          state: FireflySyncState.synced,
          attempts: 0)));

  setUp(() async {
    db = inMemoryFinanceDatabase();
    await setMode(true);
  });

  tearDown(() async {
    await setMode(false);
    db.close();
  });

  group('account details section', () {
    widgetTest('edits asset fields and saves only changes', (tester) async {
      await wallet('a',
          details: const AccountDetailsCompanion(
              accountRole: Value('savingAsset'),
              notes: Value('keep'),
              serverBalance: Value(12.5)));
      await pump(tester,
          Scaffold(body: FireflyAccountDetailsSection(walletPk: 'a', db: db)));

      expect(find.text('savingAsset'), findsOneWidget);
      expect(find.byKey(const ValueKey('firefly-account-server-balance')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('firefly-account-type')), findsNothing);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-account-iban')), 'NL00REDACTED');
      await tester.tap(find.byKey(const ValueKey('firefly-account-net-worth')));
      await tester
          .tap(find.byKey(const ValueKey('firefly-account-details-save')));
      await settle(tester);

      final saved = await io(() => db.fireflyAccountDetails('a'));
      expect(saved!.iban, 'NL00REDACTED');
      expect(saved.includeNetWorth, isFalse);
      expect(saved.notes, 'keep');
      expect(saved.accountRole, 'savingAsset');
      expect(saved.serverBalance, 12.5);
    });

    widgetTest('credit card role is read-only', (tester) async {
      await wallet('c',
          details:
              const AccountDetailsCompanion(accountRole: Value('ccAsset')));
      await pump(tester,
          Scaffold(body: FireflyAccountDetailsSection(walletPk: 'c', db: db)));
      expect(find.byKey(const ValueKey('firefly-account-role')), findsNothing);
      expect(find.text('ccAsset'), findsOneWidget);
    });

    widgetTest('mode off renders no wallet section', (tester) async {
      await setMode(false);
      await wallet('a');
      await pump(
          tester, const Scaffold(body: FireflyWalletExtras(walletPk: 'a')));
      expect(
          find.byKey(const ValueKey('firefly-account-details')), findsNothing);
      expect(fireflyAccountDetailsSection, isNotNull);
    });
  });

  group('liabilities page', () {
    widgetTest('lists active and archived apart', (tester) async {
      await wallet('l1',
          kind: AccountKind.liability,
          details: const AccountDetailsCompanion(
              liabilityType: Value('mortgage'),
              interest: Value(3.5),
              interestPeriod: Value('yearly')));
      await wallet('l2', kind: AccountKind.liability, archived: true);
      await wallet('asset');
      await pump(tester, FireflyLiabilitiesPage(db: db));

      expect(find.text('Wallet l1'), findsOneWidget);
      expect(find.text('Wallet l2'), findsOneWidget);
      expect(find.text('Wallet asset'), findsNothing);
      expect(find.byKey(const ValueKey('firefly-liabilities-archived')),
          findsOneWidget);
      expect(
          tester.getTopLeft(find.text('Wallet l1')).dy <
              tester.getTopLeft(find.text('Wallet l2')).dy,
          isTrue);
      expect(find.textContaining('mortgage'), findsOneWidget);
    });

    widgetTest('creates a liability without a virtual balance', (tester) async {
      var pushes = 0;
      await pump(tester,
          FireflyLiabilitiesPage(db: db, pushNow: () async => pushes++));
      expect(find.text('firefly-liabilities-empty'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('firefly-liability-add')));
      await settle(tester);
      expect(find.byKey(const ValueKey('firefly-account-virtual-balance')),
          findsNothing);
      await tester.tap(find.byKey(const ValueKey('firefly-liability-save')));
      await settle(tester);
      expect(find.text('firefly-liabilities-name-required'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-liability-name')), 'Car loan');
      await tester.enterText(
          find.byKey(const ValueKey('firefly-liability-currency')), 'EUR');
      await tester.enterText(
          find.byKey(const ValueKey('firefly-account-interest')), '4.2');
      await tester.tap(find.byKey(const ValueKey('firefly-liability-save')));
      await settle(tester);

      expect(pushes, 1);
      final rows = await io(() => db.fireflyLiabilities());
      expect(rows.single.name, 'Car loan');
      expect(rows.single.currency, 'eur');
      final details =
          await io(() => db.fireflyAccountDetails(rows.single.walletPk));
      expect(details!.liabilityType, 'loan');
      expect(details.liabilityDirection, 'credit');
      expect(details.interest, 4.2);
      expect(details.interestPeriod, 'monthly');
      expect(details.virtualBalance, isNull);
    });

    widgetTest('mapped liability edits virtual balance and archives',
        (tester) async {
      await wallet('l', kind: AccountKind.liability);
      await map('l');
      await pump(tester, FireflyLiabilitiesPage(db: db, pushNow: () async {}));
      await tester.tap(find.text('Wallet l'));
      await settle(tester);

      await tester.enterText(
          find.byKey(const ValueKey('firefly-account-virtual-balance')), '-50');
      await tester
          .tap(find.byKey(const ValueKey('firefly-liability-archived')));
      await tester.tap(find.byKey(const ValueKey('firefly-liability-save')));
      await settle(tester);

      final row = await io(() => db.fireflyWallet('l'));
      expect(row!.archived, isTrue);
      final details = await io(() => db.fireflyAccountDetails('l'));
      expect(details!.virtualBalance, -50);
    });
  });

  group('net worth', () {
    test('empty eligibility is zero, not every wallet', () async {
      await wallet('a',
          details:
              const AccountDetailsCompanion(includeNetWorth: Value(false)));
      final all = AllWallets(list: const [], indexedByPk: const {});
      final total = await fireflyNetWorthTotal(all, null, db: db).first;
      expect(total!.total, 0);
      expect(total.count, 0);
      final selected = await fireflyNetWorthTotal(all, ['a'], db: db).first;
      expect(selected!.total, 0);
    });
  });

  group('conflict reapply', () {
    test('restores wallet and account details together', () async {
      await wallet('a',
          details: const AccountDetailsCompanion(iban: Value('server')));
      final row = (await db.fireflyWallet('a'))!;
      final local = (await db.fireflyAccountDetails('a'))!
          .copyWith(iban: const Value('local'), notes: const Value('mine'));
      final conflict = await ConflictRepository(db).record(
        type: FireflyEntityType.walletAccount,
        localPk: 'a',
        remoteId: '1',
        local: {
          ...row.copyWith(name: 'Local name').toJson(),
          'homePageWidgetDisplay': null,
          'accountDetails': local.toJson(),
        },
        resolution: 'serverWins',
      );
      expect(jsonDecode(conflict.localJson), contains('accountDetails'));
      expect(await reapplyFireflyConflict(db, conflict), isTrue);
      expect((await db.fireflyWallet('a'))!.name, 'Local name');
      final details = (await db.fireflyAccountDetails('a'))!;
      expect(details.iban, 'local');
      expect(details.notes, 'mine');
    });
  });
}

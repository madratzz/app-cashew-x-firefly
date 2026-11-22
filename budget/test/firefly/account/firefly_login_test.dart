import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/account/firefly_account_tile.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/pages/accountsPage.dart';
import 'package:budget/pages/onBoardingPage.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/platform/capabilities.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_database.dart';

class _MemoryTokens extends TokenStore {
  _MemoryTokens(this.token);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MemoryTokens tokens;

  Future<void> connectAs(String? token, {String url = ''}) async {
    appStateSettings[FireflyConfig.baseUrlKey] = url;
    tokens = _MemoryTokens(token);
    await FireflyMode.init(() => appStateSettings, tokenStore: tokens);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    FireflyAccountTile.clearCache();
    database = inMemoryFinanceDatabase();
    await connectAs(null);
  });

  // Drift stream timers only settle in real async
  tearDown(() async => database.close());

  test('Google sign-in, Drive and Firebase are off on every platform',
      () async {
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(PlatformCapabilities.supportsGoogleSignIn, isFalse);
      expect(PlatformCapabilities.supportsFirebase, isFalse);
      expect(PlatformCapabilities.googleDriveAvailable, isFalse);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('onboarding offers Firefly login and no Google button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OnboardingLoginOptions(nextNavigation: () {}),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('firefly-onboarding-connect'), findsOneWidget);
    expect(find.text('sign-in-with-google'), findsNothing);
    expect(find.text('onboarding-info-3'), findsNothing);
    expect(find.text('continue-without-sign-in'), findsOneWidget);
  });

  testWidgets('settings shows Connect and no Google-only features',
      (tester) async {
    appStateSettings['emailScanning'] = true;
    // Phone width: no side navigation, so the account tile sits in settings
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SettingsPageContent())),
    ));
    await tester.pump();

    expect(find.byType(FireflyAccountTile), findsOneWidget);
    expect(find.text('firefly-account-connect'), findsOneWidget);
    expect(find.text('google-drive'), findsNothing);
    expect(find.text('auto-email-transactions'), findsNothing);
    // Local file backups stay
    expect(find.byType(ExportDB), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('connected tile shows host and email, Disconnect signs out',
      (tester) async {
    await connectAs('REDACTED', url: 'https://firefly.example/');
    Uri? asked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FireflyAccountTile(
          emailLoader: (url) async {
            asked = url;
            return 'user@example.com';
          },
          controller: FireflyConnectionController(
              tokens: tokens, writeSetting: (_, __) async {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(asked?.host, 'firefly.example');
    expect(find.text('firefly.example'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);

    await tester.tap(find.text('firefly-account-disconnect'));
    await tester.pumpAndSettle();
    expect(tokens.token, isNull);
    expect(find.text('firefly-account-connect'), findsOneWidget);
  });

  testWidgets('connected tile works offline without an email', (tester) async {
    await connectAs('REDACTED', url: 'https://firefly.example/');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FireflyAccountTile(
            emailLoader: (_) async => throw Exception('offline')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('firefly.example'), findsOneWidget);
    expect(find.text('firefly-account-email-unknown'), findsOneWidget);
  });

  testWidgets('accounts page is Firefly login plus local backups',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountsPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FireflyAccountTile), findsOneWidget);
    expect(find.byType(ExportDB), findsOneWidget);
    expect(find.text('sign-in-with-google'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

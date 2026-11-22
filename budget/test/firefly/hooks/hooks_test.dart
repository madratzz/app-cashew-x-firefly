import 'dart:io';

import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/slots.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokens extends TokenStore {
  _FakeTokens(this.token);

  final String? token;

  @override
  Future<String?> read() async => token;
}

class _NoNetwork extends HttpOverrides {
  int clients = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    throw StateError('Network is not allowed in hook tests');
  }
}

Future<void> _setMode(bool on) async {
  appStateSettings['fireflyMode'] = on;
  await FireflyMode.init(() => appStateSettings,
      tokenStore: _FakeTokens(on ? 'REDACTED' : null));
}

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: SettingsPageContent()),
    ),
  ));
  await tester.pump();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    appStateSettings['hasSignedIn'] = true;
    appStateSettings['backupSync'] = true;
  });

  tearDown(() => _setMode(false));

  testWidgets('Firefly mode off adds one settings entry and no network',
      (tester) async {
    await _setMode(false);
    final network = _NoNetwork();
    await HttpOverrides.runZoned(() => _pumpSettings(tester),
        createHttpClient: network.createHttpClient);

    expect(FireflyMode.enabled, isFalse);
    expect(find.byType(FireflySettingsEntry), findsOneWidget);
    expect(find.byType(FireflyHubSection), findsOneWidget);
    expect(network.clients, 0);
    await _unmount(tester);
  });

  testWidgets('Firefly mode on hides Google sections and renders slots',
      (tester) async {
    await _setMode(true);
    appStateSettings['emailScanning'] = true;
    await _pumpSettings(tester);

    expect(FireflyMode.enabled, isTrue);
    expect(find.byType(FireflySettingsEntry), findsOneWidget);
    expect(find.byType(FireflyHubSection), findsOneWidget);
    await _unmount(tester);
  });
}

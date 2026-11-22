import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/platform/capabilities.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/logging.dart';
import 'package:budget/struct/settings.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizes a reverse proxy mount and enforces the transport policy',
      () {
    expect(normalizeFireflyUrl(' HTTPS://FIREfly.example/money/api/v1/// '),
        Uri.parse('https://firefly.example/money'));
    expect(normalizeFireflyUrl('https://firefly.example:8443/'),
        Uri.parse('https://firefly.example:8443'));
    expect(normalizeFireflyUrl('https://firefly.example/my%20mount/api'),
        Uri.parse('https://firefly.example/my%20mount'));
    for (final value in [
      'firefly.example',
      'ftp://firefly.example',
      'https://user@firefly.example',
      'https://@firefly.example',
      'https://firefly.example?query',
      'https://firefly.example#fragment',
      'https://firefly.example/a b',
      'http://firefly.example',
      'http://localhost.example',
    ]) {
      expect(() => normalizeFireflyUrl(value), throwsFormatException,
          reason: value);
    }
    for (final host in ['localhost', '127.0.0.1']) {
      final url = 'http://$host:1234';
      if (const bool.fromEnvironment('FIREFLY_ALLOW_HTTP')) {
        expect(normalizeFireflyUrl(url), Uri.parse(url));
      } else {
        expect(() => normalizeFireflyUrl(url), throwsFormatException);
      }
    }
  });

  test('formats split amounts at 0, 2 and 3 decimal places', () {
    expect(formatFireflyAmount(-124.56, 0), '125');
    expect(formatFireflyAmount(-(0.1 + 0.2), 2), '0.30');
    expect(formatFireflyAmount(12.3458, 3), '12.346');
    expect(formatFireflyAmount(-0.0, 2), '0.00');
    expect(formatFireflyAmount(1.5e21, 2), '1500000000000000000000.00');
    expect(parseFireflyAmount('12.340'), 12.34);
    expect(
        () => parseFireflyAmount('NaN'), throwsA(isA<FireflyInvalidPayload>()));
    expect(() => formatFireflyAmount(double.infinity, 2), throwsArgumentError);
  });

  test('writes a local offset and parses remote strings into local time', () {
    final utc = DateTime.utc(2024, 1, 2, 3, 4);
    final local = utc.toLocal();
    final written = formatFireflyDateTime(utc);
    expect(written, formatFireflyDateTime(local));
    expect(written, matches(RegExp(r'[+-]\d\d:\d\d$')));
    expect(DateTime.parse(written).toUtc(), utc);
    final parsed = parseFireflyDateTime('2024-01-02T08:34:00+05:30');
    expect(parsed.isUtc, isFalse);
    expect(parsed.toUtc(), utc);
    expect(formatFireflyDate(DateTime(2024, 1, 2, 3)), '2024-01-02');
  });

  test('writes only to secure storage, excluding preferences, the DB and logs',
      () async {
    const fixture = 'REDACTED';
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('firefly-storage-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/budget.sqlite');
    final db = FinanceDatabase(NativeDatabase(file));
    try {
      await db.select(db.appSettings).get();

      final previousSettings = appStateSettings;
      final previousService = logService;
      appStateSettings = {'logging': true};
      logService = LogService();
      addTearDown(() {
        appStateSettings = previousSettings;
        logService = previousService;
      });

      final completion = Completer<void>();
      captureLogs(() async {
        try {
          final store = TokenStore();
          await store.write(fixture);
          expect(await store.read(), fixture);
          expect(await const FlutterSecureStorage().read(key: TokenStore.key),
              fixture);
          final settings = await SharedPreferences.getInstance();
          expect(settings.getKeys(), isEmpty);
          expect(appStateSettings, {'logging': true});
          expect(await db.select(db.appSettings).get(), isEmpty);
          logFirefly('Secure storage round trip completed');
          expect(logService.exportLogs(), contains('round trip completed'));
          expect(logService.exportLogs(), isNot(contains(fixture)));
          await store.delete();
          expect(await store.read(), isNull);
          completion.complete();
        } catch (error, stackTrace) {
          completion.completeError(error, stackTrace);
        }
      });
      await completion.future;
    } finally {
      await db.close();
    }
    final contents =
        utf8.decode(await file.readAsBytes(), allowMalformed: true);
    expect(contents, startsWith('SQLite format 3'));
    expect(contents, isNot(contains(fixture)));
    expect(contents, isNot(contains(TokenStore.key)));
  });

  test('uses session memory on Linux when libsecret is unavailable', () async {
    final storage = _UnavailableSecureStorage();
    final session = TokenStore(storage: storage, linux: true);
    expect(await session.read(), isNull);
    expect(session.sessionOnly, isTrue);
    await session.write('REDACTED');
    expect(await session.read(), 'REDACTED');
    expect(await TokenStore(storage: storage, linux: true).read(), isNull);
    await session.delete();
    expect(await session.read(), isNull);
    await expectLater(TokenStore(storage: storage, linux: false).read(),
        throwsA(isA<PlatformException>()));
  });

  test('does not read the token on disabled startup and gates Google Drive',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await FireflyMode.init(() => const {}, tokenStore: TokenStore());
    });
    expect(PlatformCapabilities.supportsFirebase, isFalse);
    expect(PlatformCapabilities.supportsCamera, isTrue);

    final settings = <String, Object?>{FireflyConfig.pageSizeKey: 25};
    await FireflyMode.init(() => settings,
        tokenStore:
            TokenStore(storage: _UnavailableSecureStorage(), linux: false));
    expect(FireflyMode.enabled, isFalse);
    expect(PlatformCapabilities.googleDriveAvailable, isFalse);

    FlutterSecureStorage.setMockInitialValues({});
    final tokens = TokenStore();
    settings[FireflyConfig.modeKey] = true;
    await FireflyMode.init(() => settings, tokenStore: tokens);
    expect(FireflyMode.enabled, isFalse);
    await tokens.write('REDACTED');
    await FireflyMode.refreshToken();
    expect(FireflyMode.enabled, isTrue);
    expect(PlatformCapabilities.googleDriveAvailable, isFalse);
    expect(FireflyMode.config.pageSize, 25);
    await tokens.delete();
    await FireflyMode.refreshToken();
    expect(FireflyMode.enabled, isFalse);
  });

  test('redacts Authorization, case-insensitive bearer and known raw tokens',
      () {
    expect(redactFireflyLog('GET failed: Bearer sample-value [401]'),
        'GET failed: Bearer REDACTED [401]');
    expect(redactFireflyLog('headers {"Authorization":"Basic sample-value"}'),
        'headers {"Authorization":REDACTED}');
    expect(redactFireflyLog('Error had sample-value', token: 'sample-value'),
        'Error had REDACTED');
  });

  test('merges the Firefly string into both normal and regional locale assets',
      () async {
    final previous = appStateSettings;
    addTearDown(() => appStateSettings = previous);
    const loader = RootBundleAssetLoaderCustomLocaleLoader();
    for (final code in ['en', 'fr', 'pt_PT', 'zh_Hant']) {
      appStateSettings = {'locale': code};
      final locale = supportedLocales[code]!;
      final path =
          loader.getLocalePath('assets/translations/generated', locale);
      final original =
          jsonDecode(await rootBundle.loadString(path)) as Map<String, Object?>;
      final translations =
          await loader.load('assets/translations/generated', locale);
      for (final e in original.entries) {
        expect(translations[e.key], e.value);
      }
      expect(translations['firefly-title'], 'Firefly III');
    }
  });
}

class _UnavailableSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      throw PlatformException(code: 'Libsecret error');
}

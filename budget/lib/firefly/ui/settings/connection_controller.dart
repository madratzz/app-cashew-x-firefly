import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/about.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:budget/firefly/db/reset_queries.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/struct/databaseGlobal.dart' as global_db;
import 'package:budget/struct/syncClient.dart';
import 'package:flutter/foundation.dart';

typedef FireflyTransportFactory = FireflyTransport Function(
    Uri baseUrl, Future<String?> Function() readToken);
typedef FireflySettingWriter = Future<void> Function(String key, Object value);

FireflyTransport _httpTransport(
        Uri baseUrl, Future<String?> Function() readToken) =>
    HttpFireflyTransport(baseUrl: baseUrl, readToken: readToken);

/// Translation keys for URL problems, or null when the URL is usable.
String? fireflyUrlError(String input) {
  if (input.trim().isEmpty) return 'firefly-connection-url-required';
  try {
    normalizeFireflyUrl(input);
    return null;
  } on FormatException {
    final scheme = Uri.tryParse(input.trim())?.scheme.toLowerCase();
    return scheme == 'http'
        ? 'firefly-connection-url-https'
        : 'firefly-connection-url-invalid';
  }
}

/// Translation key describing a failed request.
String fireflyErrorKey(Object error) => switch (error) {
      FireflyUnauthorized() => 'firefly-connection-error-auth',
      FireflyNetworkError() ||
      FireflyTimeout() =>
        'firefly-connection-error-network',
      FireflyNotFound() => 'firefly-connection-error-not-found',
      FireflyTransportUnavailable() => 'firefly-connection-error-unavailable',
      _ => 'firefly-connection-error-generic',
    };

class FireflyConnectionResult {
  const FireflyConnectionResult.success(
      FireflyAbout this.about, FireflyUser this.user)
      : errorKey = null;
  const FireflyConnectionResult.failure(String this.errorKey)
      : about = null,
        user = null;

  final FireflyAbout? about;
  final FireflyUser? user;
  final String? errorKey;
  bool get ok => errorKey == null;
}

/// Connection logic behind the settings page, kept free of widgets.
class FireflyConnectionController {
  FireflyConnectionController({
    required this.writeSetting,
    TokenStore? tokens,
    this.transportFactory = _httpTransport,
  }) : tokens = tokens ?? FireflyMode.tokens;

  final TokenStore tokens;
  final FireflyTransportFactory transportFactory;
  final FireflySettingWriter writeSetting;

  /// Checks the server and the token without saving anything.
  Future<FireflyConnectionResult> test(String url, String token) async {
    final urlError = fireflyUrlError(url);
    if (urlError != null) return FireflyConnectionResult.failure(urlError);
    if (token.trim().isEmpty) {
      return const FireflyConnectionResult.failure(
          'firefly-connection-token-required');
    }
    final transport =
        transportFactory(normalizeFireflyUrl(url), () async => token.trim());
    try {
      final api = FireflyApi(transport);
      final about = await api.about.get();
      final user = await api.about.getUser();
      return FireflyConnectionResult.success(about, user);
    } catch (error) {
      logFirefly('Firefly connection test failed: $error', token: token);
      return FireflyConnectionResult.failure(fireflyErrorKey(error));
    } finally {
      if (transport is HttpFireflyTransport) transport.close();
    }
  }

  /// Saves the URL and token only after a successful test.
  Future<FireflyConnectionResult> connect(String url, String token) async {
    final result = await test(url, token);
    if (!result.ok) return result;
    await tokens.write(token.trim());
    await writeSetting(
        FireflyConfig.baseUrlKey, normalizeFireflyUrl(url).toString());
    await FireflyMode.refreshToken();
    FireflySync.reset();
    return result;
  }

  Future<void> setMode(bool enabled) async {
    await writeSetting(FireflyConfig.modeKey, enabled);
    FireflySync.reset();
  }

  /// Removes the token only. Local data, map tables and settings stay.
  Future<void> signOut() async {
    await tokens.delete();
    await FireflyMode.refreshToken();
    FireflySync.reset();
  }
}

/// Section 5.7 "replace local with server": back up, then clear.
class FireflyReplaceFlow {
  FireflyReplaceFlow({
    required this.db,
    required this.backupDirectory,
    this.beforeBackup,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final FinanceDatabase db;
  final Future<Directory> Function() backupDirectory;
  final Future<void> Function()? beforeBackup;
  final DateTime Function() now;

  /// Returns the backup file. Nothing is cleared if the backup fails.
  Future<File> run() async {
    await beforeBackup?.call();
    final directory = await backupDirectory();
    await directory.create(recursive: true);
    final stamp = now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
    final file = File('${directory.path}/cashew-before-firefly-$stamp.sql');
    if (await file.exists()) await file.delete();
    await db.customStatement('VACUUM INTO ?', [file.path]);
    if (!await file.exists() || await file.length() == 0) {
      throw const FileSystemException('Backup was not written');
    }
    await db.clearFireflyFinanceData();
    return file;
  }

  /// True when this database has never completed a Firefly sync.
  static Future<bool> isFirstConnection(FinanceDatabase db) async =>
      await SyncMetaRepository(db).read(SyncMetaRepository.lastSync) == null;
}

/// Bridges the status UI to the app-wide scheduler in `syncClient.dart`.
class FireflySync {
  FireflySync._();

  static FinanceDatabase Function() db = () => global_db.database;

  /// Resolves the shared scheduler; tests replace it.
  static Future<SyncScheduler?> Function() resolve = fireflySchedulerIfEnabled;

  static SyncScheduler? scheduler;
  static final lastReport = ValueNotifier<SyncReport?>(null);
  static final running = ValueNotifier<bool>(false);

  static Future<SyncReport?> syncNow({bool fullResync = false}) async {
    if (running.value) return null;
    running.value = true;
    try {
      final current = scheduler = await resolve();
      if (current == null) return null;
      final report = await current.syncNow(fullResync: fullResync);
      lastReport.value = report;
      return report;
    } finally {
      running.value = false;
    }
  }

  /// Picks up the scheduler's last report, e.g. from an automatic sync.
  static Future<void> refresh() async {
    final current = scheduler = await resolve();
    final report = current?.lastReport;
    if (report != null) lastReport.value = report;
  }

  /// The shared scheduler rebuilds itself when settings change.
  static void reset() => scheduler = null;
}

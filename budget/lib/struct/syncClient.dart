import 'dart:async';
import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/bootstrap_upload.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/struct/databaseGlobal.dart';

class SyncLog {
  SyncLog({
    this.deleteLogType,
    this.updateLogType,
    required this.transactionDateTime,
    required this.pk,
    this.itemToUpdate,
  });

  DeleteLogType? deleteLogType;
  UpdateLogType? updateLogType;
  DateTime? transactionDateTime;
  String pk;
  dynamic itemToUpdate;

  @override
  String toString() {
    return "SyncLog(deleteLogType: $deleteLogType, updateLogType: $updateLogType, transactionDateTime: $transactionDateTime, pk: $pk, itemToUpdate: $itemToUpdate)";
  }
}

// Firefly mode replaces Drive sync with the Firefly sync engine
SyncScheduler? fireflyScheduler;
String? _fireflySchedulerConfig;

// Recreates the scheduler when the connection settings change.
// Timers start only from startFireflyScheduler, never from a requested sync
Future<SyncScheduler?> fireflySchedulerIfEnabled() async {
  final FireflyConfig config = FireflyMode.config;
  final String configKey = [
    config.baseUrl,
    config.syncOnChange,
    config.applyRules,
    config.fireWebhooks,
    config.transactionWindowDays,
    config.pageSize,
    config.subcategorySeparator,
    config.metaRoaming,
  ].join("|");
  if (fireflyScheduler != null &&
      (!FireflyMode.enabled || configKey != _fireflySchedulerConfig)) {
    final SyncScheduler oldScheduler = fireflyScheduler!;
    fireflyScheduler = null;
    _fireflySchedulerConfig = null;
    oldScheduler.engine.cancel();
    oldScheduler.dispose();
    await oldScheduler.engine.dispose();
  }
  if (!FireflyMode.enabled) return null;
  if (fireflyScheduler == null) {
    _fireflySchedulerConfig = configKey;
    fireflyScheduler = SyncScheduler(SyncEngine(SyncContext(
      db: database,
      api: FireflyApi(FireflyPostUploadTransport(
        baseUrl: normalizeFireflyUrl(config.baseUrl),
        readToken: FireflyMode.tokens.read,
      )),
      config: config,
    )));
    final SyncScheduler scheduler = fireflyScheduler!;
    // Ignore late Drift watcher events caused by the cycle's own writes
    scheduler.engine.progress
        .where((progress) => progress.phase == SyncPhase.complete)
        .listen((_) => scheduler.suppressLocalWrites(const Duration(seconds: 2)));
  }
  return fireflyScheduler;
}

// Foreground lifecycle entry: app load and resume
Future<void> startFireflyScheduler() async {
  (await fireflySchedulerIfEnabled())?.start();
}

Future<bool> runFireflySync({bool fullResync = false}) async {
  final SyncScheduler? scheduler = await fireflySchedulerIfEnabled();
  if (scheduler == null) return false;
  final SyncReport report = await scheduler.syncNow(fullResync: fullResync);
  return report.succeeded;
}

// Database writes made by a running sync cycle are not local edits
void fireflyLocalWrite() {
  final SyncScheduler? scheduler = fireflyScheduler;
  if (scheduler == null || scheduler.engine.isRunning) return;
  scheduler.localWrite();
}

// Stops a running Firefly sync before the database is replaced
Future<void> cancelAndPreventSyncOperation() async {
  fireflyScheduler?.engine.cancel();
}

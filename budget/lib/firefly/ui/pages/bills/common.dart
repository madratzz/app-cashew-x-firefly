import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns the running scheduler's context, or null with Firefly mode off.
typedef FireflySyncContextProvider = Future<SyncContext?> Function();

/// Runs one sync cycle after an edit so server validation is shown at once.
typedef FireflyPushNow = Future<void> Function();

Future<SyncContext?> defaultFireflySyncContext() async =>
    (await fireflySchedulerIfEnabled())?.engine.context;

Future<void> defaultFireflyPushNow() async {
  await runFireflySync();
}

FinanceDatabase fireflyBillsDb(FinanceDatabase? db) => db ?? database;

String fireflyDay(DateTime date) => DateFormat.yMMMd().format(date);

String fireflyWireDay(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// The server's last rejection of this row, kept until the next accepted push.
Future<String?> fireflyRejection(
    FinanceDatabase db, FireflyEntityType type, String pk) async {
  final mapping = await IdMapRepository(db).byLocal(type, pk);
  if (mapping?.state != FireflySyncState.error) return null;
  return mapping?.lastError ?? '';
}

/// Legacy auto-creation of the next occurrence is off for rows that came
/// from, or were pushed to, Firefly: the server owns their schedule.
Future<bool> fireflyOwnsSchedule(FinanceDatabase db, Transaction row) async {
  if (!FireflyMode.enabled) return false;
  return await IdMapRepository(db)
          .byLocal(FireflyEntityType.transaction, row.transactionPk) !=
      null;
}

class FireflyErrorBanner extends StatelessWidget {
  const FireflyErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}

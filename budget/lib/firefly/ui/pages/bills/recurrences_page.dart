import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/entities/recurrence_syncer.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/pages/bills/recurrence_editor_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

FireflyRecurrence fireflyRecurrenceFromRow(FireflyCachedResource row) =>
    FireflyRecurrence(
        id: row.resourcePk, attributes: ResourceCacheRepository.decode(row));

/// Asks the server to create the next occurrence now and imports it.
Future<void> fireflyCreateRecurrenceNow(
  BuildContext context,
  String pk, {
  FireflySyncContextProvider? syncContext,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  String message;
  try {
    final sync = await (syncContext ?? defaultFireflySyncContext)();
    final created =
        sync == null ? null : await const RecurrenceSyncer().trigger(sync, pk);
    message = (created == null
            ? 'firefly-recurrences-create-none'
            : 'firefly-recurrences-created')
        .tr();
  } catch (_) {
    message = 'firefly-recurrences-create-failed'.tr();
  }
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

class FireflyRecurrencesPage extends StatelessWidget {
  const FireflyRecurrencesPage(
      {super.key, this.db, this.syncContext, this.pushNow, this.now});

  final FinanceDatabase? db;
  final FireflySyncContextProvider? syncContext;
  final FireflyPushNow? pushNow;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final database = fireflyBillsDb(db);
    return Scaffold(
      appBar: AppBar(title: Text('firefly-recurrences-title'.tr())),
      body: StreamBuilder<List<FireflyCachedResource>>(
        stream: database.watchFireflyRecurrences(),
        builder: (context, snapshot) {
          final items = [...?snapshot.data?.map(fireflyRecurrenceFromRow)]
            ..sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
          if (items.isEmpty) {
            return Center(child: Text('firefly-recurrences-empty'.tr()));
          }
          final today = (now ?? DateTime.now)();
          return ListView(
            children: [
              for (final item in items)
                ListTile(
                  key: ValueKey('firefly-recurrence-${item.id}'),
                  title: Text(item.title ?? ''),
                  subtitle: Text(_subtitle(item, today)),
                  enabled: item.active != false,
                  trailing: IconButton(
                    key: ValueKey('firefly-recurrence-now-${item.id}'),
                    tooltip: 'firefly-recurrences-create-now'.tr(),
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: item.active == false
                        ? null
                        : () => fireflyCreateRecurrenceNow(context, item.id,
                            syncContext: syncContext),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FireflyRecurrenceEditorPage(
                        db: database,
                        recurrence: item,
                        pushNow: pushNow,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _subtitle(FireflyRecurrence item, DateTime today) {
    if (item.active == false) return 'firefly-recurrences-inactive'.tr();
    final next = item.nextOccurrence(from: today);
    return next == null
        ? 'firefly-recurrences-no-next'.tr()
        : 'firefly-recurrences-next'.tr(namedArgs: {'date': fireflyDay(next)});
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/pages/bills/recurrences_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Upcoming entries derived from server recurrence occurrences. Firefly
/// creates these transactions itself, so nothing is written locally.
class FireflyUpcomingRecurrences extends StatelessWidget {
  const FireflyUpcomingRecurrences(
      {super.key, this.db, this.now, this.syncContext, this.limit = 20});

  final FinanceDatabase? db;
  final DateTime Function()? now;
  final FireflySyncContextProvider? syncContext;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FireflyCachedResource>>(
      stream: fireflyBillsDb(db).watchFireflyRecurrences(),
      builder: (context, snapshot) {
        final today = (now ?? DateTime.now)();
        final entries = [
          for (final item in (snapshot.data ?? const <FireflyCachedResource>[])
              .map(fireflyRecurrenceFromRow))
            for (final date in item.upcomingOccurrences(from: today))
              (item: item, date: date),
        ]..sort((a, b) => a.date.compareTo(b.date));
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('firefly-recurrences-upcoming'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final entry in entries.take(limit))
              ListTile(
                key: ValueKey(
                    'firefly-upcoming-${entry.item.id}-${fireflyWireDay(entry.date)}'),
                leading: const Icon(Icons.event_repeat_rounded),
                title: Text(entry.item.title ?? ''),
                subtitle: Text(fireflyDay(entry.date)),
                trailing: IconButton(
                  tooltip: 'firefly-recurrences-create-now'.tr(),
                  icon: const Icon(Icons.playlist_add_rounded),
                  onPressed: () => fireflyCreateRecurrenceNow(
                      context, entry.item.id,
                      syncContext: syncContext),
                ),
              ),
          ],
        );
      },
    );
  }
}

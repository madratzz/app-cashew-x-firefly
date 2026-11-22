import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Server history of a goal's piggy bank, newest first.
class FireflyPiggyBankEventsPage extends StatelessWidget {
  const FireflyPiggyBankEventsPage(
      {required this.db, required this.objective, super.key});

  final FinanceDatabase db;
  final Objective objective;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("firefly-piggy-history".tr())),
      body: FutureBuilder<List<FireflyPiggyBankEvent>>(
        future: db.fireflyPiggyBankEvents(objective.objectivePk),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = [...snapshot.data!]..sort((a, b) {
              final aDate = a.createdAt, bDate = b.createdAt;
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            });
          if (events.isEmpty) {
            return Center(child: Text("firefly-piggy-no-history".tr()));
          }
          return ListView(
            children: [
              for (final event in events)
                ListTile(
                  leading: Icon((event.amount ?? 0) < 0
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded),
                  title: Text(_amount(event.amount ?? 0)),
                  subtitle: Text([
                    if (event.createdAt != null)
                      DateFormat.yMMMd(
                              Localizations.localeOf(context).toString())
                          .format(event.createdAt!.toLocal()),
                    if (event.journalId != null)
                      "firefly-piggy-linked-transaction".tr(),
                  ].join(' · ')),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _amount(double amount) =>
    '${amount < 0 ? '−' : '+'}${amount.abs().toStringAsFixed(2)}';

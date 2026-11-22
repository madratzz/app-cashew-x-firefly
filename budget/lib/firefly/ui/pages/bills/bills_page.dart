import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/ui/pages/bills/bill_editor_page.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

FireflyBill fireflyBillFromRow(FireflyCachedResource row) => FireflyBill(
    id: row.resourcePk, attributes: ResourceCacheRepository.decode(row));

String fireflyBillAmount(FireflyBill bill) {
  final code = bill.currencyCode ?? '';
  final min = bill.amountMin?.toStringAsFixed(2) ?? '';
  final max = bill.amountMax?.toStringAsFixed(2) ?? '';
  final range = min == max || max.isEmpty ? min : '$min – $max';
  return '$range $code'.trim();
}

/// Replaces the legacy subscriptions list in Firefly mode.
class FireflyBillsPage extends StatelessWidget {
  const FireflyBillsPage({super.key, this.db, this.pushNow});

  final FinanceDatabase? db;
  final FireflyPushNow? pushNow;

  @override
  Widget build(BuildContext context) {
    final database = fireflyBillsDb(db);
    return Scaffold(
      appBar: AppBar(title: Text('firefly-bills-title'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('firefly-bill-add'),
        tooltip: 'firefly-bills-add'.tr(),
        onPressed: () => _open(context, database, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<FireflyCachedResource>>(
        stream: database.watchFireflyBills(),
        builder: (context, snapshot) {
          final bills = [...?snapshot.data?.map(fireflyBillFromRow)]
            ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          if (bills.isEmpty) {
            return Center(child: Text('firefly-bills-empty'.tr()));
          }
          return ListView(
            children: [
              for (final bill in bills)
                ListTile(
                  key: ValueKey('firefly-bill-${bill.id}'),
                  title: Text(bill.name ?? ''),
                  subtitle: Text(_subtitle(bill)),
                  trailing: Text(fireflyBillAmount(bill)),
                  enabled: bill.active != false,
                  onTap: () => _open(context, database, bill),
                ),
            ],
          );
        },
      ),
    );
  }

  String _subtitle(FireflyBill bill) {
    final paid = [...bill.paidDates]..sort();
    final expected = bill.nextExpectedMatch ??
        (bill.payDates.isEmpty ? null : bill.payDates.first);
    return [
      if (bill.active == false) 'firefly-bills-inactive'.tr(),
      if (expected != null)
        'firefly-bills-expected'.tr(namedArgs: {'date': fireflyDay(expected)}),
      if (paid.isNotEmpty)
        'firefly-bills-paid'.tr(namedArgs: {'date': fireflyDay(paid.last)}),
      if (paid.isEmpty && expected == null) 'firefly-bills-no-dates'.tr(),
    ].join(' · ');
  }

  void _open(
          BuildContext context, FinanceDatabase database, FireflyBill? bill) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            FireflyBillEditorPage(db: database, bill: bill, pushNow: pushNow),
      ));
}

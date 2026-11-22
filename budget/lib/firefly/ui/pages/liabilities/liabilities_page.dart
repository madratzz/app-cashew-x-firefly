import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/pages/liabilities/liability_editor_page.dart';
import 'package:budget/struct/databaseGlobal.dart' as global;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Firefly loans, debts and mortgages. Archived ones are listed apart.
class FireflyLiabilitiesPage extends StatelessWidget {
  const FireflyLiabilitiesPage({super.key, this.db, this.pushNow});

  final FinanceDatabase? db;
  final FireflyPushNow? pushNow;

  @override
  Widget build(BuildContext context) {
    final database = db ?? global.database;
    return Scaffold(
      appBar: AppBar(title: Text('firefly-liabilities-title'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('firefly-liability-add'),
        tooltip: 'firefly-liabilities-add'.tr(),
        onPressed: () => _open(context, database, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<TransactionWallet>>(
        stream: database.watchFireflyLiabilities(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <TransactionWallet>[];
          if (all.isEmpty) {
            return Center(child: Text('firefly-liabilities-empty'.tr()));
          }
          final active = all.where((w) => !w.archived).toList();
          final archived = all.where((w) => w.archived).toList();
          return ListView(
            children: [
              for (final wallet in active) _tile(context, database, wallet),
              if (archived.isNotEmpty)
                ListTile(
                  key: const ValueKey('firefly-liabilities-archived'),
                  title: Text('firefly-liabilities-archived'.tr(),
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              for (final wallet in archived) _tile(context, database, wallet),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, FinanceDatabase database,
          TransactionWallet w) =>
      StreamBuilder<AccountDetail?>(
        key: ValueKey('firefly-liability-${w.walletPk}'),
        stream: database.watchFireflyAccountDetails(w.walletPk),
        builder: (context, snapshot) {
          final details = snapshot.data;
          return ListTile(
            title: Text(w.name),
            subtitle: Text([
              fireflyLiabilityTypeLabel(details?.liabilityType),
              if (details?.interest != null)
                'firefly-liabilities-interest-summary'.tr(namedArgs: {
                  'rate': details!.interest!.toString(),
                  'period': fireflyLiabilityPeriodLabel(details.interestPeriod),
                }),
            ].where((part) => part.isNotEmpty).join(' · ')),
            trailing: details?.serverBalance == null
                ? null
                : Text('${details!.serverBalance!.toStringAsFixed(w.decimals)} '
                    '${(w.currency ?? '').toUpperCase()}'),
            enabled: !w.archived,
            onTap: () => _open(context, database, w),
          );
        },
      );

  void _open(BuildContext context, FinanceDatabase database,
          TransactionWallet? wallet) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FireflyLiabilityEditorPage(
            db: database, wallet: wallet, pushNow: pushNow),
      ));
}

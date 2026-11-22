import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/pages/payees/common.dart';
import 'package:budget/firefly/ui/pages/payees/payee_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Firefly expense and revenue accounts.
class FireflyPayeesPage extends StatefulWidget {
  const FireflyPayeesPage({super.key, this.db, this.onWrite});

  final FinanceDatabase? db;
  final FireflyPayeeWriteNotifier? onWrite;

  @override
  State<FireflyPayeesPage> createState() => _FireflyPayeesPageState();
}

class _FireflyPayeesPageState extends State<FireflyPayeesPage> {
  late final FinanceDatabase _db = fireflyPayeesDb(widget.db);
  String _search = '';
  PayeeKind? _kind;
  late Stream<List<Payee>> _payees = _watch();

  Stream<List<Payee>> _watch() =>
      _db.watchFireflyPayees(search: _search, kind: _kind);

  void _refilter(void Function() change) => setState(() {
        change();
        _payees = _watch();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('firefly-payees-title'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('firefly-payee-add'),
        tooltip: 'firefly-payees-add'.tr(),
        onPressed: () => _open(null),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const ValueKey('firefly-payees-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                labelText: 'firefly-payees-search'.tr(),
              ),
              onChanged: (value) => _refilter(() => _search = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final kind in [null, ...PayeeKind.values])
                  ChoiceChip(
                    key: ValueKey('firefly-payees-filter-${kind?.name}'),
                    label: Text(kind == null
                        ? 'firefly-payees-kind-all'.tr()
                        : fireflyPayeeKindKey(kind).tr()),
                    selected: _kind == kind,
                    onSelected: (_) => _refilter(() => _kind = kind),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Payee>>(
              stream: _payees,
              builder: (context, snapshot) {
                final payees = snapshot.data ?? const <Payee>[];
                if (payees.isEmpty) {
                  return Center(child: Text('firefly-payees-empty'.tr()));
                }
                return ListView(
                  children: [
                    for (final payee in payees)
                      ListTile(
                        key: ValueKey('firefly-payee-${payee.payeePk}'),
                        leading: Icon(payee.kind == PayeeKind.expense
                            ? Icons.storefront_rounded
                            : Icons.payments_rounded),
                        title: Text(payee.name),
                        subtitle: Text([
                          fireflyPayeeKindKey(payee.kind).tr(),
                          if (!payee.active) 'firefly-payees-inactive'.tr(),
                        ].join(' · ')),
                        onTap: () => _open(payee),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _open(Payee? payee) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            FireflyPayeePage(db: _db, payee: payee, onWrite: widget.onWrite),
      ));
}

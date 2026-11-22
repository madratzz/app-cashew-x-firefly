import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/available_budget.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String _day(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _amount(double amount, String? currency) =>
    '${amount.toStringAsFixed(2)}${currency == null ? '' : ' ${currency.toUpperCase()}'}';

/// Firefly budget limits of one envelope, one row per period, and the
/// read-only available budgets reported by the server.
class FireflyBudgetLimitsPage extends StatelessWidget {
  const FireflyBudgetLimitsPage(
      {super.key, this.budgetPk, this.db, this.onLocalWrite});

  final String? budgetPk;
  final FinanceDatabase? db;

  /// Limits are not watched by the auto-sync trigger; tests replace this.
  final void Function()? onLocalWrite;

  @override
  Widget build(BuildContext context) {
    final database = db ?? FireflySync.db();
    final pk = budgetPk;
    return Scaffold(
      appBar: AppBar(title: Text('firefly-budgets-limits-title'.tr())),
      floatingActionButton: pk == null
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('firefly-limit-add'),
              onPressed: () => _edit(context, database, pk, null),
              icon: const Icon(Icons.add_rounded),
              label: Text('firefly-budgets-limit-add'.tr()),
            ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fireflyPageMaxWidth),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              FireflyAvailableBudgets(db: database),
              const Divider(),
              if (pk != null)
                StreamBuilder<List<BudgetLimit>>(
                  stream: database.watchFireflyBudgetLimits(pk),
                  builder: (context, snapshot) {
                    final limits = snapshot.data ?? const <BudgetLimit>[];
                    if (limits.isEmpty) {
                      return ListTile(
                          title: Text('firefly-budgets-limits-empty'.tr()));
                    }
                    return Column(children: [
                      for (final limit in limits)
                        ListTile(
                          key: ValueKey('firefly-limit-${limit.budgetLimitPk}'),
                          title: Text(_amount(limit.amount, limit.currency)),
                          subtitle:
                              Text('${_day(limit.start)} – ${_day(limit.end)}'),
                          onTap: () => _edit(context, database, pk, limit),
                          trailing: IconButton(
                            key: ValueKey(
                                'firefly-limit-delete-${limit.budgetLimitPk}'),
                            tooltip: 'firefly-budgets-limit-delete'.tr(),
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              await database.fireflyDeleteBudgetLimit(
                                  limit.budgetLimitPk);
                              (onLocalWrite ?? fireflyLocalWrite)();
                            },
                          ),
                        ),
                    ]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, FinanceDatabase database,
      String budgetPk, BudgetLimit? limit) async {
    final currency =
        limit?.currency ?? await _budgetCurrency(database, budgetPk);
    if (!context.mounted) return;
    final saved = await showDialog<BudgetLimitsCompanion>(
      context: context,
      builder: (_) => FireflyBudgetLimitDialog(limit: limit),
    );
    if (saved == null) return;
    await database.fireflySaveBudgetLimit(saved.copyWith(
      budgetLimitPk:
          limit == null ? const Value.absent() : Value(limit.budgetLimitPk),
      budgetFk: Value(budgetPk),
      currency: Value(currency),
    ));
    (onLocalWrite ?? fireflyLocalWrite)();
  }

  static Future<String> _budgetCurrency(
      FinanceDatabase database, String budgetPk) async {
    final budget = await database.fireflyBudget(budgetPk);
    final walletPk = budget?.walletFk;
    final wallet = walletPk == null
        ? null
        : await (database.select(database.wallets)
              ..where((row) => row.walletPk.equals(walletPk)))
            .getSingleOrNull();
    return wallet?.currency ?? 'usd';
  }
}

/// Amount and period of one limit. Pops a companion without keys.
class FireflyBudgetLimitDialog extends StatefulWidget {
  const FireflyBudgetLimitDialog({super.key, this.limit, this.now});

  final BudgetLimit? limit;
  final DateTime? now;

  @override
  State<FireflyBudgetLimitDialog> createState() =>
      _FireflyBudgetLimitDialogState();
}

class _FireflyBudgetLimitDialogState extends State<FireflyBudgetLimitDialog> {
  late final TextEditingController _amount = TextEditingController(
      text: widget.limit?.amount.toStringAsFixed(2) ?? '');
  late DateTime _start;
  late DateTime _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _start = widget.limit?.start ?? DateTime(now.year, now.month);
    _end = widget.limit?.end ?? DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'firefly-budgets-limit-invalid-amount');
    } else if (_end.isBefore(_start)) {
      setState(() => _error = 'firefly-budgets-limit-invalid-range');
    } else {
      Navigator.of(context).pop(BudgetLimitsCompanion(
        start: Value(_start),
        end: Value(_end),
        amount: Value(amount),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text((widget.limit == null
              ? 'firefly-budgets-limit-add'
              : 'firefly-budgets-limit-edit')
          .tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('firefly-limit-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'firefly-budgets-limit-amount'.tr(),
              errorText: _error?.tr(),
            ),
          ),
          ListTile(
            key: const ValueKey('firefly-limit-start'),
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-budgets-limit-start'.tr()),
            trailing: Text(_day(_start)),
            onTap: () => _pick(true),
          ),
          ListTile(
            key: const ValueKey('firefly-limit-end'),
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-budgets-limit-end'.tr()),
            trailing: Text(_day(_end)),
            onTap: () => _pick(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('firefly-budgets-limit-cancel'.tr()),
        ),
        FilledButton(
          key: const ValueKey('firefly-limit-save'),
          onPressed: _save,
          child: Text('firefly-budgets-limit-save'.tr()),
        ),
      ],
    );
  }
}

/// Read-only list of the server's available budgets.
class FireflyAvailableBudgets extends StatelessWidget {
  const FireflyAvailableBudgets({super.key, this.db});

  final FinanceDatabase? db;

  @override
  Widget build(BuildContext context) {
    final database = db ?? FireflySync.db();
    return StreamBuilder<List<FireflyAvailableBudget>>(
      stream: database.watchFireflyAvailableBudgets(),
      builder: (context, snapshot) {
        final items = [...?snapshot.data]
          ..sort((a, b) => b.start.compareTo(a.start));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('firefly-budgets-available-title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text('firefly-budgets-available-readonly'.tr()),
            ),
            if (items.isEmpty)
              ListTile(title: Text('firefly-budgets-available-empty'.tr())),
            for (final item in items)
              ListTile(
                key: ValueKey('firefly-available-${item.id}'),
                dense: true,
                title: Text(_amount(item.amount, item.currencyCode)),
                subtitle: Text('${_day(item.start)} – ${_day(item.end)}'),
              ),
          ],
        );
      },
    );
  }
}

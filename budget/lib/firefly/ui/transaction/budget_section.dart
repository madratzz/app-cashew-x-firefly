import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyBudgetSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyBudgetPicker(draft: draft);

/// Picks the Firefly envelope a withdrawal belongs to.
class FireflyBudgetPicker extends StatefulWidget {
  const FireflyBudgetPicker({super.key, required this.draft});

  final FireflyTransactionDraft draft;

  @override
  State<FireflyBudgetPicker> createState() => _FireflyBudgetPickerState();
}

class _FireflyBudgetPickerState extends State<FireflyBudgetPicker> {
  late final Stream<List<Budget>> _envelopes = (widget.draft.db
          .select(widget.draft.db.budgets)
        ..where((row) =>
            row.addedTransactionsOnly.equals(true) & row.archived.equals(false))
        ..orderBy([(row) => OrderingTerm.asc(row.order)]))
      .watch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: _envelopes,
      builder: (context, snapshot) {
        final envelopes = snapshot.data ?? const <Budget>[];
        final selected = widget.draft.budgetPk;
        final known = envelopes.any((budget) => budget.budgetPk == selected);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: DropdownButtonFormField<String?>(
            key: const ValueKey('firefly-budget-picker'),
            value: known ? selected : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'firefly-budgets-picker'.tr(),
              helperText: 'firefly-budgets-picker-hint'.tr(),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('firefly-budgets-picker-none'.tr()),
              ),
              for (final budget in envelopes)
                DropdownMenuItem<String?>(
                  value: budget.budgetPk,
                  child: Text(budget.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() => widget.draft.budgetPk = value),
          ),
        );
      },
    );
  }
}

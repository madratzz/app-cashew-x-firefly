import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/piggy_bank_syncer.dart';
import 'package:budget/firefly/ui/pages/piggy_banks/piggy_bank_events_page.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Goals are Firefly piggy banks; loans stay out of sync.
bool fireflyPiggyMode(Objective objective) =>
    FireflyMode.enabled && objective.type == ObjectiveType.goal;

bool fireflyHidesLoanCreation(ObjectiveType type) =>
    FireflyMode.enabled && type == ObjectiveType.loan;

/// Context for online piggy bank writes. Tests replace it.
Future<SyncContext?> Function() fireflyPiggySyncContext =
    () async => (await fireflySchedulerIfEnabled())?.engine.context;

/// Server amount, re-read whenever the cache or id map changes.
Stream<double?> watchFireflyPiggyBankCurrentAmount(
    FinanceDatabase db, String objectivePk) async* {
  yield await db.fireflyPiggyBankCurrentAmount(objectivePk);
  await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables(
      [db.fireflyResourceCache, db.fireflyIdMap]))) {
    yield await db.fireflyPiggyBankCurrentAmount(objectivePk);
  }
}

/// Asks for an amount and sets the new server total. Returns true on success.
Future<bool> showFireflyPiggyMoneyDialog(
    BuildContext context, FinanceDatabase db, Objective objective,
    {required bool add}) async {
  final entered = await showDialog<double>(
    context: context,
    builder: (context) => _MoneyDialog(add: add),
  );
  if (entered == null || entered <= 0 || !context.mounted) return false;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final current = await db.fireflyPiggyBankCurrentAmount(objective.objectivePk);
  final syncContext = await fireflyPiggySyncContext();
  if (current == null || syncContext == null) {
    messenger?.showSnackBar(
        SnackBar(content: Text("firefly-piggy-not-synced".tr())));
    return false;
  }
  final total = add ? current + entered : current - entered;
  try {
    await setFireflyPiggyBankAmount(
        syncContext, objective.objectivePk, total < 0 ? 0 : total);
    return true;
  } catch (_) {
    messenger?.showSnackBar(
        SnackBar(content: Text("firefly-piggy-update-failed".tr())));
    return false;
  }
}

class _MoneyDialog extends StatefulWidget {
  const _MoneyDialog({required this.add});

  final bool add;

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context)
      .pop(double.tryParse(_controller.text.replaceAll(',', '.').trim()));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.add
          ? "firefly-piggy-add-money".tr()
          : "firefly-piggy-remove-money".tr()),
      content: TextField(
        key: const ValueKey('firefly-piggy-amount'),
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: "firefly-piggy-amount".tr()),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("firefly-piggy-cancel".tr()),
        ),
        TextButton(onPressed: _submit, child: Text("firefly-piggy-save".tr())),
      ],
    );
  }
}

/// Add, remove and history buttons shown on a synced goal.
class FireflyPiggyBankActions extends StatelessWidget {
  const FireflyPiggyBankActions(
      {required this.db, required this.objective, super.key});

  final FinanceDatabase db;
  final Objective objective;

  @override
  Widget build(BuildContext context) {
    if (!fireflyPiggyMode(objective)) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text("firefly-piggy-add-money".tr()),
          onPressed: () =>
              showFireflyPiggyMoneyDialog(context, db, objective, add: true),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.remove_rounded),
          label: Text("firefly-piggy-remove-money".tr()),
          onPressed: () =>
              showFireflyPiggyMoneyDialog(context, db, objective, add: false),
        ),
        TextButton.icon(
          icon: const Icon(Icons.history_rounded),
          label: Text("firefly-piggy-history".tr()),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) =>
                FireflyPiggyBankEventsPage(db: db, objective: objective),
          )),
        ),
      ],
    );
  }
}

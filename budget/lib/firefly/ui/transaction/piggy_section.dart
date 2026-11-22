import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyPiggySection(
        BuildContext context, FireflyTransactionDraft draft) =>
    _PiggySection(draft: draft);

/// Firefly takes a piggy bank only on new transfers, so the hint says so.
class _PiggySection extends StatefulWidget {
  const _PiggySection({required this.draft});

  final FireflyTransactionDraft draft;

  @override
  State<_PiggySection> createState() => _PiggySectionState();
}

class _PiggySectionState extends State<_PiggySection> {
  late final Future<List<Objective>> _goals = _syncedGoals();

  Future<List<Objective>> _syncedGoals() async {
    final db = widget.draft.db;
    return [
      for (final goal in await db.fireflyGoals())
        if (!goal.archived &&
            await db.fireflyPiggyBankMapping(goal.objectivePk) != null)
          goal,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Objective>>(
      future: _goals,
      builder: (context, snapshot) {
        final goals = snapshot.data ?? const <Objective>[];
        if (goals.isEmpty) return const SizedBox.shrink();
        final selected =
            goals.any((g) => g.objectivePk == widget.draft.piggyBankPk)
                ? widget.draft.piggyBankPk
                : null;
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 22, vertical: 6),
          child: DropdownButtonFormField<String?>(
            key: const ValueKey('firefly-piggy-section'),
            value: selected,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "firefly-piggy-bank".tr(),
              helperText: "firefly-piggy-transfer-only".tr(),
              helperMaxLines: 3,
            ),
            items: [
              DropdownMenuItem(
                  value: null, child: Text("firefly-piggy-none".tr())),
              for (final goal in goals)
                DropdownMenuItem(
                    value: goal.objectivePk, child: Text(goal.name)),
            ],
            onChanged: (pk) => setState(() => widget.draft.piggyBankPk = pk),
          ),
        );
      },
    );
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/bills/bills_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyBillSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyBillPicker(draft: draft);

/// Links the transaction being edited to a Firefly bill through draft.billPk.
class FireflyBillPicker extends StatefulWidget {
  const FireflyBillPicker({super.key, required this.draft});

  final FireflyTransactionDraft draft;

  @override
  State<FireflyBillPicker> createState() => _FireflyBillPickerState();
}

class _FireflyBillPickerState extends State<FireflyBillPicker> {
  late final _bills = widget.draft.db.watchFireflyBills();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FireflyCachedResource>>(
      stream: _bills,
      builder: (context, snapshot) {
        final bills = [...?snapshot.data?.map(fireflyBillFromRow)]
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        if (bills.isEmpty && widget.draft.billPk == null) {
          return const SizedBox.shrink();
        }
        final selected = bills.any((bill) => bill.id == widget.draft.billPk)
            ? widget.draft.billPk
            : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<String?>(
            key: const ValueKey('firefly-bill-picker'),
            value: selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'firefly-bills-picker'.tr()),
            items: [
              DropdownMenuItem(
                  value: null, child: Text('firefly-bills-picker-none'.tr())),
              for (final bill in bills)
                DropdownMenuItem(value: bill.id, child: Text(bill.name ?? '')),
            ],
            onChanged: (value) => setState(() => widget.draft.billPk = value),
          ),
        );
      },
    );
  }
}

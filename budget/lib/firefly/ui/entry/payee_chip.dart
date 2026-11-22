import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/pages/payees/common.dart';
import 'package:flutter/material.dart';

Widget fireflyPayeeChip(BuildContext context, Transaction transaction) =>
    transaction.payeeFk == null
        ? const SizedBox.shrink()
        : FireflyPayeeChip(payeePk: transaction.payeeFk!);

class FireflyPayeeChip extends StatefulWidget {
  const FireflyPayeeChip({super.key, required this.payeePk, this.db});

  final String payeePk;
  final FinanceDatabase? db;

  @override
  State<FireflyPayeeChip> createState() => _FireflyPayeeChipState();
}

class _FireflyPayeeChipState extends State<FireflyPayeeChip> {
  late final _payee =
      fireflyPayeesDb(widget.db).watchFireflyPayee(widget.payeePk);

  @override
  Widget build(BuildContext context) => StreamBuilder<Payee?>(
        stream: _payee,
        builder: (context, snapshot) {
          final payee = snapshot.data;
          if (payee == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              key: ValueKey('firefly-payee-chip-${payee.payeePk}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    payee.kind == PayeeKind.expense
                        ? Icons.storefront_rounded
                        : Icons.payments_rounded,
                    size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(payee.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          );
        },
      );
}

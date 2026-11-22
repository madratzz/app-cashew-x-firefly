import 'package:budget/database/tables.dart';
import 'package:flutter/material.dart';

/// Formats a foreign amount such as `12.50 EUR` for a transaction row.
String? fireflyForeignAmountLabel(Transaction transaction) {
  final amount = transaction.foreignAmount;
  final currency = transaction.foreignCurrency?.trim();
  if (amount == null || currency == null || currency.isEmpty) return null;
  return '${amount.abs().toStringAsFixed(2)} ${currency.toUpperCase()}';
}

Widget fireflyForeignAmountChip(BuildContext context, Transaction transaction) {
  final label = fireflyForeignAmountLabel(transaction);
  if (label == null) return const SizedBox.shrink();
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsetsDirectional.only(end: 4, top: 2),
    child: DecoratedBox(
      key: const ValueKey('firefly-foreign-amount-chip'),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    ),
  );
}

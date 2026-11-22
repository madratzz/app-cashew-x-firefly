import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/material.dart';

Widget fireflyTagsChip(BuildContext context, Transaction transaction) =>
    FireflyTagsChip(transaction: transaction);

/// Shows a transaction's tags as small chips on its row.
class FireflyTagsChip extends StatefulWidget {
  const FireflyTagsChip({required this.transaction, this.db, super.key});

  final Transaction transaction;
  final FinanceDatabase? db;

  @override
  State<FireflyTagsChip> createState() => _FireflyTagsChipState();
}

class _FireflyTagsChipState extends State<FireflyTagsChip> {
  late Stream<List<Tag>> _tags = _watch();

  Stream<List<Tag>> _watch() => (widget.db ?? database)
      .watchFireflyTransactionTags(widget.transaction.transactionPk);

  @override
  void didUpdateWidget(FireflyTagsChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaction.transactionPk !=
        widget.transaction.transactionPk) {
      _tags = _watch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tag>>(
      stream: _tags,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <Tag>[];
        if (tags.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Wrap(
          key: const ValueKey('firefly-tags-chip'),
          children: [
            for (final tag in tags)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4, top: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '#${tag.name}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

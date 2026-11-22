import 'package:budget/database/tables.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/splits/splits_page.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

final _newSplits = Expando<Set<String>>();
final _anchors = Expando<String>();

/// Records which transaction the form edits, so the editor can tell the main
/// row apart from its siblings.
void fireflySetSplitAnchor(FireflyTransactionDraft draft, String pk) =>
    _anchors[draft] = pk;

/// Keys of split rows the editor added to [draft] and that are not stored yet.
Set<String> fireflyNewSplitPks(FireflyTransactionDraft draft) =>
    _newSplits[draft] ??= {};

bool _isAnchor(Transaction row, String? anchorPk) =>
    row.transactionPk == '-1' || row.transactionPk == anchorPk;

/// The translation key of the first problem that blocks saving, or null.
String? fireflySplitDraftError(FireflyTransactionDraft draft,
    {String? anchorPk}) {
  for (final row in draft.splits) {
    if (_isAnchor(row, anchorPk) || row.pairedTransactionFk != null) continue;
    if (row.name.trim().isEmpty) return 'firefly-splits-error-description';
    if (!row.amount.isFinite || row.amount.abs() <= 0) {
      return 'firefly-splits-error-amount';
    }
  }
  return null;
}

Widget fireflySplitSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflySplitEditor(draft: draft);

class FireflySplitEditor extends StatefulWidget {
  const FireflySplitEditor({super.key, required this.draft});

  final FireflyTransactionDraft draft;

  @override
  State<FireflySplitEditor> createState() => _FireflySplitEditorState();
}

class _FireflySplitEditorState extends State<FireflySplitEditor> {
  late final Future<List<TransactionCategory>> _categories = (widget
          .draft.db
          .select(widget.draft.db.categories)
        ..where((row) =>
            row.mainCategoryPk.isNull() & row.categoryPk.equals('0').not())
        ..orderBy([(row) => OrderingTerm.asc(row.order)]))
      .get();
  late final TextEditingController _title =
      TextEditingController(text: widget.draft.splitTitle ?? '');

  FireflyTransactionDraft get draft => widget.draft;

  String? get _anchorPk => _anchors[draft];

  @override
  void didUpdateWidget(FireflySplitEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final title = draft.splitTitle ?? '';
    if (_title.text != title) _title.text = title;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Transaction _newRow(Transaction template) {
    final pk = const Uuid().v4();
    fireflyNewSplitPks(draft).add(pk);
    return Transaction(
      transactionPk: pk,
      name: '',
      amount: 0,
      note: '',
      categoryFk: template.categoryFk == '-1' ? '0' : template.categoryFk,
      walletFk: template.walletFk,
      dateCreated: template.dateCreated,
      income: template.income,
      paid: template.paid,
      skipPaid: template.skipPaid,
    );
  }

  void _start() => setState(() {
        final anchor = Transaction(
          transactionPk: '-1',
          name: '',
          amount: 0,
          note: '',
          categoryFk: '-1',
          walletFk: '0',
          dateCreated: DateTime.now(),
          income: false,
          paid: true,
          skipPaid: false,
        );
        draft.splits = [anchor, _newRow(anchor)];
      });

  void _add() => setState(() {
        final template = draft.splits.firstWhere(
            (row) => _isAnchor(row, _anchorPk),
            orElse: () => draft.splits.first);
        draft.splits = [...draft.splits, _newRow(template)];
      });

  void _remove(Transaction row) => setState(() {
        final pks = {row.transactionPk, row.pairedTransactionFk};
        draft.splits = [
          for (final split in draft.splits)
            if (!pks.contains(split.transactionPk)) split,
        ];
        fireflyNewSplitPks(draft).remove(row.transactionPk);
        // One journal left means a normal transaction.
        if (_journals.length < 2) draft.splits = [];
      });

  void _replace(Transaction row) => setState(() {
        draft.splits = [
          for (final split in draft.splits)
            split.transactionPk == row.transactionPk ? row : split,
        ];
      });

  List<Transaction> get _journals => fireflyJournals(draft.splits);

  /// Firefly needs a group title; a blank one becomes the first description.
  String get _defaultTitleHelp {
    final first = _journals.isEmpty ? null : _journals.first;
    if (first == null || first.transactionPk == '-1') {
      return 'firefly-splits-group-title-default-main'.tr();
    }
    return 'firefly-splits-group-title-default'
        .tr(namedArgs: {'title': first.name.trim()});
  }

  @override
  Widget build(BuildContext context) {
    if (draft.splits.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('firefly-split-start'),
            onPressed: _start,
            icon: const Icon(Icons.call_split_rounded),
            label: Text('firefly-splits-start'.tr()),
          ),
        ),
      );
    }
    final journals = _journals;
    final others = journals.where((row) => !_isAnchor(row, _anchorPk));
    final total = others.fold<double>(0, (sum, row) => sum + row.amount.abs());
    final error = fireflySplitDraftError(draft, anchorPk: _anchorPk);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('firefly-splits-title'.tr(),
              style: Theme.of(context).textTheme.titleMedium),
          TextField(
            key: const ValueKey('firefly-split-group-title'),
            controller: _title,
            decoration: InputDecoration(
              labelText: 'firefly-splits-group-title'.tr(),
              helperText: _defaultTitleHelp,
            ),
            onChanged: (value) => setState(() => draft.splitTitle = value),
          ),
          for (final row in journals)
            _isAnchor(row, _anchorPk)
                ? ListTile(
                    key: const ValueKey('firefly-split-anchor'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('firefly-splits-main'.tr()),
                    subtitle: Text('firefly-splits-main-description'.tr()),
                  )
                : _SplitRow(
                    key: ValueKey('firefly-split-${row.transactionPk}'),
                    row: row,
                    categories: _categories,
                    onChanged: _replace,
                    onRemove: () => _remove(row),
                  ),
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('firefly-split-add'),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: Text('firefly-splits-add'.tr()),
              ),
              const Spacer(),
              Text(
                'firefly-splits-total'.tr(namedArgs: {
                  'count': '${journals.length}',
                  'total': total.toStringAsFixed(2),
                }),
                key: const ValueKey('firefly-split-total'),
              ),
            ],
          ),
          if (error != null)
            Text(error.tr(),
                key: const ValueKey('firefly-split-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}

class _SplitRow extends StatefulWidget {
  const _SplitRow({
    super.key,
    required this.row,
    required this.categories,
    required this.onChanged,
    required this.onRemove,
  });

  final Transaction row;
  final Future<List<TransactionCategory>> categories;
  final ValueChanged<Transaction> onChanged;
  final VoidCallback onRemove;

  @override
  State<_SplitRow> createState() => _SplitRowState();
}

class _SplitRowState extends State<_SplitRow> {
  late final _name = TextEditingController(text: widget.row.name);
  late final _amount = TextEditingController(
      text: widget.row.amount == 0 ? '' : widget.row.amount.abs().toString());

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final transfer = row.pairedTransactionFk != null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              key: const ValueKey('description'),
              controller: _name,
              enabled: !transfer,
              decoration: InputDecoration(
                  labelText: 'firefly-splits-description'.tr()),
              onChanged: (value) => widget.onChanged(row.copyWith(name: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              key: const ValueKey('amount'),
              controller: _amount,
              enabled: !transfer,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration:
                  InputDecoration(labelText: 'firefly-splits-amount'.tr()),
              onChanged: (value) {
                final amount =
                    double.tryParse(value.replaceAll(',', '.')) ?? 0;
                widget.onChanged(row.copyWith(
                    amount: row.income ? amount.abs() : -amount.abs()));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: FutureBuilder<List<TransactionCategory>>(
              future: widget.categories,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const [];
                final selected = categories
                        .any((category) => category.categoryPk == row.categoryFk)
                    ? row.categoryFk
                    : null;
                return DropdownButtonFormField<String>(
                  key: const ValueKey('category'),
                  value: selected,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: 'firefly-splits-category'.tr()),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.categoryPk,
                        child: Text(category.name,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: transfer
                      ? null
                      : (pk) => pk == null
                          ? null
                          : widget.onChanged(row.copyWith(
                              categoryFk: pk,
                              subCategoryFk: const Value(null))),
                );
              },
            ),
          ),
          IconButton(
            key: const ValueKey('remove'),
            tooltip: 'firefly-splits-remove'.tr(),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/payees/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyPayeeSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyPayeePicker(draft: draft);

/// Sets draft.payeePk. Withdrawals take expense payees and deposits take
/// revenue payees. The picker opens on the kind for draft.income, else on the
/// stored payee's kind, and can still be switched by hand.
class FireflyPayeePicker extends StatefulWidget {
  const FireflyPayeePicker({super.key, required this.draft, this.onWrite});

  final FireflyTransactionDraft draft;
  final FireflyPayeeWriteNotifier? onWrite;

  @override
  State<FireflyPayeePicker> createState() => _FireflyPayeePickerState();
}

class _FireflyPayeePickerState extends State<FireflyPayeePicker> {
  late Stream<Payee?> _selected = _watchSelected();

  Stream<Payee?> _watchSelected() {
    final pk = widget.draft.payeePk;
    return pk == null
        ? Stream.value(null)
        : widget.draft.db.watchFireflyPayee(pk);
  }

  Future<void> _pick(PayeeKind kind) async {
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FireflyPayeePickerSheet(
          db: widget.draft.db, initialKind: kind, onWrite: widget.onWrite),
    );
    if (result == null) return;
    setState(() {
      widget.draft.payeePk = result.payee?.payeePk;
      _selected = _watchSelected();
    });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Payee?>(
        stream: _selected,
        builder: (context, snapshot) {
          final payee = snapshot.data;
          return ListTile(
            key: const ValueKey('firefly-payee-picker'),
            leading: const Icon(Icons.storefront_rounded),
            title: Text('firefly-payees-picker'.tr()),
            subtitle: Text(payee?.name ?? 'firefly-payees-picker-none'.tr()),
            trailing: payee == null
                ? null
                : IconButton(
                    key: const ValueKey('firefly-payee-picker-clear'),
                    tooltip: 'firefly-payees-picker-clear'.tr(),
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() {
                      widget.draft.payeePk = null;
                      _selected = _watchSelected();
                    }),
                  ),
            onTap: () => _pick(switch (widget.draft.income) {
              true => PayeeKind.revenue,
              false => PayeeKind.expense,
              null => payee?.kind ?? PayeeKind.expense,
            }),
          );
        },
      );
}

class _PickResult {
  const _PickResult(this.payee);
  final Payee? payee;
}

/// Searches active payees of one kind and creates a missing one inline.
class FireflyPayeePickerSheet extends StatefulWidget {
  const FireflyPayeePickerSheet({
    super.key,
    required this.db,
    this.initialKind = PayeeKind.expense,
    this.onWrite,
  });

  final FinanceDatabase db;
  final PayeeKind initialKind;
  final FireflyPayeeWriteNotifier? onWrite;

  @override
  State<FireflyPayeePickerSheet> createState() =>
      _FireflyPayeePickerSheetState();
}

class _FireflyPayeePickerSheetState extends State<FireflyPayeePickerSheet> {
  late PayeeKind _kind = widget.initialKind;
  String _search = '';
  late Stream<List<Payee>> _payees = _watch();

  Stream<List<Payee>> _watch() => widget.db
      .watchFireflyPayees(search: _search, kind: _kind, activeOnly: true);

  void _refilter(void Function() change) => setState(() {
        change();
        _payees = _watch();
      });

  Future<void> _create() async {
    final payee =
        await widget.db.fireflyCreatePayee(name: _search, kind: _kind);
    (widget.onWrite ?? defaultFireflyPayeeWrite)();
    if (mounted) Navigator.of(context).pop(_PickResult(payee));
  }

  @override
  Widget build(BuildContext context) {
    final term = _search.trim();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, top: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<PayeeKind>(
                key: const ValueKey('firefly-payee-picker-kind'),
                segments: [
                  ButtonSegment(
                      value: PayeeKind.expense,
                      label: Text('firefly-payees-picker-withdrawal'.tr())),
                  ButtonSegment(
                      value: PayeeKind.revenue,
                      label: Text('firefly-payees-picker-deposit'.tr())),
                ],
                selected: {_kind},
                onSelectionChanged: (value) =>
                    _refilter(() => _kind = value.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const ValueKey('firefly-payee-picker-search'),
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: 'firefly-payees-search'.tr(),
                ),
                onChanged: (value) => _refilter(() => _search = value),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Payee>>(
                stream: _payees,
                builder: (context, snapshot) {
                  final payees = snapshot.data ?? const <Payee>[];
                  final exact = payees
                      .any((p) => p.name.toLowerCase() == term.toLowerCase());
                  return ListView(
                    children: [
                      ListTile(
                        key: const ValueKey('firefly-payee-picker-option-none'),
                        title: Text('firefly-payees-picker-none'.tr()),
                        onTap: () =>
                            Navigator.of(context).pop(const _PickResult(null)),
                      ),
                      for (final payee in payees)
                        ListTile(
                          key: ValueKey(
                              'firefly-payee-picker-option-${payee.payeePk}'),
                          title: Text(payee.name),
                          onTap: () =>
                              Navigator.of(context).pop(_PickResult(payee)),
                        ),
                      if (term.isNotEmpty && !exact)
                        ListTile(
                          key: const ValueKey('firefly-payee-picker-create'),
                          leading: const Icon(Icons.add_rounded),
                          title: Text('firefly-payees-picker-create'
                              .tr(namedArgs: {'name': term})),
                          onTap: _create,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

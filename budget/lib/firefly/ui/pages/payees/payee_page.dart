import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/ui/pages/payees/common.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum FireflyPayeeDeleteChoice { deactivate, delete }

/// Firefly deletes every transaction linked to an account with it, so the
/// dialog offers deactivation first.
Future<FireflyPayeeDeleteChoice?> showFireflyPayeeDeleteDialog(
        BuildContext context, Payee payee) =>
    showDialog<FireflyPayeeDeleteChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('firefly-payees-delete-title'.tr()),
        content: Text('firefly-payees-delete-warning'
            .tr(namedArgs: {'name': payee.name})),
        actions: [
          TextButton(
            key: const ValueKey('firefly-payee-delete-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('firefly-payees-cancel'.tr()),
          ),
          TextButton(
            key: const ValueKey('firefly-payee-delete-confirm'),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () =>
                Navigator.of(context).pop(FireflyPayeeDeleteChoice.delete),
            child: Text('firefly-payees-delete-everything'.tr()),
          ),
          FilledButton(
            key: const ValueKey('firefly-payee-delete-deactivate'),
            autofocus: true,
            onPressed: () =>
                Navigator.of(context).pop(FireflyPayeeDeleteChoice.deactivate),
            child: Text('firefly-payees-deactivate'.tr()),
          ),
        ],
      ),
    );

/// Creates a payee, or edits one and lists its transactions.
class FireflyPayeePage extends StatefulWidget {
  const FireflyPayeePage({
    super.key,
    this.db,
    this.payee,
    this.initialKind = PayeeKind.expense,
    this.initialName,
    this.onWrite,
  });

  final FinanceDatabase? db;
  final Payee? payee;
  final PayeeKind initialKind;
  final String? initialName;
  final FireflyPayeeWriteNotifier? onWrite;

  @override
  State<FireflyPayeePage> createState() => _FireflyPayeePageState();
}

class _FireflyPayeePageState extends State<FireflyPayeePage> {
  late final FinanceDatabase _db = fireflyPayeesDb(widget.db);
  final _form = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.payee?.name ?? widget.initialName);
  late final _notes = TextEditingController(text: widget.payee?.notes);
  late final _iban = TextEditingController(text: widget.payee?.iban);
  late PayeeKind _kind = widget.payee?.kind ?? widget.initialKind;
  late bool _active = widget.payee?.active ?? true;
  late final Stream<List<Transaction>>? _history = widget.payee == null
      ? null
      : _db.watchFireflyPayeeTransactions(widget.payee!.payeePk);

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _iban.dispose();
    super.dispose();
  }

  void _notify() => (widget.onWrite ?? defaultFireflyPayeeWrite)();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final existing = widget.payee;
    final Payee? saved;
    if (existing == null) {
      saved = await _db.fireflyCreatePayee(
        name: _name.text,
        kind: _kind,
        active: _active,
        notes: _notes.text,
        iban: _iban.text,
      );
    } else {
      saved = await _db.fireflyUpdatePayee(existing.copyWith(
        name: _name.text,
        active: _active,
        notes: Value(_notes.text),
        iban: Value(_iban.text),
      ));
    }
    _notify();
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete() async {
    final payee = widget.payee!;
    final choice = await showFireflyPayeeDeleteDialog(context, payee);
    if (choice == null) return;
    if (choice == FireflyPayeeDeleteChoice.deactivate) {
      await _db.fireflyUpdatePayee(payee.copyWith(active: false));
    } else {
      await _db.fireflyDeletePayee(payee.payeePk);
    }
    _notify();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.payee != null;
    return Scaffold(
      appBar: AppBar(
        title:
            Text((editing ? 'firefly-payees-edit' : 'firefly-payees-new').tr()),
        actions: [
          if (editing)
            IconButton(
              key: const ValueKey('firefly-payee-delete'),
              tooltip: 'firefly-payees-delete'.tr(),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const ValueKey('firefly-payee-name'),
              controller: _name,
              decoration:
                  InputDecoration(labelText: 'firefly-payees-name'.tr()),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'firefly-payees-name-required'.tr()
                  : null,
            ),
            const SizedBox(height: 12),
            // Firefly fixes the account type at creation.
            SegmentedButton<PayeeKind>(
              key: const ValueKey('firefly-payee-kind'),
              segments: [
                for (final kind in PayeeKind.values)
                  ButtonSegment(
                      value: kind, label: Text(fireflyPayeeKindKey(kind).tr())),
              ],
              selected: {_kind},
              onSelectionChanged: editing
                  ? null
                  : (value) => setState(() => _kind = value.first),
            ),
            SwitchListTile(
              key: const ValueKey('firefly-payee-active'),
              contentPadding: EdgeInsets.zero,
              title: Text('firefly-payees-active'.tr()),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            TextFormField(
              key: const ValueKey('firefly-payee-iban'),
              controller: _iban,
              decoration:
                  InputDecoration(labelText: 'firefly-payees-iban'.tr()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('firefly-payee-notes'),
              controller: _notes,
              maxLines: null,
              decoration:
                  InputDecoration(labelText: 'firefly-payees-notes'.tr()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('firefly-payee-save'),
              onPressed: _save,
              child: Text('firefly-payees-save'.tr()),
            ),
            if (_history != null) ...[
              const SizedBox(height: 24),
              Text('firefly-payees-history'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              StreamBuilder<List<Transaction>>(
                stream: _history,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <Transaction>[];
                  if (rows.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('firefly-payees-history-empty'.tr()),
                    );
                  }
                  return Column(children: [
                    for (final row in rows)
                      ListTile(
                        key: ValueKey(
                            'firefly-payee-transaction-${row.transactionPk}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(row.name),
                        subtitle:
                            Text(DateFormat.yMMMd().format(row.dateCreated)),
                        trailing: Text(row.amount.toStringAsFixed(2)),
                      ),
                  ]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/pages/links/object_group_label.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FireflyBillEditorPage extends StatefulWidget {
  const FireflyBillEditorPage(
      {super.key, required this.db, this.bill, this.pushNow});

  final FinanceDatabase db;

  /// Null creates a bill. Its id is the local cache primary key.
  final FireflyBill? bill;
  final FireflyPushNow? pushNow;

  @override
  State<FireflyBillEditorPage> createState() => _FireflyBillEditorPageState();
}

class _FireflyBillEditorPageState extends State<FireflyBillEditorPage> {
  late final _name = TextEditingController(text: widget.bill?.name ?? '');
  late final _min =
      TextEditingController(text: _amount(widget.bill?.amountMin));
  late final _max =
      TextEditingController(text: _amount(widget.bill?.amountMax));
  late DateTime _date = widget.bill?.date ?? DateTime.now();
  late FireflyBillFrequency _frequency =
      widget.bill?.frequency ?? FireflyBillFrequency.monthly;
  late bool _active = widget.bill?.active ?? true;
  String? _error;
  bool _saving = false;

  static String _amount(double? value) => value?.toStringAsFixed(2) ?? '';

  @override
  void initState() {
    super.initState();
    final pk = widget.bill?.id;
    if (pk != null) {
      fireflyRejection(widget.db, FireflyEntityType.bill, pk).then((message) {
        if (mounted && message != null) setState(() => _error = message);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  JsonObject? _fields() {
    final name = _name.text.trim();
    final min = double.tryParse(_min.text.trim());
    final max = double.tryParse(_max.text.trim()) ?? min;
    if (name.isEmpty) return _invalid('firefly-bills-name-required');
    if (min == null || max == null || max < min) {
      return _invalid('firefly-bills-amount-invalid');
    }
    final fields = <String, Object?>{
      'name': name,
      'amount_min': min.toStringAsFixed(2),
      'amount_max': max.toStringAsFixed(2),
      'date': fireflyWireDay(_date),
      'repeat_freq': _frequency.wireValue,
      'active': _active,
    };
    // Send only changed fields so an edit cannot overwrite server values.
    final old = widget.bill?.attributes;
    if (old != null) {
      fields.removeWhere((key, value) => switch (key) {
            'amount_min' => widget.bill!.amountMin == min,
            'amount_max' => widget.bill!.amountMax == max,
            'date' => widget.bill!.date != null &&
                fireflyWireDay(widget.bill!.date!) == value,
            _ => old[key] == value,
          });
    }
    return fields;
  }

  JsonObject? _invalid(String key) {
    setState(() => _error = key.tr());
    return null;
  }

  Future<void> _save() async {
    final fields = _fields();
    if (fields == null) return;
    setState(() => _saving = true);
    final pk = await widget.db.saveFireflyBill(fields, pk: widget.bill?.id);
    await (widget.pushNow ?? defaultFireflyPushNow)();
    final rejected =
        await fireflyRejection(widget.db, FireflyEntityType.bill, pk);
    if (!mounted) return;
    setState(() => _saving = false);
    if (rejected != null) {
      setState(() => _error =
          'firefly-bills-rejected'.tr(namedArgs: {'message': rejected}));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.db.deleteFireflyBill(widget.bill!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            (widget.bill == null ? 'firefly-bills-new' : 'firefly-bills-edit')
                .tr()),
        actions: [
          if (widget.bill != null)
            IconButton(
              key: const ValueKey('firefly-bill-delete'),
              tooltip: 'firefly-bills-delete'.tr(),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) FireflyErrorBanner(_error!),
          if (widget.bill case final bill?)
            FireflyObjectGroupLabel(attributes: bill.attributes),
          TextField(
            key: const ValueKey('firefly-bill-name'),
            controller: _name,
            decoration: InputDecoration(labelText: 'firefly-bills-name'.tr()),
          ),
          TextField(
            key: const ValueKey('firefly-bill-min'),
            controller: _min,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: 'firefly-bills-amount-min'.tr()),
          ),
          TextField(
            key: const ValueKey('firefly-bill-max'),
            controller: _max,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: 'firefly-bills-amount-max'.tr()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-bills-date'.tr()),
            subtitle: Text(fireflyDay(_date)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1970),
                lastDate: DateTime(2200),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          DropdownButtonFormField<FireflyBillFrequency>(
            key: const ValueKey('firefly-bill-frequency'),
            isExpanded: true,
            value: _frequency,
            decoration:
                InputDecoration(labelText: 'firefly-bills-frequency'.tr()),
            items: [
              for (final frequency in FireflyBillFrequency.values)
                DropdownMenuItem(
                  value: frequency,
                  child: Text('firefly-bills-freq-${frequency.wireValue}'.tr()),
                ),
            ],
            onChanged: (value) => setState(() => _frequency = value!),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-bills-active'.tr()),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('firefly-bill-save'),
            onPressed: _saving ? null : _save,
            child: Text('firefly-bills-save'.tr()),
          ),
        ],
      ),
    );
  }
}

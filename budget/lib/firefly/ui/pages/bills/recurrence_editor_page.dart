import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/bill_recurrence_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Edits an existing server recurrence. Its id is the local cache primary key.
class FireflyRecurrenceEditorPage extends StatefulWidget {
  const FireflyRecurrenceEditorPage(
      {super.key, required this.db, required this.recurrence, this.pushNow});

  final FinanceDatabase db;
  final FireflyRecurrence recurrence;
  final FireflyPushNow? pushNow;

  @override
  State<FireflyRecurrenceEditorPage> createState() =>
      _FireflyRecurrenceEditorPageState();
}

class _FireflyRecurrenceEditorPageState
    extends State<FireflyRecurrenceEditorPage> {
  FireflyRecurrence get _old => widget.recurrence;
  FireflyRepetition? get _repetition =>
      _old.repetitions.isEmpty ? null : _old.repetitions.first;

  late final _title = TextEditingController(text: _old.title ?? '');
  late final _description = TextEditingController(text: _old.description ?? '');
  late final _moment = TextEditingController(text: _repetition?.moment ?? '');
  late final _skip = TextEditingController(text: '${_repetition?.skip ?? 0}');
  late FireflyRepetitionType _type =
      _repetition?.type ?? FireflyRepetitionType.monthly;
  late bool _active = _old.active ?? true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    fireflyRejection(widget.db, FireflyEntityType.recurrence, _old.id)
        .then((message) {
      if (mounted && message != null) setState(() => _error = message);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _moment.dispose();
    _skip.dispose();
    super.dispose();
  }

  JsonObject? _fields() {
    final title = _title.text.trim();
    final skip = int.tryParse(_skip.text.trim());
    if (title.isEmpty) return _invalid('firefly-recurrences-title-required');
    if (skip == null || skip < 0) {
      return _invalid('firefly-recurrences-skip-invalid');
    }
    final fields = <String, Object?>{
      if (title != _old.title) 'title': title,
      if (_description.text != (_old.description ?? ''))
        'description': _description.text,
      if (_active != (_old.active ?? true)) 'active': _active,
    };
    final moment = _moment.text.trim();
    final repetition = _repetition;
    if (repetition == null ||
        _type != repetition.type ||
        moment != (repetition.moment ?? '') ||
        skip != (repetition.skip ?? 0)) {
      // Firefly 6.6.2 rejects some documented moment values on update. The
      // rejection is shown below instead of being dropped.
      fields['repetitions'] = [
        {
          ...?repetition?.fields,
          'type': _type.name,
          'moment': moment,
          'skip': skip,
        },
        ..._old.repetitions.skip(1).map((other) => other.fields),
      ];
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
    if (fields.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final pk = await widget.db.saveFireflyRecurrence(fields, pk: _old.id);
    await (widget.pushNow ?? defaultFireflyPushNow)();
    final rejected =
        await fireflyRejection(widget.db, FireflyEntityType.recurrence, pk);
    if (!mounted) return;
    setState(() => _saving = false);
    if (rejected != null) {
      setState(() => _error =
          'firefly-recurrences-rejected'.tr(namedArgs: {'message': rejected}));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.db.deleteFireflyRecurrence(_old.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('firefly-recurrences-edit'.tr()),
        actions: [
          IconButton(
            key: const ValueKey('firefly-recurrence-delete'),
            tooltip: 'firefly-recurrences-delete'.tr(),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) FireflyErrorBanner(_error!),
          TextField(
            key: const ValueKey('firefly-recurrence-title'),
            controller: _title,
            decoration:
                InputDecoration(labelText: 'firefly-recurrences-name'.tr()),
          ),
          TextField(
            key: const ValueKey('firefly-recurrence-description'),
            controller: _description,
            decoration: InputDecoration(
                labelText: 'firefly-recurrences-description'.tr()),
          ),
          DropdownButtonFormField<FireflyRepetitionType>(
            key: const ValueKey('firefly-recurrence-type'),
            isExpanded: true,
            value: _type,
            decoration: InputDecoration(
                labelText: 'firefly-recurrences-repetition'.tr()),
            items: [
              for (final type in FireflyRepetitionType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text('firefly-recurrences-type-${type.name}'.tr()),
                ),
            ],
            onChanged: (value) => setState(() => _type = value!),
          ),
          TextField(
            key: const ValueKey('firefly-recurrence-moment'),
            controller: _moment,
            decoration: InputDecoration(
              labelText: 'firefly-recurrences-moment'.tr(),
              helperText: 'firefly-recurrences-moment-help'.tr(),
            ),
          ),
          TextField(
            key: const ValueKey('firefly-recurrence-skip'),
            controller: _skip,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: 'firefly-recurrences-skip'.tr()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-recurrences-active'.tr()),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('firefly-recurrence-save'),
            onPressed: _saving ? null : _save,
            child: Text('firefly-recurrences-save'.tr()),
          ),
        ],
      ),
    );
  }
}

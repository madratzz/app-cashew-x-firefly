import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/firefly/ui/pages/rules/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class _Clause {
  _Clause(this.type, String? value, {this.prohibited = false, JsonObject? from})
      : value = TextEditingController(text: value),
        extra = {...?from};

  String type;
  final TextEditingController value;
  bool prohibited;

  /// Fields such as `active` and `stop_processing` kept from the server.
  final JsonObject extra;
}

/// Creates or edits a rule. Saving needs a connection; offline the rule
/// is shown read-only.
class FireflyRuleEditorPage extends StatefulWidget {
  const FireflyRuleEditorPage({
    super.key,
    required this.groups,
    required this.scheduler,
    this.rule,
    this.initialGroupId,
  });

  final List<FireflyRuleGroup> groups;
  final SyncScheduler? scheduler;
  final FireflyRule? rule;
  final String? initialGroupId;

  @override
  State<FireflyRuleEditorPage> createState() => _FireflyRuleEditorPageState();
}

class _FireflyRuleEditorPageState extends State<FireflyRuleEditorPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.rule?.title);
  late final _description =
      TextEditingController(text: widget.rule?.description);
  late String? _groupId = widget.rule?.ruleGroupId ??
      widget.initialGroupId ??
      (widget.groups.isEmpty ? null : widget.groups.first.id);
  late String _when = widget.rule?.trigger ?? 'store-journal';
  late bool _active = widget.rule?.active ?? true;
  late bool _strict = widget.rule?.strict ?? true;
  late bool _stopProcessing = widget.rule?.stopProcessing ?? false;
  late final List<_Clause> _triggers = [
    for (final clause in widget.rule?.triggers ?? const <JsonObject>[])
      _Clause(clause['type'] as String, clause['value']?.toString(),
          prohibited: clause['prohibited'] == true, from: clause),
  ];
  late final List<_Clause> _actions = [
    for (final clause in widget.rule?.actions ?? const <JsonObject>[])
      _Clause(clause['type'] as String, clause['value']?.toString(),
          from: clause),
  ];
  String? _clauseError;
  String? _error;
  bool _saving = false;

  bool get _online => widget.scheduler != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final clause in [..._triggers, ..._actions]) {
      clause.value.dispose();
    }
    super.dispose();
  }

  JsonObject _clauseJson(_Clause clause, {required bool trigger}) {
    final valueless = trigger
        ? fireflyValuelessTriggers.contains(clause.type)
        : fireflyValuelessActions.contains(clause.type);
    final value = clause.value.text.trim();
    return {
      ...clause.extra,
      'type': clause.type,
      'value': valueless || value.isEmpty ? null : value,
      if (trigger) 'prohibited': clause.prohibited,
    };
  }

  Future<void> _save() async {
    final valid = _form.currentState!.validate();
    final clauseError = _triggers.isEmpty
        ? 'firefly-rules-triggers-required'.tr()
        : _actions.isEmpty
            ? 'firefly-rules-actions-required'.tr()
            : null;
    setState(() => _clauseError = clauseError);
    if (!valid || clauseError != null) return;
    final scheduler = widget.scheduler!;
    final body = <String, Object?>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'rule_group_id': _groupId,
      'trigger': _when,
      'active': _active,
      'strict': _strict,
      'stop_processing': _stopProcessing,
      'triggers': [for (final c in _triggers) _clauseJson(c, trigger: true)],
      'actions': [for (final c in _actions) _clauseJson(c, trigger: false)],
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sync = scheduler.engine.context;
      final rule = widget.rule;
      if (rule == null) {
        await fireflyRuleSyncer.createRule(sync, body);
      } else {
        await fireflyRuleSyncer.updateRule(sync, rule.id, body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = fireflyRulesErrorMessage(error);
        });
      }
    }
  }

  List<String> _choices(_Clause? current, {required bool trigger}) {
    final known = trigger
        ? FireflyRule.triggerKeywords
        : [
            for (final keyword in FireflyRule.actionKeywords)
              if (!fireflyUnwritableActions.contains(keyword)) keyword,
          ];
    return [
      ...known,
      if (current != null && !known.contains(current.type)) current.type,
    ];
  }

  Widget _clauseRow(_Clause clause, int index, {required bool trigger}) {
    final prefix = trigger ? 'firefly-rule-trigger' : 'firefly-rule-action';
    final needsValue = trigger
        ? !fireflyValuelessTriggers.contains(clause.type)
        : !fireflyValuelessActions.contains(clause.type);
    final optional =
        !trigger && fireflyOptionalValueActions.contains(clause.type);
    final list = trigger ? _triggers : _actions;
    return Card(
      key: ValueKey('$prefix-$index'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: DropdownButton<String>(
                key: ValueKey('$prefix-$index-type'),
                isExpanded: true,
                value: clause.type,
                items: [
                  for (final keyword in _choices(clause, trigger: trigger))
                    DropdownMenuItem(
                      value: keyword,
                      child: Text(
                          fireflyRuleKeywordLabel(keyword, trigger: trigger)),
                    ),
                ],
                onChanged: _online
                    ? (value) => setState(() => clause.type = value!)
                    : null,
              ),
            ),
            IconButton(
              key: ValueKey('$prefix-$index-remove'),
              tooltip: 'firefly-rules-remove'.tr(),
              icon: const Icon(Icons.close_rounded),
              onPressed: _online
                  ? () => setState(() => list.removeAt(index).value.dispose())
                  : null,
            ),
          ]),
          if (needsValue)
            TextFormField(
              key: ValueKey('$prefix-$index-value'),
              controller: clause.value,
              enabled: _online,
              decoration: InputDecoration(
                  labelText: (optional
                          ? 'firefly-rules-value-optional'
                          : 'firefly-rules-value')
                      .tr()),
              validator: (value) => !optional && (value ?? '').trim().isEmpty
                  ? 'firefly-rules-value-required'.tr()
                  : null,
            ),
          if (trigger)
            CheckboxListTile(
              key: ValueKey('$prefix-$index-prohibited'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('firefly-rules-prohibited'.tr()),
              value: clause.prohibited,
              onChanged: _online
                  ? (value) => setState(() => clause.prohibited = value!)
                  : null,
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.rule != null;
    final whenChoices = [
      ...FireflyRule.triggerTypes,
      if (!FireflyRule.triggerTypes.contains(_when)) _when,
    ];
    return Scaffold(
      appBar: AppBar(
          title: Text(
              (editing ? 'firefly-rules-edit-rule' : 'firefly-rules-new-rule')
                  .tr())),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_online)
              FireflyRulesOfflineBanner('firefly-rules-offline-edit'.tr()),
            TextFormField(
              key: const ValueKey('firefly-rule-title'),
              controller: _title,
              enabled: _online,
              decoration: InputDecoration(labelText: 'firefly-rules-name'.tr()),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'firefly-rules-name-required'.tr()
                  : null,
            ),
            TextFormField(
              key: const ValueKey('firefly-rule-description'),
              controller: _description,
              enabled: _online,
              decoration:
                  InputDecoration(labelText: 'firefly-rules-description'.tr()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('firefly-rule-group'),
              isExpanded: true,
              value: _groupId,
              decoration: InputDecoration(labelText: 'firefly-rules-group'.tr()),
              items: [
                for (final group in widget.groups)
                  DropdownMenuItem(
                      value: group.id, child: Text(group.title ?? '')),
              ],
              onChanged:
                  _online ? (value) => setState(() => _groupId = value) : null,
              validator: (value) =>
                  value == null ? 'firefly-rules-group-required'.tr() : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('firefly-rule-when'),
              isExpanded: true,
              value: _when,
              decoration: InputDecoration(labelText: 'firefly-rules-when'.tr()),
              items: [
                for (final type in whenChoices)
                  DropdownMenuItem(
                      value: type,
                      child: Text(fireflyRuleTriggerTypeLabel(type))),
              ],
              onChanged:
                  _online ? (value) => setState(() => _when = value!) : null,
            ),
            SwitchListTile(
              key: const ValueKey('firefly-rule-active'),
              contentPadding: EdgeInsets.zero,
              title: Text('firefly-rules-active'.tr()),
              value: _active,
              onChanged:
                  _online ? (value) => setState(() => _active = value) : null,
            ),
            SwitchListTile(
              key: const ValueKey('firefly-rule-strict'),
              contentPadding: EdgeInsets.zero,
              title: Text('firefly-rules-strict'.tr()),
              subtitle: Text('firefly-rules-strict-description'.tr()),
              value: _strict,
              onChanged:
                  _online ? (value) => setState(() => _strict = value) : null,
            ),
            SwitchListTile(
              key: const ValueKey('firefly-rule-stop-processing'),
              contentPadding: EdgeInsets.zero,
              title: Text('firefly-rules-stop-processing'.tr()),
              subtitle: Text('firefly-rules-stop-processing-description'.tr()),
              value: _stopProcessing,
              onChanged: _online
                  ? (value) => setState(() => _stopProcessing = value)
                  : null,
            ),
            const SizedBox(height: 12),
            Text('firefly-rules-triggers'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            for (var i = 0; i < _triggers.length; i++)
              _clauseRow(_triggers[i], i, trigger: true),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('firefly-rule-add-trigger'),
                icon: const Icon(Icons.add_rounded),
                label: Text('firefly-rules-add-trigger'.tr()),
                onPressed: _online
                    ? () => setState(() => _triggers.add(
                        _Clause(FireflyRule.triggerKeywords.first, null)))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text('firefly-rules-actions'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            for (var i = 0; i < _actions.length; i++)
              _clauseRow(_actions[i], i, trigger: false),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('firefly-rule-add-action'),
                icon: const Icon(Icons.add_rounded),
                label: Text('firefly-rules-add-action'.tr()),
                onPressed: _online
                    ? () => setState(() => _actions.add(_Clause(
                        _choices(null, trigger: false).first, null)))
                    : null,
              ),
            ),
            if (_clauseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_clauseError!,
                    key: const ValueKey('firefly-rule-clause-error'),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_error != null)
              FireflyRulesOfflineBanner(_error!,
                  key: const ValueKey('firefly-rule-error')),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('firefly-rule-save'),
              onPressed: _online && !_saving ? _save : null,
              child: Text('firefly-rules-save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

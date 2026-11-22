import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/db/rule_queries.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/firefly/ui/pages/rules/common.dart';
import 'package:budget/firefly/ui/pages/rules/rule_editor_page.dart';
import 'package:budget/firefly/ui/pages/rules/rule_run_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum _GroupAction { addRule, run, edit, delete }

/// Rule groups and their rules from the cache. Reading works offline;
/// creating, editing, testing and running need the server.
class FireflyRulesPage extends StatefulWidget {
  const FireflyRulesPage({super.key, this.db, this.scheduler});

  final FinanceDatabase? db;
  final FireflyRulesSchedulerProvider? scheduler;

  @override
  State<FireflyRulesPage> createState() => _FireflyRulesPageState();
}

class _FireflyRulesPageState extends State<FireflyRulesPage> {
  late final FinanceDatabase _db = fireflyRulesDb(widget.db);
  late final Stream<List<FireflyCachedResource>> _groupRows =
      _db.watchFireflyRules(groups: true);
  late final Stream<List<FireflyCachedResource>> _ruleRows =
      _db.watchFireflyRules();
  SyncScheduler? _scheduler;
  bool _checking = true;
  List<FireflyRuleGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final scheduler = await fireflyRulesOnline(widget.scheduler);
    if (mounted) {
      setState(() {
        _scheduler = scheduler;
        _checking = false;
      });
    }
  }

  bool get _online => _scheduler != null;

  Future<void> _attempt(Future<void> Function(SyncScheduler) action) async {
    try {
      await action(_scheduler!);
    } catch (error) {
      if (!mounted) return;
      if (fireflyIsConnectionError(error)) setState(() => _scheduler = null);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fireflyRulesErrorMessage(error))));
    }
  }

  Future<void> _editGroup(FireflyRuleGroup? group) async {
    final body = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _GroupDialog(group: group),
    );
    if (body == null) return;
    await _attempt((scheduler) async {
      final context = scheduler.engine.context;
      if (group == null) {
        await fireflyRuleSyncer.createGroup(context, body);
      } else {
        await fireflyRuleSyncer.updateGroup(context, group.id, body);
      }
    });
  }

  Future<void> _deleteGroup(FireflyRuleGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('firefly-rules-delete-group-title'.tr()),
        content: Text('firefly-rules-delete-group-warning'
            .tr(namedArgs: {'name': group.title ?? ''})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('firefly-rules-cancel'.tr()),
          ),
          FilledButton(
            key: const ValueKey('firefly-rule-group-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('firefly-rules-delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _attempt((scheduler) =>
        fireflyRuleSyncer.deleteGroup(scheduler.engine.context, group.id));
  }

  Future<void> _deleteRule(FireflyRule rule) => _attempt((scheduler) =>
      fireflyRuleSyncer.deleteRule(scheduler.engine.context, rule.id));

  void _openRule(FireflyRule? rule, {String? groupId}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FireflyRuleEditorPage(
          groups: _groups,
          scheduler: _scheduler,
          rule: rule,
          initialGroupId: groupId,
        ),
      ));

  void _openRun(String id, String title, {required bool groups}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FireflyRuleRunPage(
          id: id,
          title: title,
          groups: groups,
          scheduler: _scheduler,
          db: _db,
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('firefly-rules-title'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('firefly-rule-group-add'),
        tooltip: 'firefly-rules-add-group'.tr(),
        onPressed: _online ? () => _editGroup(null) : null,
        child: const Icon(Icons.create_new_folder_rounded),
      ),
      body: StreamBuilder<List<FireflyCachedResource>>(
        stream: _groupRows,
        builder: (context, groupSnapshot) =>
            StreamBuilder<List<FireflyCachedResource>>(
          stream: _ruleRows,
          builder: (context, ruleSnapshot) {
            _groups = [...?groupSnapshot.data?.map(fireflyRuleGroupFromRow)];
            final rules = [...?ruleSnapshot.data?.map(fireflyRuleFromRow)];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              children: [
                if (!_checking && !_online)
                  FireflyRulesOfflineBanner('firefly-rules-offline-view'.tr(),
                      onRetry: _check),
                if (_groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(child: Text('firefly-rules-empty'.tr())),
                  ),
                for (final group in _groups)
                  ..._groupSection(group, [
                    for (final rule in rules)
                      if (rule.ruleGroupId == group.id) rule,
                  ]),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _groupSection(FireflyRuleGroup group, List<FireflyRule> rules) {
    final title = group.title ?? '';
    return [
      ListTile(
        key: ValueKey('firefly-rule-group-${group.id}'),
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: group.active == false
            ? Text('firefly-rules-inactive'.tr())
            : null,
        trailing: PopupMenuButton<_GroupAction>(
          key: ValueKey('firefly-rule-group-menu-${group.id}'),
          onSelected: (action) => switch (action) {
            _GroupAction.addRule => _openRule(null, groupId: group.id),
            _GroupAction.run => _openRun(group.id, title, groups: true),
            _GroupAction.edit => _editGroup(group),
            _GroupAction.delete => _deleteGroup(group),
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              key: const ValueKey('firefly-rule-group-add-rule'),
              value: _GroupAction.addRule,
              enabled: _online,
              child: Text('firefly-rules-add-rule'.tr()),
            ),
            PopupMenuItem(
              key: const ValueKey('firefly-rule-group-run'),
              value: _GroupAction.run,
              child: Text('firefly-rules-test-run'.tr()),
            ),
            PopupMenuItem(
              key: const ValueKey('firefly-rule-group-edit'),
              value: _GroupAction.edit,
              enabled: _online,
              child: Text('firefly-rules-edit-group'.tr()),
            ),
            PopupMenuItem(
              key: const ValueKey('firefly-rule-group-delete'),
              value: _GroupAction.delete,
              enabled: _online,
              child: Text('firefly-rules-delete-group'.tr()),
            ),
          ],
        ),
      ),
      if (rules.isEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text('firefly-rules-group-empty'.tr()),
        ),
      for (final rule in rules)
        ListTile(
          key: ValueKey('firefly-rule-${rule.id}'),
          contentPadding: const EdgeInsets.only(left: 16),
          enabled: rule.active != false,
          title: Text(rule.title ?? ''),
          subtitle: Text([
            fireflyRuleTriggerTypeLabel(rule.trigger ?? ''),
            'firefly-rules-summary'.tr(namedArgs: {
              'triggers': '${rule.triggers.length}',
              'actions': '${rule.actions.length}',
            }),
            if (rule.active == false) 'firefly-rules-inactive'.tr(),
          ].where((part) => part.isNotEmpty).join(' · ')),
          onTap: () => _openRule(rule),
          trailing: PopupMenuButton<String>(
            key: ValueKey('firefly-rule-menu-${rule.id}'),
            onSelected: (action) => action == 'run'
                ? _openRun(rule.id, rule.title ?? '', groups: false)
                : _deleteRule(rule),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const ValueKey('firefly-rule-run-open'),
                value: 'run',
                child: Text('firefly-rules-test-run'.tr()),
              ),
              PopupMenuItem(
                key: const ValueKey('firefly-rule-delete'),
                value: 'delete',
                enabled: _online,
                child: Text('firefly-rules-delete-rule'.tr()),
              ),
            ],
          ),
        ),
    ];
  }
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({this.group});

  final FireflyRuleGroup? group;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.group?.title);
  late bool _active = widget.group?.active ?? true;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text((widget.group == null
              ? 'firefly-rules-new-group'
              : 'firefly-rules-edit-group')
          .tr()),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            key: const ValueKey('firefly-rule-group-title'),
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: 'firefly-rules-name'.tr()),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'firefly-rules-name-required'.tr()
                : null,
          ),
          SwitchListTile(
            key: const ValueKey('firefly-rule-group-active'),
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-rules-active'.tr()),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('firefly-rules-cancel'.tr()),
        ),
        FilledButton(
          key: const ValueKey('firefly-rule-group-save'),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.of(context)
                .pop({'title': _title.text.trim(), 'active': _active});
          },
          child: Text('firefly-rules-save'.tr()),
        ),
      ],
    );
  }
}

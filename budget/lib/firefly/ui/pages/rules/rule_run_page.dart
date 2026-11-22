import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/firefly/ui/pages/rules/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _testPageSize = 50;

/// Dry-runs a rule or group against server transactions, then runs it for
/// real and syncs the changed transactions back.
class FireflyRuleRunPage extends StatefulWidget {
  const FireflyRuleRunPage({
    super.key,
    required this.id,
    required this.title,
    required this.scheduler,
    this.groups = false,
    this.db,
    this.today,
  });

  final String id;
  final String title;
  final bool groups;
  final SyncScheduler? scheduler;
  final FinanceDatabase? db;
  final DateTime Function()? today;

  @override
  State<FireflyRuleRunPage> createState() => _FireflyRuleRunPageState();
}

class _FireflyRuleRunPageState extends State<FireflyRuleRunPage> {
  late final FinanceDatabase _db = fireflyRulesDb(widget.db);
  late final DateTime _now = (widget.today ?? DateTime.now)();
  late DateTimeRange _range = DateTimeRange(
      start: DateUtils.dateOnly(_now.subtract(const Duration(days: 30))),
      end: DateUtils.dateOnly(_now));
  late SyncScheduler? _scheduler = widget.scheduler;
  late final Future<List<({String remoteId, String name})>> _accounts =
      fireflyRuleAccounts(_db);
  final Set<String> _selected = {};
  FireflyPage<FireflyTransaction>? _matches;
  String? _error;
  bool _busy = false;

  bool get _online => _scheduler != null;

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(_now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  Future<void> _guard(Future<void> Function(SyncScheduler) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(_scheduler!);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (fireflyIsConnectionError(error)) _scheduler = null;
        _error = fireflyRulesErrorMessage(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() => _guard((scheduler) async {
        final api = scheduler.engine.context.api.rules;
        final run = widget.groups ? api.testGroup : api.test;
        final matches = await run(widget.id,
            start: _range.start,
            end: _range.end,
            accounts: _selected.toList(),
            limit: _testPageSize);
        if (mounted) setState(() => _matches = matches);
      });

  Future<void> _run() => _guard((scheduler) async {
        final report = await fireflyRuleSyncer.trigger(scheduler, widget.id,
            groups: widget.groups,
            start: _range.start,
            end: _range.end,
            accounts: _selected.toList());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((report.succeeded
                  ? 'firefly-rules-run-done'
                  : 'firefly-rules-run-sync-issues')
              .tr()),
        ));
      });

  @override
  Widget build(BuildContext context) {
    final day = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            key: const ValueKey('firefly-rule-run-range'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range_rounded),
            title: Text('firefly-rules-range'.tr()),
            subtitle: Text('${day.format(_range.start)} – '
                '${day.format(_range.end)}'),
            onTap: _pickRange,
          ),
          FutureBuilder<List<({String remoteId, String name})>>(
            future: _accounts,
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? const [];
              if (accounts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('firefly-rules-accounts'.tr(),
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('firefly-rules-accounts-hint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall),
                  Wrap(spacing: 8, children: [
                    for (final account in accounts)
                      FilterChip(
                        key: ValueKey(
                            'firefly-rule-run-account-${account.remoteId}'),
                        label: Text(account.name),
                        selected: _selected.contains(account.remoteId),
                        onSelected: (on) => setState(() => on
                            ? _selected.add(account.remoteId)
                            : _selected.remove(account.remoteId)),
                      ),
                  ]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (!_online)
            FireflyRulesOfflineBanner('firefly-rules-offline-run'.tr()),
          if (_error != null && _online)
            FireflyRulesOfflineBanner(_error!,
                key: const ValueKey('firefly-rule-run-error')),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('firefly-rule-test'),
                icon: const Icon(Icons.search_rounded),
                label: Text('firefly-rules-test'.tr()),
                onPressed: _online && !_busy ? _test : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('firefly-rule-run'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('firefly-rules-run'.tr()),
                onPressed: _online && !_busy ? _run : null,
              ),
            ),
          ]),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_matches != null) ..._matchList(_matches!, day),
        ],
      ),
    );
  }

  List<Widget> _matchList(
      FireflyPage<FireflyTransaction> page, DateFormat day) {
    final rows = [
      for (final group in page.items)
        for (final split in group.splits) (group: group, split: split),
    ];
    return [
      const SizedBox(height: 16),
      Text(
        page.total > page.items.length
            ? 'firefly-rules-matches-partial'.tr(namedArgs: {
                'shown': '${page.items.length}',
                'total': '${page.total}',
              })
            : 'firefly-rules-matches'.tr(namedArgs: {'count': '${page.total}'}),
        key: const ValueKey('firefly-rule-matches-count'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('firefly-rules-matches-empty'.tr()),
        ),
      for (final row in rows)
        ListTile(
          key: ValueKey('firefly-rule-match-${row.group.id}-'
              '${row.split.journalId}'),
          contentPadding: EdgeInsets.zero,
          title: Text(row.split.description ?? ''),
          subtitle: Text(row.split.date == null
              ? ''
              : day.format(row.split.date!.toLocal())),
          trailing: Text('${row.split.amount?.toStringAsFixed(2) ?? ''} '
                  '${row.split.currencyCode ?? ''}'
              .trim()),
        ),
    ];
  }
}

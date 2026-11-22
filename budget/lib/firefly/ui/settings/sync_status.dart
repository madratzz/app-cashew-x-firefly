import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/pages/connection/sync_issues_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflySyncStatus(BuildContext context) => const FireflySyncStatusCard();

/// Shows a sync issue message, translating engine message keys.
String fireflyIssueText(SyncIssue issue) =>
    issue.message.startsWith('firefly-') ? issue.message.tr() : issue.message;

class FireflySyncStatusCard extends StatefulWidget {
  const FireflySyncStatusCard({super.key, this.db});

  final FinanceDatabase? db;

  @override
  State<FireflySyncStatusCard> createState() => _FireflySyncStatusCardState();
}

class _FireflySyncStatusCardState extends State<FireflySyncStatusCard> {
  DateTime? _lastSync;

  FinanceDatabase get _db => widget.db ?? FireflySync.db();

  @override
  void initState() {
    super.initState();
    FireflySync.lastReport.addListener(_loadLastSync);
    FireflySync.refresh();
    _loadLastSync();
  }

  @override
  void dispose() {
    FireflySync.lastReport.removeListener(_loadLastSync);
    super.dispose();
  }

  Future<void> _loadLastSync() async {
    DateTime? value;
    try {
      value =
          await SyncMetaRepository(_db).readDate(SyncMetaRepository.lastSync);
    } catch (_) {
      value = null;
    }
    if (mounted) setState(() => _lastSync = value);
  }

  String _lastSyncText() => _lastSync == null
      ? 'firefly-sync-status-never'.tr()
      : 'firefly-sync-status-last'.tr(namedArgs: {
          'time': DateFormat.yMMMd().add_jm().format(_lastSync!.toLocal())
        });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<bool>(
          valueListenable: FireflySync.running,
          builder: (context, running, _) => ValueListenableBuilder<SyncReport?>(
            valueListenable: FireflySync.lastReport,
            builder: (context, report, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('firefly-sync-status-title'.tr(),
                          style: theme.textTheme.titleMedium),
                    ),
                    TextButton.icon(
                      onPressed: running ? null : () => FireflySync.syncNow(),
                      icon: const Icon(Icons.sync_rounded),
                      label: Text('firefly-sync-now'.tr()),
                    ),
                  ],
                ),
                Text(_lastSyncText()),
                if (running) ...[
                  const SizedBox(height: 8),
                  _Progress(stream: FireflySync.scheduler?.engine.progress),
                ] else if (report != null) ...[
                  const SizedBox(height: 8),
                  _ReportSummary(report: report),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.stream});

  final Stream<SyncProgress>? stream;

  @override
  Widget build(BuildContext context) => StreamBuilder<SyncProgress>(
        stream: stream,
        builder: (context, snapshot) {
          final phase = snapshot.data?.phase;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase == null
                  ? 'firefly-sync-status-running'.tr()
                  : 'firefly-sync-status-phase'.tr(namedArgs: {
                      'phase': 'firefly-sync-phase-${phase.name}'.tr()
                    })),
              const SizedBox(height: 6),
              const LinearProgressIndicator(),
            ],
          );
        },
      );
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final SyncReport report;

  @override
  Widget build(BuildContext context) {
    final error = TextStyle(color: Theme.of(context).colorScheme.error);
    final mismatches = report.balanceMismatches.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.issues.isEmpty)
          Text('firefly-sync-status-ok'.tr())
        else ...[
          Text(fireflyIssueText(report.issues.first), style: error),
          if (report.issues.length > 1)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const FireflySyncIssuesPage())),
              child: Text('firefly-sync-status-issues'
                  .tr(namedArgs: {'count': '${report.issues.length}'})),
            ),
        ],
        Text(
          mismatches == 0
              ? 'firefly-sync-status-parity-ok'.tr()
              : 'firefly-sync-status-parity-mismatch'
                  .tr(namedArgs: {'count': '$mismatches'}),
          style: mismatches == 0 ? null : error,
        ),
      ],
    );
  }
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/firefly/ui/settings/sync_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FireflySyncIssuesPage extends StatefulWidget {
  const FireflySyncIssuesPage({super.key, this.db});

  final FinanceDatabase? db;

  @override
  State<FireflySyncIssuesPage> createState() => _FireflySyncIssuesPageState();
}

class _FireflySyncIssuesPageState extends State<FireflySyncIssuesPage> {
  late final Future<List<FireflyIdMapping>> _records = _loadRecords();

  Future<List<FireflyIdMapping>> _loadRecords() async {
    final idMap = IdMapRepository(widget.db ?? FireflySync.db());
    return [
      for (final type in FireflyEntityType.values)
        ...await idMap.list(type, state: FireflySyncState.error),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<SyncIssue> issues =
        FireflySync.lastReport.value?.issues ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text('firefly-connection-sync-issues'.tr())),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fireflyPageMaxWidth),
          child: FutureBuilder<List<FireflyIdMapping>>(
            future: _records,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data!;
              if (issues.isEmpty && records.isEmpty) {
                return Center(child: Text('firefly-sync-issues-empty'.tr()));
              }
              return ListView(
                children: [
                  if (issues.isNotEmpty)
                    ListTile(
                        title: Text('firefly-sync-issues-last-report'.tr())),
                  for (final issue in issues)
                    ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(fireflyIssueText(issue)),
                      subtitle: issue.entityType == null
                          ? null
                          : Text(issue.entityType!.name),
                    ),
                  if (records.isNotEmpty)
                    ListTile(title: Text('firefly-sync-issues-records'.tr())),
                  for (final record in records)
                    ListTile(
                      leading: const Icon(Icons.error_outline_rounded),
                      title: Text(record.lastError ?? record.localPk),
                      subtitle:
                          Text('${record.entityType.name} · ${record.localPk}'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

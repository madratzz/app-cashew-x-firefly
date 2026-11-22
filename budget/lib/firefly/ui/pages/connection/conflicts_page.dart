import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/conflict_repository.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Writes a saved local version back with a fresh modification time, so the
/// next sync sees the row as dirty and pushes it. Returns false when the
/// snapshot cannot be restored for this entity type.
Future<bool> reapplyFireflyConflict(
    FinanceDatabase db, FireflyConflict conflict,
    {DateTime Function() now = DateTime.now}) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(conflict.localJson);
  } on FormatException {
    return false;
  }
  if (decoded is! Map<String, Object?>) return false;
  final json = {...decoded, 'dateTimeModified': now().millisecondsSinceEpoch};
  try {
    switch (conflict.entityType) {
      case FireflyEntityType.walletAccount:
      case FireflyEntityType.liabilityAccount:
        await db
            .into(db.wallets)
            .insertOnConflictUpdate(TransactionWallet.fromJson(json));
      case FireflyEntityType.category:
        await db
            .into(db.categories)
            .insertOnConflictUpdate(TransactionCategory.fromJson(json));
      case FireflyEntityType.transaction:
        await db
            .into(db.transactions)
            .insertOnConflictUpdate(Transaction.fromJson(json));
      default:
        return false;
    }
  } catch (_) {
    return false;
  }
  return true;
}

class FireflyConflictsPage extends StatelessWidget {
  const FireflyConflictsPage({super.key, this.db});

  final FinanceDatabase? db;

  @override
  Widget build(BuildContext context) {
    final database = db ?? FireflySync.db();
    final conflicts = ConflictRepository(database);
    return Scaffold(
      appBar: AppBar(title: Text('firefly-connection-conflicts'.tr())),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fireflyPageMaxWidth),
          child: StreamBuilder<List<FireflyConflict>>(
            stream: conflicts.watch(unacknowledgedOnly: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return Center(child: Text('firefly-conflicts-empty'.tr()));
              }
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('firefly-conflicts-description'.tr()),
                  ),
                  for (final conflict in rows)
                    _ConflictTile(
                        db: database, conflicts: conflicts, conflict: conflict),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile(
      {required this.db, required this.conflicts, required this.conflict});

  final FinanceDatabase db;
  final ConflictRepository conflicts;
  final FireflyConflict conflict;

  String _title() {
    try {
      final json = jsonDecode(conflict.localJson);
      if (json is Map && json['name'] is String) return json['name'] as String;
      if (json is Map && json['title'] is String) {
        return json['title'] as String;
      }
    } on FormatException {
      // Fall through to the key.
    }
    return conflict.localPk;
  }

  Future<void> _reapply(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await db.transaction(() async {
      final applied = await reapplyFireflyConflict(db, conflict);
      if (applied) await conflicts.acknowledge(conflict.conflictPk);
      return applied;
    });
    messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? 'firefly-conflicts-reapplied'.tr()
            : 'firefly-conflicts-reapply-unsupported'.tr())));
  }

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(_title()),
        subtitle: Text('${conflict.entityType.name} · ${conflict.resolution} · '
            '${DateFormat.yMMMd().add_jm().format(conflict.dateCreated)}'),
        isThreeLine: false,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'firefly-conflicts-reapply'.tr(),
              icon: const Icon(Icons.restore_rounded),
              onPressed: () => _reapply(context),
            ),
            IconButton(
              tooltip: 'firefly-conflicts-dismiss'.tr(),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => conflicts.acknowledge(conflict.conflictPk),
            ),
          ],
        ),
      );
}

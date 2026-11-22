import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/piggy_bank.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FireflyObjectGroupLabel extends StatelessWidget {
  const FireflyObjectGroupLabel({required this.attributes, super.key});

  final JsonObject attributes;

  @override
  Widget build(BuildContext context) {
    final title = attributes['object_group_title'];
    if (title is! String || title.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      'firefly-object-group-label'.tr(namedArgs: {'title': title}),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class FireflyPiggyBankObjectGroupLabel extends StatefulWidget {
  const FireflyPiggyBankObjectGroupLabel({
    required this.db,
    required this.objectivePk,
    super.key,
  });

  final FinanceDatabase db;
  final String objectivePk;

  @override
  State<FireflyPiggyBankObjectGroupLabel> createState() =>
      _FireflyPiggyBankObjectGroupLabelState();
}

class _FireflyPiggyBankObjectGroupLabelState
    extends State<FireflyPiggyBankObjectGroupLabel> {
  late Stream<FireflyPiggyBank?> _bank = _watchBank();

  @override
  void didUpdateWidget(FireflyPiggyBankObjectGroupLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.db != widget.db ||
        oldWidget.objectivePk != widget.objectivePk) {
      _bank = _watchBank();
    }
  }

  Stream<FireflyPiggyBank?> _watchBank() async* {
    final db = widget.db;
    final objectivePk = widget.objectivePk;
    Future<FireflyPiggyBank?> readBank() async {
      final mapping = await db.fireflyPiggyBankMapping(objectivePk);
      if (mapping == null) return null;
      final row = await ResourceCacheRepository(db)
          .read(FireflyEntityType.piggyBank, mapping.remoteId);
      return row == null
          ? null
          : FireflyPiggyBank.fromJson(ResourceCacheRepository.decode(row));
    }

    yield await readBank();
    await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables(
        [db.fireflyResourceCache, db.fireflyIdMap, db.objectives]))) {
      yield await readBank();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<FireflyPiggyBank?>(
        stream: _bank,
        builder: (context, snapshot) {
          final bank = snapshot.data;
          return bank == null
              ? const SizedBox.shrink()
              : FireflyObjectGroupLabel(attributes: bank.attributes);
        },
      );
}

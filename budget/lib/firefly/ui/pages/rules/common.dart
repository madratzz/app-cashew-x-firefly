import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/sync/entities/rule_syncer.dart';
import 'package:budget/firefly/sync/scheduler.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const fireflyRuleSyncer = RuleSyncer();

/// Returns the running scheduler, or null with Firefly mode off.
typedef FireflyRulesSchedulerProvider = Future<SyncScheduler?> Function();

FinanceDatabase fireflyRulesDb(FinanceDatabase? db) => db ?? database;

/// Stock Firefly III 6.6.2 lists these in its OpenAPI catalog but rejects
/// them on write. Existing rules still show them.
const fireflyUnwritableActions = {
  'user_action',
  'append_description',
  'prepend_description',
  'append_notes',
  'prepend_notes',
};

const fireflyValuelessTriggers = {
  'has_attachments',
  'has_no_category',
  'has_any_category',
  'has_no_budget',
  'has_any_budget',
  'has_no_tag',
  'has_any_tag',
  'no_notes',
  'any_notes',
};

const fireflyValuelessActions = {
  'clear_category',
  'clear_budget',
  'remove_all_tags',
  'clear_notes',
  'delete_transaction',
};

/// The convert actions take an optional account name.
const fireflyOptionalValueActions = {
  'convert_withdrawal',
  'convert_deposit',
  'convert_transfer',
};

FireflyRule fireflyRuleFromRow(FireflyCachedResource row) =>
    FireflyRule.fromJson(ResourceCacheRepository.decode(row));

FireflyRuleGroup fireflyRuleGroupFromRow(FireflyCachedResource row) =>
    FireflyRuleGroup.fromJson(ResourceCacheRepository.decode(row));

/// Keywords the server sends that this app does not know show as is.
String fireflyRuleKeywordLabel(String keyword, {required bool trigger}) {
  final known = trigger
      ? FireflyRule.triggerKeywords.contains(keyword)
      : FireflyRule.actionKeywords.contains(keyword);
  if (!known) return keyword;
  return 'firefly-rules-${trigger ? 'trigger' : 'action'}-$keyword'.tr();
}

String fireflyRuleTriggerTypeLabel(String type) =>
    FireflyRule.triggerTypes.contains(type)
        ? 'firefly-rules-when-$type'.tr()
        : type;

/// Finds the scheduler and checks that the server answers. Null means
/// offline: the cached rules stay readable but nothing can be sent.
Future<SyncScheduler?> fireflyRulesOnline(
    FireflyRulesSchedulerProvider? provider) async {
  try {
    final scheduler = await (provider ?? fireflySchedulerIfEnabled)();
    if (scheduler == null) return null;
    await scheduler.engine.context.api.about.get();
    return scheduler;
  } on FireflyException {
    return null;
  }
}

bool fireflyIsConnectionError(Object error) =>
    error is FireflyNetworkError ||
    error is FireflyTimeout ||
    error is FireflyTransportUnavailable;

String fireflyRulesErrorMessage(Object error) {
  if (fireflyIsConnectionError(error)) return 'firefly-rules-offline'.tr();
  if (error is FireflyValidation) {
    final details = error.errors.values.expand((list) => list).join(' ');
    return 'firefly-rules-rejected'.tr(namedArgs: {
      'message': details.isEmpty ? error.message : details,
    });
  }
  return 'firefly-rules-failed'.tr();
}

/// Asset and liability wallets with a Firefly id, for the run filter.
Future<List<({String remoteId, String name})>> fireflyRuleAccounts(
    FinanceDatabase db) async {
  final repository = IdMapRepository(db);
  final mappings = [
    ...await repository.list(FireflyEntityType.walletAccount),
    ...await repository.list(FireflyEntityType.liabilityAccount),
  ];
  final wallets = {
    for (final wallet in await db.select(db.wallets).get())
      wallet.walletPk: wallet.name,
  };
  return [
    for (final mapping in mappings)
      if (wallets[mapping.localPk] != null)
        (remoteId: mapping.remoteId, name: wallets[mapping.localPk]!),
  ]..sort((a, b) => a.name.compareTo(b.name));
}

class FireflyRulesOfflineBanner extends StatelessWidget {
  const FireflyRulesOfflineBanner(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('firefly-rules-offline'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
        ),
        if (onRetry != null)
          TextButton(
            key: const ValueKey('firefly-rules-retry'),
            onPressed: onRetry,
            child: Text('firefly-rules-retry'.tr()),
          ),
      ]),
    );
  }
}

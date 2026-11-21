import 'package:budget/database/tables.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/settings/connection_entry.dart';
import 'package:budget/firefly/ui/settings/sync_status.dart';
import 'package:budget/firefly/ui/transaction/payee_section.dart';
import 'package:budget/firefly/ui/transaction/tags_section.dart';
import 'package:budget/firefly/ui/transaction/budget_section.dart';
import 'package:budget/firefly/ui/transaction/bill_section.dart';
import 'package:budget/firefly/ui/transaction/piggy_section.dart';
import 'package:budget/firefly/ui/transaction/split_section.dart';
import 'package:budget/firefly/ui/transaction/foreign_amount_section.dart';
import 'package:budget/firefly/ui/transaction/attachments_section.dart';
import 'package:budget/firefly/ui/entry/payee_chip.dart';
import 'package:budget/firefly/ui/entry/tags_chip.dart';
import 'package:budget/firefly/ui/entry/split_chip.dart';
import 'package:budget/firefly/ui/entry/foreign_amount_chip.dart';
import 'package:budget/firefly/ui/entry/attachment_chip.dart';
import 'package:budget/firefly/ui/wallet/account_details_section.dart';
import 'package:budget/firefly/ui/hub/bills_entry.dart';
import 'package:budget/firefly/ui/hub/recurrences_entry.dart';
import 'package:budget/firefly/ui/hub/payees_entry.dart';
import 'package:budget/firefly/ui/hub/tags_entry.dart';
import 'package:budget/firefly/ui/hub/liabilities_entry.dart';
import 'package:budget/firefly/ui/hub/currencies_entry.dart';
import 'package:budget/firefly/ui/hub/rules_entry.dart';
import 'package:budget/firefly/ui/hub/links_entry.dart';
import 'package:flutter/widgets.dart';

const fireflyTransactionSections =
    <Widget Function(BuildContext, FireflyTransactionDraft)>[
  fireflyPayeeSection,
  fireflyTagsSection,
  fireflyBudgetSection,
  fireflyBillSection,
  fireflyPiggySection,
  fireflySplitSection,
  fireflyForeignAmountSection,
  fireflyAttachmentsSection,
];

const fireflyTransactionChips = <Widget Function(BuildContext, Transaction)>[
  fireflyPayeeChip,
  fireflyTagsChip,
  fireflySplitChip,
  fireflyForeignAmountChip,
  fireflyAttachmentChip,
];

const fireflyWalletSections = <Widget Function(BuildContext, String?)>[
  fireflyAccountDetailsSection,
];

const fireflyHubEntries = <Widget Function(BuildContext)>[
  fireflyBillsEntry,
  fireflyRecurrencesEntry,
  fireflyPayeesEntry,
  fireflyTagsEntry,
  fireflyLiabilitiesEntry,
  fireflyCurrenciesEntry,
  fireflyRulesEntry,
  fireflyLinksEntry,
];

class FireflyTransactionExtras extends StatelessWidget {
  const FireflyTransactionExtras({required this.draft, super.key});

  final FireflyTransactionDraft draft;

  @override
  Widget build(BuildContext context) {
    if (!FireflyMode.enabled) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final build in fireflyTransactionSections) build(context, draft)
      ],
    );
  }
}

class FireflyTransactionEntryExtras extends StatelessWidget {
  const FireflyTransactionEntryExtras({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    if (!FireflyMode.enabled) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final build in fireflyTransactionChips) build(context, transaction)
      ],
    );
  }
}

class FireflyWalletExtras extends StatelessWidget {
  const FireflyWalletExtras({required this.walletPk, super.key});

  final String? walletPk;

  @override
  Widget build(BuildContext context) {
    if (!FireflyMode.enabled) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final build in fireflyWalletSections) build(context, walletPk)
      ],
    );
  }
}

class FireflyHubSection extends StatelessWidget {
  const FireflyHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FireflyMode.enabled) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final build in fireflyHubEntries) build(context)],
    );
  }
}

class FireflySettingsEntry extends StatelessWidget {
  const FireflySettingsEntry({super.key});

  @override
  Widget build(BuildContext context) => FireflyMode.available
      ? fireflyConnectionEntry(context)
      : const SizedBox.shrink();
}

class FireflySyncStatus extends StatelessWidget {
  const FireflySyncStatus({super.key});

  @override
  Widget build(BuildContext context) => FireflyMode.enabled
      ? fireflySyncStatus(context)
      : const SizedBox.shrink();
}

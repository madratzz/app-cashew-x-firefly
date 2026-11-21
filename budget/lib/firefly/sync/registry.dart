import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/contributors/attachments_contributor.dart';
import 'package:budget/firefly/sync/contributors/bill_contributor.dart';
import 'package:budget/firefly/sync/contributors/budget_contributor.dart';
import 'package:budget/firefly/sync/contributors/foreign_currency_contributor.dart';
import 'package:budget/firefly/sync/contributors/payee_contributor.dart';
import 'package:budget/firefly/sync/contributors/piggy_bank_contributor.dart';
import 'package:budget/firefly/sync/contributors/split_group_contributor.dart';
import 'package:budget/firefly/sync/contributors/tags_contributor.dart';
import 'package:budget/firefly/sync/entities/attachment_syncer.dart';
import 'package:budget/firefly/sync/entities/bill_syncer.dart';
import 'package:budget/firefly/sync/entities/budget_limit_syncer.dart';
import 'package:budget/firefly/sync/entities/budget_syncer.dart';
import 'package:budget/firefly/sync/entities/category_syncer.dart';
import 'package:budget/firefly/sync/entities/currency_syncer.dart';
import 'package:budget/firefly/sync/entities/liability_account_syncer.dart';
import 'package:budget/firefly/sync/entities/object_group_syncer.dart';
import 'package:budget/firefly/sync/entities/payee_account_syncer.dart';
import 'package:budget/firefly/sync/entities/piggy_bank_syncer.dart';
import 'package:budget/firefly/sync/entities/recurrence_syncer.dart';
import 'package:budget/firefly/sync/entities/rule_syncer.dart';
import 'package:budget/firefly/sync/entities/tag_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_link_syncer.dart';
import 'package:budget/firefly/sync/entities/transaction_syncer.dart';
import 'package:budget/firefly/sync/entities/wallet_account_syncer.dart';

/// Pull and push in order. Push deletions in reverse order.
const entitySyncers = <EntitySyncer>[
  CurrencySyncer(),
  WalletAccountSyncer(),
  LiabilityAccountSyncer(),
  PayeeAccountSyncer(),
  CategorySyncer(),
  TagSyncer(),
  BudgetSyncer(),
  BudgetLimitSyncer(),
  BillSyncer(),
  PiggyBankSyncer(),
  RecurrenceSyncer(),
  TransactionSyncer(),
  AttachmentSyncer(),
  ObjectGroupSyncer(),
  TransactionLinkSyncer(),
  RuleSyncer(),
];

const transactionContributors = <TransactionContributor>[
  PayeeContributor(),
  TagsContributor(),
  BudgetContributor(),
  BillContributor(),
  PiggyBankContributor(),
  SplitGroupContributor(),
  ForeignCurrencyContributor(),
  AttachmentsContributor(),
];

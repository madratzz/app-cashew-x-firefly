import 'package:budget/firefly/api/resources/about_api.dart';
import 'package:budget/firefly/api/resources/accounts_api.dart';
import 'package:budget/firefly/api/resources/attachments_api.dart';
import 'package:budget/firefly/api/resources/bills_api.dart';
import 'package:budget/firefly/api/resources/budgets_api.dart';
import 'package:budget/firefly/api/resources/categories_api.dart';
import 'package:budget/firefly/api/resources/currencies_api.dart';
import 'package:budget/firefly/api/resources/exchange_rates_api.dart';
import 'package:budget/firefly/api/resources/object_groups_api.dart';
import 'package:budget/firefly/api/resources/piggy_banks_api.dart';
import 'package:budget/firefly/api/resources/preferences_api.dart';
import 'package:budget/firefly/api/resources/recurrences_api.dart';
import 'package:budget/firefly/api/resources/rules_api.dart';
import 'package:budget/firefly/api/resources/search_api.dart';
import 'package:budget/firefly/api/resources/tags_api.dart';
import 'package:budget/firefly/api/resources/transaction_links_api.dart';
import 'package:budget/firefly/api/resources/transactions_api.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyApi {
  FireflyApi(this.transport)
      : about = AboutApi(transport),
        accounts = AccountsApi(transport),
        attachments = AttachmentsApi(transport),
        bills = BillsApi(transport),
        budgets = BudgetsApi(transport),
        categories = CategoriesApi(transport),
        currencies = CurrenciesApi(transport),
        exchangeRates = ExchangeRatesApi(transport),
        objectGroups = ObjectGroupsApi(transport),
        piggyBanks = PiggyBanksApi(transport),
        preferences = PreferencesApi(transport),
        recurrences = RecurrencesApi(transport),
        rules = RulesApi(transport),
        search = SearchApi(transport),
        tags = TagsApi(transport),
        transactionLinks = TransactionLinksApi(transport),
        transactions = TransactionsApi(transport);

  final FireflyTransport transport;
  final AboutApi about;
  final AccountsApi accounts;
  final AttachmentsApi attachments;
  final BillsApi bills;
  final BudgetsApi budgets;
  final CategoriesApi categories;
  final CurrenciesApi currencies;
  final ExchangeRatesApi exchangeRates;
  final ObjectGroupsApi objectGroups;
  final PiggyBanksApi piggyBanks;
  final PreferencesApi preferences;
  final RecurrencesApi recurrences;
  final RulesApi rules;
  final SearchApi search;
  final TagsApi tags;
  final TransactionLinksApi transactionLinks;
  final TransactionsApi transactions;
}

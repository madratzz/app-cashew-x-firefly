import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/wallet/account_details_form.dart';
import 'package:budget/struct/databaseGlobal.dart' as global;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyAccountDetailsSection(BuildContext context, String? walletPk) =>
    walletPk == null
        ? const SizedBox.shrink()
        : FireflyAccountDetailsSection(walletPk: walletPk);

/// Whether the virtual balance can be written for this wallet now.
Future<bool> fireflyVirtualBalanceEditable(
    FinanceDatabase db, TransactionWallet wallet) async {
  if (wallet.accountKind == AccountKind.asset) return true;
  if (wallet.accountKind != AccountKind.liability) return false;
  final mapping = await IdMapRepository(db)
      .byLocal(FireflyEntityType.liabilityAccount, wallet.walletPk);
  return mapping != null && !IdMapRepository.isProvisional(mapping);
}

class FireflyAccountDetailsSection extends StatefulWidget {
  const FireflyAccountDetailsSection(
      {super.key, required this.walletPk, this.db});

  final String walletPk;
  final FinanceDatabase? db;

  @override
  State<FireflyAccountDetailsSection> createState() =>
      _FireflyAccountDetailsSectionState();
}

class _FireflyAccountDetailsSectionState
    extends State<FireflyAccountDetailsSection> {
  late final FinanceDatabase _db = widget.db ?? global.database;
  final _form = GlobalKey<FireflyAccountDetailsFormState>();
  late final Future<(TransactionWallet?, AccountDetail?, bool)> _load =
      () async {
    final wallet = await _db.fireflyWallet(widget.walletPk);
    if (wallet == null) return (null, null, false);
    return (
      wallet,
      await _db.fireflyAccountDetails(widget.walletPk),
      await fireflyVirtualBalanceEditable(_db, wallet),
    );
  }();
  String? _message;

  Future<void> _save() async {
    final form = _form.currentState!;
    final invalid = form.validate();
    if (invalid != null) return setState(() => _message = invalid);
    await _db.saveFireflyAccountDetails(widget.walletPk, form.changes());
    if (mounted) {
      setState(() => _message = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('firefly-liabilities-details-saved'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _load,
        builder: (context, snapshot) {
          final (wallet, details, virtualEditable) =
              snapshot.data ?? (null, null, false);
          if (wallet == null || wallet.accountKind == AccountKind.cash) {
            return const SizedBox.shrink();
          }
          return Padding(
            key: const ValueKey('firefly-account-details'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('firefly-liabilities-details-title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium),
                if (_message != null) FireflyErrorBanner(_message!),
                FireflyAccountDetailsForm(
                  key: _form,
                  kind: wallet.accountKind,
                  details: details,
                  virtualBalanceEditable: virtualEditable,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonal(
                    key: const ValueKey('firefly-account-details-save'),
                    onPressed: _save,
                    child: Text('firefly-liabilities-details-save'.tr()),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/liability_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/ui/pages/bills/common.dart';
import 'package:budget/firefly/ui/wallet/account_details_form.dart';
import 'package:budget/firefly/ui/wallet/account_details_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String fireflyLiabilityTypeLabel(String? value) =>
    fireflyLiabilityLabel('type', value);

String fireflyLiabilityPeriodLabel(String? value) =>
    fireflyLiabilityLabel('period', value);

class FireflyLiabilityEditorPage extends StatefulWidget {
  const FireflyLiabilityEditorPage(
      {super.key, required this.db, this.wallet, this.pushNow});

  final FinanceDatabase db;

  /// Null creates a liability.
  final TransactionWallet? wallet;
  final FireflyPushNow? pushNow;

  @override
  State<FireflyLiabilityEditorPage> createState() =>
      _FireflyLiabilityEditorPageState();
}

class _FireflyLiabilityEditorPageState
    extends State<FireflyLiabilityEditorPage> {
  TransactionWallet? get _wallet => widget.wallet;
  final _form = GlobalKey<FireflyAccountDetailsFormState>();
  late final _name = TextEditingController(text: _wallet?.name ?? '');
  late final _currency =
      TextEditingController(text: _wallet?.currency?.toUpperCase() ?? '');
  late final _decimals =
      TextEditingController(text: (_wallet?.decimals ?? 2).toString());
  late bool _archived = _wallet?.archived ?? false;
  late final Future<(AccountDetail?, bool)> _load = () async {
    final wallet = _wallet;
    if (wallet == null) return (null, false);
    return (
      await widget.db.fireflyAccountDetails(wallet.walletPk),
      await fireflyVirtualBalanceEditable(widget.db, wallet),
    );
  }();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pk = _wallet?.walletPk;
    if (pk != null) {
      fireflyRejection(widget.db, FireflyEntityType.liabilityAccount, pk)
          .then((message) {
        if (mounted && message != null) setState(() => _error = message);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    _decimals.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final currency = _currency.text.trim();
    final decimals = int.tryParse(_decimals.text.trim());
    final invalid = name.isEmpty
        ? 'firefly-liabilities-name-required'.tr()
        : currency.isEmpty
            ? 'firefly-liabilities-currency-required'.tr()
            : decimals == null || decimals < 0
                ? 'firefly-liabilities-number-invalid'.tr()
                : _form.currentState!.validate();
    if (invalid != null) return setState(() => _error = invalid);
    setState(() => _saving = true);
    final order = _wallet?.order ??
        (await widget.db.select(widget.db.wallets).get())
                .fold<int>(-1, (max, w) => w.order > max ? w.order : max) +
            1;
    final saved = await widget.db.saveFireflyLiability(
      walletPk: _wallet?.walletPk,
      name: name,
      currency: currency,
      decimals: decimals!,
      order: order,
      archived: _archived,
      details: _form.currentState!.changes(),
    );
    await (widget.pushNow ?? defaultFireflyPushNow)();
    final rejected = await fireflyRejection(
        widget.db, FireflyEntityType.liabilityAccount, saved.walletPk);
    if (!mounted) return;
    setState(() => _saving = false);
    if (rejected != null) {
      return setState(() => _error =
          'firefly-liabilities-rejected'.tr(namedArgs: {'message': rejected}));
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.db.deleteWalletLocally(_wallet!.walletPk);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text((_wallet == null
                  ? 'firefly-liabilities-new'
                  : 'firefly-liabilities-edit')
              .tr()),
          actions: [
            if (_wallet != null)
              IconButton(
                key: const ValueKey('firefly-liability-delete'),
                tooltip: 'firefly-liabilities-delete'.tr(),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _delete,
              ),
          ],
        ),
        body: FutureBuilder(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final (details, virtualEditable) = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) FireflyErrorBanner(_error!),
                TextField(
                  key: const ValueKey('firefly-liability-name'),
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: 'firefly-liabilities-name'.tr()),
                ),
                TextField(
                  key: const ValueKey('firefly-liability-currency'),
                  controller: _currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                      labelText: 'firefly-liabilities-currency'.tr()),
                ),
                TextField(
                  key: const ValueKey('firefly-liability-decimals'),
                  controller: _decimals,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'firefly-liabilities-decimals'.tr()),
                ),
                FireflyAccountDetailsForm(
                  key: _form,
                  kind: AccountKind.liability,
                  details: details,
                  creating: _wallet == null,
                  virtualBalanceEditable: virtualEditable,
                ),
                SwitchListTile(
                  key: const ValueKey('firefly-liability-archived'),
                  contentPadding: EdgeInsets.zero,
                  title: Text('firefly-liabilities-archive'.tr()),
                  value: _archived,
                  onChanged: (value) => setState(() => _archived = value),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('firefly-liability-save'),
                  onPressed: _saving ? null : _save,
                  child: Text('firefly-liabilities-save'.tr()),
                ),
              ],
            );
          },
        ),
      );
}

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/currency_syncer.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<SyncContext?> _schedulerContext() async =>
    (await fireflySchedulerIfEnabled())?.engine.context;

/// Server currencies: enable or disable them, pick the primary currency and
/// choose whether Cashew's exchange rates come from the server.
class FireflyCurrenciesPage extends StatefulWidget {
  const FireflyCurrenciesPage({
    super.key,
    this.db,
    this.currencies,
    this.syncContext,
    this.syncer = const CurrencySyncer(),
    this.serverRates,
    this.setServerRates,
  });

  final FinanceDatabase? db;

  /// Defaults to the server currency cache in [db].
  final Stream<List<FireflyCachedCurrency>>? currencies;
  final Future<SyncContext?> Function()? syncContext;
  final CurrencySyncer syncer;

  /// Reads and writes the server exchange rate switch; defaults to settings.
  final bool Function()? serverRates;
  final Future<void> Function(bool)? setServerRates;

  @override
  State<FireflyCurrenciesPage> createState() => FireflyCurrenciesPageState();
}

class FireflyCurrenciesPageState extends State<FireflyCurrenciesPage> {
  late final Stream<List<FireflyCachedCurrency>> _currencies =
      widget.currencies ?? (widget.db ?? database).watchFireflyCurrencies();
  final Set<String> _busy = {};

  bool get _serverRates =>
      widget.serverRates?.call() ??
      appStateSettings[fireflyExchangeRatesSetting] == true;

  Future<void> _setServerRates(bool value) async {
    if (widget.setServerRates != null) {
      await widget.setServerRates!(value);
    } else {
      await updateSettings(fireflyExchangeRatesSetting, value,
          updateGlobalState: false);
      await getExchangeRates();
    }
    if (mounted) setState(() {});
  }

  Future<void> _run(
      String code, Future<void> Function(SyncContext) action) async {
    setState(() => _busy.add(code));
    try {
      final sync = await (widget.syncContext ?? _schedulerContext)();
      if (sync == null) throw StateError('Firefly mode is off');
      await action(sync);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('firefly-currencies-action-failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('firefly-currencies-title'.tr())),
      body: StreamBuilder<List<FireflyCachedCurrency>>(
        stream: _currencies,
        builder: (context, snapshot) {
          final currencies = snapshot.data ?? const [];
          return ListView(
            children: [
              SwitchListTile(
                key: const ValueKey('firefly-currencies-server-rates'),
                title: Text('firefly-currencies-server-rates'.tr()),
                subtitle:
                    Text('firefly-currencies-server-rates-description'.tr()),
                value: _serverRates,
                onChanged: _setServerRates,
              ),
              const Divider(),
              if (snapshot.hasData && currencies.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('firefly-currencies-empty'.tr(),
                      textAlign: TextAlign.center),
                ),
              for (final currency in currencies) _tile(currency),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(FireflyCachedCurrency currency) {
    final code = currency.code!;
    final primary = currency.primary == true;
    final busy = _busy.contains(code);
    final name = currency.attributes['name'] as String?;
    final custom = currenciesJSON.isNotEmpty && currenciesJSON[code] == null;
    return ListTile(
      key: ValueKey('firefly-currency-$code'),
      leading: IconButton(
        key: ValueKey('firefly-currency-primary-$code'),
        tooltip: primary
            ? 'firefly-currencies-primary'.tr()
            : 'firefly-currencies-set-primary'.tr(),
        icon: Icon(primary ? Icons.star_rounded : Icons.star_border_rounded),
        onPressed: primary || busy
            ? null
            : () => _run(code, (sync) => widget.syncer.setPrimary(sync, code)),
      ),
      title: Text([
        code.toUpperCase(),
        if (currency.symbol?.isNotEmpty == true) currency.symbol!,
      ].join('  ')),
      subtitle: Text([
        if (name?.isNotEmpty == true) name!,
        if (primary) 'firefly-currencies-primary'.tr(),
        if (custom) 'firefly-currencies-custom'.tr(),
      ].join(' · ')),
      trailing: Switch(
        key: ValueKey('firefly-currency-enabled-$code'),
        value: currency.enabled != false,
        // The server refuses to disable its primary currency
        onChanged: primary || busy
            ? null
            : (enabled) => _run(
                code,
                (sync) =>
                    widget.syncer.setEnabled(sync, code, enabled: enabled)),
      ),
    );
  }
}

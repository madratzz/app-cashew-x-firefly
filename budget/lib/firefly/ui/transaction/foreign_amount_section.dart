import 'package:budget/firefly/db/currency_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyForeignAmountSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyForeignAmountSection(draft: draft);

/// Edits the draft's foreign amount and currency. Both are kept or cleared
/// together, because Firefly III rejects one without the other.
class FireflyForeignAmountSection extends StatefulWidget {
  const FireflyForeignAmountSection(
      {required this.draft, this.currencies, super.key});

  final FireflyTransactionDraft draft;

  /// Defaults to the server currency cache.
  final Stream<List<FireflyCachedCurrency>>? currencies;

  @override
  State<FireflyForeignAmountSection> createState() =>
      _FireflyForeignAmountSectionState();
}

class _FireflyForeignAmountSectionState
    extends State<FireflyForeignAmountSection> {
  late final TextEditingController _amount =
      TextEditingController(text: _format(widget.draft.foreignAmount));
  late final Stream<List<FireflyCachedCurrency>> _currencies =
      widget.currencies ?? widget.draft.db.watchFireflyCurrencies();
  String? _currency;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _currency = widget.draft.foreignCurrency?.trim().toLowerCase();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  static String _format(double? amount) {
    if (amount == null) return '';
    final text = amount.abs().toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  void _apply() {
    final text = _amount.text.trim().replaceAll(',', '.');
    final amount = text.isEmpty ? null : double.tryParse(text);
    final invalid = text.isNotEmpty && (amount == null || amount <= 0);
    final complete = !invalid && amount != null && _currency != null;
    widget.draft
      ..foreignAmount = complete ? amount : null
      ..foreignCurrency = complete ? _currency : null;
    if (invalid != _invalid) setState(() => _invalid = invalid);
  }

  void _clear() {
    _amount.clear();
    setState(() {
      _currency = null;
      _invalid = false;
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: StreamBuilder<List<FireflyCachedCurrency>>(
        stream: _currencies,
        builder: (context, snapshot) {
          final codes = <String>{
            for (final currency
                in snapshot.data ?? const <FireflyCachedCurrency>[])
              if (currency.enabled != false) currency.code!,
            if (_currency != null) _currency!,
          }.toList()
            ..sort();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('firefly-foreign-amount-field'),
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'firefly-foreign-amount'.tr(),
                    errorText:
                        _invalid ? 'firefly-foreign-amount-invalid'.tr() : null,
                  ),
                  onChanged: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('firefly-foreign-currency-field'),
                  value: _currency,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: 'firefly-foreign-currency'.tr()),
                  items: [
                    for (final code in codes)
                      DropdownMenuItem(
                          value: code, child: Text(code.toUpperCase())),
                  ],
                  onChanged: (code) {
                    setState(() => _currency = code);
                    _apply();
                  },
                ),
              ),
              IconButton(
                key: const ValueKey('firefly-foreign-amount-clear'),
                tooltip: 'firefly-foreign-amount-clear'.tr(),
                icon: const Icon(Icons.clear_rounded),
                onPressed: _clear,
              ),
            ],
          );
        },
      ),
    );
  }
}

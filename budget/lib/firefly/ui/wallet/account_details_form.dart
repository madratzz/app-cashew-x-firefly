import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Roles a user may pick for an asset. `ccAsset` needs credit card metadata
/// the schema does not hold, so an existing one is shown read-only.
const fireflyAssetRoles = [
  'defaultAsset',
  'sharedAsset',
  'savingAsset',
  'cashWalletAsset',
];
const fireflyLiabilityTypes = ['loan', 'debt', 'mortgage'];
const fireflyLiabilityDirections = ['credit', 'debit'];
const fireflyInterestPeriods = ['daily', 'monthly', 'yearly'];

String fireflyLiabilityLabel(String group, String? value) {
  if (value == null) return '';
  final key = 'firefly-liabilities-$group-$value';
  final label = key.tr();
  return label == key ? value : label;
}

/// Editable Firefly account fields shared by the wallet section and the
/// liability editor. Read [FireflyAccountDetailsFormState.changes] to save.
class FireflyAccountDetailsForm extends StatefulWidget {
  const FireflyAccountDetailsForm({
    super.key,
    required this.kind,
    this.details,
    this.virtualBalanceEditable = false,
    this.creating = false,
  });

  final AccountKind kind;
  final AccountDetail? details;

  /// Firefly 6.6.2 keeps a liability's virtual balance only on PUT.
  final bool virtualBalanceEditable;

  /// A liability being created: fields the server ignores are omitted.
  final bool creating;

  @override
  State<FireflyAccountDetailsForm> createState() =>
      FireflyAccountDetailsFormState();
}

class FireflyAccountDetailsFormState extends State<FireflyAccountDetailsForm> {
  AccountDetail? get _old => widget.details;
  bool get _liability => widget.kind == AccountKind.liability;

  late String? _role = _old?.accountRole;
  late String _type = _old?.liabilityType ?? fireflyLiabilityTypes.first;
  late String _direction =
      _old?.liabilityDirection ?? fireflyLiabilityDirections.first;
  late String? _period = _old?.interestPeriod ??
      (widget.creating ? fireflyInterestPeriods[1] : null);
  late bool _netWorth = _old?.includeNetWorth ?? true;
  late final _interest = TextEditingController(text: _number(_old?.interest));
  late final _virtual =
      TextEditingController(text: _number(_old?.virtualBalance));
  late final _iban = TextEditingController(text: _old?.iban ?? '');
  late final _bic = TextEditingController(text: _old?.bic ?? '');
  late final _account = TextEditingController(text: _old?.accountNumber ?? '');
  late final _notes = TextEditingController(text: _old?.notes ?? '');

  static String _number(double? value) =>
      value == null ? '' : value.toString().replaceFirst(RegExp(r'\.0$'), '');

  @override
  void dispose() {
    for (final controller in [
      _interest,
      _virtual,
      _iban,
      _bic,
      _account,
      _notes
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Returns null and shows the field error when a number does not parse.
  String? validate() {
    for (final controller in [_interest, if (_virtualShown) _virtual]) {
      final text = controller.text.trim();
      if (text.isNotEmpty && double.tryParse(text) == null) {
        return 'firefly-liabilities-number-invalid'.tr();
      }
    }
    return null;
  }

  bool get _virtualShown =>
      !(_liability && widget.creating) &&
      (widget.virtualBalanceEditable || _old?.virtualBalance != null);

  /// Only fields that differ from the stored row, so an edit cannot clobber
  /// values the user did not touch.
  AccountDetailsCompanion changes() {
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    double? number(TextEditingController c) => double.tryParse(c.text.trim());
    Value<T> diff<T>(T value, T old) =>
        widget.details == null && value == null || value == old
            ? const Value.absent()
            : Value(value);
    return AccountDetailsCompanion(
      accountRole: _liability || _role == 'ccAsset'
          ? const Value.absent()
          : diff(_role, _old?.accountRole),
      liabilityType: _liability
          ? diff<String?>(_type, _old?.liabilityType)
          : const Value.absent(),
      liabilityDirection: _liability
          ? diff<String?>(_direction, _old?.liabilityDirection)
          : const Value.absent(),
      interest: _liability
          ? diff(number(_interest), _old?.interest)
          : const Value.absent(),
      interestPeriod: _liability
          ? diff(_period, _old?.interestPeriod)
          : const Value.absent(),
      iban: diff(text(_iban), _old?.iban),
      bic: diff(text(_bic), _old?.bic),
      accountNumber: diff(text(_account), _old?.accountNumber),
      notes: diff(text(_notes), _old?.notes),
      includeNetWorth: _netWorth == (_old?.includeNetWorth ?? true)
          ? const Value.absent()
          : Value(_netWorth),
      virtualBalance: widget.virtualBalanceEditable && _virtualShown
          ? diff(number(_virtual), _old?.virtualBalance)
          : const Value.absent(),
    );
  }

  Widget _field(String key, TextEditingController controller,
          {bool number = false, int maxLines = 1, bool enabled = true}) =>
      TextField(
        key: ValueKey('firefly-account-$key'),
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        decoration: InputDecoration(labelText: 'firefly-liabilities-$key'.tr()),
      );

  Widget _dropdown(String key, String? value, List<String> options,
      String group, ValueChanged<String?> onChanged) {
    final items = [
      ...options,
      if (value != null && !options.contains(value)) value
    ];
    return DropdownButtonFormField<String>(
      key: ValueKey('firefly-account-$key'),
      isExpanded: true,
      value: value,
      decoration: InputDecoration(labelText: 'firefly-liabilities-$key'.tr()),
      items: [
        for (final option in items)
          DropdownMenuItem(
              value: option, child: Text(fireflyLiabilityLabel(group, option))),
      ],
      onChanged: (next) => setState(() => onChanged(next)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final old = _old;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_liability)
          _role == 'ccAsset'
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('firefly-liabilities-role'.tr()),
                  subtitle: Text(fireflyLiabilityLabel('role', _role)),
                )
              : _dropdown('role', _role ?? fireflyAssetRoles.first,
                  fireflyAssetRoles, 'role', (v) => _role = v),
        if (_liability) ...[
          _dropdown(
              'type', _type, fireflyLiabilityTypes, 'type', (v) => _type = v!),
          _dropdown('direction', _direction, fireflyLiabilityDirections,
              'direction', (v) => _direction = v!),
          _field('interest', _interest, number: true),
          _dropdown('period', _period, fireflyInterestPeriods, 'period',
              (v) => _period = v),
        ],
        if (_virtualShown)
          _field('virtual-balance', _virtual,
              number: true, enabled: widget.virtualBalanceEditable),
        _field('iban', _iban),
        _field('bic', _bic),
        _field('account-number', _account),
        _field('notes', _notes, maxLines: 3),
        SwitchListTile(
          key: const ValueKey('firefly-account-net-worth'),
          contentPadding: EdgeInsets.zero,
          title: Text('firefly-liabilities-net-worth'.tr()),
          value: _netWorth,
          onChanged: (value) => setState(() => _netWorth = value),
        ),
        if (old?.serverBalance != null)
          ListTile(
            key: const ValueKey('firefly-account-server-balance'),
            contentPadding: EdgeInsets.zero,
            title: Text('firefly-liabilities-server-balance'.tr()),
            subtitle: old!.serverBalanceDate == null
                ? null
                : Text('firefly-liabilities-balance-date'.tr(namedArgs: {
                    'date': DateFormat.yMMMd().format(old.serverBalanceDate!)
                  })),
            trailing: Text(old.serverBalance!.toStringAsFixed(2)),
          ),
      ],
    );
  }
}

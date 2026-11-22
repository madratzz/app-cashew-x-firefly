import 'package:budget/firefly/ui/pages/currencies/currencies_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyCurrenciesEntry(BuildContext context) => ListTile(
      key: const ValueKey('firefly-currencies-entry'),
      leading: const Icon(Icons.currency_exchange_rounded),
      title: Text('firefly-currencies-title'.tr()),
      subtitle: Text('firefly-currencies-description'.tr()),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const FireflyCurrenciesPage())),
    );

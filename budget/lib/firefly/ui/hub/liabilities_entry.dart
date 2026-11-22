import 'package:budget/firefly/ui/pages/liabilities/liabilities_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyLiabilitiesEntry(BuildContext context) =>
    SettingsContainerOpenPage(
      openPage: const FireflyLiabilitiesPage(),
      title: 'firefly-liabilities-title'.tr(),
      description: 'firefly-liabilities-entry-description'.tr(),
      icon: Icons.account_balance_rounded,
    );

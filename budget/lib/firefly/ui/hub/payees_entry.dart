import 'package:budget/firefly/ui/pages/payees/payees_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyPayeesEntry(BuildContext context) => SettingsContainerOpenPage(
      openPage: const FireflyPayeesPage(),
      title: 'firefly-payees-title'.tr(),
      description: 'firefly-payees-entry-description'.tr(),
      icon: Icons.storefront_rounded,
    );

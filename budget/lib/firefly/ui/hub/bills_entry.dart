import 'package:budget/firefly/ui/pages/bills/bills_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyBillsEntry(BuildContext context) => SettingsContainerOpenPage(
      openPage: const FireflyBillsPage(),
      title: 'firefly-bills-title'.tr(),
      description: 'firefly-bills-entry-description'.tr(),
      icon: Icons.receipt_long_rounded,
    );

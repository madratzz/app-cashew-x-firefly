import 'package:budget/firefly/ui/pages/bills/recurrences_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyRecurrencesEntry(BuildContext context) =>
    SettingsContainerOpenPage(
      openPage: const FireflyRecurrencesPage(),
      title: 'firefly-recurrences-title'.tr(),
      description: 'firefly-recurrences-entry-description'.tr(),
      icon: Icons.event_repeat_rounded,
    );

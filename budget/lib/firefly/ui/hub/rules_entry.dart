import 'package:budget/firefly/ui/pages/rules/rules_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyRulesEntry(BuildContext context) => SettingsContainerOpenPage(
      openPage: const FireflyRulesPage(),
      title: 'firefly-rules-title'.tr(),
      description: 'firefly-rules-entry-description'.tr(),
      icon: Icons.rule_rounded,
    );

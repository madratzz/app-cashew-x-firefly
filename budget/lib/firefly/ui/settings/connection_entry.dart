import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyConnectionEntry(BuildContext context) {
  final config = FireflyMode.config;
  return SettingsContainerOpenPage(
    openPage: const FireflyConnectionPage(),
    title: 'firefly-title'.tr(),
    description: FireflyMode.enabled
        ? 'firefly-connection-entry-connected'
            .tr(namedArgs: {'url': Uri.tryParse(config.baseUrl)?.host ?? ''})
        : 'firefly-connection-entry-description'.tr(),
    icon: Icons.local_fire_department_rounded,
  );
}

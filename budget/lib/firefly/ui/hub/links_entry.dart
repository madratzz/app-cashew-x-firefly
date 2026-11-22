import 'package:budget/firefly/ui/pages/links/links_page.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyLinksEntry(BuildContext context) => SettingsContainerOpenPage(
      openPage: const FireflyLinksPage(),
      title: 'firefly-links-title'.tr(),
      description: 'firefly-links-entry-description'.tr(),
      icon: Icons.link_rounded,
    );

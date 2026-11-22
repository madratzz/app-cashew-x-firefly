import 'package:budget/firefly/ui/pages/tags/tags_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyTagsEntry(BuildContext context) => ListTile(
      key: const ValueKey('firefly-tags-entry'),
      leading: const Icon(Icons.sell_outlined),
      title: Text('firefly-tags-title'.tr()),
      subtitle: Text('firefly-tags-description'.tr()),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FireflyTagsPage())),
    );

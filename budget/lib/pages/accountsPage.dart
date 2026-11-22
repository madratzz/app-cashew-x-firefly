import 'package:budget/firefly/ui/account/firefly_account_tile.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:budget/widgets/importDB.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  State<AccountsPage> createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  bool currentlyExporting = false;

  void refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      horizontalPaddingConstrained: true,
      dragDownToDismiss: true,
      expandedHeight: 56,
      title: "firefly-account-connect".tr(),
      listWidgets: [
        const FireflyAccountTile(),
        SettingsHeader(title: "backups".tr()),
        const ExportDB(),
        const ImportDB(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/utils.dart';
import '../utils/constants.dart';
import '../models/pages.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);
  @override
  State<MyAppBar> createState() => MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}

class MyAppBarState extends State<MyAppBar> {
  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      AppBar(
        leading: appbarLeading(context, pages),
        title: appbarTitle(context),
        backgroundColor: AppColors.appBarBackground,
        toolbarHeight: 44,
      ),
      Divider(
        height: 1.0,
        thickness: 1.0,
        color: AppColors.drawerDivider,
      ),
    ]);
  }

  Widget appbarTitle(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return RichText(
        text: TextSpan(
      text: pages.currentPageID > -1 ? pages.currentPage!.modelVersion : "",
      style: const TextStyle(fontSize: 16, color: AppColors.appBarText),
    ));
  }

  Widget appbarLeading(BuildContext context, Pages pages) {
    return IconButton(
      icon: isDisplayDesktop(context)
          ? Icon(pages.isDrawerOpen ? Icons.menu_open : Icons.chevron_right)
          : const Icon(Icons.menu),
      onPressed: () {
        if (isDisplayDesktop(context)) {
          pages.isDrawerOpen = !pages.isDrawerOpen;
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}

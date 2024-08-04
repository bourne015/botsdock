import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import 'views/message_list_view.dart';
import './utils/utils.dart';
import './utils/constants.dart';
import './views/app_bar.dart';
import './views/drawer.dart';
import './models/pages.dart';
import './views/init_page.dart';
import 'views/input_field.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  var _drawerButton = Icons.more_vert_rounded;
  double _drawerWidth = drawerWidth;
  late Duration _drawerAnimationDuration;

  @override
  Widget build(BuildContext context) {
    // print("MainLayoutState");
    return Selector<Pages, int>(
        selector: (_, pages) => pages.currentPageID,
        builder: (context, currentPid, child) {
          if (isDisplayDesktop(context)) return desktopLayout(context);
          return mobilLayout(context);
        });
  }

  Widget mobilLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatPageBackground,
      appBar: const MyAppBar(),
      drawer: const ChatDrawer(drawersize: drawerWidth),
      body: _buildMainPageBody(context),
    );
  }

  Widget customDrawerButton(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return MouseRegion(
        onEnter: (_) => {
              setState(() {
                _drawerButton = Icons.chevron_left_rounded;
              })
            },
        onExit: (_) => {
              setState(() {
                _drawerButton = Icons.more_vert_rounded;
              })
            },
        child: IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(property.isDrawerOpen
                ? _drawerButton
                : Icons.chevron_right_rounded),
            tooltip: property.isDrawerOpen
                ? GalleryLocalizations.of(context)!.closeDrawerTooltip
                : GalleryLocalizations.of(context)!.openDrawerTooltip,
            onPressed: () {
              property.isDrawerOpen = !property.isDrawerOpen;
              _drawerWidth = property.isDrawerOpen ? drawerWidth : 0;
            }));
  }

  Widget desktopLayout(BuildContext context) {
    Property property = Provider.of<Property>(context);
    if (property.isLoading)
      _drawerAnimationDuration = Duration(milliseconds: 1150);
    else
      _drawerAnimationDuration = Duration(milliseconds: 270);
    //print("desktopLayout");
    return Row(
      children: <Widget>[
        AnimatedSize(
          curve: property.isDrawerOpen ? Curves.linear : Curves.ease, //out: in
          duration: _drawerAnimationDuration,
          alignment: Alignment.topRight,
          child: property.isDrawerOpen
              ? ChatDrawer(drawersize: _drawerWidth)
              : Container(),
        ),
        Container(
            alignment: Alignment.center,
            color: AppColors.chatPageBackground,
            child: customDrawerButton(context)),
        Expanded(
            child: Scaffold(
          backgroundColor: AppColors.chatPageBackground,
          appBar: !property.onInitPage ? MyAppBar() : null,
          body: _buildMainPageBody(context),
        ))
      ],
    );
  }

  Widget _buildMainPageBody(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: property.onInitPage
                  ? InitPage()
                  : Expanded(
                      child: MessageListView(),
                    )),
          ChatInputField(),
        ]);
  }
}

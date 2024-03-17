import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './views/chat_page.dart';
import './utils/utils.dart';
import './utils/constants.dart';
import './views/app_bar.dart';
import './views/drawer.dart';
import './models/pages.dart';
import './views/init_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  var _drawerButton = Icons.more_vert_rounded;

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    if (isDisplayDesktop(context)) {
      return desktopLayout(context);
    } else {
      return Scaffold(
        backgroundColor: AppColors.chatPageBackground,
        appBar: const MyAppBar(),
        drawer: const ChatDrawer(),
        body: pages.displayInitPage ? InitPage() : const ChatPage(),
      );
    }
  }

  Widget customDrawerButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return MouseRegion(
        onEnter: (_) => {
              setState(() {
                _drawerButton = Icons.arrow_back_ios_new_rounded;
              })
            },
        onExit: (_) => {
              setState(() {
                _drawerButton = Icons.more_vert_rounded;
              })
            },
        child: IconButton(
            iconSize: 18,
            icon: Icon(!pages.isDrawerOpen
                ? Icons.arrow_forward_ios_rounded
                : _drawerButton),
            tooltip: pages.isDrawerOpen ? "close sidebar" : "open sidebar",
            onPressed: () => pages.isDrawerOpen = !pages.isDrawerOpen));
  }

  Widget desktopLayout(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Row(children: <Widget>[
      if (pages.isDrawerOpen) const ChatDrawer(),
      //const VerticalDivider(width: 1),
      Container(
          alignment: Alignment.center,
          color: AppColors.chatPageBackground,
          child: customDrawerButton(context)),
      Expanded(
          child: Scaffold(
        backgroundColor: AppColors.chatPageBackground,
        //appBar: const MyAppBar(),
        body: pages.displayInitPage ? InitPage() : desktopChatPage(context),
      ))
    ]);
  }

  Widget desktopChatPage(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return NestedScrollView(
      floatHeaderSlivers: true,
      scrollDirection: Axis.vertical,

      //physics: ClampingScrollPhysics,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            title: Text(
              pages.currentPage!.modelVersion,
              style: const TextStyle(fontSize: 16, color: AppColors.appBarText),
            ),
            pinned: false,
            floating: true,
            snap: true,
            //stretch: true,
            backgroundColor: AppColors.appBarBackground,
          ),
        ];
      },
      body: const Row(
        children: <Widget>[
          Expanded(flex: 8, child: ChatPage()),
        ],
      ),
    );
  }
}

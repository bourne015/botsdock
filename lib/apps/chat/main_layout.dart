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
  double _drawerWidth = drawerWidth;
  late Duration _drawerAnimationDuration;
  bool _isDrawerVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toggleDrawer());
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerVisible = !_isDrawerVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    if (isDisplayDesktop(context)) {
      return desktopLayout(context);
    } else {
      return Scaffold(
        backgroundColor: AppColors.chatPageBackground,
        appBar: const MyAppBar(),
        drawer: const ChatDrawer(
          drawersize: drawerWidth,
        ),
        body: pages.displayInitPage ? InitPage() : const ChatPage(),
      );
    }
  }

  Widget customDrawerButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
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
            icon: Icon(!pages.isDrawerOpen
                ? Icons.chevron_right_rounded
                : _drawerButton),
            tooltip: pages.isDrawerOpen ? "close sidebar" : "open sidebar",
            onPressed: () {
              pages.isDrawerOpen = !pages.isDrawerOpen;
              _drawerWidth = pages.isDrawerOpen ? drawerWidth : 0;
            }));
  }

  Widget desktopLayout(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    if (pages.isLoading)
      _drawerAnimationDuration = Duration(milliseconds: 1150);
    else
      _drawerAnimationDuration = Duration(milliseconds: 270);
    return Row(children: <Widget>[
      AnimatedSize(
        curve: pages.isDrawerOpen ? Curves.linear : Curves.ease, //out: in
        duration: _drawerAnimationDuration,
        alignment: Alignment.topRight,
        child: _isDrawerVisible
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

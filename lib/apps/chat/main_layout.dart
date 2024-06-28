import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

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
  //bool _isDrawerVisible = false;

  // @override
  // void initState() {
  //   super.initState();
  //   // WidgetsBinding.instance.addPostFrameCallback((_) => _toggleDrawer());
  // }

  // void _toggleDrawer() {
  //   setState(() {
  //     _isDrawerVisible = !_isDrawerVisible;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // print("MainLayoutState");
    if (isDisplayDesktop(context)) return desktopLayout(context);
    return mobilLayout(context);
  }

  Widget mobilLayout(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Scaffold(
      backgroundColor: AppColors.chatPageBackground,
      appBar: const MyAppBar(),
      drawer: const ChatDrawer(
        drawersize: drawerWidth,
      ),
      body: property.onInitPage ? InitPage() : const ChatPage(),
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
    return Row(children: <Widget>[
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
        //appBar: const MyAppBar(),
        body: property.onInitPage ? InitPage() : desktopChatPage(context),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      drawer: const ChatDrawer(drawersize: DRAWERWIDTH),
      body: _buildMainPageBody(context),
    );
  }

  Widget desktopLayout(BuildContext context) {
    Property property = Provider.of<Property>(context);
    if (property.isLoading)
      _drawerAnimationDuration = Duration(milliseconds: 1150);
    else
      _drawerAnimationDuration = Duration(milliseconds: 270);

    return Row(
      children: <Widget>[
        AnimatedSize(
          curve: property.isDrawerOpen ? Curves.linear : Curves.ease, //out: in
          duration: _drawerAnimationDuration,
          alignment: Alignment.topRight,
          child: property.isDrawerOpen
              ? ChatDrawer(drawersize: DRAWERWIDTH)
              : Container(),
        ),
        Container(
            alignment: Alignment.center,
            color: AppColors.chatPageBackground,
            child: CustomDrawerButton(
              isOpen: property.isDrawerOpen,
              onPressed: () {
                property.isDrawerOpen = !property.isDrawerOpen;
              },
            )),
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
            child: property.onInitPage ? InitPage() : MessageListView(),
          ),
          ChatInputField(),
        ]);
  }
}

class CustomDrawerButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onPressed;
  final ValueNotifier<IconData> _iconNotifier =
      ValueNotifier(Icons.more_vert_rounded);

  CustomDrawerButton({Key? key, required this.isOpen, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _iconNotifier.value = Icons.chevron_left_rounded,
      onExit: (_) => _iconNotifier.value = Icons.more_vert_rounded,
      child: ValueListenableBuilder<IconData>(
        valueListenable: _iconNotifier,
        builder: (context, icon, child) {
          return IconButton(
            icon: Icon(isOpen ? icon : Icons.chevron_right_rounded),
            onPressed: onPressed,
          );
        },
      ),
    );
  }
}

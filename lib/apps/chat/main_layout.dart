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
  final Duration _drawerAnimationDuration = Duration(milliseconds: 270);

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
      // backgroundColor: AppColors.chatPageBackground,
      appBar: const MyAppBar(),
      drawer: const ChatDrawer(),
      body: _buildMainPageBody(context),
    );
  }

  Widget desktopLayout(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Row(
      children: <Widget>[
        AnimatedContainer(
          curve: Curves.easeInOut,
          duration: _drawerAnimationDuration,
          width: property.isDrawerOpen ? DRAWERWIDTH : 0,
          alignment: Alignment.topRight,
          child: const ClipRect(
            child: OverflowBox(
              alignment: Alignment.topRight,
              maxWidth: DRAWERWIDTH,
              child: RepaintBoundary(child: ChatDrawer()),
            ),
          ),
        ),
        CustomDrawerButton(),
        Expanded(
            child: Scaffold(
          // backgroundColor: AppColors.chatPageBackground,
          appBar: !property.onInitPage ? const MyAppBar() : null,
          body: AnimatedContainer(
            duration: _drawerAnimationDuration,
            child: _buildMainPageBody(context),
          ),
        )),
      ],
    );
  }

  Widget _buildMainPageBody(BuildContext context) {
    Property property = Provider.of<Property>(context);
    Pages pages = Provider.of<Pages>(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: property.onInitPage
                ? const InitPage()
                : MessageListView(
                    page: pages.currentPage!,
                    isDrawerOpen: property.isDrawerOpen),
          ),
          const ChatInputField(),
        ]);
  }
}

class CustomDrawerButton extends StatelessWidget {
  final ValueNotifier<IconData> _iconNotifier =
      ValueNotifier(Icons.more_vert_rounded);

  CustomDrawerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Container(
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surface,
        child: MouseRegion(
          onEnter: (_) => _iconNotifier.value = Icons.chevron_left_rounded,
          onExit: (_) => _iconNotifier.value = Icons.more_vert_rounded,
          child: ValueListenableBuilder<IconData>(
            valueListenable: _iconNotifier,
            builder: (context, icon, child) {
              return IconButton(
                visualDensity: VisualDensity.compact,
                // hoverColor: AppColors.chatPageBackground,
                // highlightColor: AppColors.chatPageBackground,
                icon: Icon(
                    property.isDrawerOpen ? icon : Icons.chevron_right_rounded),
                onPressed: () {
                  property.isDrawerOpen = !property.isDrawerOpen;
                },
              );
            },
          ),
        ));
  }
}

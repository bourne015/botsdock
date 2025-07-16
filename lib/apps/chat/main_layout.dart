import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart';

import 'package:botsdock/apps/chat/views/messages/message_list_view.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/views/app_bar.dart';
import 'package:botsdock/apps/chat/views/drawer.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/views/init_page.dart';
import 'views/input_field.dart';

class MainLayout extends rp.ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  rp.ConsumerState createState() => MainLayoutState();
}

class MainLayoutState extends rp.ConsumerState<MainLayout> {
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
    final propertyState = ref.watch(propertyProvider);
    return Row(
      children: <Widget>[
        AnimatedContainer(
          curve: Curves.easeInOut,
          duration: _drawerAnimationDuration,
          width: propertyState.isDrawerOpen ? DRAWERWIDTH : 0,
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
          appBar: const MyAppBar(),
          body: AnimatedContainer(
            duration: _drawerAnimationDuration,
            child: _buildMainPageBody(context),
          ),
        )),
      ],
    );
  }

  Widget _buildMainPageBody(BuildContext context) {
    final propertyState = ref.watch(propertyProvider);
    Pages pages = Provider.of<Pages>(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: propertyState.onInitPage
                ? const InitPage()
                : MessageListView(
                    page: pages.currentPage!,
                    isDrawerOpen: propertyState.isDrawerOpen),
          ),
          const ChatInputField(),
        ]);
  }
}

class CustomDrawerButton extends rp.ConsumerWidget {
  final ValueNotifier<IconData> _iconNotifier =
      ValueNotifier(Icons.more_vert_rounded);

  CustomDrawerButton({Key? key});

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final propertyState = ref.watch(propertyProvider);
    final propertyNotifier = ref.read(propertyProvider.notifier);
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
                icon: Icon(propertyState.isDrawerOpen
                    ? icon
                    : Icons.chevron_right_rounded),
                onPressed: () {
                  propertyNotifier.setIsDrawerOpen(!propertyState.isDrawerOpen);
                },
              );
            },
          ),
        ));
  }
}

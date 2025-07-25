import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:botsdock/apps/chat/main.dart';
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:botsdock/apps/chat/models/chat.dart';
import 'package:botsdock/apps/chat/vendor/assistants_api.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/views/menu/administrator.dart';
import 'package:botsdock/apps/chat/utils/global.dart';

class ChatDrawer extends rp.ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  rp.ConsumerState<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends rp.ConsumerState<ChatDrawer> {
  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyProvider);
    return PointerInterceptor(
      child: Drawer(
        width: DRAWERWIDTH,
        // backgroundColor: AppColors.drawerBackground,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        shape: isDisplayDesktop(context)
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              )
            : null,
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            children: [
              _DrawerHeader(),
              propertyState.isLoading
                  ? const Expanded(
                      child: SpinKitThreeBounce(
                        color: AppColors.generatingAnimation,
                        size: AppSize.generatingAnimation,
                      ),
                    )
                  : const ChatPageList(),
              const _DrawerFooter(),
            ],
          );
        }),
      ),
    );
  }
}

class _DrawerHeader extends rp.ConsumerWidget {
  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    return Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Column(
          children: [
            _head(context, ref),
            botsCentre(context),
          ],
        ));
  }

  Widget _homeButton(BuildContext context) {
    return Container(
      // margin: EdgeInsets.only(left: 17),
      child: IconButton(
        tooltip: "Home",
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
        icon: Icon(Icons.home_outlined),
      ),
    );
  }

  Widget _head(BuildContext context, rp.WidgetRef ref) {
    return Row(
      children: [
        // _homeButton(context),
        Expanded(
          child: newchatButton(context, ref),
        ),
      ],
    );
  }

  Widget newchatButton(BuildContext context, rp.WidgetRef ref) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    final propertyNotifier = ref.read(propertyProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Color.fromARGB(255, 162, 158, 158), width: 0.5),
        borderRadius: BORDERRADIUS10,
      ),
      margin: const EdgeInsets.fromLTRB(10, 15, 10, 10),
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BORDERRADIUS10,
        ),
        onTap: () {
          propertyNotifier.setOnInitPage(true);
          pages.currentPageID = -1;
          if (!isDisplayDesktop(context)) Navigator.pop(context);
        },
        leading: _homeButton(context),
        title: Text(
          GalleryLocalizations.of(context)!.newChat,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget botsCentre(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BORDERRADIUS10,
          ),
          leading: Icon(
            Icons.view_compact_sharp,
            color: const Color.fromARGB(255, 78, 164, 235),
          ),
          title: Text(
            GalleryLocalizations.of(context)!.botsCentre,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: () async {
            if (!isDisplayDesktop(context)) Navigator.pop(context);
            Navigator.pushNamed(context, ChatApp.botCentre);
          },
        ));
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Column(
        children: [
          const Divider(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Administrator(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ChatPageList extends rp.ConsumerStatefulWidget {
  const ChatPageList({Key? key}) : super(key: key);

  @override
  rp.ConsumerState createState() => _ChatPageListState();
}

class _ChatPageListState extends rp.ConsumerState<ChatPageList> {
  @override
  Widget build(BuildContext context) {
    final pages = Provider.of<Pages>(context);

    // List _flattenedItems = pages.flattenPages();
    List _flattenedItems = pages.flattenedPages;

    return Expanded(
      child: ListView.builder(
        itemExtent: 40,
        itemCount: _flattenedItems.length,
        itemBuilder: (context, index) {
          final item = _flattenedItems[index];
          if (item is String) {
            return _buildDateHeader(context, item);
          } else if (item is Chat) {
            return ChatPageTab(
              key: ValueKey(item.id),
              context: context,
              pages: pages,
              page: item,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, String dateLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Text(
        dateLabel,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class ChatPageTab extends rp.ConsumerStatefulWidget {
  final BuildContext context;
  final Pages pages;
  final Chat page;
  final assistant = AssistantsAPI();

  ChatPageTab({
    Key? key,
    required this.context,
    required this.pages,
    required this.page,
  }) : super(key: key);

  @override
  rp.ConsumerState createState() => _ChatPageTabState();
}

class _ChatPageTabState extends rp.ConsumerState<ChatPageTab> {
  bool isHovered = false;
  final assistant = AssistantsAPI();

  @override
  Widget build(BuildContext context) {
    final propertyNotifier = ref.read(propertyProvider.notifier);
    var bot_id = widget.page.botID;
    return MouseRegion(
        onEnter: (event) {
          setState(() {
            isHovered = true;
          });
        },
        onExit: (event) {
          setState(() {
            isHovered = false;
          });
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: ListTile(
            dense: true,
            selectedTileColor: Theme.of(context).colorScheme.secondaryFixed,
            shape: RoundedRectangleBorder(
              borderRadius: BORDERRADIUS10,
            ),
            // selectedTileColor: AppColors.drawerTabSelected,
            selected: widget.pages.currentPageID == widget.page.id,
            leading: bot_id != null
                ? Icon(
                    Icons.deblur,
                    size: 15,
                  )
                : null,
            minLeadingWidth: 0,
            contentPadding: const EdgeInsets.fromLTRB(10, 0, 3, 0),
            title: Text(
              widget.page.title,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            onTap: () {
              widget.pages.currentPageID = widget.page.id;
              propertyNotifier.setOnInitPage(false);
              if (!isDisplayDesktop(context)) Navigator.pop(context);
            },
            //always keep chat 0
            trailing: widget.pages.currentPageID == widget.page.id || isHovered
                ? delChattabButton(context, widget.pages, widget.page.id)
                : null,
          ),
        ));
  }

  Widget delChattabButton(BuildContext context, Pages pages, int removeID) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.close),
        iconSize: 15,
        tooltip: "delete",
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          doDeletePage(pages, removeID);
        },
      ),
    ]);
  }

  void doDeletePage(Pages pages, int removeID) async {
    try {
      final propertyNotifier = ref.read(propertyProvider.notifier);
      User user = ref.watch(userProvider);
      var did = pages.getPage(removeID).dbID;
      var msgs = pages.getPage(removeID).messages;
      var tid = pages.getPage(removeID).threadID;
      pages.delPage(removeID);
      pages.flattenPages();
      if (removeID == pages.currentPageID) {
        pages.currentPageID = -1;
        propertyNotifier.setOnInitPage(true);
      }
      if (user.isLogedin) {
        var cres = await DioClient().delete(ChatPath.chatDelete(user.id, did!));
        Global.deleteChat(user.id, did, cres["updated_at"]);
      }
      for (var m in msgs) {
        m.visionFiles.forEach((_filename, _content) async {
          if (_content.url.isNotEmpty) ChatAPI.deleteOSSObj(_content.url);
        });
        m.attachments.forEach((_filename, _content) async {
          if (_content.file_url != null)
            ChatAPI.deleteOSSObj(_content.file_url!);
        });
      }
      if (tid != null && tid != user.cat_id) await assistant.deleteThread(tid);
    } catch (e) {
      debugPrint("doDeletePage error: $e");
    }
  }
}

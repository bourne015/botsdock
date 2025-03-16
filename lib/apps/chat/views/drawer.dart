import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:botsdock/apps/chat/main.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import 'package:botsdock/apps/chat/models/chat.dart';
import 'package:botsdock/apps/chat/vendor/assistants_api.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/views/menu/administrator.dart';
import 'package:botsdock/apps/chat/utils/global.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends State<ChatDrawer> {
  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Drawer(
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
            const _DrawerHeader(),
            property.isLoading
                ? const Expanded(
                    child: SpinKitThreeBounce(
                        color: AppColors.generatingAnimation,
                        size: AppSize.generatingAnimation))
                : const ChatPageList(),
            const _DrawerFooter(),
          ],
        );
      }),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Column(
          children: [
            newchatButton(context),
            botsCentre(context),
          ],
        ));
  }

  Widget newchatButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Color.fromARGB(255, 162, 158, 158), width: 0.5),
        borderRadius: BORDERRADIUS10,
      ),
      margin: const EdgeInsets.fromLTRB(10, 15, 10, 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BORDERRADIUS10,
        ),
        onTap: () {
          property.onInitPage = true;
          pages.currentPageID = -1;
          if (!isDisplayDesktop(context)) Navigator.pop(context);
        },
        leading: const Icon(Icons.add),
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

class ChatPageList extends StatefulWidget {
  const ChatPageList({Key? key}) : super(key: key);

  @override
  _ChatPageListState createState() => _ChatPageListState();
}

class _ChatPageListState extends State<ChatPageList> {
  @override
  Widget build(BuildContext context) {
    final pages = Provider.of<Pages>(context);
    final property = Provider.of<Property>(context);

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
              property: property,
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

class ChatPageTab extends StatefulWidget {
  final BuildContext context;
  final Pages pages;
  final Chat page;
  final Property property;
  final assistant = AssistantsAPI();

  ChatPageTab(
      {Key? key,
      required this.context,
      required this.pages,
      required this.page,
      required this.property})
      : super(key: key);

  @override
  _ChatPageTabState createState() => _ChatPageTabState();
}

class _ChatPageTabState extends State<ChatPageTab> {
  bool isHovered = false;
  final assistant = AssistantsAPI();

  @override
  Widget build(BuildContext context) {
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
              widget.property.onInitPage = false;
              if (!isDisplayDesktop(context)) Navigator.pop(context);
            },
            //always keep chat 0
            trailing: widget.pages.currentPageID == widget.page.id || isHovered
                ? delChattabButton(
                    context, widget.pages, widget.page.id, widget.property)
                : null,
          ),
        ));
  }

  Widget delChattabButton(
      BuildContext context, Pages pages, int removeID, Property property) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.close),
        iconSize: 15,
        tooltip: "delete",
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          doDeletePage(pages, removeID, property);
        },
      ),
    ]);
  }

  void doDeletePage(Pages pages, int removeID, Property property) async {
    try {
      User user = Provider.of<User>(context, listen: false);
      var did = pages.getPage(removeID).dbID;
      var msgs = pages.getPage(removeID).messages;
      var tid = pages.getPage(removeID).threadID;
      pages.delPage(removeID);
      pages.flattenPages();
      if (removeID == pages.currentPageID) {
        pages.currentPageID = -1;
        property.onInitPage = true;
      }
      if (user.isLogedin) {
        var chatdbUrl = USER_URL + "/" + "${user.id}" + "/chat/" + "$did";
        var cres = await Dio().delete(chatdbUrl);
        Global.deleteChat(user.id, did, cres.data["updated_at"]);
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

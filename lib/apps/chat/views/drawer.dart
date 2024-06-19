import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import '../utils/constants.dart';
import '../utils/utils.dart';
import '../models/pages.dart';
import '../models/user.dart';
import 'administrator.dart';
import '../utils/global.dart';

class ChatDrawer extends StatefulWidget {
  final double drawersize;
  const ChatDrawer({super.key, required this.drawersize});

  @override
  State<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends State<ChatDrawer> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: widget.drawersize,
      backgroundColor: AppColors.drawerBackground,
      shape: isDisplayDesktop(context)
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )
          : null,
      child: Column(
        children: [
          newchatButton(context),
          chatPageTabList(context),
          Divider(
              height: 10,
              thickness: 1,
              indent: 10,
              endIndent: 10,
              color: AppColors.drawerDivider),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Administrator()),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget newchatButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
          flex: 4,
          child: Container(
              margin: const EdgeInsets.fromLTRB(10, 15, 10, 10),
              child: OutlinedButton.icon(
                onPressed: () {
                  property.onInitPage = true;
                  pages.currentPageID = -1;
                  if (!isDisplayDesktop(context)) Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
                style: ButtonStyle(
                  minimumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 52)),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  //padding: EdgeInsets.symmetric(horizontal: 20.0),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ),
              ))),
    ]);
  }

  Widget chatPageTabList(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    final Set<String> groupedTitles = {};
    var today = DateTime.now();
    return Expanded(
      child: ListView.builder(
        shrinkWrap: false,
        itemCount: pages.pagesLen,
        itemBuilder: (context, index) {
          var page = pages.getNthPage(index);
          var chat_day =
              DateTime.fromMillisecondsSinceEpoch(page.updated_at * 1000);
          int dayDiff = today.difference(chat_day).inDays.abs();
          String groupTitle = _getGroupTitle(dayDiff);
          bool isGrouped = groupedTitles.contains(groupTitle);
          if (!isGrouped) groupedTitles.add(groupTitle);

          return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(children: [
                if (!isGrouped) ChatPageTabDate(context, groupTitle),
                ChatPageTab(
                    context: context,
                    pages: pages,
                    index: index,
                    property: property)
              ]));
        },
      ),
    );
  }

  String _getGroupTitle(int dayDiff) {
    if (dayDiff == 0) {
      return "今天";
    } else if (dayDiff == 1) {
      return "昨天";
    } else if (dayDiff >= 2 && dayDiff <= 7) {
      return "三天前";
    } else {
      return "一周前";
    }
  }

  Widget ChatPageTabDate(BuildContext context, String groupTitle) {
    return ListTile(
      dense: true,
      enabled: false,
      contentPadding: EdgeInsets.only(left: 10, top: 15),
      title: RichText(
        text: TextSpan(
            text: groupTitle,
            style: TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 163, 162, 162),
            )),
      ),
    );
  }
}

class ChatPageTab extends StatefulWidget {
  final BuildContext context;
  final Pages pages;
  final int index;
  final Property property;

  ChatPageTab(
      {required this.context,
      required this.pages,
      required this.index,
      required this.property});

  @override
  _ChatPageTabState createState() => _ChatPageTabState();
}

class _ChatPageTabState extends State<ChatPageTab> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final page = widget.pages.getNthPage(widget.index);
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
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedTileColor: AppColors.drawerTabSelected,
        selected: widget.pages.currentPageID == page.id,
        //leading: const Icon(Icons.chat_bubble_outline, size: 16),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 3, 0),
        title: RichText(
            text: TextSpan(
              text: page.title,
              style: TextStyle(fontSize: 15, color: AppColors.msgText),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        onTap: () {
          widget.pages.currentPageID = page.id!;
          widget.property.onInitPage = false;
          if (!isDisplayDesktop(context)) Navigator.pop(context);
        },
        //always keep chat 0
        trailing: widget.pages.pagesLen > 1 &&
                (widget.pages.currentPageID == page.id || isHovered)
            ? delChattabButton(context, widget.pages, page.id!, widget.property)
            : null,
      ),
    );
  }

  Widget delChattabButton(
      BuildContext context, Pages pages, int removeID, Property property) {
    User user = Provider.of<User>(context, listen: false);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.close),
        iconSize: 15,
        tooltip: "delete",
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          var did = pages.getPage(removeID).dbID;
          var msgs = pages.getPage(removeID).messages;
          pages.delPage(removeID);
          if (removeID == pages.currentPageID) {
            pages.currentPageID = -1;
            property.onInitPage = true;
          }
          if (user.isLogedin) {
            var chatdbUrl = userUrl + "/" + "${user.id}" + "/chat/" + "$did";
            var cres = await Dio().delete(chatdbUrl);
            Global.deleteChat(removeID, cres.data["updated_at"]);
          }
          for (var m in msgs) {
            if (m.fileUrl == null) continue;
            var uri = Uri.parse(m.fileUrl!);
            var path =
                uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
            Client().deleteObject(path);
          }
        },
      ),
    ]);
  }
}

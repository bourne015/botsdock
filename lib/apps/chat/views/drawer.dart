import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../models/chat.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import '../models/pages.dart';
import '../models/user.dart';
import 'administrator.dart';
import '../utils/global.dart';
import '../views/bots.dart';

class ChatDrawer extends StatefulWidget {
  final double drawersize;
  const ChatDrawer({super.key, required this.drawersize});

  @override
  State<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends State<ChatDrawer> {
  bool isHovered = false;
  final dio = Dio();

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
          botsCentre(context),
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

  Widget botsCentre(BuildContext context) {
    Property property = Provider.of<Property>(context, listen: false);
    User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    return Container(
        margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            Icons.view_compact_sharp,
            color: const Color.fromARGB(255, 78, 164, 235),
          ),
          title: Text(GalleryLocalizations.of(context)!.botsCentre),
          onTap: () async {
            if (!isDisplayDesktop(context)) Navigator.pop(context);
            var botsURL = botURL + "/bots";
            Response bots = await dio.post(botsURL);
            showDialog(
              context: context,
              builder: (context) => Bots(
                  pages: pages,
                  user: user,
                  property: property,
                  bots: bots.data["bots"]),
            );
          },
        ));
  }

  Widget newchatButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Color.fromARGB(255, 162, 158, 158), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.fromLTRB(10, 15, 10, 10),
      child: ListTile(
        onTap: () {
          property.onInitPage = true;
          pages.currentPageID = -1;
          if (!isDisplayDesktop(context)) Navigator.pop(context);
        },
        leading: const Icon(Icons.add),
        title: const Text('New Chat'),
        // style: ButtonStyle(
        //   minimumSize:
        //       WidgetStateProperty.all(const Size(double.infinity, 52)),
        //   padding: WidgetStateProperty.all(EdgeInsets.zero),
        //   //padding: EdgeInsets.symmetric(horizontal: 20.0),
        //   shape: WidgetStateProperty.all(RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(10))),
        // ),
      ),
    );
  }

  Widget chatPageTabList(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    Map<String, List> _groupedPages = {};
    pages.groupByDate(_groupedPages);
    List<String> dateKeys = _groupedPages.keys.toList();
    return Expanded(
      child: ListView.builder(
          shrinkWrap: false,
          itemCount: dateKeys.length,
          itemBuilder: (context, index) {
            return Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                        enabled: false,
                        dense: true,
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.symmetric(horizontal: 10),
                        trailing: Container(width: 0),
                        title: RichText(
                          text: TextSpan(
                              text: dateKeys[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 163, 162, 162),
                              )),
                        ),
                        children: _groupedPages[dateKeys[index]]!.map((page) {
                          return ChatPageTab(
                              context: context,
                              pages: pages,
                              page: page,
                              property: property);
                        }).toList())));
          }),
    );
  }
}

class ChatPageTab extends StatefulWidget {
  final BuildContext context;
  final Pages pages;
  final Chat page;
  final Property property;

  ChatPageTab(
      {required this.context,
      required this.pages,
      required this.page,
      required this.property});

  @override
  _ChatPageTabState createState() => _ChatPageTabState();
}

class _ChatPageTabState extends State<ChatPageTab> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
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
        selected: widget.pages.currentPageID == widget.page.id,
        //leading: const Icon(Icons.chat_bubble_outline, size: 16),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 3, 0),
        title: RichText(
            text: TextSpan(
              text: widget.page.title,
              style: TextStyle(fontSize: 14.5, color: AppColors.msgText),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        onTap: () {
          widget.pages.currentPageID = widget.page.id!;
          widget.property.onInitPage = false;
          if (!isDisplayDesktop(context)) Navigator.pop(context);
        },
        //always keep chat 0
        trailing: widget.pages.pagesLen > 1 &&
                (widget.pages.currentPageID == widget.page.id || isHovered)
            ? delChattabButton(
                context, widget.pages, widget.page.id!, widget.property)
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

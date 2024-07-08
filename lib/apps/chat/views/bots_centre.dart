import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import "../utils/constants.dart";
import '../utils/utils.dart';
import './new_bot.dart';
import '../utils/assistants_api.dart';

class Bots extends StatefulWidget {
  final bots;
  final pages;
  final user;
  final property;
  const Bots(
      {super.key,
      required this.bots,
      required this.pages,
      required this.user,
      required this.property});

  @override
  State<Bots> createState() => BotsState();
}

class BotsState extends State<Bots> {
  final dio = Dio();
  final ChatGen chats = ChatGen();
  var user_likes = [];
  var botsPublicMe = [];
  final assistant = AssistantsAPI();

  @override
  void initState() {
    super.initState();
    for (var xbot in widget.bots)
      if (xbot["author_id"] == widget.user.id || xbot["public"] == true) {
        botsPublicMe.add(xbot);
      }
  }

  @override
  void dispose() {
    super.dispose();
    botsPublicMe.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(GalleryLocalizations.of(context)!.botCentreTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.chatPageBackground,
        ),
        backgroundColor: AppColors.chatPageBackground,
        body: BotsPage(context));
  }

  Widget BotsPage(BuildContext context) {
    //User user = Provider.of<User>(context, listen: false);
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text(GalleryLocalizations.of(context)!.botCentreMe,
                textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Container(
                padding:
                    EdgeInsets.only(left: isDisplayDesktop(context) ? 50 : 20),
                child: OutlinedButton.icon(
                    onPressed: () {
                      if (widget.user.isLogedin)
                        showDialog(
                            context: context,
                            builder: (context) => CreateBot(user: widget.user));
                    },
                    icon: Icon(Icons.add),
                    label: Text(
                        GalleryLocalizations.of(context)!.botCentreCreate))),
            SizedBox(height: 30),
            Text(GalleryLocalizations.of(context)!.exploreMore,
                style: TextStyle(fontSize: 18)),
            BotsList(context),
          ],
        ));
  }

  void deleteBot(bot) async {
    var _delBotURL = botURL + "/${bot["id"]}";
    var assistant_id = "";
    if (bot["file_search"] || bot["code_interpreter"] || bot["functions"])
      assistant_id = bot["assistant_id"];
    var resp = await Dio()
        .delete(_delBotURL, queryParameters: {"assistant_id": assistant_id});
    if (resp.data["result"] == "success") {
      setState(() {
        //widget.bots
        widget.bots.removeWhere((element) => element['id'] == bot["id"]);
      });
    }
  }

  // Widget editBot(context, user, bot) {
  //   return showDialog(
  //       context: context,
  //       builder: (context) => CreateBot(user: user, bot: bot));
  // }

  Widget BotTabEdit(BuildContext context, bot) {
    return PopupMenuButton<String>(
      //initialValue: "edit",
      icon: Icon(Icons.edit_note_rounded, size: 20),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 3,
      onSelected: (String value) {
        if (value == "edit") {
          showDialog(
                  context: context,
                  builder: (context) =>
                      CreateBot(user: widget.user, bots: widget.bots, bot: bot))
              .then((_) {
            setState(() {});
          });
        } else if (value == "delete") {
          deleteBot(bot);
        }
      },
      //position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: "edit",
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_rounded, size: 14),
              title: Text(GalleryLocalizations.of(context)!.botEdit),
            )),
        PopupMenuDivider(height: 1.0),
        PopupMenuItem<String>(
            value: "delete",
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete, size: 14),
              title: Text(GalleryLocalizations.of(context)!.botDelete),
            )),
      ],
    );
  }

  Widget BotTabtrailing(BuildContext context, bot) {
    return Stack(alignment: Alignment.topRight, children: [
      RichText(
          text: TextSpan(
              text: '${bot["likes"]}',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          maxLines: 1),
      IconButton(
          icon: Icon(Icons.favorite_border),
          isSelected: user_likes.contains(bot["id"]),
          selectedIcon: Icon(Icons.favorite, color: Colors.red),
          onPressed: () {
            setState(() {
              if (user_likes.contains(bot["id"])) {
                user_likes.remove(bot["id"]);
                bot["likes"] -= 1;
              } else {
                user_likes.add(bot["id"]);
                bot["likes"] += 1;
              }
            });
          })
    ]);
  }

  Widget buildListItem({
    required int rank,
    required var bot,
    required onTab,
  }) {
    String? image = bot["avatar"];
    String title = bot["name"];
    String description = bot["description"];
    String? creator = bot["author_name"] ?? "anonymous";
    return Card(
        color: Color.fromARGB(255, 244, 244, 244),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          hoverColor: Color.fromARGB(255, 230, 227, 227).withOpacity(0.3),
          onTap: onTab,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: image != null
                        ? Image.network(
                            image,
                            width: 80,
                            height: 80,
                          )
                        : Container(height: 80, width: 80)),
                SizedBox(width: 30),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    //SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                          Expanded(
                              child: Text(
                            '创建者： $creator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )),
                          if (widget.user.id == bot["author_id"])
                            Container(
                              alignment: Alignment.centerRight,
                              child: BotTabEdit(context, bot),
                            ),
                        ])),
                  ],
                )),
                //SizedBox(width: 10),
              ],
            ),
          ),
        ));
  }

  Widget BotTab(BuildContext context, index) {
    var bot = botsPublicMe[index];
    return buildListItem(
        rank: index,
        bot: bot,
        onTab: () async {
          if (widget.user.isLogedin) {
            Navigator.pop(context);
            int _pid = widget.pages.checkBot(bot["id"]);
            if (_pid >= 0) {
              widget.pages.currentPageID = _pid;
              widget.property.onInitPage = false;
            } else if (bot["assistant_id"] != null) {
              print("this is a assistant");
              var thread_id = await assistant.createThread();
              //TODO: save thread_id to bot in db
              assistant.newassistant(
                  widget.pages, widget.property, widget.user, bot, thread_id);
            } else {
              print("this is general bot");
              chats.newBot(widget.pages, widget.property, widget.user,
                  bot["name"], bot["prompts"]);
            }
          }
        });
  }

  Widget BotsList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 200.0;
    final hpaddng = isDisplayDesktop(context) ? 50.0 : 20.0;
    return Expanded(
        child: GridView.builder(
      key: UniqueKey(),
      padding: EdgeInsets.all(hpaddng),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 15.0,
        crossAxisSpacing: 25.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
      ),
      itemCount: botsPublicMe.length,
      itemBuilder: (BuildContext context, int index) {
        return BotTab(context, index);
      },
    ));
  }
}

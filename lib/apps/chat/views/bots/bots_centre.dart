import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import 'package:botsdock/apps/chat/models/bot.dart';

import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import "package:botsdock/apps/chat/utils/constants.dart";
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/views/bots/new_bot.dart';
import 'package:botsdock/apps/chat/vendor/assistants_api.dart';

class BotsCentre extends rp.ConsumerStatefulWidget {
  const BotsCentre({
    super.key,
  });

  @override
  rp.ConsumerState<BotsCentre> createState() => BotsState();
}

class BotsState extends rp.ConsumerState<BotsCentre> {
  final ChatAPI chats = ChatAPI();
  var user_likes = [];
  var botsPublicMe = [];
  final assistant = AssistantsAPI();
  late Future<void> _fetchBotsFuture;

  @override
  void initState() {
    super.initState();
    User user = ref.read(userProvider);
    _fetchBotsFuture =
        Provider.of<Bots>(context, listen: false).fetchBots(user.id);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            GalleryLocalizations.of(context)!.botCentreTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          actions: [
            createBotButton(context),
            SizedBox(width: 15),
          ],
        ),
        // backgroundColor: AppColors.chatPageBackground,
        body: BotsPage(context));
  }

  Widget BotsPage(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Text(GalleryLocalizations.of(context)!.botCentreMe,
            //     textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
            // SizedBox(height: 20),
            // createBotButton(context),
            // SizedBox(height: 30),
            Text(
              GalleryLocalizations.of(context)!.exploreMore,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            FutureBuilder(
                future: _fetchBotsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: SpinKitWaveSpinner(
                          color: AppColors.generatingAnimation,
                          waveColor: const Color.fromARGB(255, 172, 223, 173),
                          // size: AppSize.generatingAnimation,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Expanded(
                      child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: Center(child: Text('Failed to load bots'))),
                    );
                  } else {
                    return Consumer<Bots>(builder: (context, bots, child) {
                      return BotsList(context, bots);
                    });
                  }
                })
          ],
        ));
  }

  Widget createBotButton(BuildContext context) {
    User user = ref.watch(userProvider);
    return Container(
        // padding: EdgeInsets.only(left: isDisplayDesktop(context) ? 50 : 20),
        child: OutlinedButton.icon(
            onPressed: () {
              if (user.isLogedin) {
                Bots bots = Provider.of<Bots>(context, listen: false);
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) =>
                        CreateBot(user: user, bots: bots));
              } else {
                showMessage(context, "请登录");
              }
            },
            icon: Icon(Icons.add),
            label: Text(GalleryLocalizations.of(context)!.botCentreCreate)));
  }

  void deleteBot(Bots bots, Bot bot) async {
    var assistant_id;
    String? _avartar = bot.avatar;
    if (bot.assistant_id != null) assistant_id = bot.assistant_id!;
    var resp = await DioClient().delete(ChatPath.botid(bot.id),
        queryParameters: {"assistant_id": assistant_id});
    if (resp["result"] == "success") {
      //setState(() {
      //widget.bots
      bots.deleteBot(bot.id);
      if (_avartar != null && _avartar.startsWith('http'))
        ChatAPI.deleteOSSObj(_avartar);
      //});
    }
  }

  Widget BotTabEdit(BuildContext context, bot) {
    User user = ref.watch(userProvider);
    Bots bots = Provider.of<Bots>(context, listen: false);
    return PopupMenuButton<String>(
      //initialValue: "edit",
      icon: Icon(Icons.edit_note_rounded, size: 20),
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 3,
      onSelected: (String value) {
        if (value == "edit") {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) =>
                  CreateBot(user: user, bots: bots, bot: bot)).then((_) {
            setState(() {});
          });
        } else if (value == "delete") {
          deleteBot(bots, bot);
        }
      },
      //position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: "edit",
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_rounded, size: 14),
              title: Text(GalleryLocalizations.of(context)!.edit),
            )),
        PopupMenuDivider(height: 1.0),
        PopupMenuItem<String>(
            value: "delete",
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete, size: 14),
              title: Text(GalleryLocalizations.of(context)!.delete),
            )),
      ],
    );
  }

  Widget BotTabtrailing(BuildContext context, bot) {
    return Stack(alignment: Alignment.topRight, children: [
      RichText(
          text: TextSpan(
            text: '${bot["likes"]}',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
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

  Widget buildTab({
    required int rank,
    required Bot bot,
    required onTab,
  }) {
    String? image = bot.avatar;
    String title = bot.name;
    String description = bot.description ?? "";
    String? creator = bot.author_name ?? "anonymous";
    User user = ref.watch(userProvider);
    return Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS15),
        elevation: 0,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          // hoverColor: Color.fromARGB(255, 230, 227, 227).withValues(alpha: 0.3),
          onTap: onTab,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image_show(image!, 40),
                SizedBox(width: 30),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
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
                            style: Theme.of(context).textTheme.labelMedium,
                          )),
                          if (user.id == bot.author_id)
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

  Widget BotTab(BuildContext context, Bots bots, int index) {
    final propertyNotifier = ref.read(propertyProvider.notifier);
    User user = ref.watch(userProvider);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Bot bot = bots.bots_public[index];
    return buildTab(
        rank: index,
        bot: bot,
        onTab: () async {
          if (user.isLogedin) {
            Navigator.pop(context);
            int _pid = pages.checkBot(bot.id);
            if (_pid >= 0) {
              pages.currentPageID = _pid;
              propertyNotifier.setOnInitPage(false);
            } else if (bot.assistant_id != null) {
              String? thread_id = await assistant.createThread();
              //TODO: save thread_id to bot in db
              if (thread_id != null)
                assistant.newassistant(ref, pages, user, thread_id, bot: bot);
            } else {
              chats.newBot(
                ref,
                pages,
                user,
                botID: bot.id,
                name: bot.name,
                prompt: bot.instructions,
                model: bot.model,
                functions: bot.functions,
              );
            }
          } else {
            showMessage(context, "请登录");
          }
        });
  }

  Widget BotsList(BuildContext context, Bots bots) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 200.0;
    final hpaddng = isDisplayDesktop(context) ? 50.0 : 20.0;
    bots.sortBots1();
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
      itemCount: bots.bots_public.length,
      itemBuilder: (BuildContext context, int index) {
        return BotTab(context, bots, index);
      },
    ));
  }
}

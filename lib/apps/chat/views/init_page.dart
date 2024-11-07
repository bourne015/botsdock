import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/utils/prompts.dart';
import 'package:gallery/apps/chat/views/spirit_cat.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/utils.dart';

class InitPage extends StatefulWidget {
  const InitPage({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => InitPageState();
}

class InitPageState extends State<InitPage> with RestorationMixin {
  List<String> gptSub = [
    ...GPTModel().toJson().keys.toList(),
    GPTModel.gptv40Dall
  ];
  List<String> claudeSub = ClaudeModel().toJson().keys.toList();
  String gptDropdownValue = DefaultModelVersion;
  String claudeDropdownValue = DefaultClaudeModel;
  String? selected;
  final ChatGen chats = ChatGen();
  final dio = Dio();
  RestorableBool switchArtifact = RestorableBool(true);

  @override
  String get restorationId => 'switch_test';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchArtifact, 'switch_artifact');
  }

  @override
  void initState() {
    super.initState();
    Property property = Provider.of<Property>(context, listen: false);
    switchArtifact = RestorableBool(property.artifact);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    if (gptSub.contains(property.initModelVersion)) {
      selected = 'ChatGPT';
      gptDropdownValue = property.initModelVersion;
    } else if (claudeSub.contains(property.initModelVersion)) {
      selected = 'Claude';
      claudeDropdownValue = property.initModelVersion;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            modelSelectButton(context),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Chat",
                style: TextStyle(
                    color: AppColors.initPageBackgroundText,
                    fontSize: 55.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (isDisplayDesktop(context) && constraints.maxHeight > 350)
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      // botCard(context, "宠物猫", "assets/images/avatar/cat.png", Prompt.cat),
                      if (isDisplayDesktop(context) ||
                          constraints.maxHeight > 700)
                        CustomCard(
                          icon: Icons.pets,
                          color: const Color.fromARGB(255, 227, 84, 132),
                          title: "用厨房的食材制作食谱",
                          prompt: Prompt.chef,
                        ),
                      if (isDisplayDesktop(context) ||
                          constraints.maxHeight > 700)
                        CustomCard(
                          icon: Icons.translate_outlined,
                          color: const Color.fromARGB(255, 104, 197, 107),
                          title: "翻译员",
                          prompt: Prompt.translator,
                        ),
                      CustomCard(
                        icon: Icons.computer_sharp,
                        color: const Color.fromARGB(255, 241, 227, 104),
                        title: "精通计算机知识的程序员",
                        prompt: Prompt.programer,
                      ),
                      CustomCard(
                        icon: Icons.more_outlined,
                        color: Color.fromARGB(255, 119, 181, 232),
                        title: "五一去成都旅游的攻略",
                        prompt: Prompt.tguide,
                      ),
                    ],
                  )),
            Container(),
          ]);
    });
  }

  Widget botCard(
      BuildContext context, String name, String avartar, String prompt) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 5.0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {
            chats.newBot(pages, property, user, name: name, prompt: prompt);
          },
          child: Ink(
              width: 75,
              height: 75,
              padding: const EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover, image: AssetImage(avartar))),
              child: Container(
                  alignment: Alignment.bottomCenter,
                  //width: double.infinity,
                  color: Color.fromRGBO(128, 128, 128, 0.4),
                  child: Text(name,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                      )))),
        ));
  }

  Widget modelSelectButton(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Stack(alignment: Alignment.topCenter, children: [
      Container(
          margin: EdgeInsets.only(top: 32),
          child: CustomSlidingSegmentedControl(
            initialValue: selected,
            children: {
              'ChatGPT': Row(children: [
                Icon(
                  Icons.flash_on,
                  color: selected == "ChatGPT" ? Colors.green : Colors.grey,
                ),
                const Text('ChatGPT'),
                if (selected == "ChatGPT") gptdropdownMenu(context),
              ]),
              'Claude': Row(children: [
                Icon(
                  Icons.workspaces,
                  color: selected == "Claude" ? Colors.purple : Colors.grey,
                ),
                const Text('Claude'),
                if (selected == "Claude") claudedropdownMenu(context),
              ]),
            },
            decoration: BoxDecoration(
              //color: CupertinoColors.lightBackgroundGray,
              color: AppColors.modelSelectorBackground!,
              borderRadius: BORDERRADIUS10,
            ),
            thumbDecoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BORDERRADIUS10,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.3),
                  blurRadius: 4.0,
                  spreadRadius: 1.0,
                  offset: Offset(0.0, 2.0),
                )
              ],
            ),
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
            onValueChanged: (value) {
              if (value == 'ChatGPT') {
                property.initModelVersion = DefaultModelVersion;
              } else {
                property.initModelVersion = DefaultClaudeModel;
              }
              selected = value;
            },
          )),
      SpiritCat(),
    ]);
  }

  Widget gptdropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: gptDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.modelSelectorBackground,
          child: Text(allModels[gptDropdownValue]!,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        gptDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, gptSub[0], "3.5", "ChatGPT 3.5",
        //     GalleryLocalizations.of(context)?.chatGPT35Desc ?? ''),
        _buildPopupMenuItem(context, gptSub[3], "mini", "ChatGPT 4o mini",
            GalleryLocalizations.of(context)?.chatGPT4oMiniDesc ?? ''),
        _buildPopupMenuItem(context, gptSub[2], "4o", "ChatGPT 4o",
            GalleryLocalizations.of(context)?.chatGPT4oDesc ?? ''),
        _buildPopupMenuItem(context, gptSub[1], "4.0", "ChatGPT 4.0",
            GalleryLocalizations.of(context)?.chatGPT40Desc ?? ''),
        _buildPopupMenuItem(context, gptSub[4], "D·E", "DALL·E 3",
            GalleryLocalizations.of(context)?.dallEDesc ?? ''),
        PopupMenuDivider(),
        _buildArtifactSwitch(context),
      ],
    );
  }

  Widget modelTabAvatar(BuildContext context, String t) {
    return CircleAvatar(
      backgroundColor: AppColors.chatPageBackground,
      child: Text(
        t,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[300]),
      ),
    );
  }

  Widget claudedropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: claudeDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.modelSelectorBackground,
          child: Text(allModels[claudeDropdownValue]![0],
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        claudeDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, claudeSub[0], "H", "Claude3 - Haiku",
        //     GalleryLocalizations.of(context)?.claude3HaikuDesc ?? ''),
        // _buildPopupMenuItem(context, claudeSub[1], "S", "Claude3 - Sonnet",
        //     GalleryLocalizations.of(context)?.claude3SonnetDesc ?? ''),
        _buildPopupMenuItem(context, claudeSub[2], "O", "Claude3 - Opus",
            GalleryLocalizations.of(context)?.claude3OpusDesc ?? ''),
        _buildPopupMenuItem(context, claudeSub[4], "H", "Claude3.5 - Haiku",
            GalleryLocalizations.of(context)?.claude3HaikuDesc ?? ''),
        _buildPopupMenuItem(context, claudeSub[3], "S", "Claude3.5 - Sonnet",
            GalleryLocalizations.of(context)?.claude35SonnetDesc ?? ''),
        PopupMenuDivider(),
        _buildArtifactSwitch(context),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(BuildContext context, String value,
      String icon, String title, String description) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      value: value,
      child: Material(
        //color: Colors.transparent,
        color: AppColors.drawerBackground,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BORDERRADIUS15,
          ),
          child: InkWell(
            borderRadius: BORDERRADIUS15,
            onTap: () {
              Navigator.pop(context, value);
            },
            //onHover: (hovering) {},
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              leading: modelTabAvatar(context, icon),
              title: Text(title),
              subtitle: Text(description,
                  style: TextStyle(fontSize: 12.5, color: AppColors.subTitle)),
              trailing:
                  claudeDropdownValue == value || gptDropdownValue == value
                      ? Icon(Icons.check, color: Colors.blue[300])
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildArtifactSwitch(BuildContext context) {
    Property property = Provider.of<Property>(context, listen: false);
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
              //color: Colors.transparent,
              color: AppColors.drawerBackground,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BORDERRADIUS15,
                ),
                child: InkWell(
                  borderRadius: BORDERRADIUS15,
                  onTap: () {
                    // Navigator.pop(context, value);
                  },
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      leading: Icon(Icons.visibility_outlined),
                      title: Text("可视化(experimental)"),
                      subtitle: Text("提供图表、动画、地图、网页预览等可视化内容",
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.subTitle)),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: switchArtifact.value,
                          activeColor: Colors.blue[300],
                          onChanged: (value) {
                            setState(() {
                              switchArtifact.value = value;
                              property.artifact = switchArtifact.value;
                            });
                          },
                        ),
                      )),
                ),
              ));
        }));
  }
}

class CustomCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String prompt;
  final ChatGen chats = ChatGen();

  CustomCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.prompt});

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Card(
            shape: OutlineInputBorder(
              borderSide: BorderSide(
                  style: BorderStyle.solid,
                  width: 0.7,
                  color: Color.fromARGB(255, 206, 204, 204)),
              borderRadius: BORDERRADIUS15,
            ),
            elevation: 1,
            child: Material(
              child: Ink(
                decoration: BoxDecoration(
                    color: AppColors.chatPageBackground,
                    borderRadius: const BorderRadius.all(Radius.circular(15))),
                child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    hoverColor:
                        Color.fromARGB(255, 230, 227, 227).withOpacity(0.3),
                    onTap: () {
                      if (user.isLogedin)
                        chats.newTextChat(pages, property, user, prompt);
                      else
                        showMessage(context, "请登录");
                    },
                    child: Container(
                        width: 150,
                        height: 100,
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Icon(
                                  icon,
                                  size: 20.0,
                                  color: color,
                                )),
                            SizedBox(height: 8),
                            Align(
                                alignment: Alignment.topLeft,
                                child:
                                    Text(title, style: TextStyle(fontSize: 15)))
                          ],
                        ))),
              ),
            )));
  }
}

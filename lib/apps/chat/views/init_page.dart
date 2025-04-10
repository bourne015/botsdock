import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/apps/chat/utils/prompts.dart';
import 'package:botsdock/apps/chat/views/spirit_cat.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';

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

class InitPageState extends State<InitPage> {
  List<String> gptSub = [
    ...GPTModel.all,
    GPTModel.gptv40Dall,
  ];
  String gptDropdownValue = DefaultModelVersion;
  String claudeDropdownValue = DefaultClaudeModel;
  String deepseekDropdownValue = DefaultDeepSeekModel;
  String geminiDropdownValue = DefaultGeminiModel;
  String? selected;
  final ChatAPI chats = ChatAPI();
  // RestorableBool switchArtifact = RestorableBool(true);
  // RestorableBool switchInternet = RestorableBool(true);

  // @override
  // String get restorationId => 'switch_test';
  // @override
  // void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
  //   registerForRestoration(switchArtifact, 'switch_artifact');
  //   registerForRestoration(switchInternet, 'switch_internet');
  // }

  @override
  void initState() {
    super.initState();
    // Property property = Provider.of<Property>(context, listen: false);
    // switchArtifact = RestorableBool(property.artifact);
    // switchInternet = RestorableBool(property.internet);
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
    } else if (ClaudeModel.all.contains(property.initModelVersion)) {
      selected = 'Claude';
      claudeDropdownValue = property.initModelVersion;
    } else if (DeepSeekModel.all.contains(property.initModelVersion)) {
      selected = 'DeepSeek';
      deepseekDropdownValue = property.initModelVersion;
    } else if (GeminiModel.all.contains(property.initModelVersion)) {
      selected = 'Gemini';
      geminiDropdownValue = property.initModelVersion;
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
                style: Theme.of(context).textTheme.displayLarge,
                // style: TextStyle(
                //   // color: AppColors.initPageBackgroundText,
                //   fontSize: 55.0,
                //   fontWeight: FontWeight.bold,
                // ),
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
                          title: "使用说明",
                          prompt: "describe",
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
          // splashColor: Colors.blue.withAlpha(30),
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
                  // color: Color.fromRGBO(128, 128, 128, 0.4),
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
                Tooltip(
                    message: selected != "ChatGPT" ? "ChatGPT" : "",
                    child: Image.asset(
                      "assets/images/openai.png",
                      height: 24,
                      width: 24,
                      color: selected == "ChatGPT" ? Colors.teal : Colors.grey,
                    )),
                if (selected == "ChatGPT")
                  Container(
                      width: 65,
                      child: Text(' ChatGPT',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (selected == "ChatGPT") gptdropdownMenu(context),
              ]),
              'Claude': Row(children: [
                Tooltip(
                    message: selected != "Claude" ? "Claude" : "",
                    child: Image.asset(
                      "assets/images/anthropic.png",
                      height: 24,
                      width: 24,
                      color: selected == "Claude"
                          ? Colors.yellow[900]
                          : Colors.grey,
                    )),
                if (selected == "Claude")
                  Container(
                      width: 65,
                      child: Text(' Claude',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (selected == "Claude") claudedropdownMenu(context),
              ]),
              'Gemini': Row(children: [
                Tooltip(
                    message: selected != "Gemini" ? "Gemini" : "",
                    child: Image.asset(
                      "assets/images/google.png",
                      height: 24,
                      width: 24,
                      color: selected == "Gemini" ? null : Colors.grey,
                    )),
                if (selected == "Gemini")
                  Container(
                      width: 65,
                      child: Text(' Gemini ',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (selected == "Gemini") geminidropdownMenu(context),
              ]),
              'DeepSeek': Row(children: [
                Tooltip(
                    message: selected != "DeepSeek" ? "DeepSeek" : "",
                    child: Image.asset(
                      "assets/images/deepseek.png",
                      height: 24,
                      width: 24,
                      color: selected == "DeepSeek" ? Colors.blue : Colors.grey,
                    )),
                if (selected == "DeepSeek")
                  Container(
                      width: 65,
                      child: Text('DeepSeek',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (selected == "DeepSeek") deepseekdropdownMenu(context),
              ]),
            },
            decoration: BoxDecoration(
              borderRadius: BORDERRADIUS10,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            thumbDecoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BORDERRADIUS10,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .3),
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
              } else if (value == 'Claude') {
                property.initModelVersion = DefaultClaudeModel;
              } else if (value == 'DeepSeek') {
                property.initModelVersion = DefaultDeepSeekModel;
              } else if (value == 'Gemini') {
                property.initModelVersion = DefaultGeminiModel;
              }
              selected = value;
              Global.saveProperties(model: property.initModelVersion);
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
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.modelSelectorBackground,
        child: Text(
          allModels[gptDropdownValue]!,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        gptDropdownValue = value;
      },
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, gptSub[0], "3.5", "ChatGPT 3.5",
        //     GalleryLocalizations.of(context)?.chatGPT35Desc ?? ''),
        _buildPopupMenuItem(
          context: context,
          value: GPTModel.gptv4omini,
          inputType: "多模态",
          title: "ChatGPT 4o mini",
          description:
              GalleryLocalizations.of(context)?.chatGPT4oMiniDesc ?? '',
        ),
        // _buildPopupMenuItem(
        //   context: context,
        //   value: gptSub[5],
        //   inputType: "文本",
        //   title: "ChatGPT o3-mini",
        //   description: GalleryLocalizations.of(context)?.chatGPTo3mDesc ?? '',
        // ),
        _buildPopupMenuItem(
          context: context,
          value: GPTModel.gptv4o,
          inputType: "多模态",
          title: "GPT 4o",
          description: GalleryLocalizations.of(context)?.chatGPT4oDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: GPTModel.gptvo3mini,
          inputType: "文本",
          title: "GPT o3-mini",
          description: GalleryLocalizations.of(context)?.chatGPTo3mDesc ?? '',
        ),
        // _buildPopupMenuItem(
        //   context: context,
        //   value: gptSub[4],
        //   inputType: "多模态",
        //   title: "ChatGPT o1",
        //   description: GalleryLocalizations.of(context)?.chatGPTo1Desc ?? '',
        // ),
        _buildPopupMenuItem(
          context: context,
          value: GPTModel.gptv40Dall,
          inputType: "文本",
          title: "DALL·E 3",
          description: GalleryLocalizations.of(context)?.dallEDesc ?? '',
        ),
        // PopupMenuDivider(),
        // _buildArtifactSwitch(context),
        // _buildInternetSwitch(context, "Google"),
      ],
    );
  }

  Widget claudedropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: claudeDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.modelSelectorBackground,
        child: Text(
          allModels[claudeDropdownValue]![0],
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        claudeDropdownValue = value;
      },
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, claudeSub[0], "H", "Claude3 - Haiku",
        //     GalleryLocalizations.of(context)?.claude3HaikuDesc ?? ''),
        // _buildPopupMenuItem(context, claudeSub[1], "S", "Claude3 - Sonnet",
        //     GalleryLocalizations.of(context)?.claude3SonnetDesc ?? ''),
        _buildPopupMenuItem(
          context: context,
          value: ClaudeModel.sonnet_37,
          inputType: "多模态",
          title: "Claude3.7 - Sonnet",
          description:
              GalleryLocalizations.of(context)?.claude37SonnetDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: ClaudeModel.sonnet_35,
          inputType: "多模态",
          title: "Claude3.5 - Sonnet",
          description:
              GalleryLocalizations.of(context)?.claude35SonnetDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: ClaudeModel.haiku_35,
          inputType: "多模态",
          title: "Claude3.5 - Haiku",
          description: GalleryLocalizations.of(context)?.claude3HaikuDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: ClaudeModel.opus,
          inputType: "多模态",
          title: "Claude3 - Opus",
          description: GalleryLocalizations.of(context)?.claude3OpusDesc ?? '',
        ),
        // PopupMenuDivider(),
        // _buildArtifactSwitch(context),
        // _buildInternetSwitch(context, "Google"),
      ],
    );
  }

  Widget geminidropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: geminiDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.modelSelectorBackground,
        child: Text(
          allModels[geminiDropdownValue]!,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        geminiDropdownValue = value;
      },
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, gptSub[0], "3.5", "ChatGPT 3.5",
        //     GalleryLocalizations.of(context)?.chatGPT35Desc ?? ''),
        _buildPopupMenuItem(
          context: context,
          value: GeminiModel.pro_15,
          inputType: "多模态",
          title: "Gemini Pro 1.5",
          description: GalleryLocalizations.of(context)?.geminiDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: GeminiModel.flash_20,
          inputType: "多模态",
          title: "Gemini Flash 2.0",
          description: GalleryLocalizations.of(context)?.geminiDesc ?? '',
        ),
        // PopupMenuDivider(),
        // _buildArtifactSwitch(context),
        // _buildInternetSwitch(context, "Google"),
      ],
    );
  }

  Widget deepseekdropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: deepseekDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.modelSelectorBackground,
        child: Text(
          allModels[deepseekDropdownValue]!,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        property.initModelVersion = value;
        deepseekDropdownValue = value;
      },
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // _buildPopupMenuItem(context, gptSub[0], "3.5", "ChatGPT 3.5",
        //     GalleryLocalizations.of(context)?.chatGPT35Desc ?? ''),
        _buildPopupMenuItem(
          context: context,
          value: DeepSeekModel.dc,
          inputType: "文本",
          title: "DeepSeek V3",
          description: GalleryLocalizations.of(context)?.deepseekDesc ?? '',
        ),
        _buildPopupMenuItem(
          context: context,
          value: DeepSeekModel.dc_r,
          inputType: "文本",
          title: "DeepSeek R1",
          description: GalleryLocalizations.of(context)?.deepseekR1Desc ?? '',
        ),
        // PopupMenuDivider(),
        // _buildArtifactSwitch(context),
        // _buildInternetSwitch(context, "Google"),
      ],
    );
  }

  Widget inputTypeIcon(String inputs) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // gradient: const LinearGradient(
        //   colors: [Colors.lightBlueAccent, Colors.blueAccent],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: Colors.yellowAccent,
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.transparent, // 使用渐变背景
        child: Text(
          inputs,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(1, 1),
              )
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required BuildContext context,
    required String value,
    required String inputType,
    required String title,
    required String description,
  }) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      value: value,
      child: Material(
        //color: Colors.transparent,
        // color: AppColors.drawerBackground,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BORDERRADIUS15,
          ),
          child: InkWell(
            borderRadius: BORDERRADIUS15,
            onTap: () {
              Global.saveProperties(model: value);
              Navigator.pop(context, value);
            },
            //onHover: (hovering) {},
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              leading: inputTypeIcon(inputType),
              title: Text(title),
              subtitle: Text(description,
                  style: TextStyle(fontSize: 12.5, color: AppColors.subTitle)),
              trailing: deepseekDropdownValue == value ||
                      geminiDropdownValue == value ||
                      claudeDropdownValue == value ||
                      gptDropdownValue == value
                  ? Icon(Icons.check, color: Colors.blue[300])
                  : null,
            ),
          ),
        ),
      ),
    );
  }
/*
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
                  // onTap: null,
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      leading: Icon(
                        Icons.auto_graph,
                        color: switchArtifact.value ? Colors.blue[700] : null,
                      ),
                      title: Text("可视化(Beta)"),
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
                            Global.saveProperties(artifact: property.artifact);
                          },
                        ),
                      )),
                ),
              ));
        }));
  }

  PopupMenuItem<String> _buildInternetSwitch(
      BuildContext context, String? engine) {
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
                  // onTap: null,
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      leading: Icon(Icons.cloud,
                          color:
                              switchInternet.value ? Colors.yellow[800] : null),
                      title: Text("联网功能(Beta)"),
                      subtitle: Text("获取${engine}搜索的结果",
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.subTitle)),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: switchInternet.value,
                          activeColor: Colors.blue[300],
                          onChanged: (value) {
                            setState(() {
                              switchInternet.value = value;
                              property.internet = switchInternet.value;
                            });
                            Global.saveProperties(internet: property.internet);
                          },
                        ),
                      )),
                ),
              ));
        }));
  }
  */
}

class CustomCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String prompt;
  final ChatAPI chats = ChatAPI();

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
          // shape: OutlineInputBorder(
          //   borderSide: BorderSide(
          //     style: BorderStyle.solid,
          //     width: 0.7,
          //     // color: Color.fromARGB(255, 206, 204, 204),
          //   ),
          //   borderRadius: BORDERRADIUS15,
          // ),
          // elevation: 1,
          child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              // hoverColor: Color.fromARGB(255, 230, 227, 227)
              //     .withValues(alpha: 0.3),
              onTap: () {
                if (title == "使用说明")
                  describe(
                    context: context,
                    title: title,
                  );
                else if (user.isLogedin)
                  chats.newTextChat(pages, property, user, prompt);
                else
                  showMessage(context, "请登录");
              },
              child: Container(
                  width: 150,
                  height: 100,
                  padding: EdgeInsets.all(10.0),
                  // decoration: BoxDecoration(
                  //     borderRadius:
                  //         const BorderRadius.all(Radius.circular(15))),
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
                          child: Text(title, style: TextStyle(fontSize: 15)))
                    ],
                  ))),
        ));
  }

  void describe({context, var title}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        // backgroundColor: AppColors.chatPageBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: ClipRRect(
          borderRadius: BORDERRADIUS15,
          child: Container(
            width: 500,
            margin: EdgeInsets.fromLTRB(35, 30, 0, 0),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: _describe,
                // styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                styleSheet: MarkdownStyleSheet(
                  tableColumnWidth: FixedColumnWidth(150),
                  tablePadding: EdgeInsets.symmetric(horizontal: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _describe = """
### 1.输入格式

##### GPT
  - [x] 文本
  - [x] 图片: JPEG, PNG, GIF, WEBP
  - [x] 文档, 支持常用文档格式(PDF, DOC, PPT, TXT...), 功能待完善

##### Claude
  - [x] 文本
  - [x] 图片
  - [x] 文档, 仅支持PDF

##### Gemini
  - [x] 文本
  - [x] 图片
  - [x] 文档: PDF、文本文档(py, js, txt, html, css, md, csv,xml, rtf)

##### DeepSeek
  - [x] 文本
  - [ ] 图片
  - [ ] 文档

### 2.可视化
- 可视化功能支持生成**流程图**、**甘特图**、**时序图**、**思维导图**、**网页**等；
- Gemini不支持可视化输出

### 3.文档生成
- 仅GPT系列模型支持生成文档, 有两种方式:
- **方式1**: 新建智能体中开启'代码解释器(Code Interpreter)'后即支持生成文档，'Data Analyst'智能体已开启code Interpreter
- **方式2**: 新会话选择GPT模型并添加附件文档后, 会自动开启Code Interpreter和File Search功能

### 4.temperature设置
- Claude系列模型的范围是: [0.0, 1.0], 其余模型范围: [0.0, 2.0]
- 较低的值(例如0.2)将使其更加集中和确定, 适合对于分析/解题/多项选择
- 较高的值(如1.5)将使输出更加随机,适合对于创造性和生成性任务
- 如不确定怎么设置,可将值设置到最小(-0.1), 此时后端将缺省设置, 模型端会使用默认值

| 场景 | temperature |
| --- | --- |
| 代码生成/数学解题| 0.1 |
| 数据分析 |  1.0|
| 通用对话 |  1.3|
| 翻译| 1.3 |
| 创意类写作| 1.5 |

### 5.tips
- 手机端, 在浏览器中将页面添加到主屏幕, 可将网站作为PWA应用
""";

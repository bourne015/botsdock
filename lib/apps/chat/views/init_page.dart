import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/utils/prompts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import './input_field.dart';
import '../utils/utils.dart';

class InitPage extends StatefulWidget {
  const InitPage({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => InitPageState();
}

class InitPageState extends State<InitPage> {
  List<String> gptSub = <String>['3.5', '4.0', '4o', 'DALL'];
  List<String> claudeSub = <String>['Haiku', 'Sonnet', 'Opus', "Sonnet_3.5"];
  String gptDropdownValue = '4o';
  String claudeDropdownValue = 'Sonnet_3.5';
  String? selected;
  final ChatGen chats = ChatGen();
  final dio = Dio();

  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    switch (property.initModelVersion) {
      case GPTModel.gptv35:
        selected = 'ChatGPT';
        gptDropdownValue = gptSub[0];
        break;
      case GPTModel.gptv40:
        selected = 'ChatGPT';
        gptDropdownValue = gptSub[1];
        break;
      // case GPTModel.gptv40Vision:
      //   selected = 'ChatGPT';
      //   gptDropdownValue = gptSub[2];
      //   break;
      case GPTModel.gptv4o:
        selected = 'ChatGPT';
        gptDropdownValue = gptSub[2];
      case GPTModel.gptv40Dall:
        selected = 'ChatGPT';
        gptDropdownValue = gptSub[3];
        break;
      case ClaudeModel.haiku:
        selected = 'Claude';
        claudeDropdownValue = claudeSub[0];
        break;
      case ClaudeModel.sonnet:
        selected = 'Claude';
        claudeDropdownValue = claudeSub[1];
        break;
      case ClaudeModel.opus:
        selected = 'Claude';
        claudeDropdownValue = claudeSub[2];
        break;
      case ClaudeModel.sonnet_35:
        selected = 'Claude';
        claudeDropdownValue = claudeSub[3];
        break;
      default:
        break;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            modelSelectButton(context),
            Align(
                alignment: Alignment.center,
                child: Text(
                  "Chat",
                  style: TextStyle(
                      color: AppColors.initPageBackgroundText,
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold),
                )),
            if (isDisplayDesktop(context) && constraints.maxHeight > 350)
              Align(
                  alignment: Alignment.center,
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
                          title: "帮我进行汉英互译",
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
            Align(
                alignment: Alignment.bottomCenter,
                child: const ChatInputField()),
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
    return Container(
      margin: const EdgeInsets.only(top: 25),
      child: CupertinoSlidingSegmentedControl<String>(
        thumbColor: AppColors.modelSelected,
        backgroundColor: AppColors.modelSelectorBackground!,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        // This represents a currently selected segmented control.
        groupValue: selected,
        // Callback that sets the selected segmented control.
        onValueChanged: (String? value) {
          if (value == 'ChatGPT') {
            property.initModelVersion = DefaultModelVersion;
          } else {
            property.initModelVersion = DefaultClaudeModel;
          }
          selected = value;
        },
        children: <String, Widget>{
          'ChatGPT': Padding(
            padding: const EdgeInsets.only(left: 22, top: 7, bottom: 7),
            child: Row(children: [
              Icon(
                Icons.flash_on,
                color: selected == "ChatGPT" ? Colors.green : Colors.grey,
              ),
              const Text('ChatGPT'),
              //const SizedBox(width: 8),
              if (selected == "ChatGPT") gptdropdownMenu(context),
            ]),
          ),
          'Claude': Padding(
            padding: const EdgeInsets.only(left: 26, top: 7, bottom: 7),
            child: Row(children: [
              Icon(
                Icons.workspaces,
                color: selected == "Claude" ? Colors.purple : Colors.grey,
              ),
              const Text('Claude'),
              const SizedBox(width: 8),
              if (selected == "Claude") claudedropdownMenu(context),
            ]),
          ),
        },
      ),
    );
  }

  Widget gptdropdownMenu(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return PopupMenuButton<String>(
      initialValue: gptDropdownValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 2,
      icon: CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.modelSelectorBackground,
          child: Text(gptDropdownValue[0],
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        if (value == gptSub[0]) {
          property.initModelVersion = GPTModel.gptv35;
        } else if (value == gptSub[1]) {
          property.initModelVersion = GPTModel.gptv40;
        } else if (value == gptSub[2]) {
          property.initModelVersion = GPTModel.gptv4o;
        } else if (value == gptSub[3]) {
          property.initModelVersion = GPTModel.gptv40Dall;
        }
        gptDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(context, "3.5", "3.5", "ChatGPT 3.5",
            GalleryLocalizations.of(context)?.chatGPT35Desc ?? ''),
        _buildPopupMenuItem(context, "4.0", "4.0", "ChatGPT 4.0",
            GalleryLocalizations.of(context)?.chatGPT40Desc ?? ''),
        _buildPopupMenuItem(context, "4o", "4o", "ChatGPT 4o",
            GalleryLocalizations.of(context)?.chatGPT4oDesc ?? ''),
        _buildPopupMenuItem(context, "DALL", "D", "DALL·E 3",
            GalleryLocalizations.of(context)?.dallEDesc ?? ''),
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
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 2,
      icon: CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.modelSelectorBackground,
          child: Text(claudeDropdownValue[0],
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        if (value == claudeSub[0]) {
          property.initModelVersion = ClaudeModel.haiku;
        } else if (value == claudeSub[1]) {
          property.initModelVersion = ClaudeModel.sonnet;
        } else if (value == claudeSub[2]) {
          property.initModelVersion = ClaudeModel.opus;
        } else if (value == claudeSub[3]) {
          property.initModelVersion = ClaudeModel.sonnet_35;
        }
        claudeDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(context, "Haiku", "H", "Claude3 - Haiku",
            GalleryLocalizations.of(context)?.claude3HaikuDesc ?? ''),
        _buildPopupMenuItem(context, "Sonnet", "S", "Claude3 - Sonnet",
            GalleryLocalizations.of(context)?.claude3SonnetDesc ?? ''),
        _buildPopupMenuItem(context, "Opus", "O", "Claude3 - Opus",
            GalleryLocalizations.of(context)?.claude3OpusDesc ?? ''),
        _buildPopupMenuItem(context, "Sonnet_3.5", "S", "Claude3.5 - Sonnet",
            GalleryLocalizations.of(context)?.claude35SonnetDesc ?? ''),
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
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
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
              borderRadius: BorderRadius.circular(15.0),
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

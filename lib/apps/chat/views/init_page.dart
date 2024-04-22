import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/prompts.dart';
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
  List<String> gptSub = <String>['3.5', '4.0', 'DALL'];
  List<String> claudeSub = <String>['Haiku', 'Sonnet', 'Opus'];
  String gptDropdownValue = '3.5';
  String claudeDropdownValue = 'Haiku';
  String? selected;
  final ChatGen chats = ChatGen();

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    switch (pages.defaultModelVersion) {
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
      case GPTModel.gptv40Dall:
        selected = 'ChatGPT';
        gptDropdownValue = gptSub[2];
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
      default:
        break;
    }

    return Column(children: <Widget>[
      Row(children: [
        const Spacer(),
        modelSelectButton(context),
        const Spacer(),
      ]),
      Row(children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Text(
            "ChatGPT",
            style: TextStyle(
                color: AppColors.initPageBackgroundText,
                fontSize: 35.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
      ]),
      Expanded(
        child: Container(),
      ),
      Expanded(
          child: Container(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          //crossAxisCount: 1,
          // mainAxisSpacing: 3,
          // crossAxisSpacing: 3,
          //shrinkWrap: true,
          //padding: const EdgeInsets.only(left: 70, bottom: 20),
          //childAspectRatio: 1,
          //scrollDirection: Axis.horizontal,
          children: [
            botCard(context, "宠物猫", "assets/images/avatar/cat.png", Prompt.cat),
            botCard(
                context, "占卜师", "assets/images/avatar/augur.png", Prompt.augur),
            botCard(context, "程序员", "assets/images/avatar/hacker.png",
                Prompt.program),
            //botCard(context, "旅行规划", "", ""),
            SizedBox(
                width: 75,
                height: 75,
                child: ElevatedButton(
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                      elevation: MaterialStateProperty.all(5.0),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      )),
                      padding: MaterialStateProperty.all(EdgeInsets.all(5)),
                    ),
                    onPressed: () {},
                    child: Text("更多...")))
          ],
        ),
      )),
      const ChatInputField(),
    ]);
  }

  Widget botCard(
      BuildContext context, String name, String avartar, String prompt) {
    Pages pages = Provider.of<Pages>(context);
    User user = Provider.of<User>(context);
    return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 5.0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {
            newBot(pages, user, name, prompt);
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

  void newBot(pages, user, name, prompt) {
    int handlePageID = pages.addPage(Chat(title: name));
    pages.displayInitPage = false;
    pages.currentPageID = handlePageID;
    pages.setPageTitle(handlePageID, name + " - $handlePageID");
    pages.currentPage?.modelVersion = pages.defaultModelVersion;

    Message msgQ = Message(
        id: 0,
        pageID: handlePageID,
        role: MessageRole.system,
        type: MsgType.text,
        content: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    pages.addMessage(handlePageID, msgQ);
    chats.submitText(pages, handlePageID, user);
  }

  Widget modelSelectButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
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
            pages.defaultModelVersion = GPTModel.gptv35;
          } else {
            pages.defaultModelVersion = ClaudeModel.haiku;
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
    Pages pages = Provider.of<Pages>(context);
    return PopupMenuButton<String>(
      initialValue: gptDropdownValue,
      tooltip: "select model",
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      icon: CircleAvatar(
          radius: 12,
          child: Text(gptDropdownValue[0],
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        if (value == gptSub[0]) {
          pages.defaultModelVersion = GPTModel.gptv35;
        } else if (value == gptSub[1]) {
          pages.defaultModelVersion = GPTModel.gptv40;
        }
        // else if (value == gptSub[2]) {
        //   pages.defaultModelVersion = GPTModel.gptv40Vision;
        // }
        else if (value == gptSub[2]) {
          pages.defaultModelVersion = GPTModel.gptv40Dall;
        }
        gptDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: "3.5",
          child: ListTile(
            leading: CircleAvatar(child: Text('3.5')),
            title: Text("ChatGPT 3.5"),
            subtitle: Text(
              'understand and generate natural language or code',
              style: TextStyle(color: AppColors.subTitle),
            ),
            //trailing: Icon(Icons.favorite_rounded),
          ),
        ),
        const PopupMenuItem<String>(
          value: "4.0",
          child: ListTile(
            leading: CircleAvatar(child: Text('4.0')),
            title: Text("ChatGPT 4.0"),
            subtitle: Text(
              'solve difficult problems with greater accuracy',
              style: TextStyle(color: AppColors.subTitle),
            ),
            //trailing: Icon(Icons.favorite_rounded),
          ),
        ),
        // const PopupMenuItem<String>(
        //   value: "Vision",
        //   child: ListTile(
        //     leading: CircleAvatar(child: Text('V')),
        //     title: Text("ChatGPT 4.0 - vision"),
        //     subtitle: Text(
        //       'GPT-4 with the ability to understand images.',
        //       style: TextStyle(color: AppColors.subTitle),
        //     ),
        //   ),
        // ),
        const PopupMenuItem<String>(
          value: "DALL",
          child: ListTile(
            leading: CircleAvatar(child: Text('D')),
            title: Text("DALL·E 3"),
            subtitle: Text(
              'A model that can generate and edit images given a natural language prompt',
              style: TextStyle(color: AppColors.subTitle),
            ),
          ),
        ),
      ],
    );
  }

  Widget claudedropdownMenu(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return PopupMenuButton<String>(
      initialValue: claudeDropdownValue,
      tooltip: "select model",
      //icon: Icon(color: Colors.grey, size: 10, Icons.south),
      icon: CircleAvatar(
          radius: 12,
          child: Text(claudeDropdownValue[0],
              style: const TextStyle(fontSize: 10.5, color: Colors.grey))),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (String value) {
        if (value == claudeSub[0]) {
          pages.defaultModelVersion = ClaudeModel.haiku;
        } else if (value == claudeSub[1]) {
          pages.defaultModelVersion = ClaudeModel.sonnet;
        } else if (value == claudeSub[2]) {
          pages.defaultModelVersion = ClaudeModel.opus;
        }
        claudeDropdownValue = value;
      },
      position: PopupMenuPosition.over,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: "Haiku",
          child: ListTile(
            leading: CircleAvatar(child: Text('H')),
            title: Text("Claude3 - Haiku"),
            subtitle: Text(
              'Fastest and most compact model for near-instant responsiveness',
              style: TextStyle(color: AppColors.subTitle),
            ),
            //trailing: Icon(Icons.favorite_rounded),
          ),
        ),
        const PopupMenuItem<String>(
          value: "Sonnet",
          child: ListTile(
            leading: CircleAvatar(child: Text('S')),
            title: Text("Claude3 - Sonnet"),
            subtitle: Text(
              'Ideal balance of intelligence and speed for enterprise workloads',
              style: TextStyle(color: AppColors.subTitle),
            ),
          ),
        ),
        const PopupMenuItem<String>(
          value: "Opus",
          child: ListTile(
            leading: CircleAvatar(child: Text('O')),
            title: Text("Claude3 - Opus"),
            subtitle: Text(
              'Most powerful model for highly complex tasks',
              style: TextStyle(color: AppColors.subTitle),
            ),
          ),
        ),
      ],
    );
  }
}

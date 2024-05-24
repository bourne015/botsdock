import 'package:dio/dio.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:gallery/apps/chat/models/user.dart';

import "../utils/constants.dart";
import '../utils/utils.dart';

class Bots extends StatefulWidget {
  final bots;
  final user;
  const Bots({super.key, required this.bots, required this.user});

  @override
  State<Bots> createState() => BotsState();
}

class BotsState extends State<Bots> {
  final dio = Dio();
  var user_likes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('智能体中心',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        body: BotsPage(context));
  }

  Widget BotsPage(BuildContext context) {
    //User user = Provider.of<User>(context, listen: false);
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text('我的',
                textAlign: TextAlign.left, style: TextStyle(fontSize: 18.5)),
            SizedBox(height: 20),
            Container(
                padding: EdgeInsets.only(left: 25),
                child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => CreateBot(user: widget.user));
                    },
                    icon: Icon(Icons.add),
                    label: Text("创建智能体"))),
            SizedBox(height: 30),
            Text('探索更多', style: TextStyle(fontSize: 18.5)),
            BotsList(context),
          ],
        ));
  }

  void deleteBot(bot) async {
    var _delBotURL = botURL + "/${bot["id"]}";
    var resp = await Dio().delete(_delBotURL);
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

  Widget BotTabEdit(BuildContext context, user, bot) {
    return PopupMenuButton<String>(
      initialValue: "edit",
      icon: Icon(Icons.edit_note_rounded),
      onSelected: (String value) {
        if (value == "edit") {
          showDialog(
              context: context,
              builder: (context) =>
                  CreateBot(user: user, bots: widget.bots, bot: bot)).then((_) {
            setState(() {});
          });
        } else if (value == "delete") {
          deleteBot(bot);
        }
      },
      //position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
            value: "edit",
            child: ListTile(
              leading: Icon(Icons.edit_rounded, size: 14),
              title: Text("edit"),
            )),
        const PopupMenuItem<String>(
            value: "delete",
            child: ListTile(
              leading: Icon(Icons.delete, size: 14),
              title: Text("delete"),
            )),
      ],
    );
  }

  Widget BotTabSubtitle(BuildContext context, user, bot) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                  text: bot["description"],
                  style: TextStyle(fontSize: 13.5, color: AppColors.msgText)),
              maxLines: 2),
          RichText(
              text: TextSpan(
                text: '作者: ${bot["author_name"]}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              maxLines: 1),
          if (widget.user.id == bot["author_id"]) BotTabEdit(context, user, bot)
          //IconButton(icon: Icon(Icons.edit_note_rounded), onPressed: () {}),
        ]);
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

  Widget BotTab(BuildContext context, index) {
    var bot = widget.bots[index];
    return Container(
        //color: Colors.grey[300],
        decoration: BoxDecoration(
            //color: AppColors.inputBoxBackground,
            color: Colors.grey.withAlpha(50),
            borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: ListTile(
            dense: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            selectedTileColor: AppColors.drawerTabSelected,
            selected: false, //pages.currentPageID == bot.id,
            //leading: const Icon(Icons.chat_bubble_outline, size: 16),
            //minLeadingWidth: 0,
            //minVerticalPadding: 30,
            isThreeLine: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: Container(
              child: Image.network(
                bot["avatar"],
                fit: BoxFit.cover,
              ),
            ),
            title: RichText(
                text: TextSpan(
                  text: bot["name"],
                  style: TextStyle(fontSize: 18.5, color: AppColors.msgText),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            subtitle: BotTabSubtitle(context, widget.user, bot),
            onTap: () {
              Navigator.pop(context);
            },
            trailing: BotTabtrailing(context, bot)));
  }

  Widget BotsList(BuildContext context) {
    return Expanded(
        child: GridView.builder(
      key: UniqueKey(),
      padding: EdgeInsets.all(25),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0, //行距
        crossAxisSpacing: 10.0, //列距
        childAspectRatio: isDisplayDesktop(context) ? 3 : 3,
        crossAxisCount: isDisplayDesktop(context) ? 3 : 1,
      ),
      itemCount: widget.bots.length,
      itemBuilder: (BuildContext context, int index) => BotTab(context, index),
    ));
  }
}

class CreateBot extends StatefulWidget {
  final User user;
  final bots;
  final bot;

  CreateBot({required this.user, this.bots, this.bot});

  @override
  CreateBotState createState() => CreateBotState();
}

class CreateBotState extends State<CreateBot> with RestorationMixin {
  final _nameController = TextEditingController();
  final _introController = TextEditingController();
  final _configInfoController = TextEditingController();
  RestorableBool switchValueA = RestorableBool(true);
  final dio = Dio();
  String? _fileName;
  List<int>? _fileBytes;
  String? _logoURL;

  @override
  String get restorationId => 'switch_demo';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchValueA, 'switch_value1');
  }

  @override
  void initState() {
    super.initState();
    if (widget.bot != null) {
      _logoURL = widget.bot["avatar"];
      _nameController.text = widget.bot["name"];
      _introController.text = widget.bot["description"];
      _configInfoController.text = widget.bot["prompts"];
      //switchValueA.value = widget.bot["public"];
    }
  }

  @override
  void dispose() {
    switchValueA.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(context) async {
    var result;
    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles);
    } else {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles);
    }
    if (result != null) {
      setState(() {
        _fileBytes = result.files.first.bytes;
        _fileName = result.files.first.name;
      });
    }
  }

  Future<void> uploadLogo() async {
    if (_fileBytes != null) {
      var mt = DateTime.now().millisecondsSinceEpoch;
      String oss_name = "bot${widget.user.id}_${mt}" + _fileName!;
      var resp = await Client().putObject(
        _fileBytes!,
        "chat/avatar/" + oss_name,
      );
      _logoURL = (resp.statusCode == 200) ? resp.realUri.toString() : null;
    }
  }

  Widget _displayLogo(BuildContext context) {
    if (_logoURL != null)
      return Image.network(_logoURL!, height: 80, width: 80);
    else if (_fileBytes == null)
      return Image.asset(
        'assets/images/avatar/0.png',
        height: 80,
        width: 80,
      );
    else
      return Image.memory(Uint8List.fromList(_fileBytes!),
          height: 80, width: 80, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
        //margin: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('个性化配置智能体',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 45),
            GestureDetector(
                onTap: () async {
                  _pickLogo(context);
                },
                child: _displayLogo(context)),
            Text('Logo'),
            SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text('名称',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold))),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '输入智能体名字',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 25),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text('简介',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold))),
                    TextFormField(
                      controller: _introController,
                      decoration: InputDecoration(
                        hintText: '用一句话介绍该智能体',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 25),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text('配置信息',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold))),
                    TextFormField(
                      controller: _configInfoController,
                      decoration: InputDecoration(
                        hintText: '输入prompt',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    SizedBox(height: 25),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(children: [
                          Text('是否共享其他人使用?',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                          Switch(
                            value: switchValueA.value,
                            onChanged: (value) {
                              setState(() {
                                switchValueA.value = value;
                              });
                            },
                          ),
                        ])),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('保存'),
                  onPressed: () async {
                    await uploadLogo();
                    var _botsURL = botURL;
                    if (widget.bot != null)
                      _botsURL = botURL + "/${widget.bot["id"]}";
                    var botData = {
                      "name": _nameController.text,
                      "avatar": _logoURL,
                      "description": _introController.text,
                      "prompts": _configInfoController.text,
                      "author_id": widget.user.id,
                      "author_name": widget.user.name,
                      "public": switchValueA.value,
                    };
                    Response resp = await dio.post(_botsURL, data: botData);

                    Navigator.of(context).pop();
                    if (resp.data["result"] == 'success') {
                      if (widget.bots != null) {
                        int index = widget.bots.indexWhere(
                            (_bot) => _bot['id'] == widget.bot['id']);
                        widget.bots[index]["name"] = botData["name"];
                        widget.bots[index]["avatar"] = botData["avatar"];
                        widget.bots[index]["description"] =
                            botData["description"];
                        widget.bots[index]["prompts"] = botData["prompts"];
                        widget.bots[index]["author_id"] = botData["author_id"];
                        widget.bots[index]["author_name"] =
                            botData["author_name"];
                        widget.bots[index]["public"] = botData["public"];
                      }
                      return notifyBox(
                          context: context, title: "success", content: "操作成功");
                    } else
                      return notifyBox(
                          context: context, title: "warning", content: "操作失败");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

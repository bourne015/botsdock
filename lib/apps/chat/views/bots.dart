import 'package:dio/dio.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:gallery/apps/chat/models/user.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import "../utils/constants.dart";
import '../utils/utils.dart';

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
                padding: EdgeInsets.only(left: 30),
                child: OutlinedButton.icon(
                    onPressed: () {
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
    String image = bot["avatar"];
    String title = bot["name"];
    String description = bot["description"];
    String creator = bot["author_name"];
    return Card(
        color: Color.fromARGB(255, 244, 244, 244),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        //elevation: 1,
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
                    child: Image.network(
                      image,
                      width: 80,
                      height: 80,
                    )),
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
    var bot = widget.bots[index];
    return buildListItem(
        rank: index,
        bot: bot,
        onTab: () {
          if (widget.user.isLogedin) {
            Navigator.pop(context);
            chats.newBot(widget.pages, widget.property, widget.user,
                bot["name"], bot["prompts"]);
          }
        });
  }

  Widget BotsList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 200.0;
    return Expanded(
        child: GridView.builder(
      key: UniqueKey(),
      padding: EdgeInsets.all(25),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
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
  double temperature = 1;
  GlobalKey _createBotformKey = GlobalKey<FormState>();

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      //margin: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
      decoration: BoxDecoration(
          color: AppColors.chatPageBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      child: Scaffold(
        backgroundColor: AppColors.chatPageBackground,
        appBar: AppBar(
          //shadowColor: Colors.red,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.chatPageBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(GalleryLocalizations.of(context)!.botCreateTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Text('个性化配置智能体',
            //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            //SizedBox(height: 45),
            // chooseLogo(context), //_displayLogo(context)

            // Text('Logo'),
            //SizedBox(height: 25),
            Form(
                key: _createBotformKey,
                child: Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: chooseLogo(context),
                        ),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text('名称', style: TextStyle(fontSize: 15))),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: '输入智能体名字',
                                  hintStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  return v == null || v.trim().isNotEmpty
                                      ? null
                                      : "名称不能为空";
                                })),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text('简介', style: TextStyle(fontSize: 15))),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                              controller: _introController,
                              decoration: InputDecoration(
                                hintText: '用一句话介绍该智能体',
                                hintStyle: TextStyle(fontSize: 14),
                                border: OutlineInputBorder(),
                              ),
                            )),
                        Align(
                            alignment: Alignment.topLeft,
                            child:
                                Text('配置信息', style: TextStyle(fontSize: 15))),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                              controller: _configInfoController,
                              decoration: InputDecoration(
                                hintText: '输入prompt',
                                hintStyle: TextStyle(fontSize: 14),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                return v == null || v.trim().isNotEmpty
                                    ? null
                                    : "prompt不能为空";
                              },
                              maxLines: 5,
                            )),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Temperature",
                                        style: TextStyle(fontSize: 15)),
                                  ]),
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(temperature.toStringAsFixed(1),
                                      style: TextStyle(fontSize: 15))),
                              Container(
                                  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Column(children: [
                                    Slider(
                                      min: 0,
                                      max: 2,
                                      value: temperature,
                                      onChanged: (value) {
                                        setState(() {
                                          temperature = value;
                                        });
                                      },
                                    ),
                                    Container(
                                        margin:
                                            EdgeInsets.fromLTRB(25, 0, 25, 10),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("稳定",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              Text("中立",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              Text("随机",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                            ]))
                                  ])),
                            ]),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(children: [
                              Text('是否共享其他人使用?',
                                  style: TextStyle(fontSize: 15)),
                              Container(
                                  margin: EdgeInsets.only(left: 30),
                                  child: Switch(
                                    value: switchValueA.value,
                                    onChanged: (value) {
                                      setState(() {
                                        switchValueA.value = value;
                                      });
                                    },
                                  )),
                            ])),
                      ],
                    ),
                  ),
                )),
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
                    if (!(_createBotformKey.currentState as FormState)
                        .validate()) {
                      return;
                    }
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
    ));
  }

  Widget _displayLogo(BuildContext context) {
    var sz = 100.0;
    if (_fileBytes != null)
      return Image.memory(Uint8List.fromList(_fileBytes!),
          width: sz, height: sz, fit: BoxFit.cover);
    else if (_logoURL != null)
      return Image.network(_logoURL!, width: sz, height: sz, fit: BoxFit.cover);
    else
      return Image.asset('assets/images/bot/bot4.png',
          width: sz, height: sz, fit: BoxFit.cover);
  }

  Widget chooseLogo(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Ink(
            child: InkWell(
          onTap: () {
            showCustomBottomSheet(context);
          },
          borderRadius: BorderRadius.circular(45.0),
          hoverColor: Colors.red.withOpacity(0.3),
          splashColor: Colors.red.withOpacity(0.5),
          child: _displayLogo(context),
        )));
  }

  Widget localImages(BuildContext context) {
    return ListBody(
      children: [
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 1,
          ),
          itemCount: BotImages.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
                margin: EdgeInsets.all(5),
                child: InkWell(
                    onTap: () async {
                      final ByteData data = await rootBundle
                          .load('assets/images/bot/bot${index + 1}.png');
                      setState(() {
                        _fileBytes = data.buffer.asUint8List();
                        _fileName = 'bot${index + 1}.png';
                      });
                      Navigator.of(context).pop();
                    },
                    hoverColor: Colors.grey.withOpacity(0.3),
                    splashColor: Colors.brown.withOpacity(0.5),
                    child: Ink(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/bot/bot${index + 1}.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )));
          },
        ),
      ],
    );
  }

  Widget localImages1(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 6,
      crossAxisSpacing: 4.0,
      mainAxisSpacing: 4.0,
      children: List.generate(12, (index) {
        return InkWell(
            onTap: () {
              print("tap $index");
            }, // Handle your callback.
            hoverColor: Colors.grey.withOpacity(0.3),
            splashColor: Colors.brown.withOpacity(0.5),
            child: Ink(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bot/bot${index + 1}.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ));
      }),
    );
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.upload),
                title: Text('上传本地图片'),
                onTap: () {
                  _pickLogo(context);
                  Navigator.pop(context);
                },
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('选择图片'),
                ),
              ),
              localImages(context),
            ],
          ),
        );
      },
    );
  }

  List<String> BotImages = [
    'assets/images/bot/bot1.png',
    'assets/images/bot/bot2.png',
    'assets/images/bot/bot3.png',
    'assets/images/bot/bot4.png',
    'assets/images/bot/bot5.png',
    'assets/images/bot/bot6.png',
    'assets/images/bot/bot7.png',
    'assets/images/bot/bot8.png',
    'assets/images/bot/bot9.png',
    'assets/images/bot/bot10.png',
    'assets/images/bot/bot11.png',
    'assets/images/bot/bot12.png',
  ];
}

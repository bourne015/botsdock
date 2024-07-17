import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/utils.dart';
import '../models/user.dart';
import '../models/pages.dart';
import '../utils/global.dart';
import './user_info.dart';

class Administrator extends StatefulWidget {
  const Administrator({super.key});

  @override
  State<Administrator> createState() => AdministratorState();
}

class AdministratorState extends State<Administrator> {
  final _emailcontroller = TextEditingController();
  final _namecontroller = TextEditingController();
  final _pwdcontroller = TextEditingController();
  final _pwdconfirmcontroller = TextEditingController();
  final _newBotController1 = TextEditingController();
  final _newBotController2 = TextEditingController();
  final dio = Dio();
  Random random = Random();
  GlobalKey _signInformKey = GlobalKey<FormState>();
  GlobalKey _signUpformKey = GlobalKey<FormState>();

  // @override
  // void initState() {}

  // @override
  // void Dispose() {
  //   _emailcontroller.dispose();
  //   _namecontroller.dispose();
  //   _pwdcontroller.dispose();
  //   _pwdconfirmcontroller.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<User>(context);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    return PopupMenuButton<String>(
        color: AppColors.drawerBackground,
        shadowColor: Colors.blue,
        elevation: 15,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: user.isLogedin
              ? Image.asset(
                  'assets/images/avatar/${user.avatar}.png',
                  height: 24,
                  width: 24,
                )
              : Icon(Icons.account_circle),
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(vertical: 1),
          title: RichText(
              text: TextSpan(
            text: user.isLogedin
                ? user.name
                : GalleryLocalizations.of(context)!.adminstrator,
            style: TextStyle(fontSize: 15, color: AppColors.msgText),
          )),
        ),
        padding: const EdgeInsets.only(left: 2),
        onSelected: (String value) {
          switch (value) {
            case 'user':
              userInfoDialog(context, user);
              break;
            case 'Login':
              loginDialog(context);
              break;
            case 'Customize ChatGPT':
              //NewBotDialog(context);
              break;
            case 'Instructions':
              InstructionsDialog(context);
              break;
            case 'About':
              aboutDialog(context);
              break;
            case 'Logout':
              user.reset();
              property.reset();
              pages.reset();
              Global.reset();
              _pwdcontroller.clear();
              break;
            default:
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              user.isLogedin
                  ? PopupMenuItem(
                      padding: EdgeInsets.fromLTRB(20, 0, 80, 0),
                      value: "user",
                      child: ListTile(
                        leading: Image.asset(
                          'assets/images/avatar/${user.avatar}.png',
                          height: 24,
                          width: 24,
                        ),
                        title: user.name == null ? null : Text(user.name!),
                        subtitle: user.email == null ? null : Text(user.email!),
                      ),
                    )
                  : _buildPopupMenuItem(context, "Login", Icons.login,
                      GalleryLocalizations.of(context)!.login),
              PopupMenuDivider(),
              _buildPopupMenuItem(
                  context,
                  "Customize ChatGPT",
                  Icons.add_home_outlined,
                  GalleryLocalizations.of(context)!.custmizeGPT),
              _buildPopupMenuItem(
                  context,
                  "Instructions",
                  Icons.settings_rounded,
                  GalleryLocalizations.of(context)!.instructions),
              _buildPopupMenuItem(context, "About", Icons.info,
                  GalleryLocalizations.of(context)!.about),
              PopupMenuDivider(),
              _buildPopupMenuItem(context, "Logout", Icons.logout,
                  GalleryLocalizations.of(context)!.logout),
            ]);
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      BuildContext context, String value, IconData icon, String title) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      value: value,
      child: Material(
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
                leading: Icon(size: 20, icon),
                title: Text(title)),
          ),
        ),
      ),
    );
  }

  void InstructionsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('模型介绍'),
            content: modelINFO(context),
          );
        });
  }

  void userInfoDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => UserInfo(
        user: user,
      ),
    );
  }

  void aboutDialog(BuildContext context) {
    var content = aboutText + '\nVersion $appVersion';
    notifyBox(context: context, title: 'About', content: content);
  }

  void NewBotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Customize ChatGPT'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Custom Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  maxLines: 5,
                  maxLength: 2048,
                  controller: _newBotController1,
                  decoration: InputDecoration(
                    hintText: 'e.g., Information specific to my needs',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 254, 254, 254))),
                    hintStyle: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(height: 20),
                Text('How would you like ChatGPT to respond?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  maxLines: 5,
                  maxLength: 2048,
                  controller: _newBotController2,
                  decoration: InputDecoration(
                    hintText: 'e.g., Be concise and direct',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 254, 254, 254))),
                    hintStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                // Implement your save logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future loginDialog(BuildContext context) {
    User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    if (_pwdcontroller.text.isNotEmpty) _pwdcontroller.text = '';
    if (_pwdconfirmcontroller.text.isNotEmpty) _pwdconfirmcontroller.text = '';
    return showDialog(
      context: context,
      builder: (BuildContext context) =>
          buildLoginDialog(context, user, pages, property),
    );
  }

  Widget buildLoginDialog(
      BuildContext context, User user, Pages pages, Property property) {
    return AlertDialog(
      title: Text(
        textAlign: TextAlign.center,
        '登录/注册',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      scrollable: true,
      content: loginDialogContent(context),
      actions: loginDialogActions(context, user, pages, property),
    );
  }

  List<Widget> loginDialogActions(
      context, User user, Pages pages, Property property) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('登录'),
            onPressed: () async {
              if (!(_signInformKey.currentState as FormState).validate()) {
                //notifyBox(title: "warning", content: "内容不能为空");
                return;
              }
              var res = await checkLogin(user);
              if (user.isLogedin) {
                ////fetch chat data from db
                var chatdbUrl = userUrl + "/" + "${user.id}" + "/chats";
                Response cres = await dio.post(
                  chatdbUrl,
                );
                if (cres.data["result"] == "success") {
                  for (var c in cres.data["chats"]) {
                    //user dbID to recovery pageID,
                    //incase no user log, c["contents"][0]["pageID"] == currentPageID
                    var pid = c["page_id"]; //c["contents"][0]["pageID"];
                    //print("cccc: ${c["title"]}, $pid");
                    property.initModelVersion = DefaultModelVersion;
                    Global.restort_singel_page(user, pages, c);
                    Global.saveChats(user, pid, jsonEncode(c), 0);
                  }
                  pages.sortPages();
                }
                Navigator.of(context).pop();
                Global.saveProfile(user);
              } else
                notifyBox(
                    context: context, title: "login status", content: res);
            },
          ),
          SizedBox(
            width: 80,
          ),
          ElevatedButton(
            child: Text('注册'),
            onPressed: () {
              Navigator.of(context).pop();
              signUpDialog(context, user);
            },
          ),
        ],
      )
    ];
  }

  Widget loginDialogContent(BuildContext context) {
    return Container(
      width: 400,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _signInformKey,
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              logTextFormField(
                  context: context,
                  hintText: "邮箱",
                  ctr: _emailcontroller,
                  obscure: false,
                  maxLength: 45,
                  icon: Icons.email_outlined),
              logTextFormField(
                  context: context,
                  hintText: "密码",
                  ctr: _pwdcontroller,
                  obscure: true,
                  icon: Icons.lock_outline,
                  maxLength: 190),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signUpDialog(BuildContext context, User user) {
    //User user = Provider.of<User>(context, listen: false);
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildsignUpDialog(context, user),
    );
  }

  Widget buildsignUpDialog(BuildContext context, User user) {
    return AlertDialog(
      // titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
      // contentPadding: EdgeInsets.fromLTRB(50, 0, 50, 0),
      title: Text(
        textAlign: TextAlign.center,
        '注册',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      scrollable: true,
      content: sigupDialogContent(context),
      actions: signupDialogActions(context, user),
    );
  }

  List<Widget> signupDialogActions(context, User user) {
    return [
      ElevatedButton(
        child: Text('注册'),
        onPressed: () async {
          if (_pwdcontroller.text != _pwdconfirmcontroller.text) {
            notifyBox(context: context, title: "warning", content: "密码不一致");
            return;
          }
          if (!(_signUpformKey.currentState as FormState).validate()) {
            //notifyBox(title: "warning", content: "内容不能为空");
            return;
          }
          user.name = _namecontroller.text;
          user.email = _emailcontroller.text;
          var res = await checkSingUp(user);
          if (user.signUP) {
            Navigator.of(context).pop();
            notifyBox(context: context, title: "success", content: "注册成功,请登录");
          } else {
            notifyBox(context: context, title: "warning", content: res);
          }
          (_signUpformKey.currentState as FormState).reset();
        },
      )
    ];
  }

  Widget sigupDialogContent(BuildContext context) {
    return Container(
      width: 400,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _signUpformKey,
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              logTextFormField(
                  context: context,
                  hintText: "邮箱",
                  ctr: _emailcontroller,
                  maxLength: 45,
                  icon: Icons.mail_outline,
                  obscure: false),
              logTextFormField(
                  context: context,
                  hintText: "昵称",
                  ctr: _namecontroller,
                  maxLength: 45,
                  icon: Icons.person_outline,
                  obscure: false),
              logTextFormField(
                  context: context,
                  hintText: "密码",
                  ctr: _pwdcontroller,
                  icon: Icons.lock_outline,
                  maxLength: 190,
                  obscure: true),
              logTextFormField(
                  context: context,
                  hintText: "确认密码",
                  ctr: _pwdconfirmcontroller,
                  icon: Icons.lock,
                  maxLength: 190,
                  obscure: true),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> checkSingUp(User user) async {
    int avatarNum = random.nextInt(15) + 1;
    Response response;
    try {
      var userdata = {
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "avatar": avatarNum.toString(),
        "credit": 0.2,
        "pwd": _pwdcontroller.text,
      };
      response = await dio.post(userUrl, data: userdata);
      if (response.data["result"] == 'success') {
        user.signUP = true;
        user.id = response.data["id"];
        user.avatar = avatarNum.toString();
      } else {
        user.signUP = false;
      }
    } catch (e) {
      return e.toString();
    }
    return response.data["result"];
  }

  Future<String?> checkLogin(User user) async {
    var url = userUrl + "/login";
    Response response;
    try {
      var userdata = {
        "username": _emailcontroller.text,
        "password": _pwdcontroller.text
      };
      response = await dio.post(
        url,
        data: userdata,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      if (response.data["result"] == 'success') {
        user.id = response.data["id"];
        user.name = response.data["name"];
        user.email = response.data["email"];
        user.phone = response.data["phone"];
        user.avatar = response.data["avatar"];
        user.credit = response.data["credit"];
        user.updated_at = response.data["updated_at"];
        user.isLogedin = true;
      } else {
        user.isLogedin = false;
      }
    } catch (e) {
      user.isLogedin = false;
      return e.toString();
    }
    return response.data["result"];
  }

  Widget modelINFO(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('')),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.modelDescription)),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.contextWindow)),
          DataColumn(label: Text(GalleryLocalizations.of(context)!.cost)),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.inputFormat)),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text('GPT-3.5')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT35Desc)),
            DataCell(Text('16,385 tokens')),
            DataCell(Text('\$0.50 / M input tokens, \$1.50/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('GPT-4')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT40Desc)),
            DataCell(Text('128K tokens')),
            DataCell(Text('\$10.00/M input tokens, \$30.00/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('GPT-4o')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT4oDesc)),
            DataCell(Text('128K tokens')),
            DataCell(Text('\$5.00 / M input tokens, \$15.00/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('DALL·E')),
            DataCell(Text(GalleryLocalizations.of(context)!.dallEDesc)),
            DataCell(Text('-')),
            DataCell(Text('\$0.040 / image')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Haiku')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3HaikuDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('\$0.25/M input tokens, \$1.25/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Sonnet')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3SonnetDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('\$3.00/M input tokens, \$15.00/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Opus')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3OpusDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('\$15.00/M input tokens, \$75.00/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3.5 Sonnet')),
            DataCell(
                Text(GalleryLocalizations.of(context)!.claude35SonnetDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('\$3.00/M input tokens, \$15.00/M output tokens')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../utils/constants.dart';
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
    return PopupMenuButton<String>(
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
            text: user.isLogedin ? user.name : 'Administrator',
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
            case 'Settings':
              aboutDialog(context);
              break;
            case 'Logout':
              user.isLogedin = false;
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
                      padding: EdgeInsets.fromLTRB(12, 0, 100, 0),
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
                  : PopupMenuItem(
                      padding: EdgeInsets.fromLTRB(12, 0, 100, 0),
                      value: "Login",
                      child: ListTile(
                        leading: Icon(Icons.login),
                        title: Text("Login"),
                      ),
                    ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: "Customize ChatGPT",
                child: ListTile(
                  leading: Icon(Icons.add_home_outlined),
                  title: Text("Customize ChatGPT"),
                ),
              ),
              PopupMenuItem(
                value: "Settings",
                child: ListTile(
                  leading: Icon(Icons.settings_rounded),
                  title: Text("Settings"),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: "Logout",
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Logout"),
                ),
              ),
            ]);
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
      height: 180,
      //padding: EdgeInsets.all(20),
      //margin: EdgeInsets.symmetric(horizontal: 50, vertical: 25),
      child: Scrollable(viewportBuilder: (context, position) {
        return Form(
            key: _signInformKey,
            child: Column(
              //mainAxisSize: MainAxisSize.min,
              children: [
                logTextFormField(context, "邮箱", _emailcontroller, false),
                logTextFormField(context, "密码", _pwdcontroller, true),
              ],
            ));
      }),
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
      titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
      contentPadding: EdgeInsets.fromLTRB(50, 5, 300, 5),
      title: Text(
        textAlign: TextAlign.center,
        '注册',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
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
    return SingleChildScrollView(
        child: Form(
            key: _signUpformKey,
            child: Column(
              //mainAxisSize: MainAxisSize.min,
              children: [
                logTextFormField(context, "邮箱", _emailcontroller, false),
                logTextFormField(context, "昵称", _namecontroller, false),
                logTextFormField(context, "密码", _pwdcontroller, true),
                logTextFormField(context, "确认密码", _pwdconfirmcontroller, true),
              ],
            )));
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

  Widget logTextFormField(
      BuildContext context, String text, var ctr, bool obscure) {
    return TextFormField(
        decoration: InputDecoration(
            //filled: true,
            //fillColor: AppColors.inputBoxBackground,
            labelText: text,
            border: InputBorder.none,
            hintText: text),
        obscureText: obscure,
        maxLines: 1,
        textInputAction: TextInputAction.newline,
        controller: ctr,
        validator: (v) {
          return v == null || v.trim().isNotEmpty ? null : "$text不能为空";
        });
  }
}

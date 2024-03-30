import 'dart:html';
import 'dart:js_util';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../utils/constants.dart';
import '../utils/utils.dart';
import '../models/user.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => UserInfoState();
}

class UserInfoState extends State<UserInfo> {
  final _emailcontroller = TextEditingController();
  final _namecontroller = TextEditingController();
  final _pwdcontroller = TextEditingController();
  final _pwdconfirmcontroller = TextEditingController();
  final dio = Dio();
  Random random = Random();

  @override
  void initState() {}

  @override
  void Dispose() {
    _emailcontroller.dispose();
    _namecontroller.dispose();
    _pwdcontroller.dispose();
    _pwdconfirmcontroller.dispose();
  }

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
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          title: RichText(
              text: TextSpan(
            text: 'Manage',
            style: TextStyle(fontSize: 16, color: AppColors.msgText),
          )),
        ),
        padding: const EdgeInsets.only(left: 2),
        onSelected: (String value) {
          switch (value) {
            case 'Login':
              loginDialog(context);
              break;
            case 'About':
              aboutDialog(context);
              break;
            case 'Logout':
              user.isLogedin = false;
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
              PopupMenuItem(
                value: "About",
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("About"),
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

  void aboutDialog(BuildContext context) {
    var content = aboutText + '\nVersion $appVersion';
    notifyBox(title: 'About', content: content);
  }

  Future loginDialog(BuildContext context) {
    User user = Provider.of<User>(context, listen: false);
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildLoginDialog(context, user),
    );
  }

  Widget buildLoginDialog(BuildContext context, user) {
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
      actions: loginDialogActions(context, user),
    );
  }

  List<Widget> loginDialogActions(context, user) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('登录'),
            onPressed: () async {
              var res = await checkLogin(user);
              if (user.isLogedin)
                Navigator.of(context).pop();
              else
                notifyBox(title: "login status", content: res);
            },
          ),
          SizedBox(
            width: 80,
          ),
          ElevatedButton(
            child: Text('注册'),
            onPressed: () {
              // 处理注册逻辑
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
        return Column(
          //mainAxisSize: MainAxisSize.min,
          children: [
            logTextFormField(context, "邮箱", _emailcontroller, false),
            logTextFormField(context, "密码", _pwdcontroller, true),
          ],
        );
      }),
    );
  }

  Future<void> signUpDialog(BuildContext context, user) {
    //User user = Provider.of<User>(context, listen: false);
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildsignUpDialog(context, user),
    );
  }

  Widget buildsignUpDialog(BuildContext context, user) {
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

  List<Widget> signupDialogActions(context, user) {
    return [
      ElevatedButton(
        child: Text('注册'),
        onPressed: () async {
          if (_pwdcontroller.text != _pwdconfirmcontroller.text) {
            notifyBox(title: "warning", content: "密码不一致");
            return;
          }
          user.name = _namecontroller.text;
          user.email = _emailcontroller.text;
          await checkSingUp(user);
          if (user.signUP) {
            Navigator.of(context).pop();
          } else {
            // setState(() {
            //   //user.signUP = false;
            // });
          }
        },
      )
    ];
  }

  Widget sigupDialogContent(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      //mainAxisSize: MainAxisSize.min,
      children: [
        logTextFormField(context, "邮箱", _emailcontroller, false),
        logTextFormField(context, "昵称", _namecontroller, false),
        logTextFormField(context, "密码", _pwdcontroller, true),
        logTextFormField(context, "确认密码", _pwdconfirmcontroller, true),
      ],
    ));
  }

  Future<void> checkSingUp(user) async {
    int avatarNum = random.nextInt(15) + 1;
    var userdata = {
      "name": user.name,
      "email": user.email,
      "phone": user.phone,
      "avatar": avatarNum.toString(),
      "pwd": _pwdcontroller.text,
    };
    final response = await dio.post(userUrl, data: userdata);
    if (response.statusCode == 200) {
      user.signUP = true;
      user.id = response.data["id"];
      user.avatar = avatarNum.toString();
      print("user.signUP = true;");
    } else {
      user.signUP = false;
    }
  }

  Future<String?> checkLogin(user) async {
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
    );
  }

  void notifyBox({var title, var content}) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(content),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}

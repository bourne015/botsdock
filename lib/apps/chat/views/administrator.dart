import 'dart:async';
import 'dart:math';

import 'package:botsdock/apps/chat/models/settings.dart';
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
import './settings_view.dart';

class Administrator extends StatelessWidget {
  Administrator({Key? key}) : super(key: key);

  final _emailcontroller = TextEditingController();
  final _namecontroller = TextEditingController();
  final _pwdcontroller = TextEditingController();
  final _pwdconfirmcontroller = TextEditingController();
  final _newBotController1 = TextEditingController();
  final _newBotController2 = TextEditingController();
  final dio = Dio();
  final Random random = Random();
  final GlobalKey _signInformKey = GlobalKey<FormState>();
  final GlobalKey _signUpformKey = GlobalKey<FormState>();
  final GlobalKey<PopupMenuButtonState<String>> _popupMenuKey = GlobalKey();

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
        key: _popupMenuKey,
        color: AppColors.drawerBackground,
        shadowColor: Colors.blue,
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BORDERRADIUS10,
        ),
        child: Material(
            color: AppColors.drawerBackground,
            child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BORDERRADIUS15,
                ),
                child: InkWell(
                    borderRadius: BORDERRADIUS15,
                    onTap: () {
                      _popupMenuKey.currentState?.showButtonMenu();
                    },
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BORDERRADIUS10,
                      ),
                      leading: user.isLogedin
                          ? image_show(user.avatar!, 15)
                          : Icon(Icons.account_circle),
                      minLeadingWidth: 0,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 1),
                      title: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: user.isLogedin
                                ? user.name
                                : GalleryLocalizations.of(context)!
                                    .adminstrator,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.msgText,
                            ),
                          )),
                    )))),
        ////////
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
              InstructionsDialog(context, user);
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
                      padding: EdgeInsets.all(0),
                      value: "user",
                      child: Material(
                          color: AppColors.drawerBackground,
                          child: Container(
                              width: 400,
                              padding: EdgeInsets.only(left: 5, right: 5),
                              //margin: EdgeInsets.only(left: 50),
                              decoration: BoxDecoration(
                                borderRadius: BORDERRADIUS15,
                              ),
                              child: InkWell(
                                borderRadius: BORDERRADIUS15,
                                onTap: () {
                                  Navigator.pop(context, "user");
                                },
                                //onHover: (hovering) {},
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 10),
                                  leading: image_show(user.avatar!, 25),
                                  title: Text(user.name ?? "",
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(user.email ?? ""),
                                ),
                                //////
                              ))))
                  : _buildPopupMenuItem(context, "Login", Icons.login,
                      GalleryLocalizations.of(context)!.login),
              PopupMenuDivider(),
              // _buildPopupMenuItem(
              //     context,
              //     "Customize ChatGPT",
              //     Icons.add_home_outlined,
              //     GalleryLocalizations.of(context)!.custmizeGPT),
              _buildPopupMenuItem(
                  context,
                  "Instructions",
                  Icons.settings_rounded,
                  GalleryLocalizations.of(context)!.setting),
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
                leading: Icon(size: 20, icon),
                title: Text(title)),
          ),
        ),
      ),
    );
  }

  void InstructionsDialog(BuildContext context, User user) {
    // showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: Text('模型介绍'),
    //         content: modelINFO(context),
    //       );
    //     });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              child: ClipRRect(
            borderRadius: BORDERRADIUS15,
            child: SettingsView(user: user),
          ));
        });
  }

  void userInfoDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserInfo(user: user),
    );
  }

  void aboutDialog(BuildContext context) async {
    String _version = await getVersionNumber();
    var content = aboutText + '\nVersion $_version';
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
      backgroundColor: AppColors.chatPageBackground,
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
              showLoading(context, text: "正在登录...");
              var res = await checkLogin(user);
              Navigator.of(context).pop();
              if (user.isLogedin) {
                ////fetch chat data from db
                Navigator.of(context).maybePop().then((_) async {
                  property.isLoading = true;
                  await pages.fetch_pages(user.id);
                  pages.flattenPages();
                  property.isLoading = false;
                  Global.saveProfile(user);
                });
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
      backgroundColor: AppColors.chatPageBackground,
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
          showLoading(context, text: "正在注册...");
          var res = await checkSingUp(user);
          Navigator.of(context).pop();
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
      height: 370,
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
    int avatarNum = random.nextInt(15);
    Response response;
    try {
      var userdata = {
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "avatar": avatarImages[avatarNum],
        "avatar_bot": defaultUserBotAvatar,
        "credit": 0.2,
        "pwd": _pwdcontroller.text,
        "settings": Settings().toJson(),
      };
      response = await dio.post(USER_URL, data: userdata);
      if (response.data["result"] == 'success') {
        user.signUP = true;
        user.id = response.data["id"];
        user.avatar = avatarImages[avatarNum];
        user.avatar_bot = defaultUserBotAvatar;
      } else {
        user.signUP = false;
      }
    } catch (e) {
      return e.toString();
    }
    return response.data["result"];
  }

  Future<String?> checkLogin(User user) async {
    var url = USER_URL + "/login";
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
        user.avatar_bot = response.data["avatar_bot"];
        user.credit = response.data["credit"];
        user.updated_at = response.data["updated_at"];
        user.isLogedin = true;
        user.settings = Settings.fromJson(response.data["settings"] ?? {});
      } else {
        user.isLogedin = false;
      }
    } catch (e) {
      user.isLogedin = false;
      return e.toString();
    }
    return response.data["result"];
  }
}

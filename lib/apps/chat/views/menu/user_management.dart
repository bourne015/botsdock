import 'dart:async';
import 'dart:math';

import 'package:botsdock/apps/chat/models/settings.dart';
import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

import 'package:botsdock/l10n/gallery_localizations.dart';

import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/views/menu/user_info.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class UserManagement extends rp.ConsumerStatefulWidget {
  @override
  UserManagementState createState() => UserManagementState();
}

class UserManagementState extends rp.ConsumerState<UserManagement> {
  final _emailcontroller = TextEditingController();
  final _namecontroller = TextEditingController();
  final _pwdcontroller = TextEditingController();
  final _pwdconfirmcontroller = TextEditingController();
  final dio = DioClient();
  final Random random = Random();
  final GlobalKey _signInformKey = GlobalKey<FormState>();
  final GlobalKey _signUpformKey = GlobalKey<FormState>();
  final GlobalKey<PopupMenuButtonState<String>> _popupMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    User user = ref.watch(userProvider);
    await Global.restoreLocalUser(user, ref);
  }

  @override
  Widget build(BuildContext context) {
    User user = ref.watch(userProvider);

    return PopupMenuButton<String>(
        key: _popupMenuKey,
        // color: AppColors.drawerBackground,
        position: PopupMenuPosition.under,
        shadowColor: Colors.blue,
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BORDERRADIUS10,
        ),
        enabled: user.status == UserStatus.loading ? false : true,
        child: UserThumbnail(
          user: user,
          onTap: () {
            _popupMenuKey.currentState?.showButtonMenu();
          },
        ),
        ////////
        padding: const EdgeInsets.only(left: 2),
        onSelected: (String value) {
          switch (value) {
            case 'user':
              userInfoDialog(context, user);
              break;
            case 'Login':
              loginDialog(context, ref);
              break;
            case 'About':
              aboutDialog(context);
              break;
            case 'Logout':
              ref.read(userProvider.notifier).reset();
              // property.reset();
              // pages.reset();
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
                      child: UserThumbnail2(user: user, enabled: true),
                    )
                  : _buildPopupMenuItem(context, "Login", Icons.login,
                      GalleryLocalizations.of(context)!.login),
              PopupMenuDivider(),
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
        // color: AppColors.drawerBackground,
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

  Future loginDialog(BuildContext context, rp.WidgetRef ref) {
    // Pages pages = Provider.of<Pages>(context, listen: false);
    // Property property = Provider.of<Property>(context, listen: false);
    if (_pwdcontroller.text.isNotEmpty) _pwdcontroller.text = '';
    if (_pwdconfirmcontroller.text.isNotEmpty) _pwdconfirmcontroller.text = '';
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildLoginDialog(context),
    );
  }

  Widget buildLoginDialog(BuildContext context) {
    return AlertDialog(
      title: Text(textAlign: TextAlign.center, '登录/注册'),
      // titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      scrollable: true,
      // backgroundColor: AppColors.chatPageBackground,
      actionsAlignment: MainAxisAlignment.spaceAround,
      content: loginDialogContent(context),
      actions: loginDialogActions(context),
    );
  }

  List<Widget> loginDialogActions(context) {
    return [
      ElevatedButton(
        child: Text('登录'),
        onPressed: () async {
          if (!(_signInformKey.currentState as FormState).validate()) {
            //notifyBox(title: "warning", content: "内容不能为空");
            return;
          }
          showLoading(context, text: "正在登录...");
          var res = await checkLogin();
          Navigator.of(context).pop();
          User user = ref.read(userProvider);
          if (user.isLogedin) {
            ////fetch chat data from db
            Navigator.of(context).maybePop().then((_) async {
              // property.isLoading = true;
              // await pages.fetch_pages(user.id);
              // pages.flattenPages();
              // property.isLoading = false;
              Global.saveProfile(user);
              ACCESS_TOKEN = user.token;
              dio.dio.options.headers = {
                "Authorization":
                    ACCESS_TOKEN != null ? "Bearer $ACCESS_TOKEN" : "",
                "Content-Type": "application/json",
              };
            });
          } else
            notifyBox(context: context, title: "login status", content: res);
        },
      ),
      ElevatedButton(
        child: Text('注册'),
        onPressed: () {
          Navigator.of(context).pop();
          signUpDialog(context);
        },
      ),
    ];
  }

  Widget loginDialogContent(BuildContext context) {
    return Container(
      width: 400,
      height: 220,
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

  Future<void> signUpDialog(BuildContext context) {
    //User user = ref.watch(UserNotifierProvider);
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildsignUpDialog(context),
    );
  }

  Widget buildsignUpDialog(BuildContext context) {
    return AlertDialog(
      // titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
      // contentPadding: EdgeInsets.fromLTRB(50, 0, 50, 0),
      title: Text(textAlign: TextAlign.center, '注册'),
      // titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      scrollable: true,
      // backgroundColor: AppColors.chatPageBackground,
      content: sigupDialogContent(context),
      actions: signupDialogActions(context),
    );
  }

  List<Widget> signupDialogActions(context) {
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

          ref.read(userProvider.notifier).update(
                name: _namecontroller.text,
                email: _emailcontroller.text,
              );
          showLoading(context, text: "正在注册...");
          var res = await checkSingUp();
          Navigator.of(context).pop();
          User user = ref.read(userProvider);
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
      height: 400,
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

  Future<String?> checkSingUp() async {
    int avatarNum = random.nextInt(15);
    User user = ref.read(userProvider);
    var _data;
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
      _data = await dio.post(ChatPath.user, data: userdata);
      if (_data["result"] == 'success') {
        ref.read(userProvider.notifier).update(
              id: _data["id"],
              signUP: true,
              avatar: avatarImages[avatarNum],
              avatar_bot: defaultUserBotAvatar,
            );
      } else {
        ref.read(userProvider.notifier).update(signUP: false);
      }
    } catch (e) {
      return e.toString();
    }
    return _data["result"];
  }

  Future<String?> checkLogin() async {
    var _data;
    try {
      var userdata = {
        "username": _emailcontroller.text,
        "password": _pwdcontroller.text
      };
      _data = await dio.post(
        ChatPath.login,
        data: userdata,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      if (_data["result"] == 'success') {
        ref.read(userProvider.notifier).update(
              id: _data["id"],
              name: _data["name"],
              email: _data["email"],
              phone: _data["phone"],
              avatar: _data["avatar"],
              avatar_bot: _data["avatar_bot"],
              credit: _data["credit"],
              updated_at: _data["updated_at"],
              isLogedin: true,
              settings: Settings.fromJson(_data["settings"] ?? {}),
              access_token: _data["access_token"],
              status: UserStatus.loggedIn,
            );
      } else {
        ref.read(userProvider.notifier).update(isLogedin: false);
      }
    } catch (e) {
      ref.read(userProvider.notifier).update(isLogedin: false);
      return e.toString();
    }
    return _data["result"];
  }
}

class UserThumbnail extends StatelessWidget {
  final User user;
  final GestureTapCallback? onTap;
  final Color? color;

  const UserThumbnail({
    super.key,
    this.color,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: Container(
        // padding: EdgeInsets.symmetric(horizontal: 21),
        decoration: BoxDecoration(
          borderRadius: BORDERRADIUS15,
          color: Colors.transparent,
        ),
        child: InkWell(
          borderRadius: BORDERRADIUS15,
          onTap: onTap,
          child: ListTile(
            enabled: user.status == UserStatus.loading ? false : true,
            shape: RoundedRectangleBorder(
              borderRadius: BORDERRADIUS10,
            ),
            leading: switch (user.status) {
              UserStatus.loading => Container(
                  width: 30,
                  child: SpinKitWave(
                    color: Colors.blue,
                    size: 20.0,
                  ),
                ),
              UserStatus.loggedIn => image_show(user.avatar!, 15),
              UserStatus.loggedOut => Icon(Icons.account_circle),
              _ => Icon(Icons.no_accounts_outlined)
            },
            minLeadingWidth: 0,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            title: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              switch (user.status) {
                UserStatus.loading => "",
                UserStatus.loggedIn => user.name!,
                UserStatus.loggedOut =>
                  GalleryLocalizations.of(context)!.adminstrator,
                _ => ""
              },
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class UserThumbnail2 extends StatelessWidget {
  final User user;
  final bool enabled;

  const UserThumbnail2({
    super.key,
    this.enabled = true,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // color: AppColors.drawerBackground,
      child: Container(
        width: 400,
        padding: EdgeInsets.only(left: 5, right: 5),
        //margin: EdgeInsets.only(left: 50),
        decoration: BoxDecoration(
          borderRadius: BORDERRADIUS15,
        ),
        child: enabled ? userTabSelectable(context) : userTab(context),
      ),
    );
  }

  Widget userTabSelectable(BuildContext context) {
    return InkWell(
      borderRadius: BORDERRADIUS15,
      onTap: () {
        Navigator.pop(context, "user");
      },
      //onHover: (hovering) {},
      child: userTab(context),
    );
  }

  Widget userTab(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      leading: image_show(user.avatar!, 25),
      title: Text(
        user.name ?? "",
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(user.email ?? ""),
    );
  }
}

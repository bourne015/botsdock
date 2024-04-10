import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../utils/utils.dart';
import '../utils/constants.dart';
import '../utils/global.dart';

class UserInfo extends StatefulWidget {
  User user;
  UserInfo({super.key, required this.user});

  @override
  State<UserInfo> createState() => _UserInfoTabState();
}

class _UserInfoTabState extends State<UserInfo> {
  final _emailcontroller = TextEditingController();
  final _namecontroller = TextEditingController();
  final _phonecontroller = TextEditingController();
  final _pwdcontroller = TextEditingController();
  final _newpwdcontroller = TextEditingController();
  final _pwdconfirmcontroller = TextEditingController();
  bool _editName = false;
  bool _editEmail = false;
  bool _editPhone = false;
  bool _editPwd = false;
  bool _editAvatar = false;
  GlobalKey _editPwdformKey = GlobalKey<FormState>();
  final dio = Dio();

  @override
  Widget build(BuildContext context) {
    //User user = Provider.of<User>(context, listen: false);
    //Pages pages = Provider.of<Pages>(context);
    return Dialog(
        child: Container(
      width: 380,
      //     child: IntrinsicWidth(
      child: DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: userPannel(context),
      ),
    ));
  }

  Widget userPannel(BuildContext context) {
    //User user = Provider.of<User>(context, listen: false);
    String title = widget.user.name ?? "user";
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.beach_access_sharp)),
              Tab(icon: Icon(Icons.currency_exchange_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            UserInfoPage(context),
            BlankPage(),
          ],
        ));
  }

  Widget UserInfoPage(BuildContext context) {
    var editUser = userUrl + "/" + "${widget.user.id}";
    return Column(
      children: [
        SizedBox(height: 40),
        GestureDetector(
          onTap: () {
            showImagePicker(context, editUser);
          },
          child: CircleAvatar(
            radius: 50,
            backgroundImage:
                AssetImage('assets/images/avatar/${widget.user.avatar}.png'),
          ),
        ),
        SizedBox(height: 60),
        //Text(widget.user.name ?? '', style: TextStyle(fontSize: 20)),
        // userInfoFormField(context, "昵称", widget.user.name ?? '',
        //     _namecontroller, false, _editName),
        userInfoFormField(
            context, "邮箱", widget.user.email ?? '', _emailcontroller, false),
        // userInfoFormField(context, "电话", widget.user.phone ?? '',
        //     _phonecontroller, false, _editPhone),
        Container(
            margin: EdgeInsets.only(left: 15, right: 5),
            alignment: Alignment.center,
            child: Column(children: [
              Row(children: [
                userTextField(context, "昵称", widget.user.name ?? '',
                    _namecontroller, false, _editName),
                if (!_editName)
                  IconButton(
                    icon: Icon(Icons.edit, size: 14),
                    onPressed: () {
                      setState(() {
                        _editName = true;
                      });
                    },
                  ),
              ]),
              if (_editName)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                      onPressed: () async {
                        var userdata = {"name": _namecontroller.text};
                        var response = await dio.post(editUser, data: userdata);
                        setState(() {
                          _editName = false;
                        });
                        if (response.data["result"] == 'success') {
                          widget.user.name = userdata['name'];
                          Global.saveProfile(widget.user);
                        }
                      },
                      child: Text("保存")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _editName = false;
                          _namecontroller.text = widget.user.name ?? '';
                        });
                      },
                      child: Text("取消"))
                ])
            ])),
        Container(
            margin: EdgeInsets.only(left: 15, right: 5),
            alignment: Alignment.center,
            child: Column(children: [
              Row(children: [
                userTextField(context, "电话", widget.user.phone ?? '',
                    _phonecontroller, false, _editPhone),
                if (!_editPhone)
                  IconButton(
                    icon: Icon(Icons.edit, size: 14),
                    onPressed: () {
                      setState(() {
                        _editPhone = true;
                      });
                    },
                  ),
              ]),
              if (_editPhone)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                      onPressed: () async {
                        var userdata = {"phone": _phonecontroller.text};
                        var response = await dio.post(editUser, data: userdata);
                        setState(() {
                          _editPhone = false;
                        });
                        if (response.data["result"] == 'success') {
                          widget.user.phone = userdata['phone'];
                          Global.saveProfile(widget.user);
                        }
                      },
                      child: Text("保存")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _editPhone = false;
                          _phonecontroller.text = widget.user.phone ?? '';
                        });
                      },
                      child: Text("取消"))
                ])
            ])),
        SizedBox(height: 60),
        // InputChip(
        //   //avatar: Text("密码"),
        //   autofocus: true,
        //   //selected: true,
        //   isEnabled: false,
        //   label: Text("保存"),
        //   deleteIcon: Icon(Icons.edit, size: 14),
        // ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => editPwd(context),
            );
          },
          child: Text('修改密码'),
        ),
      ],
    );
  }

  Widget editPwd(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
      contentPadding: EdgeInsets.fromLTRB(50, 5, 300, 5),
      title: Text(
        textAlign: TextAlign.center,
        '修改密码',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
          child: Form(
              key: _editPwdformKey,
              child: Column(
                //mainAxisSize: MainAxisSize.min,
                children: [
                  userInfoFormField(context, "原密码:", '', _pwdcontroller, true),
                  userInfoFormField(
                      context, "新密码:", '', _newpwdcontroller, true),
                  userInfoFormField(
                      context, "请确认:", '', _pwdconfirmcontroller, true),
                ],
              ))),
      actions: [
        ElevatedButton(
          child: Text('保存'),
          onPressed: () async {
            if (_pwdcontroller.text != _pwdconfirmcontroller.text) {
              notifyBox(context: context, title: "warning", content: "密码不一致");
              return;
            }
            if (!(_editPwdformKey.currentState as FormState).validate()) {
              return;
            }
            var editUser = userUrl +
                "/${widget.user.id}/security" +
                "/${_pwdcontroller.text}";
            var userdata = {"pwd": _phonecontroller.text};
            var res = await dio.post(editUser, data: userdata);
            if (res.statusCode == 200 && res.data["result"] == 'success') {
              notifyBox(context: context, title: "success", content: "修改成功");
              Navigator.of(context).pop();
            } else {
              notifyBox(context: context, title: "warning", content: res);
            }
            (_editPwdformKey.currentState as FormState).reset();
          },
        ),
        ElevatedButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget userTextField(
      BuildContext context, prefix, text, ctr, obscure, isEditable) {
    return Expanded(
        child: TextFormField(
      decoration: InputDecoration(
          icon: Text(prefix, style: TextStyle(fontSize: 16)),
          //filled: true,
          //fillColor: AppColors.inputBoxBackground,
          //labelText: text,
          border: InputBorder.none,
          hintText: text),
      obscureText: obscure,
      textInputAction: TextInputAction.newline,
      controller: ctr,
      validator: (v) {
        return v == null || v.trim().isNotEmpty ? null : "$text不能为空";
      },
      enabled: isEditable,
    ));
  }

  Widget userInfoFormField(
      BuildContext context, String prefix, String text, var ctr, bool obscure) {
    return Container(
        margin: EdgeInsets.only(left: 15, right: 5),
        alignment: Alignment.center,
        child: Row(children: [
          Expanded(
              child: TextFormField(
            decoration: InputDecoration(
                icon: Text(prefix, style: TextStyle(fontSize: 16)),
                //filled: true,
                //fillColor: AppColors.inputBoxBackground,
                //labelText: text,
                border: InputBorder.none,
                hintText: text),
            obscureText: obscure,
            textInputAction: TextInputAction.newline,
            controller: ctr,
            validator: (v) {
              return v == null || v.trim().isNotEmpty ? null : "$text不能为空";
            },
            enabled: true,
          )),
        ]));
  }

  ////
  void showImagePicker(BuildContext context, editUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Image.asset(
            width: 200,
            height: 200,
            'assets/images/avatar/${widget.user.avatar}.png',
          ),
          content: Container(
              width: 500,
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: avatarImages.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () async {
                            // 选择新的头像
                            var userdata = {"avatar": (index + 1).toString()};
                            var response =
                                await dio.post(editUser, data: userdata);
                            selectAvatar((index + 1).toString());
                            Navigator.of(context).pop();
                            if (response.data["result"] == 'success') {
                              setState(() {
                                widget.user.avatar = userdata['avatar'];
                                Global.saveProfile(widget.user);
                              });
                            }
                          },
                          child: Image.asset(avatarImages[index]),
                        );
                      },
                    ),
                  ],
                ),
              )),
        );
      },
    );
  }

  void selectAvatar(String avatarUrl) {
    setState(() {
      widget.user.avatar = avatarUrl;
    });
  }

  List<String> avatarImages = [
    'assets/images/avatar/1.png',
    'assets/images/avatar/2.png',
    'assets/images/avatar/3.png',
    'assets/images/avatar/4.png',
    'assets/images/avatar/5.png',
    'assets/images/avatar/6.png',
    'assets/images/avatar/7.png',
    'assets/images/avatar/8.png',
    'assets/images/avatar/9.png',
    'assets/images/avatar/10.png',
    'assets/images/avatar/11.png',
    'assets/images/avatar/12.png',
    'assets/images/avatar/13.png',
    'assets/images/avatar/14.png',
    'assets/images/avatar/15.png',
  ];
}

class BlankPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Blank Page'),
    );
  }
}

import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'users_manage.dart';

class UserInfo extends StatefulWidget {
  final User user;
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
  //bool _editEmail = false;
  bool _editPhone = false;
  //bool _editPwd = false;
  //bool _editAvatar = false;
  GlobalKey _editPwdformKey = GlobalKey<FormState>();
  final dio = DioClient();
  List<int>? _userAvatarBytes;
  List<int>? _botAvatarBytes;
  String? _userAvatarUrl;
  String? _botAvatarUrl;

  @override
  Widget build(BuildContext context) {
    //User user = Provider.of<User>(context, listen: false);
    //Pages pages = Provider.of<Pages>(context);
    return Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: ClipRRect(
            borderRadius: BORDERRADIUS15,
            child: Container(
              width: 400,
              child: DefaultTabController(
                initialIndex: 0,
                length: widget.user.id == 1 ? 3 : 2,
                child: userPannel(context),
              ),
            )));
  }

  Widget userPannel(BuildContext context) {
    String title = widget.user.name ?? "user";
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.beach_access_sharp)),
              Tab(icon: Icon(Icons.currency_exchange_rounded)),
              if (widget.user.id == 1)
                Tab(icon: Icon(Icons.manage_accounts_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            SingleChildScrollView(child: UserInfoPage(context, title)),
            SingleChildScrollView(child: UserCharge(context)),
            if (widget.user.id == 1) UsersManage(),
          ],
        ));
  }

  Widget UserCharge(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(20),
          //padding: EdgeInsets.symmetric(horizontal: 10),
          //color: Colors.amber,
          decoration: BoxDecoration(
              //color: Colors.amber[50],
              borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: GestureDetector(
              onLongPressStart: (details) {
                _showDownloadMenu(context, details.globalPosition);
              },
              child: Image.asset(
                width: 300,
                height: 300,
                'assets/images/chat/paycode.jpeg',
              )),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          ElevatedButton(
              onPressed: () async {
                Uint8List imageData = await loadImageAsUInt8List(
                  'assets/images/chat/paycode.jpeg',
                );
                downloadImage(fileName: "paycode.jpeg", imageData: imageData);
              },
              child: Text("下载付款码")),
          // ElevatedButton(
          //     onPressed: () {
          //       Navigator.of(context).pop();
          //     },
          //     child: Text("完成")),
        ])
      ],
    );
  }

  void _showDownloadMenu(BuildContext context, Offset position) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx, // Left
      position.dy, // Top
      overlay!.size.width - position.dx, // Right
      overlay.size.height - position.dy, // Bottom
    );

    showMenu(
      context: context,
      position: positionRect,
      items: <PopupMenuEntry>[
        const PopupMenuItem(
          value: 'download',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text("download"),
          ),
        ),
      ],
    ).then((selectedValue) async {
      if (selectedValue == 'download') {
        Uint8List imageData = await loadImageAsUInt8List(
          'assets/images/chat/paycode.jpeg',
        );
        downloadImage(fileName: "paycode.jpeg", imageData: imageData);
      }
    });
  }

  Future<Uint8List> loadImageAsUInt8List(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint("Failed to load image: $e");
      return Uint8List(0); // return empty Uint8List to prevent error
    }
  }

  Widget _userAvatar(BuildContext context) {
    var sz = 100.0;

    if (_userAvatarBytes == null && _userAvatarUrl == null)
      return image_show(widget.user.avatar!, 50);
    return ClipRRect(
      borderRadius: BorderRadius.circular(sz),
      child: (_userAvatarUrl != null
          ? Image.network(
              _userAvatarUrl!,
              width: sz,
              height: sz,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(80)),
                );
              },
            )
          : Image.memory(
              Uint8List.fromList(_userAvatarBytes!),
              width: sz,
              height: sz,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(80)),
                );
              },
            )),
    );
  }

  Widget _botAvatar(BuildContext context) {
    var sz = 100.0;
    if (_botAvatarBytes == null && _botAvatarUrl == null)
      return image_show(widget.user.avatar_bot ?? defaultUserBotAvatar, 50);
    return ClipRRect(
      borderRadius: BorderRadius.circular(sz),
      child: (_botAvatarUrl != null
          ? Image.network(
              _botAvatarUrl!,
              width: sz,
              height: sz,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(80)),
                );
              },
            )
          : Image.memory(
              Uint8List.fromList(_botAvatarBytes!),
              width: sz,
              height: sz,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(80)),
                );
              },
            )),
    );
  }

  Widget UserInfoPage(BuildContext context, String title) {
    var editUser = ChatPath.userUpdate(widget.user.id);
    return Column(
      children: [
        SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          GestureDetector(
            onTap: () {
              showCustomBottomSheet(context,
                  images: avatarImages,
                  pickFile: _pickUserLocalImage,
                  onClickImage: onClickImage);
            },
            child: Column(children: [
              _userAvatar(context),
              Text(title.length > 10 ? "${title.substring(0, 18)}..." : title,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          GestureDetector(
              onTap: () {
                showCustomBottomSheet(context,
                    images: BotImages,
                    pickFile: _pickBotLocalImage,
                    onClickImage: onClickBotAvatar);
              },
              child: Column(children: [
                _botAvatar(context),
                Text("AI", overflow: TextOverflow.ellipsis),
              ]))
        ]),
        SizedBox(height: 60),
        //Text(widget.user.name ?? '', style: TextStyle(fontSize: 20)),
        // userInfoFormField(context, "昵称", widget.user.name ?? '',
        //     _namecontroller, false, _editName),
        userInfoFormField(
            context, "邮箱", widget.user.email ?? '', _emailcontroller,
            obscure: false, autofocus: false, readOnly: true),
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
                        var _data = await dio.post(editUser, data: userdata);
                        setState(() {
                          _editName = false;
                        });
                        if (_data["result"] == 'success') {
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
                        var _data = await dio.post(editUser, data: userdata);
                        setState(() {
                          _editPhone = false;
                        });
                        if (_data["result"] == 'success') {
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
        userInfoFormField(
            context, "余额", widget.user.credit?.toStringAsFixed(1) ?? '0', null,
            obscure: false, autofocus: false, readOnly: true),
        SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
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
        // style: TextStyle(
        //   fontSize: 20,
        //   fontWeight: FontWeight.bold,
        // ),
      ),
      content: SingleChildScrollView(
          child: Form(
              key: _editPwdformKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  userInfoFormField(context, "原密码:", '', _pwdcontroller,
                      obscure: true, autofocus: true, readOnly: false),
                  userInfoFormField(context, "新密码:", '', _newpwdcontroller,
                      obscure: true, autofocus: false, readOnly: false),
                  userInfoFormField(context, "请确认:", '', _pwdconfirmcontroller,
                      obscure: true, autofocus: false, readOnly: false),
                ],
              ))),
      actions: [
        ElevatedButton(
          child: Text('保存'),
          onPressed: () async {
            if (_newpwdcontroller.text != _pwdconfirmcontroller.text) {
              notifyBox(context: context, title: "warning", content: "密码不一致");
              return;
            }
            if (!(_editPwdformKey.currentState as FormState).validate()) {
              return;
            }
            var userdata = {
              "current_password": _pwdcontroller.text,
              "new_password": _newpwdcontroller.text,
            };
            var _data = await dio.post(ChatPath.usersecurity(widget.user.id),
                data: userdata);
            if (_data["result"] == 'success') {
              Navigator.of(context).pop();
              notifyBox(context: context, title: "success", content: "修改成功");
            } else {
              notifyBox(
                  context: context, title: "warning", content: _data["result"]);
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
          icon: Text(
            prefix,
            // style: TextStyle(fontSize: 16),
          ),
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
      BuildContext context, String prefix, String text, var ctr,
      {bool obscure = true, bool autofocus = false, bool readOnly = false}) {
    return Container(
        margin: EdgeInsets.only(left: 15, right: 5),
        alignment: Alignment.center,
        child: Row(children: [
          Expanded(
              child: TextFormField(
            decoration: InputDecoration(
                icon: Text(
                  prefix,
                  // style: TextStyle(fontSize: 16),
                ),
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
            autofocus: autofocus,
            enabled: true,
            readOnly: readOnly,
          )),
        ]));
  }

  void _showMessage(String msg) {
    var _marginL = 50.0;
    if (isDisplayDesktop(context)) _marginL = 20;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: 900),
        content: Text(msg, textAlign: TextAlign.center),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0))),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: _marginL, right: 50),
      ),
    );
  }

  Future<void> uploadUserAvatar(String file_name) async {
    try {
      if (_userAvatarBytes != null) {
        var resp = await Client()
            .putObject(_userAvatarBytes!, "chat/avatar/" + file_name);

        var _imgurl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
        if (_imgurl == null) return;

        _userAvatarUrl = _imgurl;
      }

      onClickImage(_userAvatarUrl!);
    } catch (e) {
      debugPrint("uploadImage error: $e");
    }
  }

  Future<void> uploadBotAvatar(String file_name) async {
    try {
      if (_botAvatarBytes != null) {
        var resp = await Client()
            .putObject(_botAvatarBytes!, "chat/avatar/" + file_name);

        var _imgurl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
        if (_imgurl == null) return;
        _botAvatarUrl = _imgurl;

        onClickBotAvatar(_botAvatarUrl!);
      }
    } catch (e) {
      debugPrint("uploadImage error: $e");
    }
  }

  Future<void> _pickUserLocalImage(BuildContext context) async {
    var result;
    try {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedImages);

      if (result != null) {
        if (result.files.first.size / (1024 * 1024) > maxAvatarSize) {
          _showMessage("文件大小超过限制: ${maxAvatarSize}MB");
          return;
        }
        _userAvatarBytes = await FlutterImageCompress.compressWithList(
          result.files.first.bytes,
          minHeight: 200,
          minWidth: 200,
          quality: 90,
          format: CompressFormat.png,
        );

        String _file_name = result.files.first.name;
        var mt = DateTime.now().millisecondsSinceEpoch;
        String oss_name = "user${widget.user.id}_${mt}" + _file_name;
        await uploadUserAvatar(oss_name);
      }
    } catch (e) {
      debugPrint("_pickUserLocalImage error:$e");
    }
  }

  Future<void> _pickBotLocalImage(BuildContext context) async {
    var result;
    try {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedImages);

      if (result != null) {
        if (result.files.first.size / (1024 * 1024) > maxAvatarSize) {
          _showMessage("文件大小超过限制: ${maxAvatarSize}MB");
          return;
        }
        _botAvatarBytes = await FlutterImageCompress.compressWithList(
          result.files.first.bytes,
          minHeight: 200,
          minWidth: 200,
          quality: 90,
          format: CompressFormat.png,
        );

        String _file_name = result.files.first.name;
        var mt = DateTime.now().millisecondsSinceEpoch;
        String oss_name = "userbot${widget.user.id}_${mt}" + _file_name;
        uploadBotAvatar(oss_name);
      }
    } catch (e) {
      debugPrint("_pickUserLocalImage error:$e");
    }
  }

  void onClickImage(String imagePath) async {
    var oldAvatar = widget.user.avatar;
    var userdata = {"avatar": imagePath};
    var _data =
        await dio.post(ChatPath.userUpdate(widget.user.id), data: userdata);
    //selectAvatar((index + 1).toString());

    //Navigator.of(context).pop();
    if (_data["result"] == 'success') {
      if (oldAvatar != null && oldAvatar.startsWith("http"))
        ChatAPI.deleteOSSObj(oldAvatar);
      setState(() {
        widget.user.avatar = userdata['avatar'];
        Global.saveProfile(widget.user);
      });
    } else {
      showMessage(context, "failed");
    }
  }

  void onClickBotAvatar(String imagePath) async {
    var oldAvatar = widget.user.avatar_bot;
    var userdata = {"avatar_bot": imagePath};
    var _data =
        await dio.post(ChatPath.userUpdate(widget.user.id), data: userdata);

    if (_data["result"] == 'success') {
      if (oldAvatar != null && oldAvatar.startsWith("http"))
        ChatAPI.deleteOSSObj(oldAvatar);
      setState(() {
        widget.user.avatar_bot = userdata['avatar_bot'];
        Global.saveProfile(widget.user);
      });
    } else {
      showMessage(context, "failed");
    }
  }
}

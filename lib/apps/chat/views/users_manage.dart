import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class UsersManage extends StatefulWidget {
  const UsersManage();

  @override
  State<UsersManage> createState() => _UsersManageState();
}

class _UsersManageState extends State<UsersManage> {
  var dio = Dio();
  List users = [];
  final _chargecontroller = TextEditingController();
  String userUrl = "https://botsdock.com:8443/v1/users";

  @override
  void initState() {
    super.initState();
    // _initData();
  }

  Future<void> _initData() async {
    try {
      var response = await dio.post(userUrl);
      if (response.data["result"] == "success") {
        // setState(() {
        users = response.data["users"];
        // });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future _charge(int userID, double amount) async {
    try {
      String chargeUrl = "https://botsdock.com:8443/v1/user/charge/$userID";
      var chargeData = {"account": amount};
      var response = await dio.post(chargeUrl, queryParameters: chargeData);
      if (response.data["result"] == "success") {
        setState(() {
          _initData();
        });
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FloatingActionButton(
        //     child: const Icon(Icons.refresh_outlined),
        //     onPressed: () async {
        //       _initData();
        //     })
        FutureBuilder(
            future: _initData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Expanded(
                  child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Expanded(
                  child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Center(child: Text('Failed to load users'))),
                );
              } else {
                return _users(context);
              }
            })
      ],
    );
  }

  Widget _users(BuildContext context) {
    return Expanded(
        child: ListView.builder(
      key: UniqueKey(),
      shrinkWrap: true,
      itemCount: users.length,
      itemBuilder: (context, index) => userTile(context, users[index]),
    ));
  }

  Widget userTile(BuildContext context, user) {
    var leadingstr = user["name"]
        .substring(0, user["name"].length > 4 ? 4 : user["name"].length);
    return Container(
        //margin: const EdgeInsets.all(50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
              radius: 16,
              child: Text(leadingstr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey))),
          title: Text(user["id"].toString() + " - " + user["email"]),
          trailing: Text(user["credit"].toStringAsFixed(3)),
          onTap: () {
            chargeDialog(context, user);
          },
        ));
  }

  Future chargeDialog(BuildContext context, user) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => buildLoginDialog(context, user),
    );
  }

  Widget buildLoginDialog(BuildContext context, user) {
    return AlertDialog(
      title: const Text('充值',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: loginDialogContent(context),
      actions: loginDialogActions(context, user),
      contentPadding: const EdgeInsets.all(30),
      actionsPadding: const EdgeInsets.all(30),
    );
  }

  List<Widget> loginDialogActions(BuildContext context, user) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          const SizedBox(width: 80),
          ElevatedButton(
              child: const Text('确定'),
              onPressed: () async {
                var res = await _charge(
                    user["id"], double.parse(_chargecontroller.text));
                Navigator.of(context).pop();
                if (res == true) {
                  notifyBox(
                      context: context, title: "充值结果", content: "success");
                } else {
                  notifyBox(context: context, title: "充值结果", content: "failed");
                }
              })
        ],
      )
    ];
  }

  Widget loginDialogContent(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [logTextFormField(context, "金额", _chargecontroller, false)],
      ),
    );
  }

  Widget logTextFormField(
      BuildContext context, String text, var ctr, bool obscure) {
    return TextFormField(
        decoration: InputDecoration(
            //filled: true,
            //fillColor: AppColors.inputBoxBackground,
            labelText: text,
            prefixIcon: Icon(
              Icons.currency_yuan_rounded,
              color: Colors.blue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            hintText: text),
        obscureText: obscure,
        maxLines: 1,
        textInputAction: TextInputAction.newline,
        controller: ctr,
        validator: (v) {
          return v == null || v.trim().isNotEmpty ? null : "$text不能为空";
        });
  }

  void notifyBox({context, var title, var content}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(content)]),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ]),
    );
  }
}

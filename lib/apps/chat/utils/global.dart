import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import '../models/chat.dart';
import '../models/user.dart';
import '../models/pages.dart';
import '../models/message.dart';
import '../utils/constants.dart';

class Global {
  static late SharedPreferences _prefs;
  var dio = Dio();

  Future init(user, pages) async {
    _prefs = await SharedPreferences.getInstance();
    try {
      oss_init();
      if (_prefs.containsKey("isLogedin") &&
          _prefs.getBool("isLogedin") == true) {
        var user_id = _prefs.getInt("id");
        var url = userUrl + "/${user_id}" + "/info";
        var response = await dio.post(url);
        if (response.data["updated_at"] != _prefs.getInt("updated_at")) {
          Global.reset();
          user.id = response.data["id"];
          user.email = response.data["email"];
          user.name = response.data["name"];
          user.phone = response.data["phone"];
          user.avatar = response.data["avatar"];
          user.credit = response.data["credit"];
          user.updated_at = response.data["updated_at"];
          user.isLogedin = true;
          Global.saveProfile(user);
          get_db_chats(user, pages);
        } else {
          user.id = _prefs.getInt("id");
          user.email = _prefs.getString("email");
          user.name = _prefs.getString("name");
          user.phone = _prefs.getString("phone");
          user.avatar = _prefs.getString("avatar");
          user.credit = _prefs.getDouble("credit");
          user.isLogedin = true;
          user.updated_at = _prefs.getInt("updated_at");
          get_local_chats(user, pages);
        }
        pages.sortPages();
      }
    } catch (e) {
      debugPrint("init error, reset:${e}");
      Global.reset();
    }
  }

  static int restort_singel_page(User user, Pages pages, c) {
    var pid = c["page_id"];
    pages.addPage(Chat(chatId: pid, title: c["title"]));
    pages.getPage(pid).modelVersion = c["model"];
    pages.getPage(pid).dbID = c["id"];
    pages.getPage(pid).updated_at = c["updated_at"];
    pages.getPage(pid).assistantID = c["assistant_id"];
    pages.getPage(pid).threadID = c["thread_id"];
    pages.getPage(pid).botID = c["bot_id"];
    var msgContent;
    for (var m in c["contents"]) {
      //print("load: $m");
      var smid = m["id"] ?? 0;
      int mid = smid is String ? int.parse(smid) : smid;
      if (MsgType.values[m["type"]] == MsgType.image &&
          m["role"] == MessageRole.user &&
          m["content"] is List) {
        msgContent = jsonDecode(m["content"]);
      } else
        msgContent = m["content"];
      Message msgQ = Message(
          id: mid,
          pageID: pid,
          role: m["role"],
          type: MsgType.values[m["type"]],
          content: msgContent,
          fileName: m["fileName"],
          fileBytes: m["fileBytes"],
          fileUrl: m["fileUrl"],
          timestamp: m["timestamp"]);
      pages.addMessage(pid, msgQ);
    }
    return pid;
  }

  void get_local_chats(user, pages) {
    final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
    for (var key in keys) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) {
        final c = jsonDecode(jsonChat);
        restort_singel_page(user, pages, c);
      }
    }
  }

  void get_db_chats(user, pages) async {
    var chatdbUrl = userUrl + "/" + "${user.id}" + "/chats";
    Response cres = await dio.post(
      chatdbUrl,
    );
    if (cres.data["result"] == "success") {
      for (var c in cres.data["chats"]) {
        //user dbID to recovery pageID,
        //incase no user log, c["contents"][0]["pageID"] == currentPageID
        var pid = restort_singel_page(user, pages, c);
        Global.saveChats(user, pid, jsonEncode(c), 0);
        //pid += 1;
      }
    }
  }

  static saveProfile(user) {
    if (user.id != null) _prefs.setInt("id", user.id);
    if (user.email != null) _prefs.setString("email", user.email);
    if (user.name != null) _prefs.setString("name", user.name);
    if (user.phone != null) _prefs.setString("phone", user.phone);
    if (user.avatar != null) _prefs.setString("avatar", user.avatar);
    if (user.credit != null) _prefs.setDouble("credit", user.credit);
    if (user.isLogedin != null) _prefs.setBool("isLogedin", user.isLogedin);
    if (user.updated_at != null) _prefs.setInt("updated_at", user.updated_at);
  }

  static saveChats(user, page_id, cdata, updated_at) {
    _prefs.setString("chat_$page_id", cdata);
    if (updated_at != 0) _prefs.setInt("updated_at", updated_at);
  }

  static deleteChat(page_id, updated_at) {
    _prefs.remove("chat_$page_id");
    if (updated_at != 0) _prefs.setInt("updated_at", updated_at);
  }

  static reset() {
    _prefs.clear();
  }

  void oss_init() async {
    Client.init(
        //stsUrl: "server sts url",
        ossEndpoint: "oss-cn-shanghai.aliyuncs.com",
        bucketName: "app-gallary",
        authGetter: _authGetter);
  }

  Future<Map> get_creds() async {
    var res = {};
    try {
      var url = userUrl + "/23" + "/oss_credentials";
      var response = await dio.post(url);
      res = response.data["credentials"];
    } catch (e) {
      debugPrint("get_creds error: $e");
      return {};
    }
    return res;
  }

  Future<Auth> _authGetter() async {
    //Auth _authGetter() {
    var creds = await get_creds();
    return Auth(
        accessKey: creds["AccessKeyId"] ?? "",
        accessSecret: creds["AccessKeySecret"] ?? "",
        expire: creds["Expiration"] ?? "",
        secureToken: creds["SecurityToken"] ?? "");
  }
}

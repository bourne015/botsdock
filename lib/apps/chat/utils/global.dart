import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import '../models/chat.dart';
import '../models/message.dart';
import '../utils/constants.dart';

class Global {
  static late SharedPreferences _prefs;
  var dio = Dio();

  Future init(user, pages) async {
    _prefs = await SharedPreferences.getInstance();
    var _email = _prefs.getString("email");
    if (_email != null) {
      user.id = _prefs.getInt("id");
      user.email = _prefs.getString("email");
      user.name = _prefs.getString("name");
      user.phone = _prefs.getString("phone");
      user.avatar = _prefs.getString("avatar");
      user.isLogedin = _prefs.getBool("isLogedin");
    }

    //if (user.isLogedin) {
    final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
    for (var key in keys) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) {
        final c = jsonDecode(jsonChat);
        var pid = c["id"]; //c["contents"][0]["pageID"];
        pages.defaultModelVersion = ClaudeModel.haiku;
        pages.addPage(pid, Chat(chatId: pid, title: c["title"]));
        pages.getPage(pid).modelVersion = c["model"];
        pages.getPage(pid).dbID = pid;
        for (var m in c["contents"]) {
          Message msgQ = Message(
              id: '0',
              pageID: pid,
              role: m["role"],
              type: MsgType.values[m["type"]],
              content: m["content"],
              fileName: m["fileName"],
              fileBytes: m["fileBytes"],
              timestamp: m["timestamp"]);
          pages.addMessage(pid, msgQ);
        }
      }
    }
    //}
  }

  static saveProfile(user) {
    if (user.id != null) _prefs.setInt("id", user.id);
    if (user.email != null) _prefs.setString("email", user.email);
    if (user.name != null) _prefs.setString("name", user.name);
    if (user.phone != null) _prefs.setString("phone", user.phone);
    if (user.avatar != null) _prefs.setString("avatar", user.avatar);
    if (user.isLogedin != null) _prefs.setBool("isLogedin", user.isLogedin);
  }

  static saveChats(user, dbid, cdata) {
    _prefs.setString("chat_$dbid", cdata);
  }

  static reset() {
    _prefs.clear();
  }
}

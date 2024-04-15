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
    try {
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
          user.isLogedin = true;
          user.updated_at = _prefs.getInt("updated_at");
          get_local_chats(user, pages);
        }
      }
    } catch (e) {
      print("init error: reset");
      Global.reset();
    }
  }

  void get_local_chats(user, pages) {
    print("get_local_chats");
    final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
    for (var key in keys) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) {
        final c = jsonDecode(jsonChat);
        var pid = c["page_id"]; //c["contents"][0]["pageID"];
        //pages.defaultModelVersion = ClaudeModel.haiku;
        pages.addPage(pid, Chat(chatId: pid, title: c["title"]));
        pages.getPage(pid).modelVersion = c["model"];
        pages.getPage(pid).dbID = c["id"];
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
  }

  void get_db_chats(user, pages) async {
    print("get_db_chats");
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
        pages.defaultModelVersion = GPTModel.gptv35;
        pages.addPage(pid, Chat(chatId: pid, title: c["title"]));
        pages.getPage(pid).modelVersion = c["model"];
        pages.getPage(pid).dbID = c["id"];
        for (var m in c["contents"]) {
          //print("ttt:${m["type"]}, ${MsgType.values[m["type"]]}");
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
}

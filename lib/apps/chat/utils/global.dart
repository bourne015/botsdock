import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import '../models/bot.dart';
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/user.dart';
import './chat_api.dart';

class Global {
  static late SharedPreferences _prefs;
  var chatApi = ChatAPI();

  Future init(User user, Pages pages) async {
    _prefs = await SharedPreferences.getInstance();
    try {
      oss_init();
      if (_prefs.containsKey("isLogedin") &&
          _prefs.getBool("isLogedin") == true) {
        var user_id = _prefs.getInt("cached_user_id");
        User? _u = await chatApi.userInfo(user_id);
        if (_u == null) {
          debugPrint("failed to get user info");
        } else if (_u.updated_at != _prefs.getInt("updated_at")) {
          Global.reset();
          user.copy(_u);
          user.update(isLogedin: true);
          Global.saveProfile(user);
          await pages.fetch_pages(user.id);
        } else {
          final String? jsonUser = _prefs.getString("user_${user_id}");
          if (jsonUser != null) {
            user.copy(User.fromJson(jsonDecode(jsonUser)));
            get_local_chats(user, pages);
            // pages.sortPages();
          }
        }
        pages.flattenPages();
      }
    } catch (e) {
      debugPrint("init error, reset:${e}");
      Global.reset();
    }
  }

  void get_local_chats(User user, Pages pages) {
    final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
    for (var key in keys) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) //pages.restore_single_page(jsonDecode(jsonChat));
        pages.addPage(Chat.fromJson(jsonDecode(jsonChat)));
    }
  }

  static saveProfile(User user) {
    _prefs.setInt("updated_at", user.updated_at);
    _prefs.setInt("cached_user_id", user.id);
    _prefs.setBool("isLogedin", user.isLogedin);
    _prefs.setString("user_${user.id}", jsonEncode(user.toJson()));
  }

  static saveChats(page_id, cdata, updated_at) {
    _prefs.setString("chat_$page_id", cdata);
    if (updated_at != 0) _prefs.setInt("updated_at", updated_at);
  }

  static deleteChat(page_id, updated_at) {
    _prefs.remove("chat_$page_id");
    if (updated_at != 0) _prefs.setInt("updated_at", updated_at);
  }

  static saveBots(List<Bot> bots, updated_at) {
    for (Bot bot in bots) {
      var jsBot = jsonEncode(bot.toJson());
      _prefs.setString("ai_bots_${bot.id}", jsBot);
    }
    if (updated_at != 0) _prefs.setInt("bots_updated_at", updated_at);
  }

  static bool botsCheck(int updated) {
    return updated == _prefs.getInt("bots_updated_at");
  }

  static restoreBots(bots) {
    final keys = _prefs.getKeys().where((key) => key.startsWith('ai_bots_'));
    for (var key in keys) {
      String? jsonBot = _prefs.getString(key);
      if (jsonBot != null) {
        final bot = Bot.fromJson(jsonDecode(jsonBot));
        //print("bot: ${bot.name}");
        // Bots.addBot(jsonDecode(jsonBot));
        bots.add(bot);
      }
    }
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

  Future<Auth> _authGetter() async {
    //Auth _authGetter() {
    var creds = await chatApi.get_creds();
    return Auth(
        accessKey: creds["AccessKeyId"] ?? "",
        accessSecret: creds["AccessKeySecret"] ?? "",
        expire: creds["Expiration"] ?? "",
        secureToken: creds["SecurityToken"] ?? "");
  }
}

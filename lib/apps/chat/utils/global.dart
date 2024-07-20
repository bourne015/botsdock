import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import '../models/bot.dart';
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
          user.avatar_bot = response.data["avatar_bot"];
          user.credit = response.data["credit"];
          debugPrint("kkkkkkkkkkkk1: ${response.data["updated_at"]}");
          user.updated_at = response.data["updated_at"];
          debugPrint("kkkkkkkkkkkk2: ${response.data["updated_at"]}");
          user.isLogedin = true;
          Global.saveProfile(user);
          await pages.fetch_pages(user.id);
        } else {
          user.id = _prefs.getInt("id");
          user.email = _prefs.getString("email");
          user.name = _prefs.getString("name");
          user.phone = _prefs.getString("phone");
          user.avatar = _prefs.getString("avatar");
          user.avatar_bot = _prefs.getString("avatar_bot");
          user.credit = _prefs.getDouble("credit");
          user.isLogedin = true;
          debugPrint("kkkkkkkkkkkk3: ${_prefs.getInt("updated_at")}");
          user.updated_at = _prefs.getInt("updated_at");
          debugPrint("kkkkkkkkkkkk4: ${_prefs.getInt("updated_at")}");
          get_local_chats(user, pages);
          pages.sortPages();
        }
      }
    } catch (e) {
      debugPrint("init error, reset:${e}");
      Global.reset();
    }
  }

  void get_local_chats(user, pages) {
    final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
    for (var key in keys) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) pages.restore_single_page(jsonDecode(jsonChat));
    }
  }

  static saveProfile(user) {
    if (user.id != null) _prefs.setInt("id", user.id);
    if (user.email != null) _prefs.setString("email", user.email);
    if (user.name != null) _prefs.setString("name", user.name);
    if (user.phone != null) _prefs.setString("phone", user.phone);
    if (user.avatar != null) _prefs.setString("avatar", user.avatar);
    if (user.avatar_bot != null)
      _prefs.setString("avatar_bot", user.avatar_bot);
    if (user.credit != null) _prefs.setDouble("credit", user.credit);
    if (user.isLogedin != null) _prefs.setBool("isLogedin", user.isLogedin);
    if (user.updated_at != null) _prefs.setInt("updated_at", user.updated_at);
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

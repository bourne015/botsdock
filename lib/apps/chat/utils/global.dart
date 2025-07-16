import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import '../models/bot.dart';
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/user.dart';

class Global {
  static late SharedPreferences _prefs;
  static var chatApi = ChatAPI();

  static void setUp(pf) {
    _prefs = pf;
  }

  static Future restoreLocalUser(User user, rp.WidgetRef ref) async {
    if (user.status == UserStatus.loggedIn) {
      // ref.read(userProvider.notifier).update(status: UserStatus.loggedIn);
      return;
    }
    ACCESS_TOKEN = _prefs.getString("chat_access_token");
    if (ACCESS_TOKEN == null || ACCESS_TOKEN!.isEmpty) {
      // ref.read(userProvider.notifier).update(status: UserStatus.loggedOut);
      return;
    }
    ref.read(userProvider.notifier).update(status: UserStatus.loading);
    User? _u = await chatApi.userFromToken();
    if (_u != null) {
      ref.read(userProvider.notifier).copy(_u);
      ref.read(userProvider.notifier).update(
            isLogedin: true,
            access_token: ACCESS_TOKEN,
            status: UserStatus.loggedIn,
          );
    } else {
      ref.read(userProvider.notifier).update(status: UserStatus.loggedOut);
    }
  }

  static Future restoreChats(
      User user, Pages pages, PropertyNotifier propertyNotifier) async {
    try {
      oss_init();
      restoreProperties(propertyNotifier, user);
      propertyNotifier.setIsLoading(true);
      final localChats =
          _prefs.getKeys().where((key) => key.startsWith('U${user.id}_chat_'));
      if (localChats.isEmpty ||
          user.updated_at != _prefs.getInt("U${user.id}_updated_at")) {
        reset();
        saveProfile(user);
        debugPrint("fetch remote chat");
        await pages.fetch_pages(user.id);
      } else {
        debugPrint("fetch local chat");
        await get_local_chats(user, pages, localChats);
      }
      pages.flattenPages();
    } catch (e) {
      debugPrint("init error, reset:${e}");
      reset();
    }
    propertyNotifier.setIsLoading(false);
  }

  static Future<void> get_local_chats(
      User user, Pages pages, localChats) async {
    for (var key in localChats) {
      final jsonChat = _prefs.getString(key);
      if (jsonChat != null) //pages.restore_single_page(jsonDecode(jsonChat));
        pages.addPage(Chat.fromJson(jsonDecode(jsonChat)));
    }
  }

  static void restoreProperties(PropertyNotifier propertyNotifier, User user) {
    if (_prefs.getString("init_model") != null) {
      propertyNotifier.setInitModelVersion(_prefs.getString("init_model")!);
    }
    if (user.settings?.defaultmodel != null) {
      propertyNotifier.setInitModelVersion(user.settings!.defaultmodel);
    }
    // if (_prefs.getBool("artifact") != null)
    //   property.artifact = _prefs.getBool("artifact") ?? false;
    // if (_prefs.getBool("internet") != null)
    //   property.internet = _prefs.getBool("internet") ?? false;
  }

  static saveProperties({String? model, bool? artifact, bool? internet}) {
    if (model != null) _prefs.setString("init_model", model);
    // if (artifact != null) _prefs.setBool("artifact", artifact);
    // if (internet != null) _prefs.setBool("internet", internet);
  }

  static saveProfile(User user) {
    _prefs.setInt("U${user.id}_updated_at", user.updated_at);
    // _prefs.setInt("cached_user_id", user.id);
    // _prefs.setBool("U${user.id}_isLogedin", user.isLogedin);
    // _prefs.setString("U${user.id}", jsonEncode(user.toJson()));
    if (user.token != null) _prefs.setString("chat_access_token", user.token!);
  }

  static saveChats(user_id, page_id, cdata, updated_at) {
    _prefs.setString("U${user_id}_chat_$page_id", cdata);
    if (updated_at != 0) _prefs.setInt("U${user_id}_updated_at", updated_at);
  }

  static deleteChat(user_id, page_id, updated_at) {
    _prefs.remove("U${user_id}_chat_$page_id");
    if (updated_at != 0) _prefs.setInt("U${user_id}_updated_at", updated_at);
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

  static reset() async {
    await _prefs.clear();
  }

  static void oss_init() async {
    Client.init(
        //stsUrl: "server sts url",
        ossEndpoint: "oss-cn-shanghai.aliyuncs.com",
        bucketName: "app-gallary",
        authGetter: _authGetter);
  }

  static Future<Auth> _authGetter() async {
    //Auth _authGetter() {
    var creds = await chatApi.get_creds();
    return Auth(
        accessKey: creds["AccessKeyId"] ?? "",
        accessSecret: creds["AccessKeySecret"] ?? "",
        expire: creds["Expiration"] ?? "",
        secureToken: creds["SecurityToken"] ?? "");
  }
}

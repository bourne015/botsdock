import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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

    if (user.isLogedin) {
      ////fetch chat data from db
      var chatdbUrl = userUrl + "/" + "${user.id}" + "/chats";
      Response cres = await dio.post(
        chatdbUrl,
      );
      //var pid = 1;
      if (cres.data["result"] == "success") {
        for (var c in cres.data["chats"]) {
          //user dbID to recovery pageID,
          //incase no user log, c["contents"][0]["pageID"] == currentPageID
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
          //pid += 1;
        }
      }
      ////
    }
  }

  static saveProfile(user) {
    if (user.id != null) _prefs.setInt("id", user.id);
    if (user.email != null) _prefs.setString("email", user.email);
    if (user.name != null) _prefs.setString("name", user.name);
    if (user.phone != null) _prefs.setString("phone", user.phone);
    if (user.avatar != null) _prefs.setString("avatar", user.avatar);
    if (user.isLogedin != null) _prefs.setBool("isLogedin", user.isLogedin);
  }

  static reset() {
    _prefs.clear();
  }
}

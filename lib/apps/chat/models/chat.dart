import 'package:flutter/material.dart';

import 'message.dart';
import '../views/message_box.dart';
import '../utils/constants.dart';

//model of a chat page
class Chat {
  final int id;
  int _dbID = -1;
  int updated_at = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  List<Message> messages = [];
  List<Widget> messageBox = [];
  List<Map> _gptMsg = [];
  List<Map> _msgsAll = [];

  String title;
  String _modelVersion = '';
  int tokenSpent = 0;
  bool onGenerating = false;

  Chat({
    required int chatId,
    String? title,
  })  : id = chatId,
        title = title!;

  String get modelVersion => _modelVersion;

  get gptMsgs => _gptMsg;
  get msgsAll => _msgsAll;

  set modelVersion(String? v) {
    _modelVersion = v!;
    //notifyListeners();
  }

  int get dbID => _dbID;
  set dbID(int v) {
    _dbID = v;
    //notifyListeners();
  }

  void addMessage(Message newMsg) {
    messages.add(newMsg);
    messageBox.insert(
      0,
      MessageBox(val: {
        "role": newMsg.role,
        "type": newMsg.type,
        "content": newMsg.content,
        "fileName": newMsg.fileName,
        "fileBytes": newMsg.fileBytes
      }),
    );
    var trNewMsg = newMsg.toMap(modelVersion);
    _gptMsg.add(trNewMsg["gpt"]);
    _msgsAll.add(trNewMsg["all"]);
  }

  void appendMessage(String newMsg) {
    int lastMsgID = messages.isNotEmpty ? messages.length - 1 : 0;
    messages[lastMsgID].content += newMsg;
    messageBox[0] = MessageBox(val: {
      "role": MessageRole.assistant,
      "content": messages[lastMsgID].content
    });

    _gptMsg.last["content"] = messages[lastMsgID].content;
    _msgsAll.last["content"] = messages[lastMsgID].content;
  }

  // List<Map> msgsToMap() {
  //   List<Map> res = [];
  //   List<Map> res1 = [];
  //   for (int i = 0; i < messages.length; i++) {
  //     var val = messages[i];
  //     res.add(val.toMap(modelVersion)["gpt"]);
  //     res1.add(val.toMap(modelVersion)["all"]);
  //   }
  //   msg = res;
  //   msgAll = res1;
  //   return msg;
  // }
}

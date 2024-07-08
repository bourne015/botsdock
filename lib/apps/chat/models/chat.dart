import 'package:flutter/material.dart';

import 'message.dart';
import '../views/message_box.dart';

//model of a chat page
class Chat {
  int? id = -1;
  int _dbID = -1;
  int? _botID;
  String? _assistantID;
  String? _threadID;
  int updated_at = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  List<Message> messages = [];
  List<Widget> messageBox = [];
  List<Map> _chatScheme = [];
  List<Map> _dbScheme = [];

  String title;
  String _modelVersion = '';
  int tokenSpent = 0;
  bool onGenerating = false;

  Chat({
    int? chatId,
    String? title,
  })  : id = chatId,
        title = title!;

  String get modelVersion => _modelVersion;

  get chatScheme => _chatScheme;
  get dbScheme => _dbScheme;

  set modelVersion(String? v) {
    _modelVersion = v!;
  }

  int get dbID => _dbID;
  set dbID(int v) {
    _dbID = v;
  }

  int? get botID => _botID;
  set botID(int? v) {
    _botID = v;
  }

  String? get assistantID => _assistantID;
  set assistantID(String? v) {
    _assistantID = v;
  }

  String? get threadID => _threadID;
  set threadID(String? v) {
    _threadID = v;
  }

  void addMessage(Message newMsg) {
    try {
      messages.add(newMsg);
      messageBox.insert(
        0,
        MessageBox(val: {
          "role": newMsg.role,
          "type": newMsg.type,
          "content": newMsg.content,
          "fileName": newMsg.fileName,
          "fileBytes": newMsg.fileBytes,
          "fileUrl": newMsg.fileUrl
        }),
      );
      var trNewMsg = newMsg.toMap(modelVersion);
      _chatScheme.add(trNewMsg["chat_scheme"]);
      _dbScheme.add(trNewMsg["db_scheme"]);
    } catch (e) {
      debugPrint("addMessage error:${e}");
    }
  }

  void appendMessage(String newMsg) {
    int lastMsgID = messages.isNotEmpty ? messages.length - 1 : 0;
    messages[lastMsgID].content += newMsg;
    messageBox[0] = MessageBox(val: {
      "role": messages[lastMsgID].role,
      "content": messages[lastMsgID].content
    });

    _chatScheme.last["content"] = messages[lastMsgID].content;
    _dbScheme.last["content"] = messages[lastMsgID].content;
  }

  void updateFileUrl(int msgId, String url) {
    //int lastMsgID = messages.isNotEmpty ? messages.length - 1 : 0;
    messages[msgId].fileUrl = url;
    var msg = messages[msgId];
    messageBox[0] = MessageBox(val: {
      "role": msg.role,
      "type": msg.type,
      "content": msg.content,
      "fileName": msg.fileName,
      "fileBytes": msg.fileBytes,
      "fileUrl": msg.fileUrl
    });

    // if (msg.role == MessageRole.user)
    //   _chatScheme.last["content"][1]["image_url"]["url"] = url;
    _dbScheme[msgId]["fileUrl"] = url;
  }
}

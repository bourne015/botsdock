import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/data.dart';

import 'message.dart';

//model of a chat page
class Chat with ChangeNotifier {
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
  // final ValueNotifier<Message?> lastMessageNotifier = ValueNotifier(null);
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;

  String title;
  String _modelVersion = '';
  int tokenSpent = 0;
  bool _onGenerating = false;

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

  bool get onGenerating => _onGenerating;
  set onGenerating(bool v) {
    _onGenerating = v;
  }

  void addMessage(Message newMsg) {
    try {
      messages.add(newMsg);
      // messageBox.add(MessageBox(msg: newMsg, key: ValueKey(newMsg.id)));
      var trNewMsg = newMsg.toMap(modelVersion);
      _chatScheme.add(trNewMsg["chat_scheme"]);
      _dbScheme.add(trNewMsg["db_scheme"]);
      // lastMessageNotifier.value = newMsg;
      _messageController.add(newMsg);
    } catch (e) {
      debugPrint("addMessage error:${e}");
    }
  }

  void appendMessage(
      {String? msg,
      Map<String, VisionFile>? visionFiles,
      Map<String, Attachment>? attachments}) {
    int lastMsgID = messages.isNotEmpty ? messages.length - 1 : 0;
    if (msg != null) messages[lastMsgID].content += msg;
    // messageBox[0] = MessageBox(val: {
    //   "role": messages[lastMsgID].role,
    //   "content": messages[lastMsgID].content
    // });

    if (visionFiles != null && visionFiles.isNotEmpty)
      visionFiles.forEach((String name, VisionFile content) {
        messages[lastMsgID].visionFiles[name] = VisionFile(
            name: content.name, url: content.url, bytes: content.bytes);
      });
    if (attachments != null)
      attachments.forEach((String name, Attachment content) {
        messages[lastMsgID].attachments[name] =
            Attachment(file_id: content.file_id, tools: content.tools);
      });
    _chatScheme.last["content"] = messages[lastMsgID].content;
    _dbScheme.last["content"] = messages[lastMsgID].content;
    //messages[lastMsgID] is a reference, never change
    //so notifyListeners manually
    // lastMessageNotifier.value = messages[lastMsgID];
    // lastMessageNotifier.notifyListeners();
    _messageController.add(messages.last);
  }

  void updateMsg(int msgId, {Map<String, VisionFile>? vfiles}) {
    if (vfiles != null) {
      messages[msgId].visionFiles = vfiles;
      var trNewMsg = messages[msgId].toMap(modelVersion);
      _chatScheme[msgId] = trNewMsg["chat_scheme"];
      _dbScheme[msgId] = trNewMsg["db_scheme"];
      // var msg = messages[msgId];
      // messageBox[0] = MessageBox(val: {
      //   "role": msg.role,
      //   "type": msg.type,
      //   "content": msg.content,
      //   "visionFiles": msg.visionFiles,
      //   "attachments": msg.attachments
      // });
    }
  }

  void updateScheme(int msgId) {
    var trNewMsg = messages[msgId].toMap(modelVersion);
    _chatScheme[msgId] = trNewMsg["chat_scheme"];
    _dbScheme[msgId] = trNewMsg["db_scheme"];
  }
}

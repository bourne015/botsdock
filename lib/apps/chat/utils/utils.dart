import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:html';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import '../utils/global.dart';

bool isDisplayDesktop(BuildContext context) =>
    !isDisplayFoldable(context) &&
    getWindowType(context) >= AdaptiveWindowType.medium;

bool isDisplayFoldable(BuildContext context) {
  final hinge = MediaQuery.of(context).hinge;
  if (hinge == null) {
    return false;
  } else {
    // Vertical
    return hinge.bounds.size.aspectRatio < 1;
  }
}

class ChatSSE {
  Stream<String> connect(String path, String method,
      {Map<String, dynamic>? headers, String? body}) {
    int progress = 0;
    //const asciiEncoder = AsciiEncoder();
    final httpRequest = HttpRequest();
    final streamController = StreamController<String>();
    httpRequest.open(method, path);
    headers?.forEach((key, value) {
      httpRequest.setRequestHeader(key, value);
    });
    //httpRequest.onProgress.listen((event) {
    httpRequest.addEventListener('progress', (event) {
      final data = httpRequest.responseText!.substring(progress);

      var lines = data.split("\r\n\r");
      for (var line in lines) {
        line = line.trimLeft();
        for (var vline in line.split('\n')) {
          if (vline.startsWith("data:")) {
            vline = vline.substring(5).replaceFirst(' ', '');
            streamController.add(vline);
          }
        }
      }

      progress += data.length;
    });
    httpRequest.addEventListener('loadstart', (event) {
      final data = httpRequest.responseText!.substring(0);
      debugPrint("event start:$data");
    });
    httpRequest.addEventListener('load', (event) {
      debugPrint("event load");
    });
    httpRequest.addEventListener('loadend', (event) {
      httpRequest.abort();
      if (!streamController.isClosed) {
        streamController.close();
      }
      debugPrint("event end");
    });
    httpRequest.addEventListener('error', (event) {
      String status = httpRequest.status.toString();
      String statusText = httpRequest.statusText ?? "Unknown error";
      String responseText = httpRequest.responseText ?? 'No response text';
      String errorMessage =
          "Error Status: $status, Status Text: $statusText, Response Text: $responseText";
      streamController.addError(errorMessage);
      debugPrint("event error: $errorMessage");
    });
    httpRequest.send(body);
    return streamController.stream;
  }
}

void notifyBox({context, var title, var content}) {
  showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(content),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
}

class ChatGen {
  final dio = Dio();
  final ChatSSE chatServer = ChatSSE();
  Future<void> titleGenerate(Pages pages, int handlePageID) async {
    String q;
    try {
      if (pages.getPage(handlePageID).modelVersion == GPTModel.gptv40Dall) {
        q = pages.getMessages(handlePageID)!.first.content;
      } else if (pages.getMessages(handlePageID)!.length > 1) {
        q = pages.getMessages(handlePageID)![1].content;
      } else {
        //in case no input
        return;
      }
      var chatData1 = {
        "model": ClaudeModel.haiku,
        "question": "为这段话写一个5个字左右的标题:$q"
      };
      final response = await dio.post(chatUrl, data: chatData1);
      var title = response.data;
      pages.setPageTitle(handlePageID, title);
    } catch (e) {
      debugPrint("titleGenerate error: $e");
    }
  }

  //save chats to DB and local cache
  void saveChats(user, pages, handlePageID) async {
    if (user.id != 0) {
      //only store after user login
      var chatdbUrl = userUrl + "/" + "${user.id}" + "/chat";
      var chatData = {
        "id": pages.getPage(handlePageID).dbID,
        "page_id": handlePageID,
        "title": pages.getPage(handlePageID).title,
        "contents": pages.getPage(handlePageID).msgsAll,
        "model": pages.getPage(handlePageID).modelVersion,
      };

      Response cres = await dio.post(
        chatdbUrl,
        data: chatData,
      );
      if (cres.data["result"] == "success") {
        pages.getPage(handlePageID).dbID = cres.data["id"];
        pages.getPage(handlePageID).updated_at = cres.data["updated_at"];

        chatData["id"] = cres.data["id"];
        Global.saveChats(user, chatData["page_id"], jsonEncode(chatData),
            cres.data["updated_at"]);
      }
    }
  }

  void submitText(Pages pages, int handlePageID, user) async {
    bool _isNewReply = true;

    try {
      if (pages.defaultModelVersion == GPTModel.gptv40Dall) {
        String q = pages.getMessages(handlePageID)!.last.content;
        var chatData1 = {"model": GPTModel.gptv40Dall, "question": q};
        pages.getPage(handlePageID).onGenerating = true;
        final response = await dio.post(imageUrl, data: chatData1);
        pages.getPage(handlePageID).onGenerating = false;
        if (response.statusCode == 200 &&
            pages.getPage(handlePageID).title == "Chat $handlePageID") {
          titleGenerate(pages, handlePageID);
        }

        Message msgA = Message(
            id: '1',
            pageID: handlePageID,
            role: MessageRole.assistant,
            type: MsgType.image,
            content: response.data,
            timestamp: DateTime.now().millisecondsSinceEpoch);
        pages.addMessage(handlePageID, msgA);
        saveChats(user, pages, handlePageID);
      } else {
        var chatData = {
          "model": pages.currentPage?.modelVersion,
          "question": pages.getPage(handlePageID).gptMsgs,
        };
        final stream = chatServer.connect(
          sseChatUrl,
          "POST",
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream'
          },
          body: jsonEncode(chatData),
        );
        pages.getPage(handlePageID).onGenerating = true;
        stream.listen((data) {
          if (_isNewReply) {
            Message msgA = Message(
                id: '1',
                pageID: handlePageID,
                role: MessageRole.assistant,
                type: MsgType.text,
                content: data,
                timestamp: DateTime.now().millisecondsSinceEpoch);
            pages.addMessage(handlePageID, msgA);
          } else {
            pages.appendMessage(handlePageID, data);
          }
          pages.getPage(handlePageID).onGenerating = true;
          _isNewReply = false;
        }, onError: (e) {
          debugPrint('SSE error: $e');
          pages.getPage(handlePageID).onGenerating = false;
        }, onDone: () async {
          debugPrint('SSE complete');
          if (pages.getPage(handlePageID).title == "Chat $handlePageID") {
            await titleGenerate(pages, handlePageID);
          }
          pages.getPage(handlePageID).onGenerating = false;
          saveChats(user, pages, handlePageID);
        });
      }
    } catch (e) {
      debugPrint("gen error: $e");
      pages.getPage(handlePageID).onGenerating = false;
    }
  }
}

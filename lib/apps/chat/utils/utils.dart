//import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart';

import '../models/pages.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/global.dart';

enum AdaptiveWindowType {
  small,
  medium,
  large,
}

AdaptiveWindowType getAdaptiveWindowType(BuildContext context) {
  final double width = MediaQuery.of(context).size.width;

  if (width < 600) {
    return AdaptiveWindowType.small;
  } else if (width < 1200) {
    return AdaptiveWindowType.medium;
  } else {
    return AdaptiveWindowType.large;
  }
}

bool isDisplayDesktop(BuildContext context) {
  final windowType = getAdaptiveWindowType(context);
  return windowType == AdaptiveWindowType.large;
}

bool isDisplayFoldable(BuildContext context) {
  final hinge = MediaQuery.of(context).hinge;
  if (hinge == null) {
    return false;
  } else {
    // 判断是否为垂直铰链
    return hinge.bounds.size.aspectRatio < 1;
  }
}

class ChatSSE {
  Stream<String> connect(
    String url,
    String method, {
    Map<String, String>? headers,
    String? body,
  }) async* {
    var request = http.Request(method, Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;

    var client;
    if (kIsWeb)
      client = FetchClient(mode: RequestMode.cors);
    else
      client = http.Client();
    var response = await client.send(request);
    var stream = response.stream.transform<String>(utf8.decoder);
    final controller = StreamController<String>();

    try {
      stream.transform(const LineSplitter()).listen((String line) {
        if (line.isNotEmpty) {
          var data = line.substring(5).replaceFirst(' ', '');
          data = data.length > 0 ? data : '\n';
          controller.add(data);
        }
      }, onDone: () {
        controller.close();
        client.close();
      }, onError: (error) {
        controller.addError(error);
        controller.close();
        client.close();
      });
      yield* controller.stream;
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
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
        "contents": pages.getPage(handlePageID).dbScheme,
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
        chatData["updated_at"] = cres.data["updated_at"];
        Global.saveChats(user, chatData["page_id"], jsonEncode(chatData),
            cres.data["updated_at"]);
      }
    }
  }

  Future<void> uploadImage(pages, pid, msg_id, filename, imgData) async {
    try {
      var resp = await Client().putObject(imgData, "chat/image/" + filename);
      String? ossUrl =
          (resp.statusCode == 200) ? resp.realUri.toString() : null;
      if (ossUrl != null) pages.updateFileUrl(pid, msg_id, ossUrl);
    } catch (e) {
      debugPrint("uploadImage to oss error: $e");
    }
  }

  void submitText(
      Pages pages, Property property, int handlePageID, user) async {
    bool _isNewReply = true;

    try {
      if (property.initModelVersion == GPTModel.gptv40Dall) {
        String q = pages.getMessages(handlePageID)!.last.content;
        var chatData1 = {"model": GPTModel.gptv40Dall, "question": q};
        pages.getPage(handlePageID).onGenerating = true;
        final response = await dio.post(imageUrl, data: chatData1);
        pages.getPage(handlePageID).onGenerating = false;

        var mt = DateTime.now().millisecondsSinceEpoch;
        Message msgA = Message(
            id: pages.getPage(handlePageID).messages.length,
            pageID: handlePageID,
            role: MessageRole.assistant,
            type: MsgType.image,
            //fileUrl: ossUrl,
            fileBytes: base64Decode(response.data),
            content: "",
            timestamp: mt);
        pages.addMessage(handlePageID, msgA);
        if (response.statusCode == 200 &&
            pages.getPage(handlePageID).title == "Chat $handlePageID") {
          await titleGenerate(pages, handlePageID);
        }
        String oss_name = "ai${user.id}_${handlePageID}_${mt}.png";
        await uploadImage(pages, handlePageID, msgA.id, oss_name,
            base64Decode(response.data));
        saveChats(user, pages, handlePageID);
      } else {
        var chatData = {
          "model": pages.currentPage?.modelVersion,
          "question": pages.getPage(handlePageID).chatScheme,
        };
        ////debugPrint("send question: ${chatData["question"]}");
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
                id: pages.getPage(handlePageID).messages.length,
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
          if (pages.getPage(handlePageID).title.substring(0, 6) == "Chat 0") {
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

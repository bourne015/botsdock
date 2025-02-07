import 'dart:async';
import 'dart:convert';

import 'package:botsdock/apps/chat/models/chat.dart';
import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/stream.dart';
import 'package:botsdock/apps/chat/vendor/response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:openai_dart/openai_dart.dart' as openai;

import '../models/user.dart';
import '../utils/constants.dart';

class ChatAPI {
  final dio = Dio();

  static Future<void> deleteOSSObj(String url) async {
    try {
      var path = Uri.parse(url).path;
      if (path.contains('%')) path = Uri.decodeFull(path);

      path = path.startsWith('/') ? path.substring(1) : path;
      if (await Client().doesObjectExist(path))
        await Client().deleteObject(path);
    } catch (e) {
      debugPrint("deleteOSSObj error: $e");
    }
  }

  /**
   * delete a chat page
   */
  Future<void> deleteChat(int user_id, int chat_id) async {
    try {
      var chatdbUrl = USER_URL + "/" + "$user_id" + "/chat/" + "$chat_id";
      await dio.delete(chatdbUrl);
    } catch (e) {
      debugPrint("failed to delete chat ${chat_id}, error: $e");
    }
  }

  Future<void> updateUser(int user_id, Map userdata) async {
    try {
      String endpoint = USER_URL + "/" + "${user_id}";
      await dio.post(endpoint, data: userdata);
      // Global.saveProfile(user);
    } catch (e) {
      debugPrint("failed to update user ${user_id}, error: $e");
    }
  }

  /**
   * query user information by user_id
   */
  Future<User?> userInfo(userId) async {
    try {
      String url = "${USER_URL}/${userId}/info";
      Response response = await dio.post(url);
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (error) {
      debugPrint('UserInfo error: $error');
    }
    return null;
  }

  /**
   * get all chat from db
   */
  Future<dynamic> chats(userId) async {
    try {
      String url = "${USER_URL}/${userId}/chats";
      Response cres = await dio.post(url);
      if (cres.statusCode == 200) {
        return cres.data["chats"];
      }
    } catch (error) {
      debugPrint('get chats error: $error');
    }
    return [];
  }

  Future<Map> get_creds() async {
    var res = {};
    try {
      var url = USER_URL + "/23" + "/oss_credentials";
      var response = await dio.post(url);
      res = response.data["credentials"];
    } catch (e) {
      debugPrint("get_creds error: $e");
      return {};
    }
    return res;
  }

  Future<void> titleGenerate(Pages pages, int handlePageID, user) async {
    String q;
    try {
      q = pages.getPage(handlePageID).contentforTitle();
      if (q.isEmpty) return;
      var chatData1 = {
        "model": ModelForTitleGen,
        "question": "为下面段话写一个5个字左右的标题,只需给出最终的标题内容,不要输出其他信息:$q"
      };
      final response = await dio.post(
        "${CHAT_URL}?user_id=${user.id}",
        data: chatData1,
      );
      var title = response.data;
      // in case title too long
      title = title.length > 20 ? title.substring(0, 20) : title;
      pages.setPageTitle(handlePageID, title);
    } catch (e) {
      debugPrint("titleGenerate error: $e");
    }
  }

  //save chats to DB and local cache
  Future<void> saveChats(user, pages, handlePageID) async {
    if (user.id == 0) return;
    var chatdbUrl = "${USER_URL}/${user.id}/chat";
    var chatData = {
      "id": pages.getPage(handlePageID).dbID,
      "page_id": handlePageID,
      "title": pages.getPage(handlePageID).title,
      "contents": pages.getPage(handlePageID).dbContent(),
      "model": pages.getPage(handlePageID).model,
      "assistant_id": pages.getPage(handlePageID).assistantID,
      "thread_id": pages.getPage(handlePageID).threadID,
      "bot_id": pages.getPage(handlePageID).botID,
      "artifact": pages.getPage(handlePageID).artifact,
    };

    try {
      Response cres = await dio.post(
        chatdbUrl,
        data: chatData,
      );
      if (cres.data["result"] == "success") {
        pages.getPage(handlePageID).dbID = cres.data["id"];
        pages.getPage(handlePageID).updated_at = cres.data["updated_at"];

        chatData["id"] = cres.data["id"];
        chatData["dbID"] = cres.data["id"];
        chatData["updated_at"] = cres.data["updated_at"];
        Global.saveChats(
          user.id,
          chatData["id"],
          jsonEncode(chatData),
          cres.data["updated_at"],
        );
      }
    } catch (e) {
      debugPrint("saveChats error: $e");
    }
  }

  void updateCredit(User user) async {
    var url = USER_URL + "/${user.id}" + "/info";
    var response = await dio.post(url);
    if (response.data["result"] == "success")
      user.credit = response.data["credit"];
  }

  Future<String?> uploadFile(filename, imgData) async {
    String? ossUrl;
    try {
      var resp = await Client().putObject(imgData, "chat/image/" + filename);
      ossUrl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
      //if (ossUrl != null) pages.updateFileUrl(pid, msg_id, filename, ossUrl);
    } catch (e) {
      debugPrint("uploadImage to oss error: $e");
    }
    return ossUrl;
  }

  Future<void> _imageGeneration(
      Pages pages, Property property, int handlePageID, user) async {
    var q = pages.getMessages(handlePageID)!.last.content;
    var chatData1 = {
      "model": GPTModel.gptv40Dall,
      "question": q,
    };

    pages.setPageGenerateStatus(handlePageID, true);
    var mt = DateTime.now().millisecondsSinceEpoch;
    var msg_id = pages
        .getPage(handlePageID)
        .addMessage(role: MessageTRole.assistant, text: "", timestamp: mt);
    pages.getPage(handlePageID).messages.last.onProcessing = true;
    final response =
        await dio.post("${IMAGE_URL}?user_id=${user.id}", data: chatData1);
    pages.getPage(handlePageID).messages.last.onProcessing = false;
    pages.setPageGenerateStatus(handlePageID, false);
    String _aiImageName = "ai${user.id}_${handlePageID}_${mt}.png";
    pages.getPage(handlePageID).messages.last.visionFiles = {
      _aiImageName:
          VisionFile(name: "ai_file", bytes: base64Decode(response.data))
    };

    String? ossURL =
        await uploadFile(_aiImageName, base64Decode(response.data));
    pages.getPage(handlePageID).messages[msg_id].updateVisionFiles(
          _aiImageName,
          ossURL ?? "",
        );
    _onStreamDone(pages, handlePageID, user);
  }

  void _onStreamError(Pages pages, int handlePageID, dynamic error) {
    debugPrint('SSE error: $error');
    pages.setPageGenerateStatus(handlePageID, false);
  }

  Future<void> _onStreamDone(pages, handlePageID, user) async {
    debugPrint('SSE complete');
    pages.setPageGenerateStatus(handlePageID, false);
    var pageTitle = pages.getPage(handlePageID).title;
    if (pageTitle.length >= 6 && pageTitle.substring(0, 6) == "Chat 0") {
      await titleGenerate(pages, handlePageID, user);
    }
    saveChats(user, pages, handlePageID);
    updateCredit(user);
  }

  void submitText(
    Pages pages,
    Property property,
    int handlePageID,
    user,
  ) async {
    // StreamSubscription? subscription;
    try {
      if (property.initModelVersion == GPTModel.gptv40Dall) {
        _imageGeneration(pages, property, handlePageID, user);
      } else {
        if (pages.getPage(handlePageID).artifact)
          pages.getPage(handlePageID).addArtifact();
        else
          pages.getPage(handlePageID).removeArtifact();

        var chatData = _prepareChatData(pages, handlePageID);
        final stream = CreateChatStream(
          "${SSE_CHAT_URL}?user_id=${user.id}",
          body: chatData,
        );
        _initializeAssistantMessage(pages, handlePageID);
        stream.listen(
          (data) =>
              _handleChatStream(pages, handlePageID, property, user, data),
          onError: (e) => _onStreamError(pages, handlePageID, e),
          onDone: () => _onStreamDone(pages, handlePageID, user),
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setPageGenerateStatus(handlePageID, false);
    }
  }

  void submitAssistant(
    Pages pages,
    Property property,
    int handlePageID,
    user,
    attachments,
  ) async {
    var assistantId = pages.getPage(handlePageID).assistantID;
    var threadId = pages.getPage(handlePageID).threadID;

    try {
      var chatData = _prepareAssistantData(pages, handlePageID, attachments);

      final stream = CreateAssistantChatStream(
        "${BASE_URL}/v1/assistant/vs/${assistantId}/threads/${threadId}/messages?user_id=${user.id}",
        body: chatData,
      );

      _initializeAssistantMessage(pages, handlePageID);
      stream.listen(
        (event) => AIResponse.openaiAssistant(pages, handlePageID, event),
        onError: (e) => _onStreamError(pages, handlePageID, e),
        onDone: () => _onStreamDone(pages, handlePageID, user),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setGeneratingState(handlePageID, false);
    }
  }

  void newBot(Pages pages, Property property, User user,
      {int? botID,
      String? name,
      String? prompt,
      String? model,
      Map<String, dynamic>? functions}) {
    try {
      int handlePageID = pages.addPage(
          Chat(
              title: name ?? "bot 0",
              model: model ?? property.initModelVersion),
          sort: true);
      property.onInitPage = false;
      pages.currentPageID = handlePageID;
      pages.setPageTitle(handlePageID, name ?? "Chat 0");
      pages.getPage(handlePageID).botID = botID;
      pages.currentPage?.model = model ?? property.initModelVersion;
      if (functions != null && functions.isNotEmpty) {
        if (GPTModel.all.contains(pages.currentPage!.model) ||
            DeepSeekModel.all.contains(pages.currentPage!.model)) {
          functions.forEach((name, body) {
            var func = {"type": "function", "function": json.decode(body)};
            pages.getPage(handlePageID).tools.add(
                  openai.ChatCompletionTool.fromJson(func),
                );
          });
        } else {
          functions.forEach((name, body) {
            var func = json.decode(body);
            var funcschema = func['input_schema'] ?? func['parameters'];
            var jsfunc = {
              "name": func['name'],
              "description": func['description'],
              "input_schema": funcschema
            };
            pages.getPage(handlePageID).claudeTools.add(
                  anthropic.Tool.fromJson(jsfunc),
                );
          });
        }
      }
      pages.getPage(handlePageID).addMessage(
          id: 0,
          role: MessageTRole.system,
          text: prompt ?? "",
          timestamp: DateTime.now().millisecondsSinceEpoch);
      submitText(pages, property, handlePageID, user);
    } catch (e) {
      debugPrint("newBot error: $e");
    }
  }

  void newTextChat(
    Pages pages,
    Property property,
    User user,
    String prompt,
  ) {
    int handlePageID = pages.addPage(
        Chat(title: "Chat 0", model: property.initModelVersion),
        sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    pages.currentPage?.model = property.initModelVersion;

    if (pages.getPage(handlePageID).artifact)
      pages.getPage(handlePageID).addArtifact();
    else
      pages.getPage(handlePageID).removeArtifact();

    pages.getPage(handlePageID).addMessage(
        role: MessageTRole.user,
        text: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    submitText(pages, property, handlePageID, user);
  }
}

void _handleChatStream(
  Pages pages,
  int handlePageID,
  Property property,
  User user,
  data,
) {
  pages.getPage(handlePageID).messages.last.onProcessing = false;
  if (isValidJson(data)) {
    var res = json.decode(data) as Map<String, dynamic>;
    if (GPTModel.all.contains(pages.getPage(handlePageID).model)) {
      AIResponse.Openai(pages, property, user, handlePageID, res);
    } else if (DeepSeekModel.all.contains(pages.getPage(handlePageID).model)) {
      AIResponse.DeepSeek(pages, property, user, handlePageID, res);
    } else if (GeminiModel.all.contains(pages.getPage(handlePageID).model)) {
      AIResponse.Gemini(pages, property, user, handlePageID, res);
    } else if (ClaudeModel.all.contains(pages.getPage(handlePageID).model)) {
      AIResponse.Claude(pages, property, user, handlePageID, res);
    }
  } else {
    pages.getPage(handlePageID).appendMessage(msg: data);
  }
}

/**
   * initialize an empty assistant message to show animation
   */
void _initializeAssistantMessage(Pages pages, int handlePageID) {
  pages.getPage(handlePageID).addMessage(
        role: MessageTRole.assistant,
        text: "",
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
  pages.getPage(handlePageID).messages.last.onProcessing = true;
  pages.setPageGenerateStatus(handlePageID, true);
}

String _prepareChatData(Pages pages, int handlePageID) {
  var jsChat = pages.getPage(handlePageID).toJson();
  var chatData = {
    "model": pages.currentPage?.model,
    "messages": jsChat["messages"],
    "tools": (GPTModel.all.contains(pages.currentPage!.model) ||
            DeepSeekModel.all.contains(pages.currentPage!.model))
        ? jsChat["tools"]
        : jsChat["claude_tools"],
  };
  return jsonEncode(chatData);
}

String _prepareAssistantData(Pages pages, int handlePageID, attachments) {
  var chatData = {
    "role": "user",
    "content": pages.getPage(handlePageID).jsonThreadContent(),
    "attachments":
        attachments.values.map((attachment) => attachment.toJson()).toList()
  };
  return jsonEncode(chatData);
}

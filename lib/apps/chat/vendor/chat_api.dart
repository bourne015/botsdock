import 'dart:async';
import 'dart:convert';

import 'package:botsdock/apps/chat/models/chat.dart';
import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_providers.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/http_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:botsdock/apps/chat/utils/prompts.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/response.dart';

import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

import '../models/user.dart';
import '../utils/constants.dart';

class ChatAPI {
  final dio = DioClient();

  static Future<void> deleteOSSObj(String url) async {
    try {
      var path = Uri.parse(url).path;
      if (path.contains('%')) path = Uri.decodeFull(path);

      path = path.startsWith('/') ? path.substring(1) : path;
      if (await Client().doesObjectExist(path))
        await Client().deleteObject(path);
    } catch (e) {
      Logger.error("deleteOSSObj error: $e");
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
      Logger.error("failed to delete chat ${chat_id}, error: $e");
    }
  }

  Future<void> updateUser(int user_id, Map userdata) async {
    try {
      await dio.post(ChatPath.userUpdate(user_id), data: userdata);
      // Global.saveProfile(user);
    } catch (e) {
      Logger.error("failed to update user ${user_id}, error: $e");
    }
  }

  /**
   * query user information by user_id
   */
  Future<User?> userInfo(userId) async {
    try {
      var _user = await dio.post(ChatPath.userInfo(userId));
      return User.fromJson(_user);
    } catch (error) {
      Logger.error('UserInfo error: $error');
    }
    return null;
  }

  /**
   * get user information by access token
   */
  Future<User?> userFromToken() async {
    try {
      dio.dio.options.headers = {
        "Authorization": ACCESS_TOKEN != null ? "Bearer $ACCESS_TOKEN" : "",
        "Content-Type": "application/json",
      };
      var _user = await dio.get(ChatPath.token);
      return User.fromJson(_user);
    } catch (error) {
      Logger.error('UserInfo error: $error');
    }
    return null;
  }

  /**
   * get all chat from db
   */
  Future<dynamic> chats(userId) async {
    try {
      var _data = await dio.post(ChatPath.allChats(userId));
      return _data["chats"];
    } catch (error) {
      Logger.error('get chats error: $error');
    }
    return [];
  }

  Future<Map> get_creds() async {
    var res = {};
    try {
      var _data = await dio.post(ChatPath.creds(23));
      res = _data["credentials"];
    } catch (e) {
      Logger.error("get_creds error: $e");
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
        "model": ModelForTitleGen.id,
        "question": "为下面段话写一个5个字左右的标题,只需给出最终的标题内容,不要输出其他信息:$q"
      };
      final _data = await dio.post(
        ChatPath.chat(user.id),
        data: chatData1,
      );
      var title = _data;
      // in case title too long
      title = title.length > 20 ? title.substring(0, 20) : title;
      pages.setPageTitle(handlePageID, title);
    } catch (e) {
      Logger.error("titleGenerate error: $e");
    }
  }

  //save chats to DB and local cache
  Future<void> saveChats(User user, Pages pages, handlePageID) async {
    if (user.id == 0) return;
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
      "internet": pages.getPage(handlePageID).internet,
      "temperature": pages.getPage(handlePageID).temperature,
    };

    try {
      final _data = await dio.post(ChatPath.saveChat(user.id), data: chatData);

      if (_data["result"] == "success") {
        pages.getPage(handlePageID).dbID = _data["id"];
        pages.getPage(handlePageID).updated_at = _data["updated_at"];

        chatData["id"] = _data["id"];
        chatData["dbID"] = _data["id"];
        chatData["updated_at"] = _data["updated_at"];
        Global.saveChats(
          user.id,
          chatData["id"],
          jsonEncode(chatData),
          _data["updated_at"],
        );
      }
    } catch (e) {
      Logger.error("saveChats error: $e");
    }
  }

  Future<void> updateCredit(User user) async {
    var _data = await dio.post(ChatPath.userInfo(user.id));
    if (_data["result"] == "success") user.credit = _data["credit"];
  }

  static Future<String?> uploadFile(filename, imgData) async {
    String? ossUrl;
    try {
      var resp = await Client().putObject(imgData, "chat/image/" + filename);
      ossUrl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
      //if (ossUrl != null) pages.updateFileUrl(pid, msg_id, filename, ossUrl);
    } catch (e) {
      Logger.error("uploadImage to oss error: $e");
    }
    return ossUrl;
  }

  Future<void> _imageGeneration(
      Pages pages, Property property, int handlePageID, user) async {
    var q = pages.getMessages(handlePageID)!.last.content;
    var chatData1 = {
      "model": Models.dalle3.id,
      "question": q,
    };

    pages.setPageGenerateStatus(handlePageID, true);
    var mt = DateTime.now().millisecondsSinceEpoch;
    var msg_id = pages
        .getPage(handlePageID)
        .addMessage(role: MessageTRole.assistant, text: "", timestamp: mt);
    pages.getPage(handlePageID).messages.last.onProcessing = true;
    final _data = await dio.post(ChatPath.imageGen(user.id), data: chatData1);
    pages.getPage(handlePageID).messages.last.onProcessing = false;
    pages.setPageGenerateStatus(handlePageID, false);
    String _aiImageName = "ai${user.id}_${handlePageID}_${mt}.png";
    pages.getPage(handlePageID).messages.last.visionFiles = {
      _aiImageName: VisionFile(name: "ai_file", bytes: base64Decode(_data))
    };

    String? ossURL = await uploadFile(_aiImageName, base64Decode(_data));
    pages.getPage(handlePageID).messages[msg_id].updateVisionFiles(
          _aiImageName,
          ossURL ?? "",
        );
    _onStreamDone(pages, handlePageID, user);
  }

  Future<void> _onStreamError(
      Pages pages, int handlePageID, dynamic error) async {
    Logger.error('SSE error: $error');
    pages.setPageGenerateStatus(handlePageID, false);
  }

  Future<void> _onStreamDone(pages, handlePageID, user) async {
    Logger.info('SSE complete');
    pages.setPageGenerateStatus(handlePageID, false);
    var pageTitle = pages.getPage(handlePageID).title;
    if (pageTitle.length >= 6 && pageTitle.substring(0, 6) == "Chat 0") {
      await titleGenerate(pages, handlePageID, user);
    }
    await saveChats(user, pages, handlePageID);
    await updateCredit(user);
  }

  void _cleanupSubscription(Pages page, int handlePageID) {
    int _subscriptionLen = page.getPage(handlePageID).streamSubscription.length;
    for (int i = 1; i < _subscriptionLen; i++) {
      Logger.info("cancel streamSubscription: $i");
      page.getPage(handlePageID).streamSubscription[0].cancel();
      page.getPage(handlePageID).streamSubscription.removeAt(0);
    }
  }

  void submitText(
    Pages pages,
    Property property,
    int handlePageID,
    user,
    rp.WidgetRef ref,
  ) async {
    // StreamSubscription? subscription;
    try {
      // if (pages.getPage(handlePageID).streamSubscription != null)
      //   pages.getPage(handlePageID).streamSubscription!.cancel();
      if (property.initModelVersion == Models.dalle3.id) {
        _imageGeneration(pages, property, handlePageID, user);
      } else {
        pages.getPage(handlePageID).tools.clear();
        if (pages.getPage(handlePageID).model != Models.deepseekReasoner.id) {
          if (pages.getPage(handlePageID).artifact)
            pages
                .getPage(handlePageID)
                .enable_tool(Functions.all["save_artifact"]);
          if (pages.getPage(handlePageID).internet) {
            pages
                .getPage(handlePageID)
                .enable_tool(Functions.all["google_search"]);
            pages
                .getPage(handlePageID)
                .enable_tool(Functions.all["webpage_fetch"]);
          }
          final mcpState = ref.read(mcpClientProvider);
          for (var tools in mcpState.discoveredTools.entries)
            for (var mcpTool in tools.value) {
              pages.getPage(handlePageID).enable_tool({
                "name": mcpTool.name,
                "description": mcpTool.description ?? "",
                "parameters": mcpTool.inputSchema,
              });
            }
          ;
        }
        final stream = await HttpClient.createStream(
          baseUrl: ChatPath.base,
          path: ChatPath.completion,
          queryParams: {"user_id": user.id},
          body: _prepareChatData(pages, handlePageID),
        );
        _initializeAssistantMessage(pages, handlePageID);
        pages.setPageGenerateStatus(handlePageID, true);
        var _streamSubscription = stream
            .asyncMap((data) => _handleChatStream(
                pages, handlePageID, property, user, data, ref))
            .listen(
          (_) {},
          onError: (e) async {
            await _onStreamError(pages, handlePageID, e);
            _cleanupSubscription(pages, handlePageID);
          },
          onDone: () async {
            await _onStreamDone(pages, handlePageID, user);
            _cleanupSubscription(pages, handlePageID);
          },
          cancelOnError: true,
        );
        pages.getPage(handlePageID).streamSubscription.add(_streamSubscription);
      }
    } catch (e, s) {
      Logger.error("gen error: $e, $s");
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
      final stream = HttpClient.CreateAssistantStream(
        baseUrl: ChatPath.base,
        path: ChatPath.asstMessages(assistantId!, threadId!),
        queryParams: {"user_id": user.id},
        body: _prepareAssistantData(pages, handlePageID, attachments),
      );

      _initializeAssistantMessage(pages, handlePageID);
      pages.setPageGenerateStatus(handlePageID, true);
      var _streamSubscription = stream.listen(
        (event) {
          AIResponse.openaiAssistant(pages, handlePageID, event);
        },
        onError: (e) async {
          _onStreamError(pages, handlePageID, e);
          _cleanupSubscription(pages, handlePageID);
        },
        onDone: () async {
          _onStreamDone(pages, handlePageID, user);
          _cleanupSubscription(pages, handlePageID);
        },
        cancelOnError: true,
      );
      pages.getPage(handlePageID).streamSubscription.add(_streamSubscription);
    } catch (e) {
      Logger.error("gen error: $e");
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
        functions.forEach((name, body) {
          if (Functions.all.containsKey(name))
            pages.getPage(handlePageID).enable_tool(Functions.all[name]);
        });
      }
      pages.getPage(handlePageID).addMessage(
          id: 0,
          role: MessageTRole.system,
          text: prompt ?? "",
          timestamp: DateTime.now().millisecondsSinceEpoch);
      //submitText(pages, property, handlePageID, user);
    } catch (e) {
      Logger.error("newBot error: $e");
    }
  }

  void newSampleChat(
    Pages pages,
    Property property,
    User user,
    String prompt,
    ref,
  ) {
    int handlePageID = pages.addPage(
        Chat(
          title: "Chat 0",
          model: property.initModelVersion,
          artifact: user.settings?.artifact ?? false,
          internet: user.settings?.internet ?? false,
          temperature: user.settings?.temperature,
        ),
        sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    pages.currentPage?.model = property.initModelVersion;

    // if (pages.getPage(handlePageID).artifact)
    //   pages.getPage(handlePageID).addArtifact();
    // else
    //   pages.getPage(handlePageID).removeArtifact();
    // if (pages.getPage(handlePageID).internet)
    //   pages.getPage(handlePageID).enableInternet();
    // else
    //   pages.getPage(handlePageID).disableInternet();
    pages.getPage(handlePageID).addMessage(
        role: MessageTRole.user,
        text: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    submitText(pages, property, handlePageID, user, ref);
  }
}

Future<void> _handleChatStream(
  Pages pages,
  int handlePageID,
  Property property,
  User user,
  String? data,
  rp.WidgetRef ref,
) async {
  pages.getPage(handlePageID).messages.last.onProcessing = false;
  if (data != null && isValidJson(data)) {
    var res = json.decode(data);
    String modelID = pages.getPage(handlePageID).model;
    if (Models.getOrgByModelId(modelID) == Organization.openai) {
      await AIResponse.Openai(pages, property, user, handlePageID, res, ref);
    } else if (Models.getOrgByModelId(modelID) == Organization.deepseek) {
      await AIResponse.DeepSeek(pages, property, user, handlePageID, res, ref);
    } else if (Models.getOrgByModelId(modelID) == Organization.google) {
      await AIResponse.Gemini(pages, property, user, handlePageID, res, ref);
    } else if (Models.getOrgByModelId(modelID) == Organization.anthropic) {
      await AIResponse.Claude(pages, property, user, handlePageID, res, ref);
    }
  } else {
    await pages.getPage(handlePageID).appendMessage(msg: data);
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

Object _prepareChatData(Pages pages, int handlePageID) {
  var jsChat = pages.getPage(handlePageID).toJson();

  var chatData = {
    "model": pages.getPage(handlePageID).model,
    "messages": jsChat["messages"],
    "tools": jsChat["tools"] ?? [],
    "temperature": pages.getPage(handlePageID).temperature,
  };
  return chatData;
}

Object _prepareAssistantData(Pages pages, int handlePageID, attachments) {
  var chatData = {
    "role": "user",
    "content": pages.getPage(handlePageID).jsonThreadContent(),
    "attachments":
        attachments.values.map((attachment) => attachment.toJson()).toList()
  };
  return chatData;
}

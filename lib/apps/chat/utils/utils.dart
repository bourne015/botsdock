import 'package:dual_screen/dual_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';

import '../models/anthropic/schema/schema.dart' as anthropic;
import '../models/openai/schema/schema.dart' as openai;
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/data.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/global.dart';
import './client.dart';

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

class ChatGen {
  final dio = Dio();

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
  void saveChats(user, pages, handlePageID) async {
    if (user.id != 0) {
      //only store after user login
      var chatdbUrl = USER_URL + "/" + "${user.id}" + "/chat";
      var chatData = {
        "id": pages.getPage(handlePageID).dbID,
        "page_id": handlePageID,
        "title": pages.getPage(handlePageID).title,
        "contents": pages.getPage(handlePageID).dbContent(),
        "model": pages.getPage(handlePageID).model,
        "assistant_id": pages.getPage(handlePageID).assistantID,
        "thread_id": pages.getPage(handlePageID).threadID,
        "bot_id": pages.getPage(handlePageID).botID,
      };

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
            chatData["id"], jsonEncode(chatData), cres.data["updated_at"]);
      }
    }
  }

  void updateCredit(User user) async {
    var url = USER_URL + "/${user.id}" + "/info";
    var response = await dio.post(url);
    if (response.data["result"] == "success")
      user.credit = response.data["credit"];
  }

  Future<String?> uploadImage(pages, pid, oss_name, filename, imgData) async {
    String? ossUrl;
    try {
      var resp = await Client().putObject(imgData, "chat/image/" + oss_name);
      ossUrl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
      //if (ossUrl != null) pages.updateFileUrl(pid, msg_id, filename, ossUrl);
    } catch (e) {
      debugPrint("uploadImage to oss error: $e");
    }
    return ossUrl;
  }

  void submitAssistant(
    Pages pages,
    Property property,
    int handlePageID,
    user,
    attachments,
  ) async {
    var assistant_id = pages.getPage(handlePageID).assistantID;
    var thread_id = pages.getPage(handlePageID).threadID;
    var _url =
        "${BASE_URL}/v1/assistant/vs/${assistant_id}/threads/${thread_id}/messages";
    try {
      var chatData = {
        "role": "user",
        "content": pages.getPage(handlePageID).jsonThreadContent(),
        "attachments":
            attachments.values.map((attachment) => attachment.toJson()).toList()
      };
      ////debugPrint("send question: ${chatData["question"]}");
      final stream = CreateAssistantChatStream(
        "${_url}?user_id=${user.id}",
        "POST",
        body: jsonEncode(chatData),
      );

      pages.getPage(handlePageID).addMessage(
          role: MessageTRole.assistant,
          text: "",
          timestamp: DateTime.now().millisecondsSinceEpoch);

      pages.setGeneratingState(handlePageID, true);
      stream.listen(
        (event) {
          _handleAssistantStream(pages, handlePageID, event);
        },
        onError: (e) => _handleStreamError(pages, handlePageID, e),
        onDone: () => _handleStreamDone(pages, handlePageID, user),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setGeneratingState(handlePageID, false);
    }
  }

  void _handleAssistantStream(
    Pages pages,
    int handlePageID,
    event,
  ) {
    String? _text;
    Map<String, Attachment> attachments = {};
    Map<String, VisionFile> visionFiles = {};
    if (event is openai.MessageStreamEvent &&
        event.event == openai.EventType.threadMessageCreated) {}
    event.when(
        threadStreamEvent: (final event, final data) {},
        runStreamEvent: (final event, final data) {},
        runStepStreamEvent: (final event, final data) {
          if (data.usage != null) {
            debugPrint("promptTokens: ${data.usage!.promptTokens}");
            debugPrint("completionTokens: ${data.usage!.completionTokens}");
            debugPrint("totalTokens: ${data.usage!.totalTokens}");
          }
        },
        runStepStreamDeltaEvent: (final event, final data) {
          data.delta.stepDetails!.whenOrNull(
            toolCalls: (type, toolCalls) {
              debugPrint("$type, $toolCalls");
            },
          );
        },
        messageStreamEvent: (final event, final data) {},
        messageStreamDeltaEvent: (final event, final data) {
          if (data.delta.content != null)
            data.delta.content![0].whenOrNull(
                imageFile: (index, type, imageFileObj) {
              var _image_fild_id = imageFileObj!.fileId;
              attachments["${_image_fild_id}"] =
                  Attachment(file_id: _image_fild_id);
            }, text: (index, type, textObj) {
              _text = textObj!.value;
              if (textObj.annotations != null &&
                  textObj.annotations!.isNotEmpty)
                textObj.annotations!.forEach((annotation) {
                  annotation.whenOrNull(fileCitation: (index, type, text,
                      file_citation, start_index, end_index) {
                    var file_name = text!.split('/').last;
                    attachments[file_name] =
                        Attachment(file_id: file_citation!.fileId);
                  }, filePath:
                      (index, type, text, file_path, start_index, end_index) {
                    var file_name = text!.split('/').last;
                    attachments[file_name] =
                        Attachment(file_id: file_path!.fileId);
                  });
                });
            });
          //});
        },
        errorEvent: (final event, final data) {},
        doneEvent: (final event, final data) {});

    if (_text != null)
      pages.getPage(handlePageID).appendMessage(
          msg: _text,
          visionFiles: copyVision(visionFiles),
          attachments: copyAttachment(attachments));
    //pages.setGeneratingState(handlePageID, true);
  }

  bool isValidJson(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } on FormatException catch (_) {
      return false;
    }
  }

  void submitText(
    Pages pages,
    Property property,
    int handlePageID,
    user,
  ) async {
    StreamSubscription? subscription;
    try {
      if (property.initModelVersion == GPTModel.gptv40Dall) {
        _imageGeneration(pages, property, handlePageID, user);
      } else {
        var jsChat = pages.getPage(handlePageID).toJson();
        var chatData = {
          "model": pages.currentPage?.model,
          "messages": jsChat["messages"],
          "tools": pages.currentPage!.model.startsWith('gpt')
              ? jsChat["tools"]
              : jsChat["claude_tools"],
        };
        final stream = CreateChatStream(
          "${SSE_CHAT_URL}?user_id=${user.id}",
          "POST",
          body: jsonEncode(chatData),
        );
        pages.getPage(handlePageID).addMessage(
              role: MessageTRole.assistant,
              text: "",
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
        pages.getPage(handlePageID).messages.last.onThinking = true;
        pages.setPageGenerateStatus(handlePageID, true);
        stream.listen(
          (data) {
            _handleChatStream(pages, handlePageID, property, user, data);
          },
          onError: (e) => _handleStreamError(pages, handlePageID, e),
          onDone: () => _handleStreamDone(pages, handlePageID, user),
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setPageGenerateStatus(handlePageID, false);
    }
  }

  void _handleChatStream(
    Pages pages,
    int handlePageID,
    Property property,
    User user,
    data,
  ) {
    pages.getPage(handlePageID).messages.last.onThinking = false;
    if (isValidJson(data)) {
      var res = json.decode(data) as Map<String, dynamic>;
      if (pages.getPage(handlePageID).model.startsWith('gpt')) {
        _handleOpenaiResponse(pages, property, user, handlePageID, res);
      } else {
        _handleClaudeResponse(pages, property, user, handlePageID, res);
      }
    }
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
    pages.getPage(handlePageID).messages.last.onThinking = true;
    final response =
        await dio.post("${IMAGE_URL}?user_id=${user.id}", data: chatData1);
    pages.getPage(handlePageID).messages.last.onThinking = false;
    pages.setPageGenerateStatus(handlePageID, false);
    String _aiImageName = "ai${user.id}_${handlePageID}_${mt}.png";
    pages.getPage(handlePageID).messages.last.visionFiles = {
      _aiImageName:
          VisionFile(name: "ai_file", bytes: base64Decode(response.data))
    };

    String? ossURL = await uploadImage(pages, handlePageID, _aiImageName,
        _aiImageName, base64Decode(response.data));
    pages.getPage(handlePageID).messages[msg_id].updateVisionFiles(
          _aiImageName,
          ossURL ?? "",
        );
    _handleStreamDone(pages, handlePageID, user);
  }

  void _handleStreamError(Pages pages, int handlePageID, dynamic error) {
    debugPrint('SSE error: $error');
    pages.setPageGenerateStatus(handlePageID, false);
  }

  Future<void> _handleStreamDone(pages, handlePageID, user) async {
    debugPrint('SSE complete');
    pages.setPageGenerateStatus(handlePageID, false);
    var pageTitle = pages.getPage(handlePageID).title;
    if (pageTitle.length >= 6 && pageTitle.substring(0, 6) == "Chat 0") {
      await titleGenerate(pages, handlePageID, user);
    }
    saveChats(user, pages, handlePageID);
    updateCredit(user);
  }

  void _handleOpenaiResponse(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);
    pages.getPage(handlePageID).appendMessage(
          msg: res.choices[0].delta.content,
          toolCalls: res.choices[0].delta.toolCalls,
        );

    if (res.choices[0].finishReason ==
        openai.ChatCompletionFinishReason.toolCalls) {
      pages.getPage(handlePageID).setOpenaiToolInput();
      var _toolID = pages.getPage(handlePageID).messages.last.toolCalls.last.id;
      pages.getPage(handlePageID).addMessage(
            role: MessageTRole.tool,
            text: "function result",
            toolCallId: _toolID,
          );
      submitText(pages, property, handlePageID, user);
    }
  }

  void _handleClaudeResponse(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    try {
      anthropic.MessageStreamEvent res =
          anthropic.MessageStreamEvent.fromJson(j);
      res.whenOrNull(
        contentBlockStart:
            (anthropic.Block b, int i, anthropic.MessageStreamEventType t) {
          pages.getPage(handlePageID).addTool(
                  toolUse: b.mapOrNull(
                toolUse: (x) => anthropic.ToolUseBlock(
                  id: x.id,
                  name: x.name,
                  input: x.input,
                ),
              ));
        },
        contentBlockDelta: (anthropic.BlockDelta b, int i,
            anthropic.MessageStreamEventType t) {
          pages.getPage(handlePageID).appendMessage(
                index: i,
                msg: b.mapOrNull(textDelta: (x) => x.text),
                toolUse: b.mapOrNull(inputJsonDelta: (x) => x.partialJson),
              );
        },
        contentBlockStop: (int i, anthropic.MessageStreamEventType t) {
          if (pages.getPage(handlePageID).messages.last.content is List &&
              pages.getPage(handlePageID).messages.last.content[i].type ==
                  "tool_use") {
            pages.getPage(handlePageID).setClaudeToolInput(i);
            var _toolID =
                pages.getPage(handlePageID).messages.last.content[i].id;
            pages.getPage(handlePageID).addMessage(role: MessageTRole.user);
            pages.getPage(handlePageID).addTool(
                  toolResult: anthropic.ToolResultBlock(
                    toolUseId: _toolID,
                    isError: false,
                    content:
                        anthropic.ToolResultBlockContent.text("tool result"),
                  ),
                );
            submitText(pages, property, handlePageID, user);
          }
        },
      );
    } catch (e) {
      pages.getPage(handlePageID).appendMessage(
            msg: j.toString() + e.toString(),
          );
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
        if (pages.currentPage!.model.startsWith('gpt')) {
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

    pages.getPage(handlePageID).addMessage(
        id: 0,
        role: MessageTRole.user,
        text: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    submitText(pages, property, handlePageID, user);
  }
}

Map<String, VisionFile> copyVision(Map? original) {
  Map<String, VisionFile> copy = {};
  if (original == null) return copy;
  original.forEach((_filename, _content) {
    copy[_filename] =
        VisionFile(name: _filename, bytes: _content.bytes, url: _content.url);
  });
  return copy;
}

Map<String, Attachment> copyAttachment(Map? original) {
  Map<String, Attachment> copy = {};
  if (original == null) return copy;
  original.forEach((_filename, _content) {
    copy[_filename] =
        Attachment(file_id: _content.file_id, tools: List.from(_content.tools));
  });
  return copy;
}

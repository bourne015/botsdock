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

import '../models/anthropic/schema/schema.dart' as anthropic;
import '../models/openai/schema/schema.dart' as openai;
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/message.dart';
import '../models/data.dart';
import '../models/openai/schema/schema.dart';
import '../models/user.dart';
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

Future<http.StreamedResponse> makeRequestStream(
  String url,
  String method,
  Map<String, String>? headers,
  String? body,
) async {
  var response;
  var request = http.Request(method, Uri.parse(url));
  if (headers != null) request.headers.addAll(headers);
  if (body != null) request.body = body;
  try {
    var client;
    if (kIsWeb)
      client = FetchClient(mode: RequestMode.cors);
    else
      client = http.Client();
    response = await client.send(request);
  } catch (e) {
    print("error: ${e}");
  }
  return response;
}

class _PairwiseTransformer
    extends StreamTransformerBase<String, (String, String)> {
  @override
  Stream<(String, String)> bind(final Stream<String> stream) {
    late StreamController<(String, String)> controller;
    late StreamSubscription<String> subscription;
    late String event;

    controller = StreamController<(String, String)>(
      onListen: () {
        subscription = stream.listen(
          (final String data) {
            try {
              if (data.isNotEmpty) {
                final parsedData = json.decode(data);
                final event = parsedData['event'] as String;
                final dataStr = json.encode(parsedData['data']);
                controller.add((event, dataStr));
              }
            } catch (e) {
              print("_PairwiseTransformer error: ${e}");
            }
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: true,
        );
      },
      onPause: ([final resumeSignal]) => subscription.pause(resumeSignal),
      onResume: () => subscription.resume(),
      onCancel: () async => subscription.cancel(),
    );

    return controller.stream;
  }
}

class _OpenAIAssistantStreamTransformer
    extends StreamTransformerBase<List<int>, AssistantStreamEvent> {
  const _OpenAIAssistantStreamTransformer();

  @override
  Stream<AssistantStreamEvent> bind(final Stream<List<int>> stream) {
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(_DataPreprocessorTransformer())
        .transform(_PairwiseTransformer())
        .map((final item) {
      final (event, data) = item;
      //print("event:${event}");
      print("data:${data}");

      Map<String, dynamic> getEventDataMap({final bool decode = true}) => {
            'event': event,
            'data': decode ? json.decode(data) : data,
          };

      switch (event) {
        case 'thread.created':
          return ThreadStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.created':
        case 'thread.run.queued':
        case 'thread.run.in_progress':
        case 'thread.run.requires_action':
        case 'thread.run.completed':
        case 'thread.run.failed':
        case 'thread.run.cancelling':
        case 'thread.run.cancelled':
        case 'thread.run.expired':
          return RunStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.created':
        case 'thread.run.step.in_progress':
        case 'thread.run.step.completed':
        case 'thread.run.step.failed':
        case 'thread.run.step.cancelled':
        case 'thread.run.step.expired':
          return RunStepStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.delta':
          return RunStepStreamDeltaEvent.fromJson(getEventDataMap());
        case 'thread.message.created':
        case 'thread.message.in_progress':
        case 'thread.message.completed':
        case 'thread.message.incomplete':
          return MessageStreamEvent.fromJson(getEventDataMap());
        case 'thread.message.delta':
          return MessageStreamDeltaEvent.fromJson(getEventDataMap());
        case 'error':
          return ErrorEvent.fromJson(getEventDataMap());
        case 'done':
          return DoneEvent.fromJson(getEventDataMap(decode: false));
        default:
          throw Exception('Unknown event: $event');
      }
    });
  }
}

class _DataPreprocessorTransformer
    extends StreamTransformerBase<String, String> {
  @override
  Stream<String> bind(final Stream<String> stream) {
    return stream.map((String data) {
      if (data.isNotEmpty) {
        var newData = 'data: ';
        newData = data.substring(5).replaceFirst(' ', '');
        data = data.length > 0 ? data : '\n';
        return newData;
      }
      return data;
    });
  }
}

Stream<AssistantStreamEvent> connectAssistant(
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
  var stream = response.stream;
  yield* stream.transform(const _OpenAIAssistantStreamTransformer());
}

class _OpenAIStreamTransformer
    extends StreamTransformerBase<List<int>, String> {
  const _OpenAIStreamTransformer();

  @override
  Stream<String> bind(final Stream<List<int>> stream) {
    return stream //
        .transform(utf8.decoder) //
        .transform(const LineSplitter()) //
        .where((final i) => i.startsWith('data: ') && !i.endsWith('[DONE]'))
        .map((final item) => item.substring(6));
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
    var _newLine = false;

    try {
      stream.transform(const LineSplitter()).listen((String line) {
        if (line.length == 0) {
          _newLine = false;
        } else if (line.startsWith('data:')) {
          var data = line.substring(6);
          data = _newLine ? '\n' + data : data;
          controller.add(data);
          _newLine = true;
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

class ChatGen {
  final dio = Dio();
  final ChatSSE chatServer = ChatSSE();
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

  void submitAssistant(Pages pages, Property property, int handlePageID, user,
      attachments) async {
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
      final stream = connectAssistant(
        "${_url}?user_id=${user.id}",
        "POST",
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream'
        },
        body: jsonEncode(chatData),
      );

      pages.getPage(handlePageID).addMessage(
          role: MessageTRole.assistant,
          text: "",
          timestamp: DateTime.now().millisecondsSinceEpoch);

      pages.setGeneratingState(handlePageID, true);
      stream.listen((event) {
        String? _text;
        Map<String, Attachment> attachments = {};
        Map<String, VisionFile> visionFiles = {};
        if (event is MessageStreamEvent &&
            event.event == EventType.threadMessageCreated) {}
        event.when(
            threadStreamEvent: (final event, final data) {},
            runStreamEvent: (final event, final data) {},
            runStepStreamEvent: (final event, final data) {
              if (data.usage != null) {
                print("promptTokens: ${data.usage!.promptTokens}");
                print("completionTokens: ${data.usage!.completionTokens}");
                print("totalTokens: ${data.usage!.totalTokens}");
              }
            },
            runStepStreamDeltaEvent: (final event, final data) {
              data.delta.stepDetails!.whenOrNull(
                toolCalls: (type, toolCalls) {
                  print("$type, $toolCalls");
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
                      }, filePath: (index, type, text, file_path, start_index,
                          end_index) {
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
      }, onError: (e) {
        debugPrint('SSE error: $e');
        pages.setGeneratingState(handlePageID, false);
      }, onDone: () async {
        pages.setGeneratingState(handlePageID, false);
        debugPrint('SSE complete');
        // if (msgA != null) pages.getPage(handlePageID).updateScheme(msgA!.id);
        var pageTitle = pages.getPage(handlePageID).title;
        if (pageTitle.length >= 6 && pageTitle.startsWith("Chat 0")) {
          await titleGenerate(pages, handlePageID, user);
        }
        saveChats(user, pages, handlePageID);
        updateCredit(user);
      });
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setGeneratingState(handlePageID, false);
    }
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
      Pages pages, Property property, int handlePageID, user) async {
    try {
      if (property.initModelVersion == GPTModel.gptv40Dall) {
        String q = pages.getMessages(handlePageID)!.last.content;
        var chatData1 = {"model": GPTModel.gptv40Dall, "question": q};
        pages.setPageGenerateStatus(handlePageID, true);
        final response =
            await dio.post("${IMAGE_URL}?user_id=${user.id}", data: chatData1);
        pages.setPageGenerateStatus(handlePageID, false);

        var mt = DateTime.now().millisecondsSinceEpoch;
        String _aiImageName = "ai${user.id}_${handlePageID}_${mt}.png";

        var msg_id = pages.getPage(handlePageID).addMessage(
            role: MessageTRole.assistant,
            text: "",
            visionFiles: {
              _aiImageName: VisionFile(
                  name: "ai_file", bytes: base64Decode(response.data))
            },
            timestamp: mt);

        if (response.statusCode == 200 &&
            pages.getPage(handlePageID).title == "Chat 0") {
          await titleGenerate(pages, handlePageID, user);
        }

        String? ossURL = await uploadImage(pages, handlePageID, _aiImageName,
            _aiImageName, base64Decode(response.data));
        if (ossURL != null)
          pages.getPage(handlePageID).updateVision(
                msg_id,
                _aiImageName,
                ossURL,
              );
        saveChats(user, pages, handlePageID);
        updateCredit(user);
      } else {
        var jsChat = pages.getPage(handlePageID).toJson();
        var chatData = {
          "model": pages.currentPage?.model,
          "messages": jsChat["messages"],
          "tools": pages.currentPage!.model.startsWith('gpt')
              ? jsChat["tools"]
              : jsChat["claude_tools"],
        };
        print("$chatData");
        ////debugPrint("send question: ${chatData["question"]}");
        final stream = chatServer.connect(
          "${SSE_CHAT_URL}?user_id=${user.id}",
          "POST",
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream'
          },
          body: jsonEncode(chatData),
        );
        pages.getPage(handlePageID).addMessage(
              role: MessageTRole.assistant,
              text: "",
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
        pages.getPage(handlePageID).messages.last.onThinking = true;
        pages.setPageGenerateStatus(handlePageID, true);
        stream.listen((data) {
          print("data");
          pages.getPage(handlePageID).messages.last.onThinking = false;
          if (isValidJson(data)) {
            var res = json.decode(data) as Map<String, dynamic>;
            if (pages.getPage(handlePageID).model.startsWith('gpt')) {
              _handleOpenaiResponse(pages, property, user, handlePageID, res);
            } else {
              _handleClaudeResponse(pages, property, user, handlePageID, res);
            }
          }
        }, onError: (e) {
          debugPrint('SSE error: $e');
          pages.setPageGenerateStatus(handlePageID, false);
        }, onDone: () async {
          debugPrint('SSE complete');
          pages.setPageGenerateStatus(handlePageID, false);
          var pageTitle = pages.getPage(handlePageID).title;
          if (pageTitle.length >= 6 && pageTitle.substring(0, 6) == "Chat 0") {
            await titleGenerate(pages, handlePageID, user);
          }
          saveChats(user, pages, handlePageID);
          updateCredit(user);
        });
      }
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setPageGenerateStatus(handlePageID, false);
    }
  }

  void _handleOpenaiResponse(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);
    pages.getPage(handlePageID).appendMessage(
          msg: res.choices[0].delta.content,
          toolCalls: res.choices[0].delta.toolCalls,
        );

    if (res.choices[0].finishReason == ChatCompletionFinishReason.toolCalls) {
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
    anthropic.MessageStreamEvent res = anthropic.MessageStreamEvent.fromJson(j);
    res.map(
      messageStart: (anthropic.MessageStartEvent v) {
        print("messageStart");
      },
      messageDelta: (anthropic.MessageDeltaEvent v) {
        print("messageDelta");
      },
      messageStop: (anthropic.MessageStopEvent v) {
        print("messageStop");
      },
      contentBlockStart: (anthropic.ContentBlockStartEvent v) {
        pages.getPage(handlePageID).addTool(
                toolUse: v.contentBlock.mapOrNull(
              toolUse: (x) => anthropic.ToolUseBlock(
                id: x.id,
                name: x.name,
                input: x.input,
              ),
            ));
      },
      contentBlockDelta: (anthropic.ContentBlockDeltaEvent v) {
        pages.getPage(handlePageID).appendMessage(
              index: v.index,
              msg: v.delta.mapOrNull(textDelta: (x) => x.text),
              toolUse: v.delta.mapOrNull(inputJsonDelta: (x) => x.partialJson),
            );
      },
      contentBlockStop: (anthropic.ContentBlockStopEvent v) {
        print("contentBlockStop");
        if (pages.getPage(handlePageID).messages.last.content is List &&
            pages.getPage(handlePageID).messages.last.content[v.index].type ==
                "tool_use") {
          pages.getPage(handlePageID).setClaudeToolInput(v.index);
          var _toolID =
              pages.getPage(handlePageID).messages.last.content[v.index].id;
          pages.getPage(handlePageID).addMessage(role: MessageTRole.user);
          print("toolID: ${_toolID}");
          pages.getPage(handlePageID).addTool(
                toolResult: anthropic.ToolResultBlock(
                  toolUseId: _toolID,
                  isError: false,
                  content: anthropic.ToolResultBlockContent.text("tool result"),
                ),
              );
          submitText(pages, property, handlePageID, user);
        }
      },
      ping: (anthropic.PingEvent v) {
        print("ping");
      },
    );
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
      if (functions != null) {
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
            pages.getPage(handlePageID).claudeTools.add(
                  ClaudeTool(
                    name: func['name'],
                    description: func['description'],
                    inputSchema: funcschema,
                  ),
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
      print("newBot error: $e");
    }
  }

  void newTextChat(Pages pages, Property property, User user, String prompt) {
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

Future<void> deleteOSSObj(String url) async {
  try {
    var path = Uri.parse(url).path;
    if (path.contains('%')) path = Uri.decodeFull(path);

    path = path.startsWith('/') ? path.substring(1) : path;
    if (await Client().doesObjectExist(path)) await Client().deleteObject(path);
  } catch (e) {
    debugPrint("deleteOSSObj error: $e");
  }
}
